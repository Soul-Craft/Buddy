# Buddy Customizer

Claude Code plugin that customizes the terminal Buddy companion by writing name and personality to Claude Code's companion system, and maintaining a Tamagotchi-style visual card with plugin-local cosmetic metadata.

## Architecture

```
.claude-plugin/plugin.json       Plugin manifest (name, version, metadata)
.claude-plugin/marketplace.json  Marketplace listing (for /plugin install)
.claude-plugin/agents/           Subagents (cache-analyzer, docs-reviewer, token-review)
.claude/settings.json            Permissions for common bash patterns
hooks/hooks.json                 Plugin hooks (SessionStart + SessionEnd + PreToolUse)
hooks/session-start.sh           SessionStart hook: dynamic dev context + pending cleanup retry
hooks/session-end.sh             SessionEnd hook: automatic worktree self-cleanup on exit
hooks/validate-patcher-args.sh   Security hook: validates patcher arguments
hooks/check-doc-freshness.sh     Pre-commit doc freshness check
hooks/pre-commit-test-reminder.sh Context-aware test reminders on git commit
agents/security-reviewer.md      Security review agent for Swift code changes
agents/comment-reviewer.md       Inline comment audit agent for /session-end (Haiku)
agents/test-runner.md            Test execution agent for Swift suite
skills/buddy-evolve/             Evolution skill (/buddy-evolve)
skills/buddy-reset/              Reset skill (/buddy-reset)
skills/buddy-status/             Buddy card display (/buddy-status)
skills/run-tests/                Swift test runner (/run-tests)
skills/run-all-tests/            Full pipeline runner (/run-all-tests)
skills/security-audit/           Security posture audit (/security-audit)
skills/cache-clean/              Cache management skill (/cache-clean)
skills/token-review/             Token optimization audit (/token-review)
skills/sync-docs/                Documentation sync (/sync-docs)
skills/start-session/            Dev session context (/start-session) — delegates to hook
skills/session-execute/          Plan → Execute transition (/session-execute) — model guidance
skills/session-end/              Pre-commit wrap-up (/session-end) — tests + security review
skills/session-deploy/           Post-merge sync + worktree cleanup (/session-deploy; --release publishes)
skills/session-exit/             Pre-/exit checks + branch cleanup (/session-exit)
scripts/BuddyPatcher/            Soul patching engine (Swift, zero dependencies)
scripts/BuddyPatcher/Tests/      Unit test suite (~98 tests across 6 files)
scripts/BuddyPatcher/Tests/Fixtures/  Golden files for CLI snapshot tests
scripts/run-buddy-patcher.sh     Lazy-build wrapper (compiles Swift on first use)
scripts/cache-clean.sh           Cache cleanup script (used by hook + skill)
scripts/process-pending-cleanup.sh  Shared worktree cleanup retry logic (session-end + session-start hooks)
scripts/lint.sh                  Local lint (shellcheck, JSON, frontmatter, hygiene)
scripts/test-smoke.sh            Smoke tier: build sanity + CLI contract (<30s, 13 tests)
scripts/test-security.sh         Security validation test suite (~25 tests)
scripts/test-ui.sh               Buddy card rendering against fixtures (23 tests)
scripts/test-snapshots.sh        Golden file comparison for CLI output (6 tests)
scripts/test-docs.sh             Documentation path + link + count consistency (16 tests)
scripts/test-perf.sh             Performance benchmarks (7 benchmarks, on-demand)
scripts/coverage.sh              Local HTML coverage report (test-results/coverage/)
scripts/test-ui-renderer.py      Standalone Python renderer (reference for /buddy-status)
scripts/test-visual-smoke.sh     Manual pre-release visual check (interactive)
scripts/test-all.sh              Master runner — all tiers, JSON/JUnit output
scripts/upload-test-results.sh   Uploads results to GitHub as a Check Run
scripts/bump-version.sh          Atomic version bump across plugin.json + marketplace.json + README badge
scripts/update-changelog.sh      Move [Unreleased] content to dated [X.Y.Z] section in CHANGELOG.md
scripts/setup-labels.sh          One-time GitHub label setup for new/forked repos
```

### How it works

Buddy customization writes to two places:

**Soul (actually reaches Claude Code):**
- Name and personality are written to `~/.claude.json#companion`
- Claude Code reads these fields and injects your buddy's name/personality into every session via the `companion_intro` system reminder
- Changes take effect immediately — no restart required

