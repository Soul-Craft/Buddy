---
name: buddy-e2e-test
description: "Use when the user asks to 'run E2E test', 'run end-to-end test', 'test the buddy flow end to end', 'E2E buddy', or 'verify buddy evolver works'. Runs the full reset→evolve→verify→reset flow against the real Claude Code binary and reports UI card verification results as a pass/fail table."
disable-model-invocation: true
---

# Buddy Evolver — End-to-End Test

Runs the full Buddy Evolver flow end-to-end against the real Claude Code
binary: reset → evolve to Aethos (legendary shiny dragon, full stats) →
verify UI card → reset → verify cleanup. Reports a pass/fail table.

**Safety:** This skill patches the real binary, then restores it. The
running Claude Code session is unaffected because the binary is loaded
into memory at startup. `ensureBackup()` in the Swift patcher auto-
restores on codesign failure, and this skill adds a bash `trap` to
restore on any mid-flow failure.

## Step 1: Pre-flight checks

```bash
cd "${CLAUDE_PLUGIN_ROOT}"
BINARY="$(readlink ~/.local/bin/claude 2>/dev/null)"
test -f "$BINARY" || { echo "ABORT: binary not found at $BINARY"; exit 1; }
./scripts/run-buddy-patcher.sh --help > /dev/null || { echo "ABORT: patcher build failed"; exit 1; }
echo "  binary: $BINARY"
test -f "${BINARY}.original-backup" && echo "  backup: present" || echo "  backup: will be created on first patch"
```

Arm a safety `trap` so any mid-flow failure triggers an automatic restore:

```bash
trap '"${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" --restore 2>&1 | tail -5' EXIT
```

## Step 2: Phase 1 — initial reset

```bash
./scripts/run-buddy-patcher.sh --restore
test ! -f ~/.claude/backups/buddy-patch-meta.json && echo "  clean ✅" || echo "  clean ❌"
```

Either a successful restore or a "nothing to restore" no-op is acceptable — both leave the state clean.

## Step 3: Phase 2 — evolve to Aethos

```bash
./scripts/run-buddy-patcher.sh \
  --species dragon --rarity legendary --shiny \
  --emoji "🐉" --name "Aethos" \
  --personality "An ancient golden dragon, wise and patient, who watches over the terminal with quiet amusement." \
  --stats '{"debugging":100,"patience":100,"chaos":100,"wisdom":100,"snark":100}'
```

If the patcher reports `WARNING: Could not find ... anchor` the binary
patch patterns are stale for the current Claude Code version. The soul
and metadata will still be written (so the UI test will pass), but the
real binary isn't actually patched. In that case, suggest running
`/update-species-map` to refresh `knownVarMaps` entries.

## Step 4: Verify evolved state (programmatic assertions)

```bash
python3 scripts/test-ui-renderer.py --json | jq -e '
  .evolved == true and
  .meta.species == "dragon" and
  .meta.rarity == "legendary" and
  .meta.shiny == true and
  .meta.emoji == "🐉" and
  .meta.name == "Aethos" and
  .meta.stats.debugging == 100 and
  .meta.stats.patience == 100 and
  .meta.stats.chaos == 100 and
  .meta.stats.wisdom == 100 and
  .meta.stats.snark == 100 and
  .soul.name == "Aethos"
' && echo "  assertions ✅ (12 fields)" || echo "  assertions ❌"
```

## Step 5: Verify evolved state (UI render — the "UI test")

```bash
python3 scripts/test-ui-renderer.py
```

Display the rendered card to the user. Verify it contains:
- `★ LEGENDARY ✨ SHINY` rarity flair
- `A E T H O S` (spaced letter rendering)
- `🐉` dragon emoji
- `dragon` species line
- All 5 stat bars showing `100`
- Footer with `/buddy-evolve` and `/buddy-reset` hints

## Step 6: Phase 3 — second reset and cleanup verification

```bash
./scripts/run-buddy-patcher.sh --restore
test ! -f ~/.claude/backups/buddy-patch-meta.json && echo "  cleanup ✅" || echo "  cleanup ❌"
python3 scripts/test-ui-renderer.py
```

Verify the rendered card shows "Wild Buddy — Not yet evolved" or "No buddy found", NOT the Aethos evolved card.

Clear the safety trap now that restoration is confirmed successful:

```bash
trap - EXIT
```

## Step 7: Report results table

Emit a markdown table with one row per phase:

| Phase | Step | Result |
|---|---|---|
| Sanity | binary + backup + build | ✅ / ❌ |
| Reset 1 | initial reset + clean verified | ✅ / ❌ |
| Evolve | patch + 12-field JSON assertions | ✅ / ❌ |
| UI | card renders LEGENDARY/dragon/Aethos/stats | ✅ / ❌ |
| Reset 2 | restore + cleanup verified | ✅ / ❌ |

If any phase failed:
- Note which step and include the error output
- Suggest `/security-audit` for backup/codesign diagnostics
- Suggest `/test-patch` for anchor pattern diagnostics
- Suggest `/update-species-map` if the evolve step showed `WARNING: Could not find ... anchor`
