---
name: buddy-reset
description: This skill should be used when the user asks to "buddy reset", "reset buddy", "restore buddy", "revert buddy", "undo buddy changes", or "get my original buddy back".
---

# Buddy Reset — Restore Your Original Pet

Restore the user's original Claude Code Buddy by reverting companion data to the pre-evolution state.

## Step 1: Check for soul backup

```bash
echo "Soul backup exists: $(test -f ~/.claude/backups/.claude.json.pre-customize && echo 'yes' || echo 'no')"
echo "Metadata exists: $(test -f ~/.claude/backups/buddy-patch-meta.json && echo 'yes' || echo 'no')"
```

If the soul backup does not exist, tell the user there is nothing to restore and exit.

## Step 2: Show current companion data

```bash
plutil -extract companion json -o - ~/.claude.json 2>/dev/null || echo "{}"
```

Display the current name and personality so the user knows what they are reverting from.

## Step 3: Confirm with user

Ask: "This will restore your original companion data and remove the buddy card. Continue?"

## Step 4: Execute restore

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" --restore
```

## Step 5: Inform user

Tell the user:
```
Your original buddy has been restored.
Changes take effect on your next Claude Code conversation — no restart needed.
Run /buddy-status to confirm the card is cleared.
To re-evolve at any time, run /buddy-evolve.
```