**Card metadata (plugin-local cosmetic layer):**
- Species, rarity, shiny, emoji, name, personality, and stats are stored in `~/.claude/backups/buddy-patch-meta.json`
- This drives the `/buddy-status` visual card — the Tamagotchi-style terminal display
- Claude Code never reads this file; it is purely for the plugin's card renderer (`scripts/test-ui-renderer.py`)

### Data flow

```
/buddy-evolve
  → Reads current buddy from ~/.claude.json
  → Collects choices (species, rarity, emoji, name, personality, stats)
  → Runs: run-buddy-patcher.sh --name X --personality Y --meta-species Z ...
  → Tool backs up ~/.claude.json, writes name+personality to companion field,
    saves card metadata; all writes are atomic
  → Changes are live immediately

/buddy-reset
  → Restores ~/.claude.json from soul backup (.claude.json.pre-customize)
  → Removes buddy-patch-meta.json
```

### Key file locations (on user's machine)

- Soul backup: `~/.claude/backups/.claude.json.pre-customize`
- Card metadata: `~/.claude/backups/buddy-patch-meta.json`

## Platform

macOS only. Requires Xcode Command Line Tools (provides Swift compiler). Zero third-party dependencies.

## Security

Defense-in-depth across three layers:

### Layer 1: Swift input validation (`Validation.swift`)

All user-provided inputs are validated before any write operation:
- **Emoji**: Single grapheme cluster, all scalars `.isEmoji`, max 16 UTF-8 bytes
- **Name**: Non-empty, max 100 chars, no control characters
- **Personality**: Non-empty, max 500 chars, no control characters
- **Stats**: JSON with known keys only, integer values 0-100

### Layer 2: Atomic operations and permissions

- All file writes use `.atomic` option (`rename(2)` under the hood)
- Soul backup is idempotent — created once, never overwritten
- Backup directory and files set to 0o700/0o600

### Layer 3: Plugin-level enforcement

- **PreToolUse hook** (`hooks/validate-patcher-args.sh`): Intercepts Bash calls to the patcher, validates arguments for shell metacharacters (`;|&$\``), length limits, and subshell injection (`$()`)
- **Security audit skill** (`/security-audit`): On-demand check of backup health, file permissions, and metadata integrity
- **Security review agent** (`agents/security-reviewer.md`): Read-only agent that reviews Swift code changes for missing validation, non-atomic writes, and unsafe patterns

## Testing

~181 automated tests in `test-all.sh` (6 tiers) + 34 on-demand tests. The critical design decision: **macOS-dependent tests run locally on the contributor's machine, NOT in GitHub Actions.** GitHub runners only run cheap Ubuntu-based quality checks. This keeps CI costs bounded while still enforcing test passage on every PR.

### The 6 automated tiers (run via `test-all.sh`)

| Tier | Script | Stage | Purpose |
|------|--------|-------|---------|
| Smoke | `scripts/test-smoke.sh` | smoke | Build sanity + CLI contract (<30s) |
| Unit | `swift test` | core | Swift XCTest suite — soul patching, validation, backup, orchestration |
| Security | `scripts/test-security.sh` | core | Input validation, hook enforcement, injection checks |
| UI | `scripts/test-ui.sh` | real-world | Buddy card rendering against pinned JSON fixtures |
| Snapshots | `scripts/test-snapshots.sh` | full-system | Golden file comparison for CLI output |
| Docs | `scripts/test-docs.sh` | peripheral | Documentation path + link + count consistency |

### On-demand suites (not in `test-all.sh`)

| Suite | Script | Tests | Purpose |
|-------|--------|-------|---------|
| Performance | `scripts/test-perf.sh` | 7 | Timing benchmarks — catches catastrophic regressions only |

Run everything: `scripts/test-all.sh` — emits `test-results/results.json`, `test-results/junit.xml`, and `test-results/full-output.log`. Local HTML coverage report: `bash scripts/coverage.sh` → `test-results/coverage/index.html`.

### Visual smoke test

`scripts/test-visual-smoke.sh` is an interactive script used before releases. It renders a fixture buddy card (legendary shiny dragon) and walks the tester through a visual checklist. Not part of `test-all.sh`.

### Test isolation via `BUDDY_HOME`

Swift tests that touch the filesystem use `resolvedHome` (in `Paths.swift`) which honors the `BUDDY_HOME` env var. This is **critical**: on macOS, `FileManager.homeDirectoryForCurrentUser` reads the user database directly and ignores `HOME`, so bash test scripts must set `BUDDY_HOME` to isolate test runs from the user's real `~/.claude`.

