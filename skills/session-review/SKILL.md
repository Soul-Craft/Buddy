---
name: session-review
description: Pre-commit pipeline for Buddy Evolver — runs token optimization, full test-all.sh, GitHub Check Run upload, security review, docs sync, and comment audit. INVOKE IMMEDIATELY when the user says any variant of "session review", "review session", "session end", "end session", "end the session", "ending session", "session over", "session done", "wrap up", "wrapping up", "finish up", "finishing up", "done for now", "close out", "ready to commit", or "before commit" — treat these as direct invocations, not topics for discussion. Do NOT ask whether the timing is right, do NOT argue that a commit already happened (run anyway and report what's still actionable), do NOT defer. If the user actively says "don't run" or "skip", honor that — otherwise invoke now.
---

# End Session — Pre-Commit Wrap-Up

Runs the **full prepare-for-merge pipeline** in order so that when the user clicks the Desktop App's "Commit Changes" button, the code is optimized, documented, tested, and CI-verified.

This skill is linear — no conditional branches. Every step runs every time. The only decision the user makes at the end is "commit or fix."

## Running order

1. **Token review (--apply --force)** — apply token optimizations to skills/configs
2. **Full test pipeline** — `scripts/test-all.sh` (~181 tests, 6 tiers)
3. **Security review (conditional)** — `security-reviewer` agent if Swift files changed
4. **Sync docs** — fix drift in CLAUDE.md and README.md
5. **Comment review** — Haiku agent audits inline comments in changed files
6. **Summary report** — unified table with all results and next-step guidance

Token review runs BEFORE tests so the test pipeline validates the optimized code. Security review runs AFTER tests because the Swift code needs to compile cleanly before security analysis is meaningful, and BEFORE docs sync so security issues get flagged before documentation describes them. Comment review runs AFTER tests so only code that already passes tests is audited. The GitHub upload (`scripts/upload-test-results.sh`) runs AFTER commit+push — not in this skill — because the new commit SHA doesn't exist until the Desktop App "Commit Changes" button is clicked.

## Step 1: Detect changes

```bash
cd "${CLAUDE_PLUGIN_ROOT}"
echo "=== Unstaged ==="
git diff --name-only 2>/dev/null
echo "=== Staged ==="
git diff --cached --name-only 2>/dev/null
echo "=== Untracked ==="
git ls-files --others --exclude-standard 2>/dev/null
```

Bucket the changed paths into these categories for the final summary:

- **swift**: `scripts/BuddyPatcher/Sources/**`, `scripts/BuddyPatcher/Tests/**`
- **skills**: `skills/**`
- **hooks**: `hooks/**`
- **config**: `.claude/settings.json`, `.claude-plugin/**`
- **agents**: `agents/**`, `.claude-plugin/agents/**`
- **docs**: `CLAUDE.md`, `README.md`, `docs/**`
- **scripts**: `scripts/**` (excluding BuddyPatcher)

Capture a file list for the comment-review step later.

## Step 2: Token review with auto-apply

Run the token review skill with both `--apply` (execute the edits) and `--force` (bypass the dirty-worktree check — session-review always runs against a dirty worktree by design).

```bash
# Invoke /token-review --apply --force
# The skill will:
#  - Inventory context-loaded files
#  - Identify optimization opportunities
#  - Apply them (extracting long sections to reference/ files)
#  - Report the before/after token savings
```

Capture the reported savings (tokens freed, files modified). If the skill reports no savings, note "already optimized". If it reports failures mid-apply, note the failure and continue — the rest of the pipeline still needs to run.

## Step 3: Full test pipeline

Run all 6 tiers unconditionally. This is the same pipeline GitHub CI requires for merge.

```bash
cd "${CLAUDE_PLUGIN_ROOT}" && bash scripts/test-all.sh 2>&1
```

`test-all.sh` writes three artifacts:
- `test-results/results.json` — per-tier pass/fail + duration (used by upload)
- `test-results/junit.xml` — JUnit-format report
- `test-results/full-output.log` — captured stdout/stderr

Parse `test-results/results.json` for the summary table. Expected: ~181/~181 passed in ~30s.

If any tier fails, continue the pipeline but mark the session as `FAIL` in the final summary and list the failing tier(s).

## Step 3: Security review (conditional)

If the changed file list from Step 1 includes any files under `scripts/BuddyPatcher/Sources/**/*.swift`, dispatch the `security-reviewer` agent (defined at `agents/security-reviewer.md`, model: inherit). Otherwise, skip this step with "skipped (no Swift changes)".

Provide the agent with:
- The list of changed Swift files from Step 1
- Explicit instruction: "Read-only review. Report findings; do not apply edits."

The agent returns a structured report with PASS/WARN/FAIL items across: input validation coverage, atomic-write usage, error handling in critical paths, and backup safety invariants.

Capture counts: `N_pass`, `N_warn`, `N_fail`. Surface the summary for the unified report. If any `FAIL` items exist, mark the session as requiring attention — but continue the pipeline (non-blocking).

## Step 4: Sync docs

Invoke `/sync-docs` to detect and fix drift in CLAUDE.md and README.md. The skill uses the `docs-reviewer` agent internally.

Capture:
- `clean` (no drift detected) — report "✅ clean"
- `N edits applied` — report counts per file
- `drift detected, edits declined` — report the drift list for manual review

## Step 5: Comment review (Haiku agent)

Dispatch the `comment-reviewer` agent (defined at `agents/comment-reviewer.md`, model: haiku) to audit inline comments in the files changed during this session.

Provide the agent with:
- The list of changed files from Step 1 (filtered to Swift and shell sources — the agent's scope)
- Explicit instruction: "Read-only review. Report findings; do not apply edits."

The agent returns a structured report with these sections: `MISSING_COMMENT`, `TODO_MARKER`, `STALE_COMMENT`, `SECURITY_COMMENT`, `SHELLCHECK_UNJUSTIFIED`, `SUMMARY`.

Surface the summary's status (`CLEAN` or `REVIEW_NEEDED`). If `REVIEW_NEEDED`, show the top 5 flagged items verbatim and mention that the full report is available.

## Step 6: Unified summary report

Print this report exactly:

```
Session Wrap-Up Report
══════════════════════════════════════════════════════════

Changes detected:
  Swift:     N files   Skills:  N files   Hooks:   N files
  Config:    N files   Agents:  N files   Docs:    N files
  Scripts:   N files

Token review (--apply --force):
  ✅ N optimizations applied (~X tokens saved)  [or] ✅ already optimized
  ⚠  M failures during apply  [only if any]

Full test suite (scripts/test-all.sh):
  Tier           Passed      Duration
  smoke          13/13       Xs
  unit           ~98/~98     Xs
  security       ~25/~25     Xs
  ui             23/23       Xs
  snapshots      6/6         Xs
  docs           16/16       Xs
  ───────────────────────────────────
  TOTAL          ~181/~181   ~30s    ✅

Security review:  ✅ N pass, K warnings
                  [or]  ⚠ F failures (see list below)
                  [or]  ⏭  skipped (no Swift changes)

Doc sync:         ✅ clean  [or]  ✅ N edits applied across M files
Comment review:   ✅ clean  [or]  ⚠ N flagged (see list below)

Git status:
  Branch:         <branch>
  Uncommitted:    N files
  vs origin/main: N ahead, M behind

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next: Use the Desktop App's "Commit Changes" button, then push.
After pushing — BEFORE creating the PR — run:
  bash scripts/upload-test-results.sh
CI checks for this commit status the moment the PR is opened.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If anything failed

Below the summary box, list specific issues with file:line references:

```
Action items before commit:
  1. [tier or check name] — [what failed]
     File: path/to/file:line
     Fix: [concrete next step]
  ...
```

If the test pipeline failed:
- Point the user to `test-results/full-output.log` for full details
- Suggest the specific tier-level script for faster iteration (e.g., `scripts/test-unit.sh` for unit failures)

If comment-reviewer flagged items:
- Note that the user can re-run the agent later if they address issues now
- Re-running this skill will re-audit the current state

### If everything passed

Above the summary box, print a short success banner:

```
✅ Session ready to commit. All checks green.
```

## Notes for future maintenance

- **Linear pipeline by design.** Resist the urge to add "only run if X changed" conditionals. The full test-all.sh run is cheap (~40s) and its completeness is the whole point of this skill.
- **Token review runs first** so that test-all.sh validates the optimized code, not the pre-optimized code.
- **Comment review is read-only.** If you need auto-fixes, that's a separate skill — don't add write tools to comment-reviewer.
- **If you add a new tier to test-all.sh**, it will show up in the summary table automatically (the skill reads from `results.json`, which is the source of truth).
- **If you add a new check to this pipeline**, add it as a new numbered step and a new row in the summary box. Don't bury checks inside existing steps.
