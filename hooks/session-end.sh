#!/usr/bin/env bash
# session-end.sh — best-effort cleanup of staged worktree removals on session exit.
#
# Fires when a Claude Code session ends (via /exit or window close).
# Reads ~/.claude/buddy-evolver-cleanup-pending.json (written by /session-deploy)
# and attempts to remove each staged worktree from the main repo.
#
# This is a BEST-EFFORT first attempt. If cleanup fails because Claude hasn't
# released the worktree CWD yet, the pending file is rewritten with any
# unremoved entries, and the next SessionStart hook (in any future session)
# retries the cleanup via the same helper script.
#
# Must always exit 0 — never block session shutdown.
set -uo pipefail

# Resolve plugin root so we can find the shared helper
PROJECT_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PROJECT_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

HELPER="$PROJECT_ROOT/scripts/process-pending-cleanup.sh"

# Silent no-op if the helper is missing (defensive — should always exist)
if [[ -x "$HELPER" ]]; then
  bash "$HELPER" 2>/dev/null || true
fi

exit 0
