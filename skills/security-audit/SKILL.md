---
name: security-audit
description: This skill should be used when the user asks to "security audit", "check security", "audit buddy", "check backup health", "verify backup", or "security check".
---

# Security Audit — Buddy Evolver Health Check

Run a security audit of the Buddy Evolver installation. Check backup health, file permissions, and metadata integrity.

## Step 1: Check backup files

```bash
SOUL_BACKUP="$HOME/.claude/backups/.claude.json.pre-customize"
META_FILE="$HOME/.claude/backups/buddy-patch-meta.json"

echo "=== Backup Files ==="
ls -la "$SOUL_BACKUP" 2>/dev/null || echo "Soul backup: NOT FOUND"
ls -la "$META_FILE" 2>/dev/null || echo "Metadata: NOT FOUND"
```

## Step 2: Check file permissions

```bash
echo "=== Permissions ==="
stat -f "%Sp %N" "$HOME/.claude/backups/" 2>/dev/null || echo "Backup dir: NOT FOUND"
stat -f "%Sp %N" "$SOUL_BACKUP" 2>/dev/null || echo "Soul backup: NOT FOUND"
stat -f "%Sp %N" "$META_FILE" 2>/dev/null || echo "Metadata: NOT FOUND"
```

Check that backup dir is `drwx------` (700) and files are `-rw-------` (600). Flag any world-readable files.

## Step 3: Read current companion data

```bash
plutil -extract companion json -o - ~/.claude.json 2>/dev/null || echo "No companion data found"
```

## Step 4: Validate metadata

```bash
if [ -f "$META_FILE" ]; then
  python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    meta = json.load(f)
print(f'  schema_version: {meta.get(\"schema_version\", \"MISSING\")}')
for key in ['species', 'rarity', 'shiny', 'emoji', 'name', 'personality', 'stats']:
    if key in meta:
        print(f'  {key}: {meta[key]}')
" "$META_FILE"
fi
```

## Step 5: Report scorecard

Display results as a security scorecard:

```
Security Audit Report
═════════════════════

  Soul backup exists            ✅ / ❌
  Metadata file exists          ✅ / ❌ / ⚠️ (not found)
  Backup dir permissions (700)  ✅ / ❌
  Backup file permissions (600) ✅ / ❌
  Companion data present        ✅ / ❌
  Metadata is valid JSON        ✅ / ❌
  Metadata schema_version == 2  ✅ / ❌

Overall: X/7 checks passed
```

If any checks failed, provide specific remediation advice:
- Missing soul backup: "Run /buddy-evolve to create a fresh evolution (backup is created automatically)"
- Bad permissions: "Run: chmod 700 ~/.claude/backups && chmod 600 ~/.claude/backups/*"
- Missing companion data: "Run /buddy-evolve to set name and personality"
- Old schema_version (not 2): "Run /buddy-evolve to upgrade to v2 metadata format"