### Snapshot golden files

`scripts/BuddyPatcher/Tests/Fixtures/GoldenFiles/` contains pinned CLI output. After any CLI output change, regenerate with:

```bash
UPDATE_GOLDEN=1 bash scripts/test-snapshots.sh
```

Review diffs before committing.

### CI architecture

Four workflows in `.github/workflows/`:

- **`ci-quality.yml`** (Ubuntu, runs on every push/PR) — shellcheck, JSON/YAML validation, skill frontmatter checks, repo hygiene, doc-sync validation.
- **`ci-verify-local.yml`** (Ubuntu, runs on every PR) — queries the GitHub Checks API for a `Local Tests (macOS)` Check Run on the head commit. If missing or failed, posts a sticky PR comment.
- **`ci-macos-fallback.yml`** (macOS-14, manual only) — escape hatch for contributors without macOS. Runs the full `test-all.sh` suite.
- **`release.yml`** — triggered on `v*` tag pushes.

### Local → GitHub bridge

`scripts/upload-test-results.sh` reads `test-results/results.json` and POSTs a GitHub Check Run via `gh api`. On permission failure (e.g. forks without `checks:write`), falls back to `gh pr comment`.

### Contributor workflow

1. Edit code on macOS.
2. Run `scripts/test-all.sh` — all 6 tiers must pass.
3. Run `scripts/upload-test-results.sh` — results appear as a Check Run on the current commit.
4. Push the branch, open a PR.
5. `ci-quality.yml` runs on Ubuntu; `ci-verify-local.yml` confirms the Check Run is present and green.
6. Maintainer reviews and merges.

## Automations

### Hook: session-start context injection

A `SessionStart` hook in `hooks/hooks.json` runs `hooks/session-start.sh` at the start of each Claude Code session. **Dynamic discovery**: parses frontmatter from every SKILL.md, agent markdown file, and hook definition to emit up-to-date lists with no hardcoded drift. Compares the current branch to `origin/main` via a cached `git fetch` (5-min TTL) and warns if >10 commits behind. Always exits 0 (never blocks session startup). Timeout: 10s.

### Hook: session-end automatic cleanup

A `SessionEnd` hook in `hooks/hooks.json` runs `hooks/session-end.sh` when a Claude Code session ends. Reads `~/.claude/buddy-evolver-cleanup-pending.json` (written by `/session-deploy`) and attempts to remove each staged worktree. Always exits 0. Timeout: 5s.

### Skill: /start-session

Manual re-trigger of the SessionStart hook. **Delegates to `hooks/session-start.sh`** so there is no parallel hardcoded list to drift. The hook output includes a **Session Lifecycle** roadmap (Phases 1–6) so the model and user always know where they are in the cycle.

### Skill: /session-execute

Plan → Execute transition checkpoint. Run after a plan is approved (Plan Mode exit, `/superpowers:write-plan`, etc.). Confirms a plan exists, displays the model/effort recommendation table (Opus 4.6 Max for planning; Sonnet high for coding; per-agent haiku/inherit configs), restates plan scope for confirmation, and prints the "switch model and begin" transition message. Advisory only — Claude Code cannot switch models programmatically.

### Skill: /session-end

Pre-commit wrap-up. Run BEFORE clicking the Desktop App's "Commit Changes" button. Unconditional linear pipeline:
1. Token review with `--apply --force`
2. Full test pipeline via `scripts/test-all.sh` — all 6 tiers
3. Upload results to GitHub as a Check Run via `scripts/upload-test-results.sh`
4. Security review via `security-reviewer` agent (conditional on Swift changes)
5. Sync docs via `/sync-docs`
6. Comment review via the `comment-reviewer` Haiku agent
7. Unified summary table

### Skill: /session-deploy

Post-merge sync and worktree cleanup. Run AFTER the PR is merged via the Desktop App's CI popup. With `--release`, also runs Steps 9–12: bump version via `scripts/bump-version.sh`, move `[Unreleased]` to dated section via `scripts/update-changelog.sh`, tag + push (triggers `release.yml` → marketplace publish), verify local plugin reloads. Requires explicit user confirmation before pushing the tag.

### Skill: /session-exit

Pre-`/exit` cleanup. Run BEFORE typing `/exit`. Inventories worktrees + branches + open PRs, recommends merged-branch deletions (never force, always asks), warns about uncommitted work in other worktrees, and reports pending operations (unpushed commits, staged cleanup). Complements the `SessionEnd` hook which continues to handle automatic worktree cleanup via `scripts/process-pending-cleanup.sh`.

