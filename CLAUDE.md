# Buddy Customizer

Claude Code plugin that customizes the terminal Buddy pet by patching the Mach-O binary and companion data.

## Architecture

```
.claude-plugin/plugin.json       Plugin manifest (name, version, metadata)
.claude-plugin/marketplace.json  Marketplace listing (for /plugin install)
.claude-plugin/agents/           Subagents (cache-analyzer, token-review)
.claude/settings.json            Hooks (byte-length reminder + permissions)
hooks/hooks.json                 Plugin hooks (SessionStart + SessionEnd + PreToolUse)
hooks/session-start.sh           SessionStart hook: dynamic dev context + pending cleanup retry
hooks/session-end.sh             SessionEnd hook: automatic worktree self-cleanup on exit
hooks/validate-patcher-args.sh   Security hook: validates patcher arguments
hooks/check-doc-freshness.sh     Pre-commit doc freshness check
hooks/pre-commit-test-reminder.sh Context-aware test reminders on git commit
agents/security-reviewer.md      Security review agent for Swift code changes
agents/comment-reviewer.md       Inline comment audit agent for /end-session (Haiku)
agents/test-runner.md            Test execution agent for Swift suite
skills/buddy-evolve/             Evolution skill (/buddy-evolve)
skills/buddy-reset/              Reset skill (/buddy-reset)
skills/buddy-status/             Buddy card display (/buddy-status)
skills/buddy-e2e-test/           E2E flow validation (/buddy-e2e-test)
skills/test-patch/               Dry-run validation (/test-patch)
skills/run-tests/                Swift test runner (/run-tests)
skills/run-all-tests/            Full pipeline runner (/run-all-tests)
skills/security-audit/           Security posture audit (/security-audit)
skills/update-species-map/       Binary version maintenance (/update-species-map)
skills/cache-clean/              Cache management skill (/cache-clean)
skills/token-review/             Token optimization audit (/token-review)
skills/sync-docs/                Documentation sync (/sync-docs)
skills/start-session/            Dev session context (/start-session) — delegates to hook
skills/end-session/              Pre-commit wrap-up (/end-session) — full test pipeline
skills/session-deploy/           Post-merge sync + worktree cleanup (/session-deploy)
scripts/BuddyPatcher/            Binary patching engine (Swift, CryptoKit only)
scripts/BuddyPatcher/Tests/      Unit test suite (178 tests across 12 files)
scripts/BuddyPatcher/Tests/Fixtures/  Golden files for CLI snapshot tests
scripts/run-buddy-patcher.sh     Lazy-build wrapper (compiles Swift on first use)
scripts/cache-clean.sh           Cache cleanup script (used by hook + skill)
scripts/process-pending-cleanup.sh  Shared worktree cleanup retry logic (session-end + session-start hooks)
scripts/build-test-binary.sh     Compiles a synthetic Mach-O with embedded patch patterns
scripts/lint.sh                  Local lint (shellcheck, JSON, frontmatter, hygiene)
scripts/test-smoke.sh            Smoke tier: build sanity + CLI contract (<30s, 13 tests)
scripts/test-security.sh         Security validation test suite (27 tests)
scripts/test-integration.sh      End-to-end patch/restore/metadata flows (23 tests)
scripts/test-functional.sh       Byte-level patch correctness + Mach-O validity (19 tests)
scripts/test-ui.sh               Buddy card rendering against fixtures (23 tests)
scripts/test-e2e.sh              E2E tier — real-binary reset→evolve→verify→reset flow (23 tests)
scripts/test-snapshots.sh        Golden file comparison for CLI output (6 tests)
scripts/test-docs.sh             Documentation path + link + count consistency (16 tests)
scripts/test-compatibility.sh    Compatibility validation against knownVarMaps (~27 tests, on-demand)
scripts/test-perf.sh             Performance benchmarks (7 benchmarks, on-demand)
scripts/coverage.sh              Local HTML coverage report (test-results/coverage/)
scripts/BuddyPatcher/Tests/BuddyPatcherTests/RegressionTests.swift  One test per fixed bug (3 tests)
scripts/test-ui-renderer.py      Standalone Python renderer (reference for /buddy-status)
scripts/test-visual-smoke.sh     Manual pre-release visual check (interactive)
scripts/test-all.sh              Master runner — all tiers, JSON/JUnit output
scripts/upload-test-results.sh   Uploads results to GitHub as a Check Run
```

