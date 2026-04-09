---
name: security-audit
description: This skill should be used when the user asks to "security audit", "check security", "verify buddy integrity", "audit buddy", "check binary integrity", "verify backup", or "security check".
---

# Security Audit — Buddy Evolver Health Check

Run a comprehensive security audit of the Buddy Evolver installation. Check binary integrity, backup health, codesign status, file permissions, and pattern compatibility.

## Step 1: Resolve binary

```bash
BINARY=$(readlink ~/.local/bin/claude 2>/dev/null || echo "NOT_FOUND")
echo "Binary: $BINARY"
echo "Version: $(basename "$BINARY")"
```

If binary not found, report and skip binary-specific checks.

## Step 2: Check backup integrity

```bash
BACKUP="${BINARY}.original-backup"
HASH_FILE="$HOME/.claude/backups/binary-sha256.txt"
META_FILE="$HOME/.claude/backups/buddy-patch-meta.json"
SOUL_BACKUP="$HOME/.claude/backups/.claude.json.pre-customize"

echo "=== Backup Files ==="
ls -la "$BACKUP" 2>/dev/null || echo "Binary backup: NOT FOUND"
ls -la "$SOUL_BACKUP" 2>/dev/null || echo "Soul backup: NOT FOUND"
ls -la "$HASH_FILE" 2>/dev/null || echo "Hash file: NOT FOUND"
ls -la "$META_FILE" 2>/dev/null || echo "Metadata: NOT FOUND"
```

## Step 3: Verify SHA-256 integrity

```bash
if [ -f "$HASH_FILE" ] && [ -f "$BACKUP" ]; then
  STORED_HASH=$(cat "$HASH_FILE")
  ACTUAL_HASH=$(shasum -a 256 "$BACKUP" | awk '{print $1}')
  echo "Stored:  $STORED_HASH"
  echo "Actual:  $ACTUAL_HASH"
  if [ "$STORED_HASH" = "$ACTUAL_HASH" ]; then
    echo "Result:  MATCH"
  else
    echo "Result:  MISMATCH — backup may be corrupted!"
  fi
else
  echo "Cannot verify — hash file or backup missing"
fi
```

## Step 4: Check codesign status

```bash
codesign -v "$BINARY" 2>&1 && echo "Codesign: VALID" || echo "Codesign: INVALID or missing"
```

## Step 5: Detect patched state

```bash
if [ -f "$BACKUP" ]; then
  BINARY_HASH=$(shasum -a 256 "$BINARY" | awk '{print $1}')
  BACKUP_HASH=$(shasum -a 256 "$BACKUP" | awk '{print $1}')
  if [ "$BINARY_HASH" = "$BACKUP_HASH" ]; then
    echo "State: ORIGINAL (binary matches backup)"
  else
    echo "State: PATCHED (binary differs from backup)"
  fi
fi
```

## Step 6: Check file permissions

```bash
echo "=== Permissions ==="
stat -f "%Sp %N" "$HOME/.claude/backups/" 2>/dev/null || echo "Backup dir: NOT FOUND"
stat -f "%Sp %N" "$BACKUP" 2>/dev/null || echo "Binary backup: NOT FOUND"
stat -f "%Sp %N" "$SOUL_BACKUP" 2>/dev/null || echo "Soul backup: NOT FOUND"
stat -f "%Sp %N" "$META_FILE" 2>/dev/null || echo "Metadata: NOT FOUND"
stat -f "%Sp %N" "$HASH_FILE" 2>/dev/null || echo "Hash file: NOT FOUND"
```

Check that backup dir is `drwx------` (700) and files are `-rw-------` (600). Flag any world-readable files.

## Step 7: Validate metadata

```bash
if [ -f "$META_FILE" ]; then
  python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    meta = json.load(f)
required = ['version', 'binary_path']
for key in required:
    status = 'present' if key in meta else 'MISSING'
    print(f'  {key}: {status}')
optional = ['species', 'rarity', 'shiny', 'emoji', 'name', 'personality', 'stats', 'binary_sha256']
for key in optional:
    if key in meta:
        print(f'  {key}: {meta[key]}')
" "$META_FILE"
fi
```

## Step 8: Dry-run compatibility check

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" \
  --dry-run \
  --species dragon \
  --rarity legendary \
  --shiny \
  --emoji "🐲" \
  --name "AuditTest" \
  --personality "Security audit test run"
```

## Step 9: Report scorecard

Display results as a security scorecard:

```
Security Audit Report
═════════════════════

Binary:      [path]
Version:     [version]
State:       Original / Patched

  Binary backup exists          ✅ / ❌
  Soul backup exists            ✅ / ❌
  SHA-256 integrity verified    ✅ / ❌ / ⚠️ (no hash file)
  Codesign valid                ✅ / ❌
  Backup dir permissions (700)  ✅ / ❌
  Backup file permissions (600) ✅ / ❌
  Metadata valid JSON           ✅ / ❌ / ⚠️ (not found)
  Metadata has SHA-256 field    ✅ / ❌
  Dry-run compatibility         ✅ / ❌

Overall: X/9 checks passed
```

If any checks failed, provide specific remediation advice:
- Missing backup: "Run /buddy-reset to restore, then /buddy-evolve to re-create backup"
- Bad permissions: "Run: chmod 700 ~/.claude/backups && chmod 600 ~/.claude/backups/*"
- SHA-256 mismatch: "Backup may be corrupted. Reinstall Claude Code and re-run /buddy-evolve"
- Codesign invalid: "Run: codesign --force --sign - [binary path]"
