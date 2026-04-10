## What does this PR do?

<!-- Brief description of the change -->

## Type of change

- [ ] Bug fix
- [ ] New feature (species, skill, patch type, etc.)
- [ ] Refactoring (no behavior change)
- [ ] Documentation
- [ ] CI / tooling

## Checklist

- [ ] I have read [CONTRIBUTING.md](CONTRIBUTING.md)
- [ ] My changes follow the existing code style
- [ ] I have tested my changes locally

### If modifying Swift code (`scripts/BuddyPatcher/`)

- [ ] `make test` passes (94 unit tests)
- [ ] `make test-security` passes
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

## Test plan

<!-- How did you verify this works? -->
