---
name: buddy-status
description: This skill should be used when the user asks to "buddy status", "show buddy", "show my buddy", "my buddy", "buddy info", "buddy stats", "buddy card", "who is my buddy", "what is my buddy", or "check buddy".
---

# Buddy Status — View Your Terminal Pet

Display the user's current buddy as a visual status card. This is **read-only** — no files are modified, no scripts are run that change anything.

## Step 1: Read buddy data

Run this command to gather all buddy information:

```bash
python3 -c "
import json, os, time, datetime

soul = {}
try:
    with open(os.path.expanduser('~/.claude.json')) as f:
        soul = json.load(f).get('companion', {})
except Exception:
    pass

meta = {}
try:
    with open(os.path.expanduser('~/.claude/backups/buddy-patch-meta.json')) as f:
        meta = json.load(f)
except Exception:
    pass

hatched = soul.get('hatchedAt', 0)
if hatched:
    age_ms = time.time() * 1000 - hatched
    age_days = int(age_ms / 86400000)
    age_hours = int((age_ms % 86400000) / 3600000)
    hatched_date = datetime.datetime.fromtimestamp(hatched / 1000).strftime('%b %d, %Y')
else:
    age_days = 0
    age_hours = 0
    hatched_date = 'Unknown'

print(json.dumps({
    'soul': soul,
    'meta': meta,
    'age_days': age_days,
    'age_hours': age_hours,
    'hatched_date': hatched_date,
    'evolved': bool(meta)
}, indent=2))
"
```

## Step 2: Render the buddy card

Use the JSON output to render the appropriate card.

Read card templates from `${CLAUDE_PLUGIN_ROOT}/skills/buddy-status/references/card-templates.md` and use the matching variant below.

### If evolved (metadata exists)

Use the "Evolved Card" template from card-templates.md, substituting actual values.

**Rarity flair** — prefix the rarity name with:
- legendary → `★ LEGENDARY`
- epic → `◆ EPIC`
- rare → `● RARE`
- uncommon → `○ UNCOMMON`
- common → `· COMMON`

**Stat bars** — for each stat value `n` (0–99):
- Filled blocks: `floor(n / 10)` × `█`
- Empty blocks: `(10 - floor(n / 10))` × `░`
- Example: 85 → `████████░░`

**If stats is null or missing**, use the "No-Stats Variant" from card-templates.md to replace the stats section.

**Age display**:
- Less than 1 hour → "Just hatched!"
- Less than 1 day → "[hours] hours old"
- 1+ days → "[days] days old"

**Shiny display**: Only show `✨ SHINY` on the flair line if `shiny` is true.

**Name spacing**: Space out the name in caps for the header, e.g., "Smaug" → "S M A U G".

### If NOT evolved (no metadata)

Use the "Unevolved Card" template from card-templates.md.

### If no buddy at all (no ~/.claude.json or no companion key)

Use the "No Buddy" template from card-templates.md.
