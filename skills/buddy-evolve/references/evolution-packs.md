# Evolution Packs — Data Reference

Used by the `/buddy evolve` flow in `SKILL.md`. Each pack is a complete buddy bundle: one pick, everything set.

All packs use **rarity: legendary** and **--shiny** by default.

## Pack Table

| Pack | Species | Emoji | Default Name | Personality | Stats Preset |
|------|---------|-------|--------------|-------------|--------------|
| 🐉 Golden Dragon | dragon | 🐉 | Aurelius | Rare, radiant, and worth their weight in gold | All maxed |
| 🌈 Rainbow Axolotl | axolotl | 🌈 | Sparkle | Happy, silly, and oh-so-sparkly | All maxed |
| 👻 Spooky Ghost | ghost | 👻 | Boo | Mysterious and a little mischievous | Chaos gremlin |
| 🦫 Chill Capybara | capybara | 🦫 | Mellow | Takes life one nap at a time | Zen master |
| 🐙 Smart Octopus | octopus | 🐙 | Tako | Eight arms, infinite ideas | All maxed |
| 🤖 Cool Robot | robot | 🤖 | Bleep | Calculating the snarkiest response... | All maxed |
| 🦉 Wise Owl | owl | 🦉 | Sage | Has read every book in the forest | Zen master |
| 🐱 Sneaky Cat | cat | 🐱 | Whiskers | Clever, curious, and always plotting | Chaos gremlin |

## Stat Presets

| Preset | debugging | patience | chaos | wisdom | snark |
|--------|-----------|----------|-------|--------|-------|
| All maxed | 99 | 99 | 99 | 99 | 99 |
| Chaos gremlin | 20 | 20 | 99 | 20 | 60 |
| Zen master | 40 | 99 | 10 | 99 | 20 |

## Stats JSON (for `--stats` flag)

```
All maxed:     {"debugging":99,"patience":99,"chaos":99,"wisdom":99,"snark":99}
Chaos gremlin: {"debugging":20,"patience":20,"chaos":99,"wisdom":20,"snark":60}
Zen master:    {"debugging":40,"patience":99,"chaos":10,"wisdom":99,"snark":20}
```

## Invocation Template

For each pack, the patching call looks like:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" \
  --species <species> \
  --rarity legendary \
  --shiny \
  --emoji "<emoji>" \
  --name "<name>" \
  --personality "<personality>" \
  --stats '<stats_json>'
```

## Surprise Me!

When the user picks "🎲 Surprise Me!", select a random pack from the 8 above and run with its full bundle.

## Build My Own

When the user picks "🎨 Build My Own", see the "Build My Own (Advanced)" section in `SKILL.md` for the 4-question expert flow. It uses the same species→default_name mapping as the packs above, plus these extras for species not in the pack roster:

| Species | Default Name |
|---------|--------------|
| duck | Ducky |
| goose | Honk |
| blob | Blobby |
| penguin | Tux |
| turtle | Shelly |
| snail | Slurp |
| mushroom | Shroomie |
| cactus | Spike |
| rabbit | Hop |
| chonk | Chonk |
