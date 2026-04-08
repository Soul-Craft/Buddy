# 🍄 Buddy Evolver | Claude Code Plugin

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)
![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)

> Your buddy found a psychedelic mushroom. What happens next is entirely up to you.

Pick the species. Choose the rarity. Name it. Define its personality. Max out its stats. This isn't random evolution — **you design every detail**, then watch your buddy transform like a Pokemon eating a Super Mushroom.

18 species 🧬 | 5 rarity tiers ⭐ | custom emoji 🎨 | your name ✏️ | your personality 💬 | your stats 📊

### 🎬 Here's what it looks like

**You choose everything:**

```
🍄 What species should your buddy evolve into?
  > 🐲 dragon — Fearsome fire-breather
    🐱 cat — Mysterious and independent
    🦎 axolotl — Adorable regenerating amphibian
    🦫 capybara — Chill vibes only

⭐ What rarity tier?
  > ✨ legendary — The rarest of the rare

🎨 What emoji represents your buddy?
  > 🐲

✏️  What should your evolved buddy be named?
  > Aethos

💬 Describe your buddy's personality:
  > Ancient dragon who mass speaks in mass riddles

📊 How should stats be distributed?
  > All maxed (99) — Every stat at maximum
```

**Then the magic happens:**

```
    ✨✨✨✨✨✨✨✨✨✨
    ✨                ✨
    ✨       🐲       ✨
    ✨                ✨
    ✨✨✨✨✨✨✨✨✨✨

  Claude evolved into Aethos!

  ★ LEGENDARY            DRAGON

    Aethos
    "Ancient dragon who speaks in riddles"

    DEBUGGING  ████████████  99
    PATIENCE   ████████████  99
    CHAOS      ████████████  99
    WISDOM     ████████████  99
    SNARK      ████████████  99
```

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Install](#install)
- [Quick Start](#quick-start)
- [Commands](#commands)
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

<a id="prerequisites"></a>

## 📦 Prerequisites

Before installing, make sure you have:

- 🍎 **macOS** — required (uses `codesign` for binary re-signing)
- 🛠️ **Xcode Command Line Tools** — provides Swift compiler and codesign; install with `xcode-select --install`
- 🤖 **Claude Code** — CLI version with the Buddy feature

---

<a id="install"></a>

## 🔧 Install

Run these commands **inside Claude Code** (not your regular terminal):

```
/plugin marketplace add Soul-Craft/buddy-evolver
/plugin install buddy-evolver@soul-craft
```

Then restart Claude Code to activate the plugin.

This adds four slash commands: `/buddy-evolve`, `/buddy-reset`, `/test-patch`, and `/update-species-map`.

---

<a id="quick-start"></a>

## 🎮 Quick Start

**Press START on your evolution adventure:**

1. 🍄 Run `/buddy-evolve`
2. 🎨 Design your buddy — pick species, rarity, emoji, name, personality, and stats
3. ✨ Restart Claude Code — your new companion appears

The whole process takes about 60 seconds. Every choice is yours.

To revert anytime: `/buddy-reset` 🔄

---

<a id="commands"></a>

## 🕹️ Commands

### `/buddy-evolve`

Your buddy's evolution unfolds in four acts — like a classic RPG cutscene:

**🍄 Act 1 — Discovery.** Your current buddy stumbles upon a mysterious psychedelic mushroom, displayed with species-accurate ASCII art.

**🎨 Act 2 — Design.** Six customization steps where you control everything:
1. **🧬 Species** — Pick from 18 species (dragon, cat, axolotl, capybara, and 14 more)
2. **⭐ Rarity** — Choose a tier from legendary to common
3. **🎭 Emoji** — Any emoji to represent your buddy in the terminal
4. **✏️ Name** — Give your evolved buddy a name
5. **💬 Personality** — A sentence or two shown on the buddy card
6. **📊 Stats** — Max all, pick a preset (Chaos Gremlin, Zen Master), or set each individually

**✨ Act 3 — Evolution.** Confirmation summary, then sparkles fly as the binary is patched. Level-up complete.

**🎉 Act 4 — Reveal.** Your evolved buddy card appears with stats, personality, and rarity badge. Like opening a legendary pack.

All evolved buddies are ✨ shiny by default. A backup of the original binary is created automatically — your save file is always safe.

### `/buddy-reset`

🔄 Restores your original buddy by reverting all patches.

- Restores both the binary and `~/.claude.json`
- Safe to run anytime — does nothing if no backup exists
- Requires a restart after reset

### `/test-patch`

🧪 Dry-run validation of binary compatibility. Run this after Claude Code updates to check if the patching anchors still match.

Reports pass/fail for each patch type:
- 🧬 Species array
- ⭐ Rarity weights
- ✨ Shiny threshold
- 🎭 Art templates
- 💬 Soul (companion data)

If any fail, the plugin suggests running `/update-species-map`.

### `/update-species-map`

🔬 **Advanced.** Investigates the binary when anchor patterns break after a major Claude Code update. Searches for updated variable names and proposes code updates.

Most players will never need this — it's for when `/test-patch` reports failures.

---

<a id="species"></a>

## 🧬 Species

Choose from 18 species during evolution:

| | | | |
|---|---|---|---|
| 🦆 duck | 🪿 goose | 🫠 blob | 🐱 cat |
| 🐲 dragon | 🐙 octopus | 🦉 owl | 🐧 penguin |
| 🐢 turtle | 🐌 snail | 🦎 axolotl | 👻 ghost |
| 🤖 robot | 🍄 mushroom | 🌵 cactus | 🐇 rabbit |
| 🐖 chonk | 🦫 capybara | | |

---

<a id="rarity-tiers"></a>

## ⭐ Rarity Tiers

Rarity determines how often your buddy reacts to your work — like a companion's chattiness slider:

| Tier | Reaction Rate | Vibe |
|------|:---:|---|
| **✨ Legendary** | 50% | Main character energy — reacts to everything |
| **💎 Epic** | 35% | Hype beast — always in the mix |
| **🔮 Rare** | 25% | Solid sidekick energy |
| **🌿 Uncommon** | 15% | Occasional words of wisdom |
| **🪨 Common** | 5% | The strong, silent type |

---

<a id="stats"></a>

## 📊 Stats

Five RPG stats, each ranging 0–99. Choose a preset during evolution or min-max to your heart's content:

| Stat | What It Does |
|------|-------------|
| **🐛 DEBUGGING** | How tenaciously your buddy hunts bugs |
| **⏳ PATIENCE** | Tolerance for long builds and slow tests |
| **🌀 CHAOS** | Tendency toward creative mischief |
| **🧠 WISDOM** | Depth of sage advice offered |
| **😏 SNARK** | Sharpness of witty commentary |

**Presets:**
- 💪 **All Maxed** — 99 across the board, the power fantasy
- 🌀 **Chaos Gremlin** — 99 CHAOS, low everything else
- 🧘 **Zen Master** — 99 WISDOM and PATIENCE, inner peace
- 🎛️ **Custom** — Set each stat yourself, RPG style

---

<a id="how-it-works"></a>

## 🔬 How It Works

The plugin patches the Claude Code binary (a Bun-compiled Mach-O executable) to swap your buddy's species, rarity, shiny status, and ASCII art. Name and personality are written to `~/.claude.json` separately.

The important bits:

- 📏 All patches maintain **exact byte length** — like fitting new sprites into the same cartridge
- 🔍 Patterns are located by anchor searching, not hardcoded offsets
- 🧬 **Multi-version support** — the script stores multiple known variable maps and auto-detects which one matches the current binary at runtime. No manual updates needed when switching between supported versions.
- 💾 The original binary is **backed up automatically** before any changes — your save file is safe
- 🔏 After patching, the binary is re-signed with `codesign`
- ✅ Post-patch **binary verification** — runs `--version` after patching; auto-restores from backup if the binary is corrupted
- 🔄 Everything is fully reversible with `/buddy-reset`

---

<a id="after-claude-code-updates"></a>

## 🔄 After Claude Code Updates

Claude Code auto-updates replace the patched binary, which reverts your buddy to default. Don't panic — your buddy remembers who they are.

**To re-evolve:**

```
/buddy-evolve
```

Your preferences are saved, so re-application is quick — just confirm your choices and go. Like re-equipping your gear after a save reload. ⚔️

The patching script auto-detects which binary version you're running and uses the matching variable map — no manual intervention needed for supported versions.

**If patching fails after an update:**

1. 🧪 Run `/test-patch` to check which anchors broke
2. 🔬 If failures found, run `/update-species-map` or [file an issue](https://github.com/Soul-Craft/buddy-evolver/issues)
3. 💾 Your backup is safe and unaffected by updates

---

<a id="troubleshooting"></a>

## 🩹 Troubleshooting

<details>
<summary>🔄 <b>My buddy didn't change after evolving</b></summary>

You need to restart Claude Code after evolution — like rebooting after installing a mod:

```bash
pkill -f claude && claude
```

</details>

<details>
<summary>🔏 <b>codesign failed</b></summary>

Make sure you're on macOS. Verify the binary path resolves:

```bash
readlink ~/.local/bin/claude
```

If the path is broken, Claude Code may need to be reinstalled.

</details>

<details>
<summary>⚠️ <b>Pattern not found / anchor warnings</b></summary>

Claude Code updated and the binary structure changed. Run `/test-patch` to check compatibility, then `/update-species-map` if needed.

Your existing buddy still works — only re-customization is affected until patterns are updated.

</details>

<details>
<summary>🔁 <b>I want to change my buddy again</b></summary>

Just run `/buddy-evolve` again! No need to reset first — the script is re-runnable. Redesign as many times as you want.

</details>

<details>
<summary>🐧 <b>Can I use this on Linux or Windows?</b></summary>

Not currently. The plugin requires macOS `codesign` for binary re-signing after patching.

</details>

<details>
<summary>🛡️ <b>Is this safe? Can it break Claude Code?</b></summary>

The original binary is always backed up before changes — like a save state before the boss fight. Run `/buddy reset` to restore it at any time. In the worst case, reinstalling Claude Code gives you a fresh binary.

</details>

---

<a id="uninstall"></a>

## 🗑️ Uninstall

If you've customized your buddy, reset first:

```
/buddy-reset
```

Then remove the plugin (inside Claude Code):

```
/plugin uninstall buddy-evolver@soul-craft
```

If you skip the reset, your customized buddy remains until the next Claude Code auto-update replaces the binary.

---

<a id="contributing"></a>

## 🤝 Contributing

Issues and PRs welcome at [github.com/Soul-Craft/buddy-evolver](https://github.com/Soul-Craft/buddy-evolver).

If you modify the Swift source in `scripts/BuddyPatcher/`, every binary patch **must** produce output identical in byte length to the original — like fitting new sprites into the same ROM. Test with `--dry-run` before committing.

---

<a id="license"></a>

## 📄 License

[MIT](LICENSE)