### How patching works

The Claude Code binary is a Bun-compiled JavaScript bundle. Buddy customization patches the binary in-place:

1. **Species** — The species array (`Trq`) contains 3-byte variable references (`GL_`, `ZL_`, etc.). All refs are replaced with the target species' variable. Found via anchor pattern `GL_,ZL_,LL_,kL_,`.
2. **Rarity** — Weight string `common:60,uncommon:25,rare:10,epic:4,legendary:1` is modified to zero all weights except the target.
3. **Shiny** — Threshold `H()<0.01` changed to `H()<1.01` (guarantees shiny).
4. **Art** — Species-keyed ASCII art arrays replaced with centered emoji.
5. **Soul** — Name and personality written to `~/.claude.json` (not binary).

After patching, the binary is re-signed with `codesign --force --sign -`.

### Critical constraints

- **Exact byte length**: Every binary patch MUST produce output identical in byte length to the original. The Bun bytecode has fixed offsets — changing length corrupts the binary.
- **3-byte variable refs**: Species variables are always exactly 3 bytes (e.g., `GL_`, `vL_`). This is a bytecode invariant.
- **Anchor patterns**: The tool locates patch sites by searching for known byte patterns, not fixed offsets. This provides version portability but means patches break if Anthropic refactors the variable names or string formats.
- **Backup before patch**: `ensureBackup()` is idempotent — it creates a one-time backup and never overwrites it. The original binary must always be recoverable.

### Data flow

```
/buddy-evolve
  → Reads current buddy from ~/.claude.json (via plutil)
  → Collects choices (species, rarity, emoji, name, personality, stats)
  → Runs: run-buddy-patcher.sh --species X --rarity Y ...
  → Tool backs up binary + soul, patches binary, re-signs, saves metadata
  → User restarts Claude Code

/buddy-reset
  → Checks for backup at <binary>.original-backup
  → Copies backup over current binary, restores ~/.claude.json
  → Re-signs binary
```

### Key file locations (on user's machine)

- Binary: resolved from `~/.local/bin/claude` symlink → `~/.local/share/claude/versions/<ver>`
- Binary backup: `<binary>.original-backup`
- Soul backup: `~/.claude/backups/.claude.json.pre-customize`
- Patch metadata: `~/.claude/backups/buddy-patch-meta.json`

## Platform

macOS only. Requires Xcode Command Line Tools (provides Swift compiler and `codesign`). Zero third-party dependencies.

## Security

Defense-in-depth across three layers:

### Layer 1: Swift input validation (`Validation.swift`)

All user-provided inputs are validated before any write operation:
- **Emoji**: Single grapheme cluster, all scalars `.isEmoji`, max 16 UTF-8 bytes
- **Name**: Non-empty, max 100 chars, no control characters
- **Personality**: Non-empty, max 500 chars, no control characters
- **Stats**: JSON with known keys only, integer values 0-100
- **Binary path** (`--binary`): Must exist, be a regular file, have Mach-O magic bytes

### Layer 2: Atomic operations and integrity

- All file writes use `.atomic` option (`rename(2)` under the hood)
- SHA-256 hash of original binary stored on first backup
- Restore verifies backup integrity against stored hash
- Codesign failure after patching triggers auto-restore + exit(1)
- Backup directory and files set to 0o700/0o600

### Layer 3: Plugin-level enforcement

- **PreToolUse hook** (`hooks/validate-patcher-args.sh`): Intercepts Bash calls to the patcher, validates arguments for shell metacharacters (`;|&$\``), length limits, and subshell injection (`$()`)
- **Security audit skill** (`/security-audit`): On-demand check of binary integrity, backup health, codesign status, file permissions, and pattern compatibility
- **Security review agent** (`agents/security-reviewer.md`): Read-only agent that reviews Swift code changes for missing validation, byte-length invariant violations, non-atomic writes, and unsafe patterns

