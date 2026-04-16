<!--
Thanks for contributing to Buddy Evolver!

This repo uses a local-first testing model: macOS-dependent tests run on
YOUR machine, and the results are uploaded to GitHub as a Check Run. Only
cheap Ubuntu checks run in GitHub Actions automatically.
-->

## Summary

<!-- What does this PR change? 1-3 bullets. -->

-

## Type of change

- [ ] Bug fix
- [ ] New feature (species, skill, patch type, etc.)
- [ ] Refactoring (no behavior change)
- [ ] Documentation
- [ ] CI / tooling

## Testing checklist

Before requesting review, run the full local suite on macOS:

- [ ] `make test-all` — all 9 tiers pass (328 tests: smoke / unit / security / integration / functional / UI / e2e / snapshots / docs)
- [ ] `scripts/upload-test-results.sh` — run after push, **before** opening this PR (posts commit status that CI checks immediately)
- [ ] If touching UI: `scripts/test-visual-smoke.sh` — visual checks pass, screenshot attached below

**Additional checks (run when relevant):**
- [ ] `make test-smoke` — if you want a fast (<30s) build + CLI sanity check before the full run
- [ ] `UPDATE_GOLDEN=1 make test-snapshots` — if CLI output changed intentionally (review golden file diffs before committing)
- [ ] `make test-docs` — if documentation changed
- [ ] `make test-compat` — if touching patch patterns or `knownVarMaps`
- [ ] `make lint` — if modifying shell scripts

<!-- Attach visual-smoke screenshot here if applicable -->

### If modifying Swift code (`scripts/BuddyPatcher/`)

- [ ] Byte-length invariant maintained — every patch produces identical-length output
- [ ] New user inputs validated in `Validation.swift`
- [ ] All `Data.write()` calls use `.atomic`
- [ ] `--dry-run` works for any new patch functionality

### If adding a new species

- [ ] Added to `allSpecies` in `VariableMapDetection.swift`
- [ ] Variable mapping added to **every** entry in `knownVarMaps`
- [ ] `PatchLengthInvariantTests` cases added
- [ ] Species table updated in `README.md`

### If modifying skills, hooks, or agents

- [ ] `CLAUDE.md` updated (or `/sync-docs` ran)
- [ ] `README.md` updated if change is user-facing

## Scope checklist

- [ ] No `.build/` or `test-results/` committed
- [ ] Commit messages describe the "why", not just the "what"

## Risk

<!-- Does this change affect patching, backup/restore, or codesign? Flag here. -->

-
