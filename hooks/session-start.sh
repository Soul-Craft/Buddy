#!/usr/bin/env bash
# session-start.sh — Inject dev context into Claude's session at startup.
#
# Output becomes "SessionStart hook additional context" in system-reminder.
# Designed to be plan-friendly: dynamic skill/agent/hook discovery, origin/main
# comparison, and pending-cleanup retry for /session-deploy.
#
# Must always exit 0 — never block session startup.
# Target budget: ≤60 lines output, ≤10s execution (cached fetch keeps most runs <2s).
set -uo pipefail

# --- Resolve project root ---
PROJECT_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PROJECT_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# --- Portable timeout wrapper (macOS has no `timeout` command) ---
# Usage: run_with_timeout SECS CMD [ARGS...]
# Returns: exit code of CMD, or 124 if killed by timeout.
run_with_timeout() {
  local secs=$1; shift
  "$@" &
  local pid=$!
  ( sleep "$secs"; kill -9 "$pid" 2>/dev/null ) &
  local killer=$!
  wait "$pid" 2>/dev/null
  local status=$?
  kill "$killer" 2>/dev/null
  wait "$killer" 2>/dev/null || true
  return "$status"
}

# --- Git State: branch, uncommitted, fetch, origin/main comparison ---
git_branch=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
git_short=$(git -C "$PROJECT_ROOT" status --short 2>/dev/null || echo "")
uncommitted=0
if [[ -n "$git_short" ]]; then
  uncommitted=$(echo "$git_short" | wc -l | tr -d ' ')
fi
git_log=$(git -C "$PROJECT_ROOT" log --oneline -3 2>/dev/null || echo "  (no commits)")

# Cached fetch: skip network call if we fetched within the last 5 minutes.
# This is the key to staying under the 10s hook budget on slow networks.
fetch_state="skipped (cached)"
FETCH_HEAD_PATH=$(git -C "$PROJECT_ROOT" rev-parse --git-path FETCH_HEAD 2>/dev/null || echo "")
fetch_age=9999
if [[ -n "$FETCH_HEAD_PATH" && -f "$FETCH_HEAD_PATH" ]]; then
  mtime=$(stat -f %m "$FETCH_HEAD_PATH" 2>/dev/null || echo 0)
  now=$(date +%s)
  fetch_age=$(( now - mtime ))
fi

if (( fetch_age >= 300 )); then
  # Fetch needed. Use low-speed timeout (bounds slow connections) + bash timeout (bounds hung connects).
  if run_with_timeout 4 git -C "$PROJECT_ROOT" \
       -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=3 \
       fetch --quiet origin main 2>/dev/null; then
    fetch_state="fetched just now"
  else
    fetch_state="fetch timed out (using last known state)"
  fi
else
  if (( fetch_age < 60 )); then
    fetch_state="fetched <1m ago"
  else
    fetch_state="fetched $(( fetch_age / 60 ))m ago"
  fi
fi

