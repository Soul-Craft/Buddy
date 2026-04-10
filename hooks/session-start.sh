#!/usr/bin/env bash
# session-start.sh — Inject dev context into Claude's session at startup.
# Output becomes "SessionStart hook additional context" in system-reminder.
# Must always exit 0 — never block session startup.
set -uo pipefail

# --- Resolve project root ---
PROJECT_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PROJECT_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# --- Git State ---
git_branch=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
git_log=$(git -C "$PROJECT_ROOT" log --oneline -3 2>/dev/null || echo "  (no commits)")
git_short=$(git -C "$PROJECT_ROOT" status --short 2>/dev/null || echo "")
uncommitted=0
if [[ -n "$git_short" ]]; then
  uncommitted=$(echo "$git_short" | wc -l | tr -d ' ')
fi

sync_status="no upstream"
git_upstream=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo "")
if [[ -n "$git_upstream" ]]; then
  ahead=$(git -C "$PROJECT_ROOT" rev-list --count '@{u}..HEAD' 2>/dev/null || echo "0")
  behind=$(git -C "$PROJECT_ROOT" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo "0")
  if [[ "$ahead" == "0" && "$behind" == "0" ]]; then
    sync_status="up to date with $git_upstream"
  else
    sync_status="ahead $ahead, behind $behind vs $git_upstream"
  fi
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
    compat="WARNINGS — some anchor patterns not found. Run /test-patch for details."
  elif echo "$dry_output" | grep -q '\[DRY RUN\]'; then
    compat="all patterns match"
  else
    compat="could not determine (run /test-patch to check)"
  fi
fi

# --- Cache State ---
build_count=0
MAIN_REPO="$PROJECT_ROOT"
if [[ -f "$PROJECT_ROOT/.git" ]]; then
  MAIN_REPO="$(git -C "$PROJECT_ROOT" rev-parse --show-superproject-working-tree 2>/dev/null || echo "$PROJECT_ROOT")"
  [[ -z "$MAIN_REPO" ]] && MAIN_REPO="$PROJECT_ROOT"
fi
WORKTREES_DIR="$MAIN_REPO/.claude/worktrees"
if [[ -d "$WORKTREES_DIR" ]]; then
  while IFS= read -r -d '' _; do
    build_count=$((build_count + 1))
  done < <(find "$WORKTREES_DIR" -maxdepth 4 -name ".build" -type d -print0 2>/dev/null)
fi
[[ -d "$PROJECT_ROOT/scripts/BuddyPatcher/.build" ]] && build_count=$((build_count + 1))

# --- Output context ---
cat <<CONTEXT
Buddy Evolver Dev Session
=========================

Git: branch=$git_branch | uncommitted=$uncommitted | $sync_status
Recent:
$git_log

Binary: $binary_status (v: $version) | $backup_status | $meta_status
Compatibility: $compat
Cache: $build_count .build dir(s)

Dev Skills:
  /run-tests         Run Swift test suite (175 tests) — after modifying Swift code
  /test-patch        Verify binary compatibility via dry-run — after Claude Code updates
  /security-audit    Binary integrity, backups, codesign, permissions — after security changes
  /token-review      Context footprint audit — after modifying skills or configs
  /cache-clean       Clean .build/ and .DS_Store — to free disk space
  /update-species-map  Investigate binary changes — when /test-patch fails
  /start-session     Re-run this context check
  /end-session       Automated wrap-up: detects changes, runs tests/review/cleanup

Agents:
  security-reviewer  Review Swift diffs for security issues (invoke after BuddyPatcher changes)
  test-runner        Run and parse Swift tests
  cache-analyzer     Deep disk usage analysis
  token-review       Deep context footprint audit

Hooks Active:
  PreToolUse(Edit/Write): Byte-length invariant reminder on BuddyPatcher files
  PreToolUse(Bash): Patcher argument validation (shell injection prevention)
  PreToolUse(Bash): Test reminder before git commit

Constraints:
  1. BYTE-LENGTH: Every binary patch must produce identical byte length output
  2. 3-BYTE VARS: Species variables are exactly 3 bytes (e.g. GL_, vL_)
  3. ANCHOR PATTERNS: Patch sites found by pattern search, not fixed offsets
  4. ATOMIC WRITES: All Data.write() must use .atomic option
  5. VALIDATION: All user inputs validated in Validation.swift before writes
  6. BACKUP: ensureBackup() is idempotent; original must always be recoverable
CONTEXT

exit 0
