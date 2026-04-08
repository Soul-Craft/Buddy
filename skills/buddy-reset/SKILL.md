---
name: buddy-reset
description: This skill should be used when the user asks to "buddy reset", "reset buddy", "restore buddy", "revert buddy", "undo buddy changes", or "get my original buddy back".
---

# Buddy Reset — Restore Your Original Pet

Restore the user's original Claude Code Buddy by reverting all binary patches and companion data.

## Step 1: Check for backups

```bash
BINARY=$(readlink ~/.local/bin/claude 2>/dev/null || echo "NOT_FOUND")
BACKUP="${BINARY}.original-backup"
echo "Binary: $BINARY"
echo "Backup exists: $(test -f "$BACKUP" && echo 'yes' || echo 'no')"
echo "Soul backup exists: $(test -f ~/.claude/backups/.claude.json.pre-customize && echo 'yes' || echo 'no')"
```

If no backups exist, tell the user there is nothing to restore and exit.

## Step 2: Show current vs original

Read and display the current companion data from ~/.claude.json so the user knows what they are reverting from.

## Step 3: Confirm with user

Ask: "This will restore your original buddy and revert all customizations. Continue?"

## Step 4: Execute restore

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" --restore
```

## Step 5: Instruct user

Tell the user to restart Claude Code:
```
Your original buddy has been restored!

⚠️  Restart Claude Code to see your original buddy:
   pkill -f claude && claude
   Then run /buddy

To re-evolve anytime: /buddy-evolve
```
