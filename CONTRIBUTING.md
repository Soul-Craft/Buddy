# Contributing to Buddy Evolver

Contributions are welcome — bug reports, feature requests, new species, new skills,
and Swift patcher improvements. Please read this guide before opening a PR.

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).

---

## Prerequisites

- **macOS** (required — the tool patches Mach-O binaries)
- **Xcode Command Line Tools** — provides Swift 5.9+ and `codesign`
  ```bash
  xcode-select --install
  ```
- **Claude Code** — needed to test plugin integration
- No other dependencies. The Swift patcher uses only Foundation and CryptoKit.

---

## Getting Started

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/buddy-evolver.git
cd buddy-evolver

# Build the Swift patcher
make build
# or: swift build -c release --package-path scripts/BuddyPatcher

# Run unit tests (178 tests across 12 files)
make test
# or: swift test --package-path scripts/BuddyPatcher

# Run security validation tests
make test-security
# or: bash scripts/test-security.sh

# Install locally for end-to-end testing (inside Claude Code)
/plugin install --local .
```

Run `make help` to see all available development targets.

---

## Project Structure

Three main areas contributors touch:

| Area | Path | What's Here |
|------|------|-------------|
| Swift patcher | `scripts/BuddyPatcher/` | Binary patching engine, 178 unit tests |
| Skills | `skills/` | Slash commands (`/buddy-evolve`, `/run-tests`, etc.) |
| Hooks | `hooks/` | Session-start context, argument validation, pre-commit checks |

See [CLAUDE.md](CLAUDE.md) for the full architecture reference, including the data
flow, security model, and automation system.

---

## The Byte-Length Invariant

> **This is the most critical constraint in the codebase.**

The Claude Code binary is a Bun-compiled JavaScript bundle with fixed bytecode
offsets. Every binary patch **must** produce output identical in byte length to
the original. Changing the length by even one byte corrupts the binary.

```swift
// Every patch site must assert length equality before writing
assert(replacement.count == original.count, "Patch length mismatch!")
```

The `PatchLengthInvariantTests` suite enforces this for all species, rarities,
and patch types. Any new patch type **must** include cases in this suite.

Use `--dry-run` to validate anchor patterns and byte-length compliance before
committing:

```bash
scripts/BuddyPatcher/.build/release/buddy-patcher \
  --species dragon --rarity legendary --shiny \
  --emoji "🐲" --name "Test" --personality "Test" \
  --dry-run
```

---

## Coding Standards

### Swift (`scripts/BuddyPatcher/`)

- **No third-party dependencies** — Foundation and CryptoKit only
- **Validate all inputs** in `Validation.swift` before any write operation
- **Atomic writes** — use `.atomic` option on every `Data.write()` call
- **Assert byte-length** equality before writing any binary patch
- **Dry-run branch** — add `[DRY RUN]` output for any new patch type
- **findAll()** to locate patterns; never hardcode byte offsets

### Shell scripts (`hooks/*.sh`, `scripts/*.sh`)

- Use `set -uo pipefail` (or `set -euo pipefail` for non-hooks)
- Hooks must always `exit 0` — never block session startup
- Use `python3` only for JSON parsing, not for core logic

### Skills (`skills/*/SKILL.md`)

Follow the existing YAML frontmatter pattern:

```yaml
---
name: skill-name
description: "Use when the user asks to '...'"
argument-hint: "[optional arg]"
disable-model-invocation: true  # only for non-conversational skills
---
```

---

## How to Contribute

### Bug reports

Use the [Bug Report](.github/ISSUE_TEMPLATE/bug_report.yml) template. Include
your Claude Code version, macOS version, and the output of `/security-audit` so
the buddy backup and metadata state is visible to whoever triages the issue.

### Feature requests

Use the [Feature Request](.github/ISSUE_TEMPLATE/feature_request.yml) template.

### Pull requests

1. Branch from `main`
2. One logical change per PR
3. Fill out the [PR template](.github/PULL_REQUEST_TEMPLATE.md) checklist
4. All Swift PRs must pass `make test-all` before review

### Adding a new species

1. Add the species to `allSpecies` in `VariableMapDetection.swift`
2. Add variable mappings to **every** entry in `knownVarMaps`
3. Add `PatchLengthInvariantTests` cases for the new species
4. Update the species table in `README.md`

### Adding a new patch type

Follow the checklist in CLAUDE.md under "Modifying the Swift source":
use `findAll()`, assert byte-length, add `[DRY RUN]` branch, call
`saveMetadata()`, validate inputs, use `.atomic` writes.

---

## Testing Expectations

| Change type | Required locally | Required before PR |
|-------------|------------------|--------------------|
| Any Swift change | `make test` (178 unit tests) | `make test-all` (328 tests across 9 tiers) |
| Security-sensitive Swift | `make test` + `make test-security` | `make test-all` |
| New bug fix | Add test to `RegressionTests.swift` | `make test-all` |
| New patch type | Add `PatchLengthInvariantTests` cases | `make test-all` + `make test-compat` |
| New species | Add to `VariableMapDetectionTests` | `make test-all` + `make test-compat` |
| Shell scripts changed | `make lint` | `make test-all` |
| Documentation changed | `make test-docs` | `make test-all` |
| CLI output changed | `UPDATE_GOLDEN=1 make test-snapshots` (review diffs) | `make test-all` |
| New skill/hook | Manual end-to-end test inside Claude Code | `make test-all` + `make test-docs` |

---

## Review Process

- Swift changes trigger the `security-reviewer` agent (read-only, reviews for
  validation gaps, byte-length violations, unsafe patterns)
- Maintainer checks byte-length invariant compliance on all patcher changes
- CI must pass before merge: `ci-quality.yml` (lint/JSON/hygiene, runs on Ubuntu) and `ci-verify-local.yml` (confirms that `scripts/test-all.sh && scripts/upload-test-results.sh` has posted a passing Check Run on the head commit)
