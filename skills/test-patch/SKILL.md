---
name: test-patch
description: This skill should be used when the user asks to "test patch", "test-patch", "verify patch", "check if patching works", "dry run buddy", "test buddy customizer", or "check binary compatibility".
disable-model-invocation: true
---

# Test Patch — Verify Binary Compatibility

Run the patching script in dry-run mode to verify all anchor patterns still match the current Claude Code binary. Use this after Claude Code updates to check if the customizer still works.

## Steps

### 1. Resolve binary

```bash
BINARY=$(readlink ~/.local/bin/claude 2>/dev/null || echo "NOT_FOUND")
echo "Binary: $BINARY"
echo "Version: $(basename "$BINARY")"
file "$BINARY" 2>/dev/null | head -1
```

If the binary is not found, tell the user Claude Code doesn't appear to be installed and exit.

### 2. Run dry-run with all patch types

Run the patching script with every patch type enabled to test all anchor patterns:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" \
  --dry-run \
  --species dragon \
  --rarity legendary \
  --shiny \
  --emoji "🐲" \
  --name "Test" \
  --personality "Test personality"
```

### 3. Analyze results

Read the output and check for:
- `[DRY RUN]` lines — these indicate patterns that WOULD be patched (good)
- `[!] WARNING` lines — these indicate patterns that were NOT FOUND (bad)

### 4. Report summary

Display a clear pass/fail report:

```
Patch Compatibility Report
══════════════════════════

Binary:  [path]
Version: [version]

  Species array (Trq anchor)   ✅ Found  /  ❌ Not found
  Rarity weights (LN6)         ✅ Found  /  ❌ Not found
  Shiny threshold              ✅ Found  /  ❌ Not found
  Art templates                ✅ Found  /  ❌ Not found
  Soul (claude.json)           ✅ Found  /  ❌ Not found

Result: ALL PASS ✅  /  [N] FAILED ❌
```

If any patterns failed:
- Suggest running `/update-species-map` to investigate binary changes
- Note that Claude Code may have been refactored and the script needs updating
- Remind the user their existing buddy still works — only re-customization is affected