## Testing

328 automated tests in `test-all.sh` (9 tiers) + 34 on-demand tests, plus an interactive visual smoke test. The critical design decision: **macOS-dependent tests run locally on the contributor's machine, NOT in GitHub Actions.** GitHub runners only run cheap Ubuntu-based quality checks. This keeps CI costs bounded while still enforcing test passage on every PR.

### The 9 automated tiers (run via `test-all.sh`)

| Tier | Script | Tests | Stage | Purpose |
|------|--------|-------|-------|---------|
| Smoke | `scripts/test-smoke.sh` | 13 | smoke | Build sanity + CLI contract (<30s) |
| Unit | `swift test` | 178 | core | Swift XCTest suite — pure functions, validation, patch engine, orchestration, regressions |
| Security | `scripts/test-security.sh` | 27 | core | Input validation, hook enforcement, injection checks |
| Integration | `scripts/test-integration.sh` | 23 | real-world | End-to-end patch/restore/metadata flows against a synthetic binary |
| Functional | `scripts/test-functional.sh` | 19 | real-world | Byte-level patch verification + Mach-O validity + codesign |
| UI | `scripts/test-ui.sh` | 23 | real-world | Buddy card rendering against pinned JSON fixtures |
| E2E | `scripts/test-e2e.sh` | 23 | real-world | Real-binary reset→evolve→verify→reset flow + UI render assertions |
| Snapshots | `scripts/test-snapshots.sh` | 6 | full-system | Golden file comparison for CLI output |
| Docs | `scripts/test-docs.sh` | 16 | peripheral | Documentation path + link + count consistency |

### On-demand suites (not in `test-all.sh`)

| Suite | Script | Tests | Purpose |
|-------|--------|-------|---------|
| Compatibility | `scripts/test-compatibility.sh` | ~27 | Verify knownVarMaps entries still work against current test binary |
| Performance | `scripts/test-perf.sh` | 7 | Timing benchmarks — catches catastrophic regressions only |

Run everything: `scripts/test-all.sh` — emits `test-results/results.json`, `test-results/junit.xml`, and `test-results/full-output.log`. Local HTML coverage report: `make coverage` → `test-results/coverage/index.html`.

### Visual smoke test

`scripts/test-visual-smoke.sh` is an interactive script used before releases. It renders a fixture buddy card (legendary shiny dragon) and walks the tester through a 10-item visual checklist, capturing a terminal screenshot for PR evidence. Not part of `test-all.sh`.

### Test isolation via `BUDDY_HOME`

Swift tests that touch the filesystem use `resolvedHome` (in `Paths.swift`) which honors the `BUDDY_HOME` env var. This is **critical**: on macOS, `FileManager.homeDirectoryForCurrentUser` reads the user database directly and ignores `HOME`, so bash test scripts must set `BUDDY_HOME` to isolate test runs from the user's real `~/.claude`. Integration and functional scripts do this automatically.

### Synthetic test binary

`scripts/build-test-binary.sh` compiles a small Swift program whose source embeds every patchable pattern (species array, rarity weights, shiny threshold, art block) as string constants. The resulting Mach-O binary contains those patterns in `__TEXT/__cstring` where the patcher can find them. Integration, functional, and UI tests use this binary so they never touch the real Claude Code binary.

### CI architecture

Four workflows in `.github/workflows/`:

- **`ci-quality.yml`** (Ubuntu, runs on every push/PR) — shellcheck, JSON/YAML validation, skill frontmatter checks, repo hygiene (no `.build/`, no `.DS_Store`), doc-sync validation. Fast, deterministic, cheap.
- **`ci-verify-local.yml`** (Ubuntu, runs on every PR) — queries the GitHub Checks API for a `Local Tests (macOS)` Check Run on the head commit. If missing or failed, posts a sticky PR comment telling the contributor to run `scripts/test-all.sh && scripts/upload-test-results.sh`.
- **`ci-macos-fallback.yml`** (macOS-14, manual only via `workflow_dispatch` or `v*` tag push) — escape hatch for contributors without macOS access. Runs the full `test-all.sh` suite and uploads artifacts. Not part of default CI because macOS runners are expensive.
- **`release.yml`** — triggered on `v*` tag pushes to package and publish releases.