### Agent: comment-reviewer

Haiku read-only agent used by `/session-end`. Audits inline code comments in recently changed files (Swift sources + shell scripts). Reports only — never edits.

### Skill: /buddy-evolve

Interactive 4-act evolution flow: discover current buddy, design new buddy (species, rarity, emoji, name, personality, stats), run `run-buddy-patcher.sh` with `--meta-*` flags, display the evolved card. Writes name and personality to `~/.claude.json#companion` and card metadata to `~/.claude/backups/buddy-patch-meta.json`. Changes take effect immediately.

### Skill: /buddy-reset

Restores `~/.claude.json` from the pre-evolution soul backup (`~/.claude/backups/.claude.json.pre-customize`) and removes card metadata. Safe to run any time; no-ops if no backup exists.

### Skill: /buddy-status

Read-only display of the current buddy as a visual card with rarity flair, stat bars, and age. Reads `~/.claude.json` and `~/.claude/backups/buddy-patch-meta.json`. No files modified.

### Hook: argument validation

A `PreToolUse` hook in `hooks/hooks.json` fires on Bash tool calls. If the command invokes `buddy-patcher`, it validates all arguments for injection attacks and length limits before allowing execution.

### Hook: pre-commit test reminder

A `PreToolUse` hook in `hooks/hooks.json` fires on Bash tool calls containing `git commit`. Delegates to `hooks/pre-commit-test-reminder.sh`, which inspects staged files and injects context-aware reminders.

### Hook: doc freshness check

A `PreToolUse` hook in `hooks/hooks.json` fires on `git commit`. Checks if code files were staged without corresponding updates to `CLAUDE.md` or `README.md`.

### Skill: /cache-clean

Manual cache management with interactive preview. Runs dry-run first, then cleans on confirmation.

### Agent: cache-analyzer

Deep cache analysis subagent. Scans for build artifacts, orphaned worktrees, backup sizes, and disk usage.

### Skill: /security-audit

Runs a focused security audit: soul backup health, file permissions, companion data presence, and metadata schema validation.

### Skill: /run-tests

Runs `swift test` in `scripts/BuddyPatcher/`, parses results per suite, and reports a pass/fail scorecard. Non-conversational (`disable-model-invocation: true`).

### Skill: /run-all-tests

Runs the full 6-tier test pipeline via `scripts/test-all.sh`, reads `test-results/results.json`, and reports a per-tier summary table. Non-conversational (`disable-model-invocation: true`).

### Skill: /token-review

5-phase audit of plugin context footprint. Inventories all context-loaded files, evaluates against an optimization checklist. Optional `--apply` flag for automated optimization.

### Skill: /sync-docs

Compares actual project structure against CLAUDE.md and README.md using the `docs-reviewer` agent. Applies recommended edits to fix gaps, stale references, and incorrect paths.

### Agent: test-runner

Haiku-powered subagent for building and running Swift tests. Parses output per suite and reports pass/fail with failure details.

### Agent: token-review

Haiku-powered subagent for deep context footprint analysis.

### Agent: docs-reviewer

Haiku-powered read-only agent that compares actual project structure against documentation.

## Modifying the Swift source

When adding new features:
- Add input validation in `Validation.swift` for any new user-provided arguments
- Use `.atomic` option on all `Data.write()` calls
- Add a `[DRY RUN]` branch for `--dry-run` mode
- Save new fields to metadata via `saveMetadata()`
- Run `scripts/test-security.sh` to verify validation works

### Swift source layout

```
scripts/BuddyPatcher/
  Package.swift                  SPM manifest (zero dependencies)
  Sources/BuddyPatcher/
    main.swift                   CLI entry point
  Sources/BuddyPatcherLib/
    ArgumentParsing.swift        CLI argument parsing, help output, buddyPatcherVersion
    Validation.swift             Input validation (emoji, name, personality, stats)
    SoulPatcher.swift            patchSoul() — ~/.claude.json updates
    BackupRestore.swift          ensureSoulBackup(), restoreSoulBackup()
    Metadata.swift               saveMetadata(), loadMetadata(), removeMetadata()
    Orchestration.swift          Soul pipeline: runSoulPipeline(), hasPatchWork()
    Paths.swift                  resolvedHome — BUDDY_HOME override for test isolation
  Tests/BuddyPatcherTests/       ~98 tests across 6 files
```
