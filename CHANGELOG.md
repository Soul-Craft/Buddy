# Changelog

All notable changes to Buddy Evolver are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- E2E test tier (`scripts/test-e2e.sh`) — 23-check real-binary reset→evolve→verify→reset
  flow with `trap`-based cleanup and graceful CI skip when binary not installed
- `/buddy-e2e-test` skill — on-demand E2E validation with phase-by-phase pass/fail table;
  non-conversational (`disable-model-invocation: true`)
- `make test-e2e` Makefile target (Stage 4: Real-world, depends on `build`)

### Changed
- Binary patch failure UX: when the binary doesn't match any known anchor pattern, the
  patcher now emits a single consolidated warning ("No matching anchor found — binary
  patches skipped") instead of four separate per-type warnings. Soul customization
  (name, personality, stats) is unaffected. `Orchestration.swift` short-circuits the
  pipeline on anchor miss rather than letting all four patch functions fail individually.
- Completion message now distinguishes "0 binary patches, soul applied" from full
  success, with a clear `run /update-species-map` prompt.
- Test pipeline expanded from 8 tiers (303 tests) to 9 tiers (326 tests).

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

[Unreleased]: https://github.com/Soul-Craft/buddy-evolver/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/Soul-Craft/buddy-evolver/releases/tag/v1.0.1
[1.0.0]: https://github.com/Soul-Craft/buddy-evolver/releases/tag/v1.0.0
