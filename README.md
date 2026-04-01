# Buddy Customizer

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)
![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)

> Evolve your Claude Code Buddy terminal pet — feed it a psychedelic mushroom and watch it transform into your dream companion.

18 species | 5 rarity tiers | custom emoji, name, personality & stats

```
  Your buddy Claude waddles up curiously...

      .---.
      (o>o)       ? ?
     /(   )\
      `---'

  Claude eats the mushroom...

      * * * * * * * * * *
      *                 *
      *       >>        *
      *                 *
      * * * * * * * * * *

  Claude evolved into Aethos the Dragon!
```

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Install](#install)
- [Quick Start](#quick-start)
- [Commands](#commands)
  - [/buddy evolve](#buddy-evolve)
  - [/buddy reset](#buddy-reset)
  - [/test-patch](#test-patch)
  - [/update-species-map](#update-species-map)
- [Species](#species)
- [Rarity Tiers](#rarity-tiers)
- [Stats](#stats)
- [How It Works](#how-it-works)
- [After Claude Code Updates](#after-claude-code-updates)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Contributing](#contributing)
- [License](#license)

---

## Prerequisites

Before installing, make sure you have:

- **macOS** — required (uses `codesign` for binary re-signing)
- **Python 3** — ships with macOS; verify with `python3 --version`
- **Claude Code** — CLI version with the Buddy feature

---

## Install

```bash
claude plugin add github:Soul-Craft/Buddy
```

Then restart Claude Code:

```bash
pkill -f claude && claude
```

This adds three slash commands: `/buddy`, `/test-patch`, and `/update-species-map`.

---

## Quick Start

1. Run `/buddy evolve`
2. Follow the prompts — pick species, rarity, emoji, name, personality, and stats
3. Restart Claude Code — your new buddy appears

The whole process takes about 60 seconds. To revert anytime: `/buddy reset`

---

## Commands

### `/buddy evolve`

Interactive evolution experience in four acts:

**Act 1 — Discovery.** Your current buddy encounters a mysterious mushroom.

**Act 2 — Choices.** Six customization steps:
1. **Species** — Pick from 18 species (dragon, cat, axolotl, capybara, and more)
2. **Rarity** — Choose a tier from legendary to common
3. **Emoji** — Any emoji to represent your buddy in the terminal
4. **Name** — Give your evolved buddy a name
5. **Personality** — A sentence or two shown on the buddy card
6. **Stats** — Max all, pick a preset (Chaos Gremlin, Zen Master), or set each individually

**Act 3 — Evolution.** Confirmation summary and sparkle animation while the binary is patched.

**Act 4 — Reveal.** Your evolved buddy card with stats, personality, and rarity badge.

All evolved buddies are shiny by default. A backup of the original binary is created automatically before any changes.

### `/buddy reset`

Restores your original buddy by reverting all binary patches and companion data.

- Restores both the binary and `~/.claude.json`
- Safe to run anytime — does nothing if no backup exists
- Requires a restart after reset

### `/test-patch`

Dry-run validation of binary compatibility. Run this after Claude Code updates to check if the patching anchors still match.

Reports pass/fail for each patch type:
- Species array
- Rarity weights
- Shiny threshold
- Art templates
- Soul (companion data)

If any fail, the plugin suggests running `/update-species-map`.

### `/update-species-map`

**Advanced.** Investigates the binary when anchor patterns break after a major Claude Code update. Searches for updated variable names and proposes code updates.

Most users will never need this — it's for when `/test-patch` reports failures.

---

## Species

Choose from 18 species during evolution:

| | | | |
|---|---|---|---|
| duck | goose | blob | cat |
| dragon | octopus | owl | penguin |
| turtle | snail | axolotl | ghost |
| robot | mushroom | cactus | rabbit |
| chonk | capybara | | |

---

## Rarity Tiers

Rarity determines how often your buddy reacts to your work:

| Tier | Reaction Rate | Vibe |
|------|:---:|---|
| **Legendary** | 50% | Reacts to half of everything |
| **Epic** | 35% | Frequent companion chatter |
| **Rare** | 25% | Regular reactions |
| **Uncommon** | 15% | Occasional commentary |
| **Common** | 5% | The strong, silent type |

---

## Stats

Five stats, each ranging 0–99. Choose a preset during evolution or set each one manually:

| Stat | Flavor |
|------|--------|
| **DEBUGGING** | How tenaciously your buddy hunts bugs |
| **PATIENCE** | Tolerance for long builds and slow tests |
| **CHAOS** | Tendency toward creative mischief |
| **WISDOM** | Depth of sage advice offered |
| **SNARK** | Sharpness of witty commentary |

**Presets:** All Maxed (99 across the board), Chaos Gremlin (99 CHAOS, low everything else), Zen Master (99 WISDOM and PATIENCE), or fully Custom.

---

## How It Works

The plugin patches the Claude Code binary (a Bun-compiled Mach-O executable) to swap your buddy's species, rarity, shiny status, and ASCII art. Name and personality are written to `~/.claude.json` separately.

Key points:

- All patches maintain **exact byte length** to preserve binary integrity
- Patterns are located by searching for known anchors, not hardcoded offsets
- The original binary is **backed up automatically** before any changes
- After patching, the binary is re-signed with `codesign`
- Everything is fully reversible with `/buddy reset`

---

## After Claude Code Updates

Claude Code auto-updates replace the patched binary, which reverts your buddy to default. This is expected.

**To re-apply your customization:**

```
/buddy evolve
```

Your preferences are saved, so re-application is quick — just confirm your choices and go.

**If patching fails after an update:**

1. Run `/test-patch` to check which anchors broke
2. If failures found, run `/update-species-map` or [file an issue](https://github.com/Soul-Craft/Buddy/issues)
3. Your backup is safe and unaffected by updates

---

## Troubleshooting

<details>
<summary><b>My buddy didn't change after evolving</b></summary>

You need to restart Claude Code after evolution. Run:

```bash
pkill -f claude && claude
```

</details>

<details>
<summary><b>codesign failed</b></summary>

Make sure you're on macOS. Verify the binary path resolves:

```bash
readlink ~/.local/bin/claude
```

If the path is broken, Claude Code may need to be reinstalled.

</details>

<details>
<summary><b>Pattern not found / anchor warnings</b></summary>

Claude Code updated and the binary structure changed. Run `/test-patch` to check compatibility, then `/update-species-map` if needed.

Your existing buddy still works — only re-customization is affected until patterns are updated.

</details>

<details>
<summary><b>I want to change my buddy again</b></summary>

Just run `/buddy evolve` again. No need to reset first — the script is re-runnable.

</details>

<details>
<summary><b>Can I use this on Linux or Windows?</b></summary>

Not currently. The plugin requires macOS `codesign` for binary re-signing after patching.

</details>

<details>
<summary><b>Is this safe? Can it break Claude Code?</b></summary>

The original binary is always backed up before changes. Run `/buddy reset` to restore it at any time. In the worst case, reinstalling Claude Code gives you a fresh binary.

</details>

---

## Uninstall

If you've customized your buddy, reset first:

```
/buddy reset
```

Then remove the plugin:

```bash
claude plugin remove buddy-customizer
```

If you skip the reset, your customized buddy remains until the next Claude Code auto-update replaces the binary.

---

## Contributing

Issues and PRs welcome at [github.com/Soul-Craft/Buddy](https://github.com/Soul-Craft/Buddy).

If you modify `scripts/patch-buddy.py`, every binary patch **must** produce output identical in byte length to the original. Test with `--dry-run` before committing.

---

## License

[MIT](LICENSE)
