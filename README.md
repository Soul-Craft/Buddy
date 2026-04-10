# 🍄 Buddy Evolver | Claude Code Plugin

[![CI](https://github.com/Soul-Craft/buddy-evolver/actions/workflows/ci.yml/badge.svg)](https://github.com/Soul-Craft/buddy-evolver/actions/workflows/ci.yml)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)
![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)

> Your buddy found a psychedelic mushroom 🍄 What happens next is entirely up to you ✨

Pick the species. Choose the rarity. Name it. Define its personality. Max out its stats. This isn't random evolution — **you design every detail**, then watch your buddy transform as if it was a Pokemon eating a psychdelic Super Mario mushroom 🍄

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

**Use It**

- [Prerequisites](#-prerequisites)
- [Install](#-install)
- [Quick Start](#-quick-start)
- [Commands](#commands)
- [Species](#-species)
- [Rarity Tiers](#-rarity-tiers)
- [Stats](#-stats)
- [How It Works](#-how-it-works)
- [After Claude Code Updates](#-after-claude-code-updates)
- [Troubleshooting](#-troubleshooting)
- [Uninstall](#uninstall)

**Build It**

- [Architecture](#architecture)
- [Security Model](#security-model)
- [Development Setup](#-development-setup)
- [Testing](#-testing)
- [Contributing](#-contributing)
- [Acknowledgments](#-acknowledgments)
- [License](#-license)

---

## 📦 Prerequisites

Before installing, make sure you have:

- 🍎 **macOS** — required (uses `codesign` for binary re-signing)
- 🛠️ **Xcode Command Line Tools** — provides Swift compiler and codesign; install with `xcode-select --install`
- 🤖 **Claude Code** — CLI version with the Buddy feature

---

## 🔧 Install

Run these commands **inside Claude Code** (not your regular terminal):

```
/plugin marketplace add Soul-Craft/buddy-evolver
```

Then

```
/plugin install buddy-evolver@soul-craft
```

Then restart Claude Code to activate the plugin.

This adds slash commands including `/buddy-evolve`, `/buddy-reset`, `/buddy-status`, `/test-patch`, `/security-audit`, and `/update-species-map`.

---

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

### `/buddy-status`

📋 Shows your current buddy as a visual card — like checking your character sheet.

- Works whether your buddy is evolved or not
- Shows rarity badge, stats bars, personality, and age
- Read-only — doesn't change anything

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

### `/security-audit`

🛡️ Comprehensive health check for your buddy's integrity. Verifies:

- Binary backup exists and SHA-256 hash matches
- Codesign status is valid
- File permissions are correct
- Patch metadata is intact
- Anchor patterns still match the current binary

Run this if something feels off, or after a Claude Code update to make sure everything is still healthy.

---

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

# 🛠️ For Developers

Everything below is for contributors and developers working on the plugin itself.

---

<a id="architecture"></a>

## 🏗️ Architecture

<details>
<summary>📁 Project structure</summary>

```
.claude-plugin/
  plugin.json                     Plugin manifest (name, version, metadata)
  marketplace.json                Marketplace listing
  agents/                         Plugin agents (cache-analyzer, docs-reviewer, token-review)
.claude/settings.json             Byte-length invariant reminder hook
.github/workflows/ci.yml          CI: build + test + security checks (macOS 14)
agents/
  security-reviewer.md            Security review agent for Swift changes
  test-runner.md                  Test execution agent
hooks/
  hooks.json                      Hook definitions (SessionStart + PreToolUse)
  session-start.sh                Dev context injection at session startup
  validate-patcher-args.sh        Shell injection prevention for patcher args
  check-doc-freshness.sh          Pre-commit doc sync reminder
scripts/
  BuddyPatcher/                   Swift binary patching engine (zero dependencies)
    Package.swift                 SPM manifest (Swift 5.9, macOS 13+)
    Sources/BuddyPatcher/        CLI entry point
    Sources/BuddyPatcherLib/     Library: patching, validation, backup, analysis
    Tests/BuddyPatcherTests/     94 tests across 8 suites
  run-buddy-patcher.sh            Lazy-build wrapper (compiles on first use)
  cache-clean.sh                  Cache cleanup utility
  test-security.sh                Security validation test suite
skills/                           12 slash commands (see tables below)
```

</details>

### Data flow

```
/buddy-evolve
  → Reads current buddy from ~/.claude.json
  → Collects 6 choices (species, rarity, emoji, name, personality, stats)
  → Calls run-buddy-patcher.sh --species X --rarity Y ...
  → Swift tool backs up binary, patches in-place, re-signs with codesign
  → User restarts Claude Code

/buddy-reset
  → Verifies backup integrity (SHA-256)
  → Copies backup over patched binary, restores ~/.claude.json
  → Re-signs binary
```

### Plugin automation

The plugin ships 12 skills, 5 agents, and 5 hooks:

<details>
<summary>📜 Skills (12 slash commands)</summary>

**User-facing:**

| Skill | Description |
|-------|-------------|
| `/buddy-evolve` | Interactive 4-act evolution — species, rarity, emoji, name, personality, stats |
| `/buddy-reset` | Restore original buddy from backup |
| `/buddy-status` | Display current buddy as a visual card |
| `/test-patch` | Dry-run validation after Claude Code updates |
| `/update-species-map` | Investigate binary when anchor patterns break |
| `/security-audit` | 9-point integrity and permission check |

**Developer-facing:**

| Skill | Description |
|-------|-------------|
| `/run-tests` | Run Swift test suite (94 tests, 8 suites) with per-suite reporting |
| `/cache-clean` | Interactive cache management with dry-run preview |
| `/token-review` | 5-phase context footprint audit with optimization recommendations |
| `/sync-docs` | Compare project structure against CLAUDE.md and README.md, fix gaps |
| `/start-session` | Refresh dev context (git state, binary version, compatibility) |
| `/end-session` | Automated wrap-up: runs tests, security review, token review, cache cleanup |

</details>

<details>
<summary>🤖 Agents (5 subagents)</summary>

| Agent | Purpose |
|-------|---------|
| `security-reviewer` | Reviews Swift code for validation gaps, byte-length violations, unsafe patterns |
| `test-runner` | Builds and runs Swift tests, parses per-suite results |
| `cache-analyzer` | Scans build artifacts, orphaned worktrees, backup sizes, disk usage |
| `docs-reviewer` | Detects documentation gaps, stale entries, and path mismatches |
| `token-review` | Context footprint analysis with optimization scoring |

</details>

<details>
<summary>🔗 Hooks (5 automation hooks)</summary>

| Hook | Trigger | Purpose |
|------|---------|---------|
| Session context | `SessionStart` | Injects git state, binary version, compatibility status, backup health |
| Argument validation | `PreToolUse` (Bash) | Validates patcher args for shell metacharacters, injection, length limits |
| Test reminder | `PreToolUse` (Bash) | Reminds to run `swift test` before `git commit` on Swift changes |
| Doc freshness | `PreToolUse` (Bash) | Warns if code changed but CLAUDE.md/README.md weren't updated |
| Byte-length reminder | `PreToolUse` (Edit/Write) | Reminds about byte-length invariant when editing Swift sources |

</details>

> For the full architecture reference, see [CLAUDE.md](CLAUDE.md).

---

<a id="security-model"></a>

## 🛡️ Security Model

The plugin uses defense-in-depth across three layers to protect binary patching operations:

<details>
<summary>🔍 Layer details</summary>

**Layer 1: Swift input validation** (`Validation.swift`)

All user-provided inputs are validated before any write operation:
- **Emoji** — Single grapheme cluster, all Unicode scalars must be `.isEmoji`, max 16 UTF-8 bytes
- **Name** — Non-empty, max 100 chars, no control characters
- **Personality** — Non-empty, max 500 chars, no control characters
- **Stats** — JSON with known keys only (`debugging`, `patience`, `chaos`, `wisdom`, `snark`), integer values 0–100
- **Binary path** — Must exist, be a regular file, have Mach-O magic bytes

**Layer 2: Atomic operations and integrity**

- All file writes use `.atomic` option (`rename(2)` under the hood) — no partial writes on crash
- SHA-256 hash of original binary stored on first backup
- Restore verifies backup integrity against stored hash before overwriting
- Codesign failure after patching triggers automatic restore + exit(1)
- Backup directory: `0o700`; backup files: `0o600`

**Layer 3: Plugin-level enforcement**

- **PreToolUse hook** intercepts Bash calls to the patcher, validates for shell metacharacters (`;|&$\``), length limits, and `$()` subshell injection
- **Security audit skill** (`/security-audit`) provides on-demand integrity checking
- **Security review agent** reviews Swift code changes for missing validation, byte-length violations, and unsafe patterns

</details>

---

## 💻 Development Setup

```bash
# Clone the repository
git clone https://github.com/Soul-Craft/buddy-evolver.git
cd buddy-evolver

# Build the Swift patcher (requires Xcode CLT with Swift 5.9+)
swift build -c release --package-path scripts/BuddyPatcher

# Run unit tests (94 tests, 8 suites)
swift test --package-path scripts/BuddyPatcher

# Run security validation tests
bash scripts/test-security.sh

# Install locally for testing (inside Claude Code)
/plugin install --local .
```

> **Tip:** The lazy-build wrapper `scripts/run-buddy-patcher.sh` compiles the Swift tool on first use. You don't need to build manually unless you're modifying the source.

---

## 🧪 Testing

**94 unit tests** across 8 suites validate every component:

| Suite | What It Tests |
|-------|--------------|
| `ArgumentParsingTests` | CLI flag parsing, unknown flag rejection |
| `BinaryDiscoveryTests` | Symlink resolution, error handling |
| `ByteUtilsTests` | Pattern search correctness, edge cases |
| `MetadataTests` | JSON serialization, file I/O |
| `PatchEngineTests` | Species, rarity, shiny, art patching + idempotency |
| `PatchLengthInvariantTests` | **Byte-length equality** — the critical invariant |
| `SoulPatcherTests` | `~/.claude.json` updates, missing file handling |
| `VariableMapDetectionTests` | Anchor detection, version compatibility |

**Security tests** (`scripts/test-security.sh`) validate input rejection at both Swift and hook layers.

**CI** runs on every push/PR to `main` via GitHub Actions (macOS 14): build, unit tests, and security tests. Runs are cached via SPM build artifacts.

Run everything locally:

```bash
swift test --package-path scripts/BuddyPatcher && bash scripts/test-security.sh
```

---

## 🤝 Contributing

Issues and PRs welcome at [github.com/Soul-Craft/buddy-evolver](https://github.com/Soul-Craft/buddy-evolver).

**Development workflow:**

1. Fork and clone the repo
2. Create a feature branch
3. Make your changes
4. Run `swift test --package-path scripts/BuddyPatcher` and `bash scripts/test-security.sh`
5. Open a PR against `main`

**Key constraints** — if you modify the Swift source in `scripts/BuddyPatcher/`:

- Every binary patch **must** produce output identical in byte length to the original — like fitting new sprites into the same ROM
- Use `findAll()` to locate patterns (never hardcode offsets)
- Add input validation in `Validation.swift` for any new user-provided arguments
- Use `.atomic` option on all `Data.write()` calls
- Add a `[DRY RUN]` branch for `--dry-run` mode in any new patch type
- Test with `--dry-run` before committing

**When updating for new Claude Code versions:**

- Check if anchor patterns still exist in the new binary (`/test-patch`)
- Variable names may change — update `knownVarMaps` in `VariableMapDetection.swift`
- Test with `--dry-run` first, then verify with the full test suite

CI enforces build + unit tests + security tests on every PR.

---

## 🙏 Acknowledgments

- The [Claude Code](https://docs.anthropic.com/en/docs/claude-code) team at Anthropic for the Buddy feature and the plugin system that makes this possible
- The Claude Code plugin ecosystem and its community of builders

---

## 📄 License

[MIT](LICENSE)
