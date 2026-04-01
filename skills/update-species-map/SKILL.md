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

### 2. Search for the species anchor pattern

The current anchor is `b0_,I0_,x0_,u0_,` — the first four species variable refs in the Trq array. Search the binary:

```bash
python3 -c "
data = open('$(readlink ~/.local/bin/claude)', 'rb').read()
anchor = b'b0_,I0_,x0_,u0_,'
idx = data.find(anchor)
if idx >= 0:
    print(f'  [+] Anchor found at offset 0x{idx:x}')
    # Extract surrounding context (the full species array)
    start = max(0, idx - 20)
    end = min(len(data), idx + 200)
    region = data[start:end]
    # Find the array bounds
    arr_start = region.rfind(b'[')
    arr_end = region.find(b']', idx - start)
    if arr_start >= 0 and arr_end >= 0:
        array_content = region[arr_start:arr_end+1].decode('ascii', errors='replace')
        print(f'  [+] Species array: {array_content}')
else:
    print('  [!] Anchor NOT FOUND — binary structure has changed')
    # Search for any 3-char comma pattern that looks like variable refs
    import re
    # Look for patterns like X0_,Y0_, which are the variable ref format
    matches = set(re.findall(rb'([A-Za-z][0-9]_)', data))
    candidates = sorted(m.decode() for m in matches)
    print(f'  [?] Found {len(candidates)} potential 3-byte variable refs:')
    for c in candidates[:30]:
        print(f'      {c}')
"
```

### 3. Search for rarity weight string

```bash
python3 -c "
data = open('$(readlink ~/.local/bin/claude)', 'rb').read()
# Try original weights
original = b'common:60,uncommon:25,rare:10,epic:4,legendary:1'
idx = data.find(original)
if idx >= 0:
    print(f'  [+] Original rarity weights found at 0x{idx:x}')
else:
    # Try patched variants
    import re
    pattern = rb'common:\d{2},uncommon:\d{2},rare:\d{2},epic:\d,legendary:\d'
    match = re.search(pattern, data)
    if match:
        print(f'  [+] Rarity weights (patched) found at 0x{match.start():x}: {match.group().decode()}')
    else:
        print('  [!] Rarity weights NOT FOUND')
"
```

### 4. Search for shiny threshold

```bash
python3 -c "
data = open('$(readlink ~/.local/bin/claude)', 'rb').read()
for pattern in [b'H()<0.01', b'H()<1.01']:
    idx = data.find(pattern)
    if idx >= 0:
        print(f'  [+] Shiny threshold found at 0x{idx:x}: {pattern.decode()}')
        break
else:
    print('  [!] Shiny threshold NOT FOUND')
"
```

### 5. Report and recommend

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

1. Read the current `SPECIES_VAR_MAP` from `${CLAUDE_PLUGIN_ROOT}/scripts/patch-buddy.py`
2. Compare against what was found in the binary
3. Suggest specific code changes:
   - New variable names for `SPECIES_VAR_MAP`
   - Updated `TRQ_ANCHOR` pattern
   - Any changes to rarity or shiny patterns
4. Offer to apply the updates to the script

### 6. Update the reference doc

If changes were needed and applied, also update `${CLAUDE_PLUGIN_ROOT}/skills/buddy/references/species-map.md` with the new variable mappings and binary version.
