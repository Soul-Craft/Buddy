# Changelog

All notable changes to Buddy Evolver are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-04-12

### Changed
- **Retired binary-patching layer** — The plugin no longer patches the Claude Code Mach-O
  binary. Investigation confirmed the patchable surface was removed from Claude Code
  between v2.1.90 and v2.1.98 (approximately 2026-04-01 to 2026-04-09).
- `run-buddy-patcher.sh` now writes name and personality to `~/.claude.json#companion`
  (soul patching) and saves card metadata to `~/.claude/backups/buddy-patch-meta.json`.
  No binary is read, no codesign step, no restart required.
- New CLI flags: `--meta-species`, `--meta-rarity`, `--meta-shiny`, `--meta-no-shiny`,
  `--meta-emoji`, `--meta-stats` for card metadata. Old flags (`--species`, `--rarity`,
  `--shiny`, `--binary`, `--analyze`) are rejected as unknown options.
- Metadata schema bumped to `schema_version: 2` (removes `binary_path` and `binary_sha256`).
- `/buddy-evolve` skill rewritten: drops binary patch prompts, passes `--meta-*` flags,
  confirms name/personality are live immediately with no restart needed.
- `/buddy-reset` skill rewritten: restores soul backup only, no binary restore or codesign.
- `/security-audit` skill rewritten: 7-point backup health check, no SHA-256 or codesign steps.
- Test pipeline reduced from 9 tiers (328 tests) to 6 tiers (~181 tests). Retired tiers:
  integration, functional, e2e (all exercised the binary-patching layer via a synthetic Mach-O).
- Plugin version bumped to 2.0.0.

### Removed
- `PatchEngine.swift`, `VariableMapDetection.swift`, `Analyze.swift`, `ByteUtils.swift`,
  `BinaryDiscovery.swift` — binary patching source files.
- `scripts/build-test-binary.sh` — synthetic Mach-O test fixture builder.
- `scripts/test-functional.sh`, `scripts/test-integration.sh`, `scripts/test-e2e.sh`,
  `scripts/test-compatibility.sh` — test suites that exercised the binary-patching layer.
- `/buddy-e2e-test`, `/test-patch`, `/update-species-map` skills — obsolete with binary layer.

## [Unreleased]

### Changed
- Confirmed retirement of the plugin-registered `/buddy` command. The skill itself was
  split into `/buddy-evolve`, `/buddy-reset`, and `/buddy-status` in PR #4 (pre-v2.0.0)
  and is absent from the current source. However, Claude Code v2.1.104 shipped a native
  `/buddy` command for hatching companions, and installs pinned to the v1.0.0 cache
  (`gitCommitSha 2cc775d`) were shadowing it. Existing users must reinstall to pick up
  the v2.0.0 surface — see "Upgrading from v1.x" in `README.md`.

### Added
- Regression guard in `scripts/test-docs.sh` (Group 10) — rejects any future skill named
  `buddy`, `test-patch`, or `update-species-map` (either as a `skills/<name>/` directory
  or via `name:` frontmatter). Prevents accidental re-introduction of retired commands.

### Fixed
- Stale references to the retired `/test-patch` and `/update-species-map` skills in
  `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/bug_report.yml`, `hooks/session-start.sh`,
  `skills/start-session/SKILL.md`, `skills/sync-docs/SKILL.md`,
  `skills/token-review/SKILL.md`, `skills/buddy-evolve/references/evolution-packs.md`,
  and `.claude-plugin/agents/docs-reviewer.md`. Updated the `/token-review` dry-run
  invocation to use v2.0.0 `--meta-*` flags.

## [1.0.1] - 2026-04-10

### Fixed
- Stale `/buddy` references in `/buddy-evolve` and `/buddy-reset` post-restart
  messages — users were told to "run /buddy" after restart, but that command was
  removed in the #4 split. Now points at `/buddy-status`.
