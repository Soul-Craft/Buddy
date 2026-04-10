---
name: run-all-tests
description: "Use when the user asks to 'run all tests', 'test everything', 'run the full pipeline', 'check all stages', or 'run test-all'. Runs scripts/test-all.sh and reports per-tier results with a summary table."
disable-model-invocation: true
---

# Run All Tests — Full Pipeline

Runs the complete Buddy Evolver test pipeline (all tiers in `test-all.sh`) and
reports per-tier results with pass/fail counts, durations, and failure details.

## Steps

### 1. Run test-all.sh

```bash
cd "${CLAUDE_PLUGIN_ROOT}" && bash scripts/test-all.sh 2>&1
```

### 2. Read results.json

```bash
cat "${CLAUDE_PLUGIN_ROOT}/test-results/results.json"
```

### 3. Display summary table

Format one row per tier from `results.json`. Use ✅ if `exit_code == 0`,
❌ otherwise. Group by `stage` field when present.

```
Test Pipeline Results
══════════════════════════════════════════════════════════
  TIER              STATUS    PASSED      DURATION
  ────────────────  ──────    ────────    ─────────
  smoke             ✅        13/13       8s
  unit              ✅        178/178     12s
  security          ✅        27/27       3s
  integration       ✅        23/23       6s
  functional        ✅        19/19       5s
  ui                ✅        23/23       2s
  e2e               ✅        23/23       2s
  snapshots         ✅        6/6         1s
  docs              ✅        16/16       1s
  ──────────────────────────────────────────────────────
  TOTAL             ✅        328/328     40s
```

### 4. On failure

If any tier has `exit_code != 0`, show which tier failed and suggest:

- **smoke failure** → build or CLI contract broken; check `swift build` output
- **unit failure** → run `/run-tests` to see per-suite breakdown with failure details
- **security failure** → `make test-security` — run standalone for focused output
- **snapshots failure** → if CLI output changed intentionally, run `UPDATE_GOLDEN=1 make test-snapshots` to regenerate golden files; review diffs before committing
- **docs failure** → run `/sync-docs` to fix documentation drift
- **compat failure** (on-demand) → run `/test-patch` to diagnose anchor pattern issues; run `/update-species-map` if variable names changed
