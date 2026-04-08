# Buddy Customizer

Claude Code plugin that customizes the terminal Buddy pet by patching the Mach-O binary and companion data.

## Architecture

```
.claude-plugin/plugin.json       Plugin manifest (name, version, metadata)
.claude-plugin/marketplace.json  Marketplace listing (for /plugin install)
.claude/settings.json            Hooks (byte-length invariant reminder)
skills/buddy-evolve/             Evolution skill (/buddy-evolve)
skills/buddy-reset/              Reset skill (/buddy-reset)
skills/test-patch/               Dry-run validation (/test-patch)
skills/update-species-map/       Binary version maintenance (/update-species-map)
scripts/BuddyPatcher/            Binary patching engine (Swift, zero dependencies)
scripts/run-buddy-patcher.sh     Lazy-build wrapper (compiles Swift on first use)
```

### How patching works

The Claude Code binary is a Bun-compiled JavaScript bundle. Buddy customization patches the binary in-place:

1. **Species** — The species array (`Trq`) contains 3-byte variable references (`GL_`, `ZL_`, etc.). All refs are replaced with the target species' variable. Found via anchor pattern `GL_,ZL_,LL_,kL_,`.
2. **Rarity** — Weight string `common:60,uncommon:25,rare:10,epic:4,legendary:1` is modified to zero all weights except the target.
3. **Shiny** — Threshold `H()<0.01` changed to `H()<1.01` (guarantees shiny).
4. **Art** — Species-keyed ASCII art arrays replaced with centered emoji.
5. **Soul** — Name and personality written to `~/.claude.json` (not binary).

After patching, the binary is re-signed with `codesign --force --sign -`.

### Critical constraints

- **Exact byte length**: Every binary patch MUST produce output identical in byte length to the original. The Bun bytecode has fixed offsets — changing length corrupts the binary.
- **3-byte variable refs**: Species variables are always exactly 3 bytes (e.g., `GL_`, `vL_`). This is a bytecode invariant.
- **Anchor patterns**: The tool locates patch sites by searching for known byte patterns, not fixed offsets. This provides version portability but means patches break if Anthropic refactors the variable names or string formats.
- **Backup before patch**: `ensureBackup()` is idempotent — it creates a one-time backup and never overwrites it. The original binary must always be recoverable.

### Data flow

```
/buddy-evolve
  → Reads current buddy from ~/.claude.json (via plutil)
  → Collects choices (species, rarity, emoji, name, personality, stats)
  → Runs: run-buddy-patcher.sh --species X --rarity Y ...
  → Tool backs up binary + soul, patches binary, re-signs, saves metadata
  → User restarts Claude Code

/buddy-reset
  → Checks for backup at <binary>.original-backup
  → Copies backup over current binary, restores ~/.claude.json
  → Re-signs binary
```

### Key file locations (on user's machine)

- Binary: resolved from `~/.local/bin/claude` symlink → `~/.local/share/claude/versions/<ver>`
- Binary backup: `<binary>.original-backup`
- Soul backup: `~/.claude/backups/.claude.json.pre-customize`
- Patch metadata: `~/.claude/backups/buddy-patch-meta.json`

## Platform

macOS only. Requires Xcode Command Line Tools (provides Swift compiler and `codesign`). Zero third-party dependencies.

## Automations

### Hook: byte-length protection

A `PreToolUse` hook in `.claude/settings.json` fires when editing files in `BuddyPatcher/`. It injects a reminder about the byte-length invariant into Claude's context. This is a prompt-based hook (awareness, not enforcement).

### Skill: /test-patch

Runs the patching tool in `--dry-run` mode with all patch types to verify anchor patterns still match the current binary. Use after Claude Code updates.

### Skill: /update-species-map

Investigates the binary when patterns break. Uses `--analyze` mode to search for anchor patterns, extract variable names, and compare against `knownVarMaps`. Use when `/test-patch` reports failures.

## Modifying the Swift source

When adding new patch types:
- Always use `findAll()` to locate patterns (never hardcode offsets)
- Assert byte length equality before writing
- Add a `[DRY RUN]` branch for `--dry-run` mode
- Save new fields to metadata via `saveMetadata()`
- Handle the "already patched" case (tool should be re-runnable)

When updating for new Claude Code versions:
- Check if anchor patterns still exist in the new binary
- Variable names may change — update `knownVarMaps` in `VariableMapDetection.swift`
- Test with `--dry-run` first

### Swift source layout

```
scripts/BuddyPatcher/
  Package.swift                  SPM manifest (zero dependencies)
  Sources/BuddyPatcher/
    main.swift                   CLI entry point, argument parsing, orchestration
    ByteUtils.swift              findAll(), findFirst(), utf8Bytes() helpers
    BinaryDiscovery.swift        findBinary(), getVersion(), PatchError
    VariableMapDetection.swift   knownVarMaps, detectVarMap(), anchorForMap()
    PatchEngine.swift            patchSpecies(), patchRarity(), patchShiny(), patchArt()
    SoulPatcher.swift            patchSoul() — ~/.claude.json updates
    BackupRestore.swift          ensureBackup(), restoreBackup(), verifyBinary(), resignBinary()
    Metadata.swift               saveMetadata(), loadMetadata()
```
