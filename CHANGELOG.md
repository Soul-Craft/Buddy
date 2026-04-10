# Changelog

All notable changes to Buddy Evolver are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- CONTRIBUTING.md, SECURITY.md, issue templates, PR template, Makefile, CHANGELOG,
  and .gitattributes for open-source contributor readiness

## [1.0.0] - 2026-04-09

### Added
- Initial plugin release as `buddy-customizer`, rebranded to Buddy Evolver (#2)
- Marketplace listing (`marketplace.json`) and plugin install instructions (#3)
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

### Changed
- Removed species selection shortcut — species now chosen interactively in evolve flow
- Simplified commands from `/buddy evolve` / `/buddy reset` to `/buddy-evolve` / `/buddy-reset`

[Unreleased]: https://github.com/Soul-Craft/buddy-evolver/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Soul-Craft/buddy-evolver/releases/tag/v1.0.0