- `/buddy reset` typo in `README.md` (should be `/buddy-reset`).
- Inaccurate 1.0.0 changelog entry — the published 1.0.0 marketplace snapshot
  predates the `/buddy` → `/buddy-evolve`+`/buddy-reset` split (#4) and all
  subsequent development. The changelog previously listed those features under
  1.0.0, but they never actually reached users. Reorganized to reflect reality.
- Republish required: old 1.0.0 cache contained the legacy `/buddy` skill whose
  `$ARGUMENTS` routing triggers a Claude Code parser error
  ("Unhandled node type: string"). v1.0.1 delivers the already-fixed skills to
  the marketplace so users can actually receive the #4 fix.

### Added
- `/buddy-evolve` and `/buddy-reset` skills, split from original `/buddy` command (#4)
- Auto-approval of buddy skill Bash commands to avoid mid-flow prompts (#5)
- Post-patch binary verification and automatic restore on codesign failure (#6)
- Multi-version variable map detection (`knownVarMaps`) for version portability (#7)
- `/buddy-status` skill — visual buddy card with rarity flair and stat bars (#8)
- Binary patching engine rewritten in native Swift 5.9 (zero third-party dependencies,
  replacing the Python prototype) (#9)
- 18 species with species-specific ASCII art and multi-version anchor detection
- 5 rarity tiers with weight manipulation (`common:60` → target-only weights)
- Shiny mode — threshold patch guarantees shiny on every spawn
- Custom emoji patching (species art arrays replaced with centered emoji)
- Soul patching — name, personality, and stats written to `~/.claude.json`
- Security hardening: Swift input validation for all user inputs, atomic file writes
  (`rename(2)`), SHA-256 backup integrity, plugin-level argument validation hook,
  shell injection prevention (#11)
- 94 unit tests across 8 suites, `/run-tests` skill, pre-commit test reminder hook,
  and `test-runner` agent (#12)
- Cache management system: `scripts/cache-clean.sh`, `/cache-clean` skill, and
  `cache-analyzer` agent (#13)
- `/token-review` skill and agent for context footprint auditing (#14)
- GitHub Actions CI: build, unit tests, and security tests on macOS 14 (#15)
- `/start-session` and `/end-session` skills and `SessionStart` hook for dev
  session lifecycle management (#17)
- Doc-sync infrastructure: `docs-reviewer` agent and `/sync-docs` skill for keeping
  CLAUDE.md and README.md in sync with the project structure (#18)
- Developer-facing README sections: architecture, security model, development setup,
  testing reference, and expanded contributing guide (#20)
- CONTRIBUTING.md, SECURITY.md, issue templates, PR template, Makefile, and
  .gitattributes for open-source contributor readiness (#21)
- 8-tier testing infrastructure (303 automated tests + 34 on-demand): smoke,
  unit (178), security, integration, functional, ui, snapshots, docs. On-demand
  compatibility and performance suites. Local HTML coverage report. (#23, #28)

### Changed
- Removed species selection shortcut — species now chosen interactively in evolve flow
- Simplified commands from `/buddy evolve` / `/buddy reset` to `/buddy-evolve` / `/buddy-reset`
- Post-restart instructions in `/buddy-evolve` and `/buddy-reset` now point at
  `/buddy-status` (was: the deleted `/buddy`), and drop the prescriptive warning
  emoji per Claude Code skill message best practice.

## [1.0.0] - 2026-04-01

### Added
- Initial plugin release as `buddy-customizer`, rebranded to Buddy Evolver (#2)
- Marketplace listing (`marketplace.json`) and plugin install instructions (#3)
- Original `/buddy` skill with `$ARGUMENTS` routing (`evolve` / `reset` subcommands).
  **Known bug:** routing construct triggers Claude Code parser error
  "Unhandled node type: string" — fixed in 1.0.1 by splitting into separate
  `/buddy-evolve`, `/buddy-reset`, and `/buddy-status` skills.

[Unreleased]: https://github.com/Soul-Craft/buddy-evolver/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/Soul-Craft/buddy-evolver/releases/tag/v2.0.0
[1.0.1]: https://github.com/Soul-Craft/buddy-evolver/releases/tag/v1.0.1
[1.0.0]: https://github.com/Soul-Craft/buddy-evolver/releases/tag/v1.0.0
