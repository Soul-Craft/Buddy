---
name: session-exit
description: Pre-/exit cleanup for Buddy Evolver — inventories worktrees and merged branches, reports unpushed commits and open PRs, prepares for clean session termination. Use when the user says "exit session", "session exit", "before exit", "ready to exit", "clean up and exit", or "final checks before exit". This is NOT the pre-commit pipeline — for "session end", "wrap up", "ready to commit", or any test/docs/security work before committing, use /session-review instead.
---

# Session Exit — Pre-Exit Cleanup & Final Checks

Run this skill **before** typing `/exit` to tidy up branches, review pending work, and make sure nothing important is dropped when the session ends. The automatic `SessionEnd` hook (`hooks/session-exit.sh`) handles worktree cleanup for the current worktree, but it cannot report on dirty worktrees elsewhere, unpushed commits, or open PRs — those checks live here.

This skill is intentionally interactive: it never deletes branches without explicit confirmation.

## Step 1: Branch & worktree inventory

```bash
cd "${CLAUDE_PLUGIN_ROOT}"
echo "=== Worktrees ==="
git worktree list --porcelain
echo ""
echo "=== Local branches ==="
git branch -vv
echo ""
echo "=== Open PRs (yours) ==="
gh pr list --state open --author @me --json number,title,headRefName 2>/dev/null || echo "gh unavailable"
```

Categorize the results:
- **Worktrees**: which are active (non-current), which are the current one
- **Branches**: which are merged into `origin/main`, which are unmerged, which have no upstream
- **PRs**: which branches have open PRs

## Step 2: Recommend branch cleanup

For each **merged branch with no open PR**, list it and ask the user which to delete. Never force-delete.

```bash
# Branches merged into origin/main (safe to delete)
git -C "$MAIN_REPO" branch --merged origin/main | grep -v '^\*' | grep -v 'main$'
```

For each candidate:
- If the branch has a worktree attached, note that the worktree must be removed first
- If the branch has unpushed commits, warn: "branch X has N unpushed commits — keep?"
- If the user confirms deletion: `git branch -d <name>` (safe, refuses if unmerged)

Skip deletion entirely if the user declines. Collect two lists for the report: `deleted` and `kept_with_reason`.

## Step 3: Check for uncommitted work

Check the current worktree:

```bash
git status --porcelain
```

For each other worktree in the list:

```bash
git -C "$path" status --porcelain 2>/dev/null
```

If any worktree has uncommitted changes, warn:
> "Worktree `<path>` has N uncommitted files. If this work should be committed, run `/session-review` in that worktree first. Exiting now will not lose the work, but it will remain uncommitted."

## Step 4: Check for pending operations

Collect these data points for the report:

- **Unpushed commits on current branch**:
  ```bash
  git log '@{u}..HEAD' --oneline 2>/dev/null || echo "no upstream configured"
  ```
- **Pending worktree cleanup** (staged by `/session-deploy`):
  ```bash
  cat ~/.claude/buddy-evolver-cleanup-pending.json 2>/dev/null
  ```
  If present, report how many worktrees are staged and when they were staged.
- **Open PRs**: from Step 1, list PR numbers and titles.

## Step 5: Session Exit Report

Print:

```
Session Exit Report
══════════════════════════════════════════════════════════

Worktrees:
  Active:   N
  Cleaned:  N (list)
  Staged:   N (will auto-clean on /exit via SessionEnd hook)

Branches:
  Deleted:  N (list)
  Kept:     N (list with reasons)

Pending work:
  Open PRs:       N  [#num: title]
  Unpushed:       N commits on <branch>
  Uncommitted:    N files across M worktrees
  Staged cleanup: N worktrees awaiting SessionEnd

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type /exit to close the session.
Worktree cleanup runs automatically on exit via the
SessionEnd hook (hooks/session-exit.sh). If it cannot
remove the current worktree (Claude still holds CWD),
the next SessionStart will retry.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If anything needs attention before exit

Above the report, surface a short banner with the highest-priority warning:

```
⚠ N uncommitted files in worktree <path>
  → Run /session-review there first, or exit to preserve as-is
```

### If everything is clean

Above the report, show:

```
✅ Ready to exit. No uncommitted work, no open PRs waiting.
```

## Notes for future maintenance

- **Do not modify `hooks/session-exit.sh`.** That hook's contract is: runs non-interactively, exits 0 within 5 seconds, cleans staged worktrees only. Additional checks belong here.
- **Never force-delete branches.** Use `-d`, not `-D`. If a merged-check fooled itself on a squash merge, `-d` will refuse and the user can intervene.
- **`gh` may be unavailable.** If `gh pr list` fails, continue with the other checks and note "open PR count unavailable" in the report.
- **This skill reads from `~/.claude/buddy-evolver-cleanup-pending.json`** which is written by `/session-deploy`. The schema is defined in `scripts/process-pending-cleanup.sh`.
