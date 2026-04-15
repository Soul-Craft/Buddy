# Buddy Card Templates

Box-drawing templates for the three card variants rendered by `/buddy-status`.
Substitute bracketed placeholders with actual values from the buddy JSON.

## Evolved Card (metadata exists)

```
╔══════════════════════════════════════════╗
║  [EMOJI]  [N A M E — spaced out caps]   ║
║  [RARITY_FLAIR] [✨ SHINY if shiny]     ║
╠══════════════════════════════════════════╣
║                                          ║
║  Species:      [species] [emoji]         ║
║  Personality:  "[personality]"           ║
║  Age:          [age display]             ║
║  Hatched:      [hatched_date]            ║
║  Evolution:    Evolved (v[version])      ║
║                                          ║
╠══════════════════════════════════════════╣
║  S T A T S                               ║
║                                          ║
║  DEBUGGING  [██████████]  [n]            ║
║  PATIENCE   [██████████]  [n]            ║
║  CHAOS      [██████████]  [n]            ║
║  WISDOM     [██████████]  [n]            ║
║  SNARK      [██████████]  [n]            ║
║                                          ║
╠══════════════════════════════════════════╣
║  /buddy-evolve   Re-evolve your buddy   ║
║  /buddy-reset    Restore original buddy ║
╚══════════════════════════════════════════╝
```

## No-Stats Variant (stats null or missing)

Replace the stats section with:

```
║  S T A T S                               ║
║                                          ║
║  No stats assigned yet.                  ║
║  Re-evolve with /buddy-evolve to set     ║
║  custom stats for your buddy.            ║
║                                          ║
```

## Unevolved Card (no metadata)

```
╔══════════════════════════════════════════╗
║  🐣  [N A M E — spaced out caps]        ║
║  Wild Buddy — Not yet evolved            ║
╠══════════════════════════════════════════╣
║                                          ║
║  Personality:  "[personality]"           ║
║  Age:          [age display]             ║
║  Hatched:      [hatched_date]            ║
║                                          ║
║  Your buddy hasn't evolved yet!          ║
║  Feed it a psychedelic mushroom 🍄       ║
║  to unlock species, stats, and more.     ║
║                                          ║
╠══════════════════════════════════════════╣
║  /buddy-evolve   Start evolution 🍄     ║
╚══════════════════════════════════════════╝
```

## No Buddy (no ~/.claude.json or no companion key)

```
No buddy found! Start Claude Code to hatch your companion,
then run /buddy-evolve to customize it.
```
