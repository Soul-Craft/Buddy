---
name: update-species-map
description: This skill should be used when the user asks to "update species map", "update-species-map", "fix patching for new version", "binary changed", "new claude version broke patching", "update anchor patterns", or "patching stopped working after update".
disable-model-invocation: true
---

# Update Species Map — Adapt to New Binary

Investigate the current Claude Code binary to find anchor patterns and update the patching script if the binary structure has changed. Use this when `/test-patch` reports failures after a Claude Code update.

## Steps

### 1. Resolve binary and version

```bash
BINARY=$(readlink ~/.local/bin/claude 2>/dev/null || echo "NOT_FOUND")
echo "Binary: $BINARY"
echo "Version: $(basename "$BINARY")"
echo "Size: $(wc -c < "$BINARY" 2>/dev/null) bytes"
```

### 2. Run binary analysis

Use the built-in analyze mode to search for all anchor patterns, rarity weights, and shiny thresholds:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" --analyze
```

This outputs:
- Species anchor location and array content (or candidate variable refs if not found)
- Rarity weight string location (original or patched variant)
- Shiny threshold location

### 3. Report and recommend

Display a summary of what was found:

```
Binary Analysis Report
══════════════════════

Binary:  [path]
Version: [version]

  Species anchor (Trq)    ✅ Found  /  ❌ Changed
  Species array content   [show extracted array]
  Rarity weights          ✅ Found  /  ❌ Changed
  Shiny threshold         ✅ Found  /  ❌ Changed
```

If all patterns match, report that the script is compatible and no changes needed.

If patterns are missing, analyze the differences:

1. Read the current `knownVarMaps` from `${CLAUDE_PLUGIN_ROOT}/scripts/BuddyPatcher/Sources/BuddyPatcher/VariableMapDetection.swift`
2. Compare against what was found in the binary
3. Suggest specific code changes:
   - New variable names for `knownVarMaps`
   - Updated anchor patterns
   - Any changes to rarity or shiny patterns
4. Offer to apply the updates to the Swift source

### 4. Update the reference doc

If changes were needed and applied, also update `${CLAUDE_PLUGIN_ROOT}/skills/buddy-evolve/references/species-map.md` with the new variable mappings and binary version.
