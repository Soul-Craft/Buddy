# 🍄 Buddy Evolver | Claude Code Plugin

[![CI](https://github.com/Soul-Craft/buddy-evolver/actions/workflows/ci.yml/badge.svg)](https://github.com/Soul-Craft/buddy-evolver/actions/workflows/ci.yml)
![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)
![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)

> Your buddy found a psychedelic mushroom 🍄 What happens next is entirely up to you ✨

Pick the species. Choose the rarity. Name it. Define its personality. Max out its stats. This isn't random evolution — **you design every detail**, then watch your buddy transform as if it was a Pokemon eating a psychedelic Super Mario mushroom 🍄

18 species 🧬 | 5 rarity tiers ⭐ | custom emoji 🎨 | your name ✏️ | your personality 💬 | your stats 📊

**Name and personality reach Claude Code directly** — your buddy's name appears in the sidebar, its personality shapes how it introduces itself. Species, rarity, emoji, and stats are plugin-local card flair displayed by `/buddy-status`.

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
  > Ancient dragon who speaks in riddles

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

- 🍎 **macOS** — required (Swift compiler uses Xcode CLT)
- 🛠️ **Xcode Command Line Tools** — provides the Swift compiler; install with `xcode-select --install`
- 🤖 **Claude Code** — CLI version with the Buddy/companion feature

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

This adds slash commands including `/buddy-evolve`, `/buddy-reset`, `/buddy-status`, and `/security-audit`.

---

## 🎮 Quick Start

**Press START on your evolution adventure:**

1. 🍄 Run `/buddy-evolve`
2. 🎨 Design your buddy — pick species, rarity, emoji, name, personality, and stats
3. ✨ Name and personality take effect immediately — no restart needed

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

**✨ Act 3 — Evolution.** Confirmation summary, then sparkles fly as companion data is written. Level-up complete.

**🎉 Act 4 — Reveal.** Your evolved buddy card appears with stats, personality, and rarity badge. Like opening a legendary pack.

All evolved buddies are ✨ shiny by default. A backup of your original companion data is created automatically.

### `/buddy-status`

📋 Shows your current buddy as a visual card — like checking your character sheet.

- Works whether your buddy is evolved or not
- Shows rarity badge, stats bars, personality, and age
- Read-only — doesn't change anything

### `/buddy-reset`

🔄 Restores your original companion data from the pre-evolution backup.

- Restores `~/.claude.json` from soul backup and removes card metadata
- Safe to run anytime — does nothing if no backup exists
- No restart needed — changes take effect on your next conversation

### `/security-audit`

🛡️ Health check for your buddy's state. Verifies:

- Soul backup exists and is accessible
- File permissions are correct (700/600)
- Companion data is present in `~/.claude.json`
- Card metadata is valid JSON with v2 schema

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

Rarity is card flair — it determines how your buddy is displayed in `/buddy-status`:

| Tier | Badge | Vibe |
|------|:---:|---|
| **✨ Legendary** | ★ LEGENDARY | Main character energy |
| **💎 Epic** | ◆ EPIC | Hype beast |
| **🔮 Rare** | ● RARE | Solid sidekick |
| **🌿 Uncommon** | · UNCOMMON | Occasional wisdom |
| **🪨 Common** | · COMMON | The strong, silent type |

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

The plugin writes to two places:

**Soul (actually reaches Claude Code):**
- Name and personality are written to `~/.claude.json#companion`
- Claude Code reads these fields and injects your buddy's name into every session
- Changes take effect immediately — **no restart needed**

**Card metadata (plugin-local cosmetic layer):**
- Species, rarity, shiny, emoji, and stats are stored in `~/.claude/backups/buddy-patch-meta.json`
- This drives the `/buddy-status` visual card — a Tamagotchi-style terminal display
- Claude Code itself never reads this file; it's purely for the plugin's card renderer

A backup of `~/.claude.json` is created automatically before any soul write — run `/buddy-reset` to restore the original any time.

**After Claude Code updates:** Nothing to worry about. Your name and personality live in `~/.claude.json`, which updates never touch. Your buddy persists through any number of Claude Code version bumps.

---

## 🩹 Troubleshooting

<details>
<summary>✏️ <b>My buddy's name didn't change</b></summary>

Name and personality take effect on the next Claude Code conversation after evolution. If you're already in a session, start a new one (or close and reopen Claude Code).

Check the raw value:

```bash
plutil -extract companion json -o - ~/.claude.json
```

If the name is there, it's working — just start a fresh conversation.

</details>

<details>
<summary>🔁 <b>I want to change my buddy again</b></summary>

Just run `/buddy-evolve` again! No need to reset first — the script is fully re-runnable. Redesign as many times as you want.

</details>

<details>
<summary>🗑️ <b>Can I clear my buddy entirely?</b></summary>

Run `/buddy-reset`. This restores your `~/.claude.json` to the pre-evolution state (before your first `/buddy-evolve`). If you never ran `/buddy-evolve`, there's nothing to restore.

</details>

<details>
<summary>🐧 <b>Can I use this on Linux or Windows?</b></summary>

Not currently. The plugin requires macOS (Swift compiler + `codesign`). A Linux port would be possible if there is demand.

</details>

<details>
<summary>🛡️ <b>Is this safe? What does it write to my system?</b></summary>

Two files are written:
- `~/.claude.json` — your existing Claude Code config; only the `companion.name` and `companion.personality` fields are modified
- `~/.claude/backups/buddy-patch-meta.json` — new file; purely plugin-local card state

A backup of the original `~/.claude.json` is saved to `~/.claude/backups/.claude.json.pre-customize` before any change. Run `/buddy-reset` to restore it at any time.

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
.claude/settings.json             Permissions for common bash patterns
.github/workflows/                CI workflows (quality, verify-local, macos-fallback, release)
agents/
  security-reviewer.md            Security review agent for Swift changes
  comment-reviewer.md             Inline comment audit agent for /end-session (Haiku)
  test-runner.md                  Test execution agent
hooks/
  hooks.json                      Hook definitions (SessionStart + SessionEnd + PreToolUse)
  session-start.sh                Dynamic dev context injection at session startup
  session-end.sh                  Automatic worktree self-cleanup on exit
  validate-patcher-args.sh        Shell injection prevention for patcher args
  check-doc-freshness.sh          Pre-commit doc sync reminder
  pre-commit-test-reminder.sh     Context-aware test reminders on git commit
scripts/
  BuddyPatcher/                   Swift soul-patching engine (zero dependencies)
    Package.swift                 SPM manifest (Swift 5.9, macOS 13+)
    Sources/BuddyPatcher/        CLI entry point
    Sources/BuddyPatcherLib/     Library: soul patching, validation, backup, metadata
    Tests/BuddyPatcherTests/     ~98 tests across 6 files
    Tests/Fixtures/               Golden files for CLI snapshot tests
  run-buddy-patcher.sh            Lazy-build wrapper (compiles on first use)
  cache-clean.sh                  Cache cleanup utility
  process-pending-cleanup.sh      Shared worktree cleanup retry (session-end + session-start hooks)
  lint.sh                         Local lint (shellcheck, JSON, frontmatter, hygiene)
  test-smoke.sh                   Smoke tier: build sanity + CLI contract (<30s)
  test-security.sh                Security validation test suite
  test-ui.sh                      Buddy card rendering against fixtures
  test-snapshots.sh               Golden file comparison for CLI output
  test-docs.sh                    Documentation path + link + count consistency
  test-compatibility.sh           On-demand compatibility validation
  test-perf.sh                    Performance benchmarks (on-demand)
  coverage.sh                     Local HTML coverage report
skills/                           12 slash commands (see tables below)
```

</details>

### Data flow

```
/buddy-evolve
  → Reads current buddy from ~/.claude.json
  → Collects 6 choices (species, rarity, emoji, name, personality, stats)
  → Calls run-buddy-patcher.sh --meta-species X --meta-rarity Y --name Z ...
  → Swift tool backs up ~/.claude.json, writes name+personality, saves card metadata
  → Changes are live immediately (no restart)

/buddy-reset
  → Restores ~/.claude.json from soul backup
  → Removes card metadata file
```

### Plugin automation

The plugin ships 12 skills, 6 agents, and 5 hooks:

<details>
<summary>📜 Skills (12 slash commands)</summary>

**User-facing:**

| Skill | Description |
|-------|-------------|
| `/buddy-evolve` | Interactive 4-act evolution — species, rarity, emoji, name, personality, stats |
| `/buddy-reset` | Restore original companion data from soul backup |
| `/buddy-status` | Display current buddy as a visual card |
| `/security-audit` | 7-point backup health and permission check |

**Developer-facing:**

| Skill | Description |
|-------|-------------|
| `/run-tests` | Run Swift test suite with per-suite reporting |
| `/run-all-tests` | Run the full 6-tier pipeline via `test-all.sh` with per-tier summary table |
| `/cache-clean` | Interactive cache management with dry-run preview |
| `/token-review` | 5-phase context footprint audit with optimization recommendations |
| `/sync-docs` | Compare project structure against CLAUDE.md and README.md, fix gaps |
| `/start-session` | Refresh dev context (delegates to SessionStart hook — no hardcoded list to drift) |
| `/end-session` | Pre-commit wrap-up: token review → test-all → upload Check Run → sync docs → comment audit |
| `/session-deploy` | Post-merge: sync local main, verify smoke, clean other worktrees, stage self-cleanup for `/exit` |

</details>

<details>
<summary>🤖 Agents (6 subagents)</summary>

| Agent | Purpose |
|-------|---------|
| `security-reviewer` | Reviews Swift code for validation gaps and unsafe patterns |
| `comment-reviewer` | Haiku read-only audit of inline comments in changed files — used by `/end-session` |
| `test-runner` | Builds and runs Swift tests, parses per-suite results |
| `cache-analyzer` | Scans build artifacts, orphaned worktrees, backup sizes, disk usage |
| `docs-reviewer` | Detects documentation gaps, stale entries, and path mismatches |
| `token-review` | Context footprint analysis with optimization scoring |

</details>

<details>
<summary>🔗 Hooks (5 automation hooks)</summary>

| Hook | Trigger | Purpose |
|------|---------|---------|
| Session context | `SessionStart` | Dynamic discovery of skills/agents/hooks + git freshness + pending cleanup retry |
| Worktree cleanup | `SessionEnd` | Attempts to remove staged worktree from `/session-deploy` on exit |
| Argument validation | `PreToolUse` (Bash) | Validates patcher args for shell metacharacters, injection, length limits |
| Test reminder | `PreToolUse` (Bash) | Reminds to run `swift test` before `git commit` on Swift changes |
| Doc freshness | `PreToolUse` (Bash) | Warns if code changed but CLAUDE.md/README.md weren't updated |

</details>

> For the full architecture reference, see [CLAUDE.md](CLAUDE.md).

---

<a id="security-model"></a>

## 🛡️ Security Model

The plugin uses defense-in-depth across two layers to protect write operations:

<details>
<summary>🔍 Layer details</summary>

**Layer 1: Swift input validation** (`Validation.swift`)

All user-provided inputs are validated before any write operation:
- **Emoji** — Single grapheme cluster, all Unicode scalars must be `.isEmoji`, max 16 UTF-8 bytes
- **Name** — Non-empty, max 100 chars, no control characters
- **Personality** — Non-empty, max 500 chars, no control characters
- **Stats** — JSON with known keys only (`debugging`, `patience`, `chaos`, `wisdom`, `snark`), integer values 0–100

**Layer 2: Atomic operations and permissions**

- All file writes use `.atomic` option (`rename(2)` under the hood) — no partial writes on crash
- Backup directory: `0o700`; backup files: `0o600`
- Soul backup is idempotent — created once, never overwritten, always recoverable

**Layer 3: Plugin-level enforcement**

- **PreToolUse hook** intercepts Bash calls to the patcher, validates for shell metacharacters (`;|&$\``), length limits, and `$()` subshell injection
- **Security audit skill** (`/security-audit`) provides on-demand backup health and permission checking
- **Security review agent** reviews Swift code changes for missing validation and unsafe patterns

</details>

---

## 💻 Development Setup

```bash
# Clone the repository
git clone https://github.com/Soul-Craft/buddy-evolver.git
cd buddy-evolver

# Build the Swift patcher (requires Xcode CLT with Swift 5.9+)
swift build -c release --package-path scripts/BuddyPatcher

# Run unit tests
swift test --package-path scripts/BuddyPatcher

# Run security validation tests
bash scripts/test-security.sh

# Run all tests
bash scripts/test-all.sh

# Install locally for testing (inside Claude Code)
/plugin install --local .
```

> **Tip:** The lazy-build wrapper `scripts/run-buddy-patcher.sh` compiles the Swift tool on first use. You don't need to build manually unless you're modifying the source.

---

## 🧪 Testing

**~98 unit tests** across 6 files validate every component:

| Suite | What It Tests |
|-------|--------------|
| `ArgumentParsingTests` | CLI flag parsing, unknown/old flag rejection |
| `BackupRestoreTests` | Soul backup creation, idempotency, permissions, restore |
| `MetadataTests` | JSON serialization, schema version, file I/O |
| `OrchestrationTests` | End-to-end soul pipeline composition |
| `SoulPatcherTests` | `~/.claude.json` updates, missing file handling |
| `ValidationTests` | Input validation (emoji, name, personality, stats) |

**6 automated test tiers** via `test-all.sh`:

| Tier | Script | Stage | Purpose |
|------|--------|-------|---------|
| Smoke | `scripts/test-smoke.sh` | smoke | Build sanity + CLI contract (<30s) |
| Unit | `swift test` | core | Swift XCTest suite |
| Security | `scripts/test-security.sh` | core | Input validation, hook enforcement, injection checks |
| UI | `scripts/test-ui.sh` | real-world | Buddy card rendering against pinned JSON fixtures |
| Snapshots | `scripts/test-snapshots.sh` | full-system | Golden file comparison for CLI output |
| Docs | `scripts/test-docs.sh` | peripheral | Documentation path + link + count consistency |

**CI** is local-first: `ci-quality.yml` runs on Ubuntu for every PR (shellcheck, JSON/YAML validation, hygiene checks). macOS-dependent tests run on contributor machines via `scripts/test-all.sh && scripts/upload-test-results.sh`; `ci-verify-local.yml` blocks merge until the upload appears and passes.

Run everything locally:

```bash
bash scripts/test-all.sh                # all 6 tiers, emits test-results/results.json
bash scripts/upload-test-results.sh     # publish as GitHub Check Run on this commit
bash scripts/coverage.sh                # local HTML coverage → test-results/coverage/index.html
```

---

## 🤝 Contributing

Issues and PRs welcome at [github.com/Soul-Craft/buddy-evolver](https://github.com/Soul-Craft/buddy-evolver).

For security issues, please use [GitHub Security Advisories](https://github.com/Soul-Craft/buddy-evolver/security/advisories/new)
rather than opening a public issue. See [SECURITY.md](SECURITY.md) for details.

**Development workflow:**

1. Fork and clone the repo
2. Create a feature branch
3. Make your changes
4. Run `swift test --package-path scripts/BuddyPatcher && bash scripts/test-security.sh`
5. Run `bash scripts/test-all.sh` — all 6 tiers must pass
6. Run `bash scripts/upload-test-results.sh` to post results as a Check Run
7. Open a PR against `main` — the [PR template](.github/PULL_REQUEST_TEMPLATE.md) will guide you

**Key constraints** — if you modify the Swift source in `scripts/BuddyPatcher/`:

- Add input validation in `Validation.swift` for any new user-provided arguments
- Use `.atomic` option on all `Data.write()` calls
- Add a `[DRY RUN]` branch for `--dry-run` mode in any new functionality
- Run `bash scripts/test-security.sh` before committing

---

## 🙏 Acknowledgments

- The [Claude Code](https://docs.anthropic.com/en/docs/claude-code) team at Anthropic for the companion feature and the plugin system that makes this possible
- The Claude Code plugin ecosystem and its community of builders

---

## 📄 License

[MIT](LICENSE)