### Local → GitHub bridge

`scripts/upload-test-results.sh` reads `test-results/results.json` and POSTs a GitHub Check Run via `gh api`. The Check Run carries the tier breakdown, duration, environment metadata, and pass/fail counts. On permission failure (e.g. forks without `checks:write`), falls back to `gh pr comment` on the current PR.

### Contributor workflow

1. Edit code on macOS.
2. Run `scripts/test-all.sh` — all 5 tiers must pass.
3. Run `scripts/upload-test-results.sh` — results appear as a Check Run on the current commit.
4. Push the branch, open a PR.
5. `ci-quality.yml` runs on Ubuntu; `ci-verify-local.yml` confirms the Check Run is present and green.
6. Maintainer reviews and merges.

## Automations

### Hook: session-start context injection

A `SessionStart` hook in `hooks/hooks.json` runs `hooks/session-start.sh` at the start of each Claude Code session. **Dynamic discovery**: parses frontmatter from every SKILL.md, agent markdown file, and hook definition to emit up-to-date lists with no hardcoded drift. Compares the current branch to `origin/main` via a cached `git fetch` (5-min TTL) and warns if >10 commits behind. Reports git state, binary version, compatibility status, backup health, cache state, and any pending worktree cleanups from a prior `/session-deploy`. Always exits 0 (never blocks session startup). Timeout: 10s. Output budget: ≤60 lines, typical runtime <2s.

### Hook: session-end automatic cleanup

A `SessionEnd` hook in `hooks/hooks.json` runs `hooks/session-end.sh` when a Claude Code session ends. Reads `~/.claude/buddy-evolver-cleanup-pending.json` (written by `/session-deploy`) and attempts to remove each staged worktree from the main repo. Delegates to `scripts/process-pending-cleanup.sh` (shared with the session-start retry path). Best-effort first attempt — if Claude Code hasn't released the worktree's CWD yet, the cleanup is retried on the next `SessionStart` in any future session. Always exits 0. Timeout: 5s.

### Skill: /start-session

Manual re-trigger of the SessionStart hook. **Delegates to `hooks/session-start.sh`** so there is no parallel hardcoded list to drift. Use to refresh context mid-session or when hook output has scrolled away.

### Skill: /end-session

Pre-commit wrap-up. Run BEFORE clicking the Desktop App's "Commit Changes" button. Unconditional linear pipeline:
1. Token review with `--apply --force` — applies optimizations (so tests validate the optimized code)
2. Full test pipeline via `scripts/test-all.sh` — all 328 tests across 9 tiers
3. Upload results to GitHub as a Check Run via `scripts/upload-test-results.sh`
4. Sync docs via `/sync-docs` (uses `docs-reviewer` agent internally)
5. Comment review via the `comment-reviewer` Haiku agent — flags missing/stale comments in changed files
6. Unified summary table with per-tier test results, upload status, doc sync outcome, and comment findings

When all checks pass, the user commits via the Desktop App's button. `ci-verify-local.yml` then verifies the uploaded Check Run matches the commit.

### Skill: /session-deploy

Post-merge sync and worktree cleanup. Run AFTER the PR is merged via the Desktop App's CI popup. Steps:
1. Detects main repo path via `git worktree list | head -1`
2. Verifies the current branch's PR is actually merged (via `gh pr list --state merged`)
3. Fast-forwards local `main` to the merged state
4. Runs `scripts/test-smoke.sh` on main to verify the merged code still builds
5. Removes OTHER merged worktrees immediately (skips dirty ones)
6. Stages the current worktree for self-cleanup in `~/.claude/buddy-evolver-cleanup-pending.json`
7. Cleans build caches with `scripts/cache-clean.sh --all`
8. Reports the plan and instructs the user to type `/exit`

