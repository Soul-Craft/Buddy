# 🍄 Buddy Customizer

> Evolve your Claude Code Buddy terminal pet — feed it a psychedelic mushroom and watch it transform into your dream companion.

Choose any species, rarity, custom emoji, name, personality, and stats.

## Install

```
claude plugin add github:Soul-Craft/Buddy
```

Restart Claude Code after installing.

## Quick Start

```
/customize-buddy
```

An interactive evolution ceremony walks you through every choice:

1. 🍄 Your buddy discovers a mysterious mushroom
2. 🎭 Pick species, rarity, emoji, name, personality, and stats
3. ✨ Watch the evolution animation
4. 🔄 Restart Claude Code — run `/buddy` to meet your new companion

To revert anytime:
```
/restore-buddy
```

## Species

| | | | |
|---|---|---|---|
| 🦆 duck | 🪿 goose | 🫠 blob | 🐱 cat |
| 🐲 dragon | 🐙 octopus | 🦉 owl | 🐧 penguin |
| 🐢 turtle | 🐌 snail | 🦎 axolotl | 👻 ghost |
| 🤖 robot | 🍄 mushroom | 🌵 cactus | 🐇 rabbit |
| 🐖 chonk | 🦫 capybara | | |

## Rarity Tiers

| Tier | Reaction Rate | Vibe |
|------|:---:|---|
| **Legendary** | 50% | Reacts to half of everything |
| **Epic** | 35% | Frequent companion chatter |
| **Rare** | 25% | Regular reactions |
| **Uncommon** | 15% | Occasional commentary |
| **Common** | 5% | The strong, silent type |

## How It Works

The plugin patches the Claude Code Mach-O binary to swap your buddy's species, rarity weights, shiny threshold, and ASCII art. It also writes your buddy's name and personality to `~/.claude.json`.

All patches maintain exact byte length to preserve binary integrity. The original binary is backed up automatically before any changes and can be fully restored with `/restore-buddy`.

**Important**: Claude Code auto-updates replace the patched binary. Run `/customize-buddy` again after updates — your preferences are saved and can be re-applied instantly.

## Requirements

- **macOS** (uses `codesign` for binary re-signing)
- **Python 3** (ships with macOS)
- **Claude Code** (CLI version with Buddy feature)

## Uninstall

```
claude plugin remove buddy-customizer
```

## License

[MIT](LICENSE)
