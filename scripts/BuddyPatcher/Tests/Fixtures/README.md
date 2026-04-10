# Test Fixtures

This directory contains golden files (pinned CLI output) used by
`scripts/test-snapshots.sh` to detect unintended changes to the
`buddy-patcher` command-line interface.

## Golden files

Each file in `GoldenFiles/` captures the normalized output of one
`buddy-patcher` invocation. Volatile fields are replaced by stable
placeholders during normalization (see below).

| File | Command | Expected exit |
|------|---------|---------------|
| `help-output.txt` | `buddy-patcher --help` | 0 |
| `error-no-args.txt` | `buddy-patcher --binary <test>` (no action flags) | 1 |
| `error-invalid-species.txt` | `buddy-patcher --species unicorn --binary <test>` | 1 |
| `error-invalid-rarity.txt` | `buddy-patcher --rarity mythic --binary <test>` | 1 |
| `error-invalid-emoji.txt` | `buddy-patcher --species duck --emoji "AB" --binary <test> --dry-run` | 1 |
| `dry-run-full.txt` | `buddy-patcher --species dragon --rarity legendary --shiny --emoji 🐲 --dry-run --binary <test>` | 0 |

## Normalization

Before comparing, volatile fields are replaced:

| Raw value | Placeholder |
|-----------|-------------|
| `v1.0.0` (version strings) | `<VERSION>` |
| Full path to test binary | `<TESTBIN>` |
| macOS temp dir paths (`/var/folders/...`, `/tmp/...`) | `<TMPDIR>` |
| File sizes (`71,120 bytes`) | `<SIZE> bytes` |
| Hex offsets (`0x1a2b3c`) | `<OFFSET>` |

## Regenerating golden files

Run with `UPDATE_GOLDEN=1` to overwrite all golden files with current output:

```bash
UPDATE_GOLDEN=1 bash scripts/test-snapshots.sh
# or:
UPDATE_GOLDEN=1 make test-snapshots
```

**Always review the diff before committing regenerated files.** A change
in golden output means the CLI contract drifted — which may be intentional
(new feature, improved error message) or a regression. Use `git diff` to
inspect what changed.

## No committed Mach-O binaries

Test binaries are generated at runtime by `scripts/build-test-binary.sh`
and are never committed. Only JSON and text files live here.