The current worktree cannot remove itself (Claude Code holds its CWD), so the SessionEnd hook attempts cleanup on exit, and the next SessionStart hook retries as a safety net. Supports `--dry-run` for previewing without making changes.

### Agent: comment-reviewer

Haiku read-only agent used by `/end-session`. Audits inline code comments in recently changed files (filtered to Swift sources under `scripts/BuddyPatcher/Sources/**` and shell scripts under `scripts/**` and `hooks/**`). Five checks:
1. Missing doc comments on non-obvious functions (>15 lines, touches anchor patterns, does byte-length math, or writes to the binary)
2. `TODO`/`FIXME`/`HACK` markers
3. Stale comments (two-signal rule — symbol mentioned but absent from surrounding ±10 lines)
4. Security-critical files (`Validation.swift`, `BackupRestore.swift`, `SoulPatcher.swift`) without `// SECURITY:` markers on modified functions
5. `shellcheck disable=` lines without justification comments

Tools: `[Read, Glob, Grep]`. Never applies edits — reports only. Output sections: `MISSING_COMMENT`, `TODO_MARKER`, `STALE_COMMENT`, `SECURITY_COMMENT`, `SHELLCHECK_UNJUSTIFIED`, `SUMMARY`.

### Skill: /buddy-status

Read-only display of the current buddy as a visual card with rarity flair, stat bars, and age. Reads `~/.claude.json` and `~/.claude/backups/buddy-patch-meta.json`. Shows different cards for evolved, wild (un-evolved), and missing buddies. No files modified.

### Skill: /buddy-e2e-test

End-to-end validation of the full Buddy Evolver flow against the real Claude Code binary. Runs reset → evolve to Aethos (legendary shiny dragon, full stats) → verify via `test-ui-renderer.py` (JSON + visual card) → reset → verify cleanup. Installs a bash `trap` so any mid-flow failure still triggers `--restore`. Non-conversational (`disable-model-invocation: true`). Use for pre-release validation or after upgrading Claude Code. Also runs automatically as the `e2e` tier in `test-all.sh`, where it gracefully skips if no Claude Code binary is installed.

### Hook: byte-length protection

A `PreToolUse` hook in `.claude/settings.json` fires when editing files in `BuddyPatcher/`. It injects a reminder about the byte-length invariant into Claude's context. This is a prompt-based hook (awareness, not enforcement).

### Hook: argument validation

A `PreToolUse` hook in `hooks/hooks.json` fires on Bash tool calls. If the command invokes `buddy-patcher`, it validates all arguments for injection attacks and length limits before allowing execution.

### Hook: pre-commit test reminder

A `PreToolUse` hook in `hooks/hooks.json` fires on Bash tool calls containing `git commit`. Delegates to `hooks/pre-commit-test-reminder.sh`, which inspects staged files and injects context-aware reminders: `make test` for Swift changes, `make test-security` for security-sensitive code, `make lint` for shell scripts, `make test-docs` for documentation, `make test-compat` for patch pattern changes, and `make test-snapshots` if CLI output files were modified.

### Hook: doc freshness check

A `PreToolUse` hook in `hooks/hooks.json` fires on `git commit`. Checks if code files (skills, agents, hooks, scripts) were staged without corresponding updates to `CLAUDE.md` or `README.md`. Injects a reminder to run `/sync-docs` if drift is detected.

### Skill: /cache-clean

Manual cache management with interactive preview. Runs dry-run first, then cleans on confirmation. Use `--all` flag to also clean the current worktree's build cache.

### Agent: cache-analyzer

Deep cache analysis subagent. Scans for build artifacts, orphaned worktrees, backup sizes, and disk usage. Produces a structured report with recommendations.

### Skill: /test-patch

Runs the patching tool in `--dry-run` mode with all patch types to verify anchor patterns still match the current binary. Use after Claude Code updates.

### Skill: /security-audit

Runs a comprehensive security audit: binary integrity, backup health, SHA-256 verification, codesign status, file permissions, metadata validation, and dry-run compatibility.

### Skill: /update-species-map

