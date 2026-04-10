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

- [ ] `scripts/test-all.sh` — all 5 tiers pass (unit / security / integration / functional / UI)
- [ ] `scripts/upload-test-results.sh` — Check Run appears on this PR's head commit
- [ ] If touching UI: `scripts/test-visual-smoke.sh` — visual checks pass, screenshot attached below

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
