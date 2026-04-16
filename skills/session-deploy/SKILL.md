---
name: session-deploy
description: Use after a PR is merged to GitHub main. Syncs local main, verifies the merged code builds, removes merged worktrees, and stages the current worktree for automatic self-cleanup on /exit. With --release, also bumps version, updates CHANGELOG, tags the commit, pushes to trigger marketplace publish, and verifies the local plugin reloads. Use when the user says "deploy", "session deploy", "pr merged", "post-merge sync", "deploy session", "clean up after merge", or "release new version".
argument-hint: "--dry-run (preview only, no changes) | --release (also publish new version to marketplace)"
---

# Session Deploy — Post-Merge Sync & Worktree Cleanup

Runs after the user merges their PR via the Desktop App's CI popup. Performs three related jobs:

1. **Sync local main** with the just-merged remote state
2. **Verify** the synced main still builds and passes smoke tests (catches the rare case where a merge broke main)
3. **Clean up worktrees** — remove OTHER merged worktrees immediately, and stage the CURRENT worktree for automatic self-removal when the user types `/exit`

The current worktree cannot remove itself directly (Claude Code holds its CWD), so cleanup is two-phased:
- `/session-deploy` writes `~/.claude/buddy-evolver-cleanup-pending.json` with the current worktree's details
- The `SessionEnd` hook (`hooks/session-exit.sh`) attempts removal when Claude Code exits
- If that fails (Claude hasn't released CWD yet), the next `SessionStart` hook retries via the same helper

This gives **automatic** cleanup with **guaranteed eventual completion**. The user's only action is `/exit`.

## Arguments

- `--dry-run` — detect state and print the plan; make NO changes. Use this to preview before deploying.
- `--release` — after the sync + cleanup steps, also run the release workflow (Steps 9–12): bump version, update CHANGELOG, tag + push, verify local plugin. Combine with `--dry-run` to preview a release without any changes.

## Step 1: Detect main repo and current worktree

```bash
# The main repo is always the first record; --porcelain is space-safe.
MAIN_REPO=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')
CURRENT=$(pwd)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

If `MAIN_REPO` is empty or `CURRENT == MAIN_REPO`, the user is probably running this from the main repo itself, which is unusual. Confirm before proceeding — the worktree self-cleanup step should be skipped in that case.

## Step 2: Verify the PR is actually merged

```bash
# Query GitHub for a merged PR whose head matches the current branch
PR_JSON=$(gh pr list --state merged --head "$BRANCH" \
  --json number,title,mergedAt,mergeCommit --limit 1)
```

Handle three cases:
- **Merged PR found** → proceed. Capture: number, title, mergedAt, mergeCommit
- **No merged PR, but an open PR exists for the branch** → `gh pr list --state open --head "$BRANCH"`. If found, stop with: "PR #N is still open. Run `/session-review` first, then merge via the Desktop App, then re-run `/session-deploy`."
- **No PR at all** → stop with: "No PR found for branch `$BRANCH`. Did you push and open a PR?"

## Step 3: Sync local main

```bash
# Record state before sync so we can report what changed
before=$(git -C "$MAIN_REPO" rev-parse main 2>/dev/null || echo "unknown")

# Fast-forward only — safe because main is only checked out at $MAIN_REPO
git -C "$MAIN_REPO" fetch --quiet origin main
git -C "$MAIN_REPO" pull --ff-only origin main

after=$(git -C "$MAIN_REPO" rev-parse main)
new_commits=$(git -C "$MAIN_REPO" rev-list --count "${before}..${after}" 2>/dev/null || echo "?")
```

If `--dry-run`, skip `pull` and just compute `git -C "$MAIN_REPO" rev-list --count main..origin/main` for the preview.

Report the before/after SHAs and commit count.

## Step 4: Smoke test the synced main

```bash
bash "$MAIN_REPO/scripts/test-smoke.sh" 2>&1
```

Parse the last line of output for `Results: N/M passed`. Expected: 13/13.

If smoke fails:
- Flag the deploy as `BLOCKED`
- Do NOT proceed with cleanup — main is broken and the user may need to investigate
- Suggest: "Main build is broken. Roll back the merge, or investigate with `scripts/test-all.sh`."
- Skip to the final report

If `--dry-run`, still run smoke (it's read-only and <30s) because knowing main is healthy is core to the deploy plan.

## Step 5: Remove OTHER merged worktrees

Loop over all worktrees and identify which are safe to remove.

```bash
git -C "$MAIN_REPO" worktree list --porcelain
```

For each worktree entry (path + branch):
- Skip if `path == MAIN_REPO` (never remove main)
- Skip if `path == CURRENT` (current worktree — handled in Step 6)
- Check if the branch is merged into main:
  ```bash
  git -C "$MAIN_REPO" branch --merged main | grep -E "^  ${branch}$"
  ```
- Check if the worktree has uncommitted changes:
  ```bash
  git -C "$path" status --porcelain 2>/dev/null
  ```
- If merged AND clean → remove:
  ```bash
  git -C "$MAIN_REPO" worktree remove "$path"
  git -C "$MAIN_REPO" branch -d "$branch"  # -d (not -D) as safety
  ```
- If merged but dirty → skip, report as "kept (dirty)"
- If not merged → skip, report as "kept (active)"

If `--dry-run`, only print the plan (which worktrees would be removed, which kept, why) — do not execute.

Collect two lists for the summary: `removed` and `kept_with_reason`.

## Step 6: Stage current worktree for self-cleanup

Skip this step if `CURRENT == MAIN_REPO` (nothing to clean up — you're in the main repo).

Write the staged cleanup file:

```bash
PENDING_FILE="$HOME/.claude/buddy-evolver-cleanup-pending.json"
mkdir -p "$HOME/.claude"

python3 <<PY
import json
from datetime import datetime, timezone
data = {
    "staged_at": datetime.now(timezone.utc).isoformat(),
    "worktrees": [
        {
            "path": "${CURRENT}",
            "branch": "${BRANCH}",
            "main_repo": "${MAIN_REPO}",
            "reason": "session-deploy"
        }
    ]
}
with open("${PENDING_FILE}", "w") as f:
    json.dump(data, f, indent=2)
PY
```

If the pending file already exists (e.g., from an earlier incomplete deploy), MERGE the new entry instead of overwriting. Read the existing file, append the current worktree if not already present, write back.

If `--dry-run`, print what would be written but don't write it.

## Step 7: Cache cleanup

```bash
bash "$MAIN_REPO/scripts/cache-clean.sh" --all --verbose
```

Use `--all` because the current worktree is about to vanish anyway — its `.build/` should not be preserved.

Capture: items freed, bytes recovered.

If `--dry-run`, use `--dry-run --verbose` (cache-clean.sh supports dry-run).

## Step 8: Report

Print:

```
Deploy Report
═════════════════════════════════════════════════════════

Source worktree:   <relative path from MAIN_REPO>
Branch:            <branch>
PR:                #<N> "<title>" ✅ merged <mergedAt>
Main repo:         <MAIN_REPO>

Main sync:
  Before:       <before-sha (short)>
  After:        <after-sha (short)>  ✅
  New commits:  <N>

Smoke test on main:  <N>/<M> ✅  [or]  ⚠ FAILED — deploy blocked

Cache cleaned:       <N> items freed (<bytes>)

Other worktrees removed: <count>
  - <path> (<branch>)
  ...

Other worktrees kept:    <count>
  - <path> (<branch>) — <reason>
  ...

Current worktree cleanup: STAGED ✅
  → Will run automatically on SessionEnd (when you type /exit)
  → Safety net retries on next SessionStart if needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type /exit when ready. Cleanup happens automatically.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Dry-run variant

Prepend a banner:
```
DRY RUN — no changes made
─────────────────────────
```

And change the final instruction to:
```
Re-run without --dry-run to execute this plan.
```

---

## Release workflow (Steps 9–12, only with `--release`)

**Run Steps 9–12 ONLY if `--release` was passed.** Skip the entire block otherwise. These steps publish a new version to the Claude Marketplace via the `release.yml` GitHub Actions workflow, which fires when a `v*` tag is pushed. Steps 9–11 must run on the **main repo**, not the current worktree.

Prerequisite checks before Step 9:
- Steps 1–8 above must have completed successfully (main synced, smoke passed)
- `CURRENT != MAIN_REPO` is fine; the release steps use `git -C "$MAIN_REPO"`
- The current worktree's branch is merged into main (already verified in Step 2)

### Step 9: Bump version

Ask the user: "Which version bump? (patch / minor / major)"

Once they choose, run:

```bash
cd "$MAIN_REPO"
read -r OLD NEW < <(bash "$MAIN_REPO/scripts/bump-version.sh" "$BUMP_TYPE")
```

The script writes the new version atomically to three files:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `README.md` (the `![Version](...)` badge URL)

Capture `OLD` and `NEW` for the report.

If `--dry-run`, print what the bump would produce (compute manually or call the script and immediately `git -C "$MAIN_REPO" checkout -- <files>` — safer to compute manually in the skill).

### Step 10: Update CHANGELOG

```bash
bash "$MAIN_REPO/scripts/update-changelog.sh" "$NEW"
```

This script:
1. Finds the `## [Unreleased]` section in `CHANGELOG.md`
2. Moves its content under a new `## [X.Y.Z] - YYYY-MM-DD` section
3. Leaves a fresh empty `## [Unreleased]` section at the top
4. Writes atomically

**If the script exits 1 with "Unreleased section is empty"**: do NOT proceed. Ask the user to describe the changes for this release, then manually write them into the `[Unreleased]` section before re-running. This script intentionally refuses to publish a release with no changelog entry.

**Before running**, show the user the current `[Unreleased]` content and ask them to confirm it represents this release. If they want to edit it, pause the skill and let them.

If `--dry-run`, print the Unreleased content that would be moved.

### Step 11: Tag and push

**This step pushes to the public repo and triggers the marketplace release.** Require explicit user confirmation before executing:

> "Ready to tag and push `v$NEW`? This will:
>  - Commit the version bump + CHANGELOG update
>  - Create an annotated tag `v$NEW`
>  - Push to origin/main, triggering `release.yml` on GitHub Actions
>  - Publish the new version to the Claude Marketplace
>
>  Type 'yes' to proceed."

Only on explicit confirmation, run:

```bash
git -C "$MAIN_REPO" add \
  .claude-plugin/plugin.json \
  .claude-plugin/marketplace.json \
  README.md \
  CHANGELOG.md

git -C "$MAIN_REPO" commit -m "Release v$NEW"
git -C "$MAIN_REPO" tag -a "v$NEW" -m "Release v$NEW"
git -C "$MAIN_REPO" push origin main --follow-tags
```

Capture the Actions URL: `https://github.com/Soul-Craft/buddy-evolver/actions`. `release.yml` will run validation (build + unit tests + security tests + version match check), then create a GitHub Release using the CHANGELOG entry as the body.

If `--dry-run`, show the exact commands that would run without executing them.

### Step 12: Local plugin verification

After the tag is pushed, verify the plugin still works locally:

```bash
# Clear local plugin caches so any stale state is flushed
bash "$MAIN_REPO/scripts/cache-clean.sh" --all --verbose
```

Then ask the user to invoke `/buddy-status` in a fresh session (or report that they can do so on their next Claude Code startup). Confirm:
- `/buddy-status` loads successfully without errors
- The plugin version displayed matches `$NEW`

If either check fails, the release is **live** but the local installation is broken. Report the failure and suggest: `/plugin reinstall buddy-evolver` (via Claude Code Desktop) or manual cache clearing.

If `--dry-run`, describe the verification steps without running them.

---

## Release report additions

When `--release` was used, append this block to the Deploy Report (between the existing report body and the trailing horizontal rule):

```
Release (--release):
  Version bump:      2.0.0 → 2.1.0 (minor)
  CHANGELOG:         ✅ [Unreleased] → [2.1.0] - 2026-04-14
  Tag:               v2.1.0 pushed
  GitHub Actions:    https://github.com/Soul-Craft/buddy-evolver/actions
  Marketplace:       ⏳ publishing (release.yml running)
  Local verify:      ✅ /buddy-status loads v2.1.0  [or]  ⚠ verify failed
```

When `--release --dry-run` was used, prefix the block with a `DRY RUN` marker and show the commands that would have run.

## Failure modes

If any step fails catastrophically (e.g., `git pull` reports non-fast-forward, network error), STOP and report what succeeded so far. Do not attempt to roll back — the user may need to intervene manually.

If the PR merge check says the branch is not yet merged, the whole skill should stop early (Step 2) — do not run cleanup or cache cleanup against an unmerged branch.

## Notes for future maintenance

- **The staging file schema** (`~/.claude/buddy-evolver-cleanup-pending.json`) is shared with `scripts/process-pending-cleanup.sh`. If you change the schema, update both.
- **The two-phase cleanup design** is deliberate: SessionEnd hook attempts immediate removal, SessionStart hook retries on the next session. Both call `scripts/process-pending-cleanup.sh` to avoid duplicating logic.
- **Do not add a `--force` remove flag.** Dirty worktrees should always be kept — losing uncommitted work is worse than leaving a worktree behind.
- **Branch deletion uses `-d` (safe) not `-D` (force)** to catch cases where the merged-into-main check got fooled by a squash merge or rebase. If `-d` refuses, the cleanup log will show it and the user can intervene.
- **Release steps (9–12) require explicit user confirmation** at Step 11 before the push. Tag pushes trigger marketplace publish and are visible to downstream users; never push a tag without a clear yes.
- **Release version validation lives in `release.yml`.** That workflow compares the tag name against `plugin.json#version` and fails fast if they disagree. `scripts/bump-version.sh` keeps them in sync; don't bypass it.
- **CHANGELOG entry is required for release.** `scripts/update-changelog.sh` exits 1 if `[Unreleased]` is empty. This is intentional — a release with no changelog entry is a bug.
- **If `release.yml` fails mid-publish**, the tag is already pushed. To retry: delete the bad tag (`git tag -d v$N && git push origin :refs/tags/v$N`), fix the issue, re-run `/session-deploy --release`.
