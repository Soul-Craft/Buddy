---
name: buddy-evolve
description: This skill should be used when the user asks to "buddy evolve", "evolve buddy", "change my buddy", "customize buddy", "I want a different buddy", "change buddy species", or "make my buddy shiny".
argument-hint: "species name (optional)"
---

# Buddy Evolve — Transform Your Terminal Pet

Transform the user's Claude Code Buddy terminal pet through an interactive evolution experience.

## Act 1 — Discovery

Run pre-flight checks:

```bash
BINARY=$(readlink ~/.local/bin/claude 2>/dev/null || echo "NOT_FOUND")
echo "Binary: $BINARY"
file "$BINARY" 2>/dev/null
python3 -c "import json,os; c=json.load(open(os.path.expanduser('~/.claude.json'))); print(json.dumps(c.get('companion',{}), indent=2))" 2>/dev/null
```

Read the current buddy name and species from the output. Then display the discovery scene — the current buddy encountering a mysterious mushroom. Use the buddy's actual name:

```
Your buddy [NAME] waddles up curiously...

    .---.
    (°>°)       🍄 ?
   /(   )\
    `---´

[NAME] found a mysterious mushroom!
What will [NAME] evolve into?
```

## Act 2 — Choices

Gather all customization choices. Use AskUserQuestion for structured selections and direct conversation for freeform inputs.

### Step 1: Species
Use AskUserQuestion:
- header: "Species"
- question: "What species should your buddy evolve into?"
- options (pick 4 most popular, user can type Other for full list):
  - "dragon" with description "Fearsome fire-breather"
  - "cat" with description "Mysterious and independent"
  - "axolotl" with description "Adorable regenerating amphibian"
  - "capybara" with description "Chill vibes only"

If user picks Other, list all 18: duck, goose, blob, cat, dragon, octopus, owl, penguin, turtle, snail, axolotl, ghost, robot, mushroom, cactus, rabbit, chonk, capybara.

### Step 2: Rarity
Use AskUserQuestion:
- header: "Rarity"
- question: "What rarity tier?"
- options:
  - "legendary" with description "The rarest of the rare (Recommended)"
  - "epic" with description "Extremely rare"
  - "rare" with description "Uncommon but special"
  - "common" with description "Keep it humble"

### Step 3: Emoji
Ask in conversation (freeform): "What emoji should represent your buddy? (e.g., 🐲, 🦄, 👻, 🍄, 🔥)"

### Step 4: Name
Ask in conversation: "What should your evolved buddy be named?"

### Step 5: Personality
Ask in conversation: "Describe your buddy's personality in a sentence or two. This appears as the italic description on the buddy card."

### Step 6: Stats
Use AskUserQuestion:
- header: "Stats"
- question: "How should your buddy's stats be distributed?"
- options:
  - "All maxed (99)" with description "Every stat at maximum"
  - "Chaos gremlin" with description "99 CHAOS, everything else low"
  - "Zen master" with description "99 WISDOM and PATIENCE, moderate others"
  - "Custom" with description "Set each stat individually"

If Custom, ask for each stat (DEBUGGING, PATIENCE, CHAOS, WISDOM, SNARK) as a number 0-99.

## Act 3 — The Evolution

Display a confirmation summary table, then the evolution animation.

First show the summary:
```
Evolution Summary:
  Species:     [species] [emoji]
  Rarity:      [rarity]
  Shiny:       Yes ✨
  Name:        [name]
  Personality: [personality]
  Stats:       DEBUGGING:[n] PATIENCE:[n] CHAOS:[n] WISDOM:[n] SNARK:[n]
```

Then display the evolution:
```
[OLD_NAME] eats the mushroom... 🍄

    .---.
    (°>°)    ✨ ✨ ✨
   /(   )\   ✨ ✨
    `---´

Evolving...
```

Run the patching script:
```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/patch-buddy.py" \
  --species [species] \
  --rarity [rarity] \
  --shiny \
  --emoji "[emoji]" \
  --name "[name]" \
  --personality "[personality]"
```

Note: always pass --shiny since all evolved buddies are shiny by default.

## Act 4 — The Reveal

After the script succeeds, display the evolved buddy:

```
    ✨✨✨✨✨✨✨✨✨✨
    ✨                ✨
    ✨    [emoji]     ✨
    ✨                ✨
    ✨✨✨✨✨✨✨✨✨✨

[OLD_NAME] evolved into [NEW_NAME]!

★ LEGENDARY          [SPECIES]

  [NAME]
  "[personality]"

  DEBUGGING  ████████████  [n]
  PATIENCE   ████████████  [n]
  CHAOS      ████████████  [n]
  WISDOM     ████████████  [n]
  SNARK      ████████████  [n]
```

Then tell the user:
```
⚠️  Restart Claude Code to see your evolved buddy:
   exit
   claude
   Then run /buddy

To revert anytime: /buddy-reset
```

## Error Handling

If the script fails:
- Display the error output
- Suggest running /buddy-reset to revert
- Note that binary offsets are version-specific — if Claude Code just updated, run /test-patch to check compatibility