Investigates the binary when patterns break. Uses `--analyze` mode to search for anchor patterns, extract variable names, and compare against `knownVarMaps`. Use when `/test-patch` reports failures.

### Skill: /run-tests

Runs `swift test` in `scripts/BuddyPatcher/`, parses results per suite (12 files, 178 tests), and reports a pass/fail scorecard. Non-conversational (`disable-model-invocation: true`).

### Skill: /run-all-tests

Runs the full 9-tier test pipeline via `scripts/test-all.sh`, reads `test-results/results.json`, and reports a per-tier summary table grouped by stage (smoke → core → real-world → full-system → peripheral). On failure, suggests the appropriate follow-up skill or command for each tier type. Non-conversational (`disable-model-invocation: true`).

### Skill: /token-review

5-phase audit of plugin context footprint. Inventories all context-loaded files, evaluates against an optimization checklist, and reports token savings opportunities. Optional `--apply` flag for automated optimization.

### Skill: /sync-docs

Compares actual project structure against CLAUDE.md and README.md using the `docs-reviewer` agent. Applies recommended edits to fix gaps, stale references, and incorrect paths. Run manually or when the doc freshness hook fires.

### Agent: test-runner

Haiku-powered subagent for building and running Swift tests. Parses output per suite and reports pass/fail with failure details. Used by `/end-session` when Swift code changes and by `/run-tests`. Tools: Bash, Read, Glob, Grep.

### Agent: token-review

Haiku-powered subagent for deep context footprint analysis. Inventories context-loaded files, evaluates against optimization checklist, and scores each check. Used by `/token-review` skill and `/end-session`. Tools: Read, Glob, Grep, Bash.

### Agent: docs-reviewer

Haiku-powered read-only agent that compares actual project structure against documentation. Globs for all skills, agents, hooks, Swift sources, and scripts, then checks each against CLAUDE.md and README.md. Reports gaps as `MISSING_FROM_DOCS`, `STALE_IN_DOCS`, `PATH_MISMATCH`, or `DESCRIPTION_OUTDATED`.

## Modifying the Swift source

When adding new patch types:
- Always use `findAll()` to locate patterns (never hardcode offsets)
- Assert byte length equality before writing
- Add a `[DRY RUN]` branch for `--dry-run` mode
- Save new fields to metadata via `saveMetadata()`
- Handle the "already patched" case (tool should be re-runnable)
- Add input validation in `Validation.swift` for any new user-provided arguments
- Use `.atomic` option on all `Data.write()` calls
- Run `scripts/test-security.sh` to verify validation works

When updating for new Claude Code versions:
- Check if anchor patterns still exist in the new binary
- Variable names may change — update `knownVarMaps` in `VariableMapDetection.swift`
- Test with `--dry-run` first

### Swift source layout

```
scripts/BuddyPatcher/
  Package.swift                  SPM manifest (zero dependencies)
  Sources/BuddyPatcher/
    main.swift                   CLI entry point, delegates to Orchestration
  Sources/BuddyPatcherLib/
    ArgumentParsing.swift        CLI argument parsing, help output
    Analyze.swift                Binary introspection (--analyze mode)
    Validation.swift             Input validation (emoji, name, personality, stats, binary path)
    ByteUtils.swift              findAll(), findFirst(), utf8Bytes() helpers
    BinaryDiscovery.swift        findBinary(), getVersion(), PatchError
    VariableMapDetection.swift   knownVarMaps, detectVarMap(), anchorForMap()
    PatchEngine.swift            patchSpecies(), patchRarity(), patchShiny(), patchArt()
    SoulPatcher.swift            patchSoul() — ~/.claude.json updates
    BackupRestore.swift          ensureBackup(), restoreBackup(), verifyBinary(), sha256Hex()
    Metadata.swift               saveMetadata(), loadMetadata()
    Orchestration.swift          Pure pipeline: runPatchPipeline(), hasPatchWork()
    Paths.swift                  resolvedHome — BUDDY_HOME override for test isolation
  Tests/BuddyPatcherTests/       178 tests across 12 files
```