# Compare current branch to origin/main. We care about main-relative distance,
# not @{u}-relative, because feature branches diverge from main, not from themselves.
main_behind=$(git -C "$PROJECT_ROOT" rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
main_ahead=$(git -C "$PROJECT_ROOT" rev-list --count origin/main..HEAD 2>/dev/null || echo "?")

# Stale warning threshold (tune here if needed): > 10 commits behind main is concerning.
stale_marker=""
if [[ "$main_behind" =~ ^[0-9]+$ ]] && (( main_behind > 10 )); then
  stale_marker="  ⚠ STALE — consider rebasing onto main"
fi

# --- Binary Info ---
binary=$(readlink ~/.local/bin/claude 2>/dev/null || echo "")
binary_status="not found"
version="unknown"
if [[ -n "$binary" && -f "$binary" ]]; then
  version=$(basename "$binary")
  binary_status="found"
fi

# --- Backup & Metadata Health ---
backup_status="no backup"
if [[ -n "$binary" && -f "${binary}.original-backup" ]]; then
  backup_status="backup exists"
fi
meta_status="no metadata"
if [[ -f "$HOME/.claude/backups/buddy-patch-meta.json" ]]; then
  meta_status="metadata exists"
fi

# --- Compatibility (dry-run, only if patcher is already compiled) ---
PATCHER_BIN="$PROJECT_ROOT/scripts/BuddyPatcher/.build/release/buddy-patcher"
compat="not checked (patcher not compiled)"
if [[ -f "$PATCHER_BIN" && "$binary_status" == "found" ]]; then
  dry_output=$("$PROJECT_ROOT/scripts/run-buddy-patcher.sh" \
    --dry-run --species dragon --rarity legendary --shiny \
    --emoji "🐲" --name "Test" --personality "Test" 2>&1 || true)
  if echo "$dry_output" | grep -q '\[!\] WARNING'; then
    compat="WARNINGS (see dry-run output)"
  elif echo "$dry_output" | grep -q '\[DRY RUN\]'; then
    compat="dry-run ok"
  else
    compat="could not determine"
  fi
fi

# --- Cache State ---
build_count=0
MAIN_REPO_FOR_CACHE="$PROJECT_ROOT"
if [[ -f "$PROJECT_ROOT/.git" ]]; then
  MAIN_REPO_FOR_CACHE=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
  [[ -z "$MAIN_REPO_FOR_CACHE" ]] && MAIN_REPO_FOR_CACHE="$PROJECT_ROOT"
fi
WORKTREES_DIR="$MAIN_REPO_FOR_CACHE/.claude/worktrees"
if [[ -d "$WORKTREES_DIR" ]]; then
  while IFS= read -r -d '' _; do
    build_count=$((build_count + 1))
  done < <(find "$WORKTREES_DIR" -maxdepth 4 -name ".build" -type d -print0 2>/dev/null)
fi
[[ -d "$PROJECT_ROOT/scripts/BuddyPatcher/.build" ]] && build_count=$((build_count + 1))

# --- Dynamic skill discovery ---
# Parse frontmatter `name:` + first sentence of `description:` from each SKILL.md.
# Output: one line per skill, sorted alphabetically, max 15 visible, descriptions capped at 60 chars.
discover_skills() {
  local total=0
  local skills_dir="$PROJECT_ROOT/skills"
  [[ ! -d "$skills_dir" ]] && return 0

  # Collect all skills into a temp list first (for total count)
  local lines=()
  for f in "$skills_dir"/*/SKILL.md; do
    [[ -f "$f" ]] || continue
    total=$((total + 1))
    local name
    local desc
    name=$(awk '
      /^---$/ { c++; next }
      c==1 && /^name:/ { sub(/^name: *"?/,""); sub(/"? *$/,""); print; exit }
    ' "$f")
    desc=$(awk '
      /^---$/ { c++; next }
      c==1 && /^description:/ {
        sub(/^description: *"?/,"")
        # Take only first line of multi-line descriptions
        sub(/ *"? *$/,"")
        # Truncate at first period or 80 chars
        if (match($0, /\. /)) $0 = substr($0, 1, RSTART - 1)
        if (length($0) > 60) $0 = substr($0, 1, 57) "..."
        print
        exit
      }
    ' "$f")
    [[ -z "$name" ]] && continue
    lines+=("$(printf "  /%-18s %s" "$name" "$desc")")
  done

  # Sort and print up to 15
  printf '%s\n' "${lines[@]}" | sort | head -15
  if (( total > 15 )); then
    printf "  ... and %d more — run /start-session\n" $(( total - 15 ))
  fi
}

# --- Dynamic agent discovery ---
# Parse `name:` and first-sentence `description:` from agent markdown files in two locations.
discover_agents() {
  local locations=("$PROJECT_ROOT/agents" "$PROJECT_ROOT/.claude-plugin/agents")
  local lines=()
  for dir in "${locations[@]}"; do
    [[ ! -d "$dir" ]] && continue
    for f in "$dir"/*.md; do
      [[ -f "$f" ]] || continue
      local name
      local desc
      name=$(awk '
        /^---$/ { c++; next }
        c==1 && /^name:/ { sub(/^name: *"?/,""); sub(/"? *$/,""); print; exit }
      ' "$f")
      desc=$(awk '
        /^---$/ { c++; next }
        c==1 && /^description:/ {
          sub(/^description: *"?/,"")
          sub(/ *"? *$/,"")
          if (match($0, /\. /)) $0 = substr($0, 1, RSTART - 1)
          if (length($0) > 60) $0 = substr($0, 1, 57) "..."
          print
          exit
        }
      ' "$f")
      [[ -z "$name" ]] && continue
      lines+=("$(printf "  %-20s %s" "$name" "$desc")")
    done
  done
  printf '%s\n' "${lines[@]}" | sort
}

# --- Dynamic hook discovery ---
# Parse hooks.json and .claude/settings.json for enabled hooks.
# Emits "EventName (matcher): friendly-label" lines.
discover_hooks() {
  python3 - "$PROJECT_ROOT" <<'PY' 2>/dev/null || true
import json
import os
import sys

root = sys.argv[1]

# Friendly labels for known hook scripts — keeps the output human-readable.
SCRIPT_LABELS = {
    "session-start.sh":           "session context injection",
    "session-end.sh":             "worktree cleanup (auto)",
    "validate-patcher-args.sh":   "argument validation",
    "pre-commit-test-reminder.sh":"test reminders on commit",
    "check-doc-freshness.sh":     "doc freshness on commit",
}

# Content-based fallbacks for inline bash commands (no script file).
CONTENT_LABELS = [
    ("BYTE-LENGTH", "byte-length invariant reminder"),
    ("byte-length", "byte-length invariant reminder"),
    ("validation",  "validation reminder"),
]

import re

def label_for(cmd: str) -> str:
    # 1. Match a known script by filename
    for name, lbl in SCRIPT_LABELS.items():
        if name in cmd:
            return lbl
    # 2. If it references a .sh file, use its basename
    m = re.search(r'([a-zA-Z0-9_-]+)\.sh', cmd)
    if m:
        return m.group(1).replace("-", " ")
    # 3. Inline bash — infer from content keywords
    for keyword, lbl in CONTENT_LABELS:
        if keyword in cmd:
            return lbl
    return "inline bash hook"

def scan(path: str):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        return
    hooks = data.get("hooks", {})
    for event, groups in hooks.items():
        if not isinstance(groups, list):
            continue
        for g in groups:
            matcher = g.get("matcher", "")
            for h in g.get("hooks", []):
                cmd = h.get("command", "")
                if not cmd:
                    continue
                prefix = f"{event}"
                if matcher:
                    prefix += f"({matcher})"
                print(f"  {prefix}: {label_for(cmd)}")

scan(os.path.join(root, "hooks", "hooks.json"))
scan(os.path.join(root, ".claude", "settings.json"))
PY
}

# --- Run discoveries into variables (capture output) ---
skills_block=$(discover_skills)
agents_block=$(discover_agents)
hooks_block=$(discover_hooks)

# --- Pending cleanup retry (safety net for /session-deploy) ---
cleanup_line=""
if [[ -x "$PROJECT_ROOT/scripts/process-pending-cleanup.sh" ]]; then
  out=$(bash "$PROJECT_ROOT/scripts/process-pending-cleanup.sh" 2>/dev/null || true)
  if [[ -n "$out" ]]; then
    cleanup_line="Pending cleanup: $out"
  fi
fi

# --- Output context ---
cat <<CONTEXT
Buddy Evolver Dev Session
=========================

Git: branch=$git_branch | uncommitted=$uncommitted | $fetch_state
Main: $main_behind behind, $main_ahead ahead vs origin/main$stale_marker
Recent:
$git_log

Binary: $binary_status (v: $version) | $backup_status | $meta_status
Compatibility: $compat
Cache: $build_count .build dir(s)${cleanup_line:+
$cleanup_line}

Dev Skills:
$skills_block

Agents:
$agents_block

Hooks Active:
$hooks_block

Session Lifecycle:
  Phase 1 → Plan      Start in Plan Mode (Opus 4.6 Max). Design before building.
  Phase 2 → Execute   /session-execute — transition to code mode (Sonnet High)
  Phase 3 → End       /session-end — tests, docs, security review, comment audit
  Phase 4 → GitHub    Commit/PR/Merge via Desktop App buttons
  Phase 5 → Deploy    /session-deploy [--release] — sync, cleanup, marketplace
  Phase 6 → Exit      /session-exit — final checks, branch/worktree cleanup

Current phase: Plan

Constraints:
  1. BYTE-LENGTH: Every binary patch must produce identical byte length output
  2. 3-BYTE VARS: Species variables are exactly 3 bytes (e.g. GL_, vL_)
  3. ANCHOR PATTERNS: Patch sites found by pattern search, not fixed offsets
  4. ATOMIC WRITES: All Data.write() must use .atomic option
  5. VALIDATION: All user inputs validated in Validation.swift before writes
  6. BACKUP: ensureBackup() is idempotent; original must always be recoverable
CONTEXT

exit 0
