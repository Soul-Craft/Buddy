#!/usr/bin/env bash
# cache-clean.sh — Clean build artifacts and cache files from Buddy Evolver
#
# Usage: cache-clean.sh [--dry-run] [--verbose] [--all]
#
#   --dry-run   Show what would be cleaned without deleting
#   --verbose   Print each file/dir being removed
#   --all       Include current worktree's .build/ (normally preserved)
#
# Exit 0 always — cleanup failures must never block session teardown.

set -uo pipefail

# --- Parse arguments ---
DRY_RUN=false
VERBOSE=false
CLEAN_ALL=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --verbose)  VERBOSE=true ;;
    --all)      CLEAN_ALL=true ;;
    *)          echo "Unknown option: $arg" >&2 ;;
  esac
done

# --- Resolve project root ---
# Works from worktrees, hooks, and direct invocation
PROJECT_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PROJECT_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# Detect if running from a worktree and find the main repo
MAIN_REPO="$PROJECT_ROOT"
if [[ -f "$PROJECT_ROOT/.git" ]]; then
  # Worktree — .git is a file pointing to the main repo
  MAIN_REPO="$(git -C "$PROJECT_ROOT" rev-parse --show-superproject-working-tree 2>/dev/null || echo "$PROJECT_ROOT")"
  if [[ -z "$MAIN_REPO" ]]; then
    MAIN_REPO="$(git -C "$PROJECT_ROOT" rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_ROOT")"
  fi
fi

WORKTREES_DIR="$MAIN_REPO/.claude/worktrees"
CURRENT_WORKTREE="$(basename "$PROJECT_ROOT" 2>/dev/null || echo "")"

TOTAL_FREED=0
ITEMS_CLEANED=0

log() {
  if $VERBOSE || $DRY_RUN; then
    echo "$1"
  fi
}

add_size() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local size_kb
    size_kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
    TOTAL_FREED=$((TOTAL_FREED + size_kb))
  fi
}

remove_item() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    add_size "$path"
    ITEMS_CLEANED=$((ITEMS_CLEANED + 1))
    if $DRY_RUN; then
      local size_human
      size_human=$(du -sh "$path" 2>/dev/null | awk '{print $1}')
      echo "  [dry-run] Would remove: $label ($size_human)"
    else
      log "  Removing: $label"
      xattr -rc "$path" 2>/dev/null
      rm -rf "$path" 2>/dev/null
    fi
  fi
}

# --- 1. Clean Swift .build/ directories from worktrees ---
echo "=== Swift Build Cache ==="

if [[ -d "$WORKTREES_DIR" ]]; then
  for wt in "$WORKTREES_DIR"/*/; do
    [[ -d "$wt" ]] || continue
    wt_name="$(basename "$wt")"
    build_dir="$wt/scripts/BuddyPatcher/.build"

    # Skip current worktree unless --all
    if [[ "$wt_name" == "$CURRENT_WORKTREE" ]] && ! $CLEAN_ALL; then
      if [[ -d "$build_dir" ]]; then
        log "  Skipping current worktree: $wt_name (use --all to include)"
      fi
      continue
    fi

    if [[ -d "$build_dir" ]]; then
      remove_item "$build_dir" "$wt_name/.build"
    fi
  done
fi

# Also check main repo's BuddyPatcher .build
MAIN_BUILD="$MAIN_REPO/scripts/BuddyPatcher/.build"
if [[ -d "$MAIN_BUILD" ]]; then
  remove_item "$MAIN_BUILD" "main-repo/.build"
fi

# --- 2. Clean .DS_Store files ---
echo "=== .DS_Store Files ==="

while IFS= read -r -d '' dsstore; do
  remove_item "$dsstore" "$(basename "$(dirname "$dsstore")")/.DS_Store"
done < <(find "$MAIN_REPO" -name ".DS_Store" -not -path "*/.git/*" -print0 2>/dev/null)

# Also clean worktree .DS_Store files
if [[ -d "$WORKTREES_DIR" ]]; then
  while IFS= read -r -d '' dsstore; do
    remove_item "$dsstore" "worktrees/$(echo "$dsstore" | sed "s|$WORKTREES_DIR/||")  "
  done < <(find "$WORKTREES_DIR" -name ".DS_Store" -print0 2>/dev/null)
fi

# --- 3. Summary ---
echo ""
if [[ $ITEMS_CLEANED -eq 0 ]]; then
  echo "Nothing to clean."
else
  SIZE_HUMAN=""
  if [[ $TOTAL_FREED -ge 1024 ]]; then
    SIZE_HUMAN="$((TOTAL_FREED / 1024))M"
  else
    SIZE_HUMAN="${TOTAL_FREED}K"
  fi

  if $DRY_RUN; then
    echo "Would free: ~$SIZE_HUMAN ($ITEMS_CLEANED items)"
  else
    echo "Freed: ~$SIZE_HUMAN ($ITEMS_CLEANED items cleaned)"
  fi
fi

exit 0
