#!/usr/bin/env bash
# process-pending-cleanup.sh — attempt to complete any staged worktree removals.
#
# Called by both hooks/session-exit.sh (on session exit) and hooks/session-start.sh
# (safety net on session start). Reads ~/.claude/buddy-evolver-cleanup-pending.json,
# tries to remove each staged worktree, rewrites the file with any that still failed.
#
# Always exits 0. Never blocks a session.
#
# Output: single line to stdout if anything was processed, empty otherwise.
#   "cleanup: processed X, failed Y"
set -uo pipefail

PENDING_FILE="$HOME/.claude/buddy-evolver-cleanup-pending.json"
[[ ! -f "$PENDING_FILE" ]] && exit 0

# Use python3 for robust JSON handling. Available by default on macOS.
python3 - "$PENDING_FILE" <<'PY'
import json
import os
import subprocess
import sys

pending_path = sys.argv[1]

try:
    with open(pending_path) as f:
        data = json.load(f)
except Exception:
    # Malformed file — remove it silently so it doesn't keep failing
    try:
        os.remove(pending_path)
    except Exception:
        pass
    sys.exit(0)

worktrees = data.get("worktrees", [])
if not worktrees:
    try:
        os.remove(pending_path)
    except Exception:
        pass
    sys.exit(0)

remaining = []
processed = 0
failed = 0

for wt in worktrees:
    main = wt.get("main_repo")
    wt_path = wt.get("path")
    branch = wt.get("branch")

    if not (main and wt_path and branch):
        # Malformed entry — drop it
        continue

    # If the directory is already gone, treat as success (drop from pending)
    if not os.path.exists(wt_path):
        subprocess.run(
            ["git", "-C", main, "branch", "-D", branch],
            capture_output=True, text=True
        )
        processed += 1
        continue

    # Attempt worktree removal from the main repo (not from inside the worktree)
    rm = subprocess.run(
        ["git", "-C", main, "worktree", "remove", wt_path],
        capture_output=True, text=True
    )

    if rm.returncode == 0:
        # Best-effort branch cleanup. Use -D because the merge may have been a squash,
        # and we already verified merge status in /session-deploy before staging.
        subprocess.run(
            ["git", "-C", main, "branch", "-D", branch],
            capture_output=True, text=True
        )
        processed += 1
    else:
        # Common failure: worktree is still in use (Claude Code hasn't released it yet).
        # Keep it staged for the next session.
        remaining.append(wt)
        failed += 1

# Update or remove the pending file
if remaining:
    data["worktrees"] = remaining
    with open(pending_path, "w") as f:
        json.dump(data, f, indent=2)
else:
    try:
        os.remove(pending_path)
    except Exception:
        pass

# Emit a single status line only if anything was processed (keeps hook output clean)
if processed > 0 or failed > 0:
    print(f"cleanup: processed {processed}, failed {failed}")
PY

exit 0
