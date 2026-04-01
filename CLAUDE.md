# Buddy Customizer

Claude Code plugin that customizes the terminal Buddy pet by patching the Mach-O binary and companion data.

## Architecture

```
.claude-plugin/plugin.json    Plugin manifest (name, version, metadata)
.claude/settings.json         Hooks (byte-length invariant reminder)
skills/buddy/                 Main skill (/buddy evolve, /buddy reset)
skills/test-patch/            Dry-run validation (/test-patch)
skills/update-species-map/    Binary version maintenance (/update-species-map)
scripts/patch-buddy.py        Binary patching engine (Python 3)
```

### How patching works

The Claude Code binary is a Bun-compiled JavaScript bundle. Buddy customization patches the binary in-place:

1. **Species** — The species array (`Trq`) contains 3-byte variable references (`b0_`, `I0_`, `m0_`, etc.). All refs are replaced with the target species' variable. Found via anchor pattern `b0_,I0_,x0_,u0_,`.
2. **Rarity** — Weight string `common:60,uncommon:25,rare:10,epic:4,legendary:1` is modified to zero all weights except the target.
3. **Shiny** — Threshold `H()<0.01` changed to `H()<1.01` (guarantees shiny).
4. **Art** — Species-keyed ASCII art arrays replaced with centered emoji.
5. **Soul** — Name and personality written to `~/.claude.json` (not binary).

After patching, the binary is re-signed with `codesign --force --sign -`.

### Critical constraints

- **Exact byte length**: Every binary patch MUST produce output identical in byte length to the original. The Bun bytecode has fixed offsets — changing length corrupts the binary.
- **3-byte variable refs**: Species variables are always exactly 3 bytes (e.g., `b0_`, `m0_`). This is a bytecode invariant.
- **Anchor patterns**: The script locates patch sites by searching for known byte patterns, not fixed offsets. This provides version portability but means patches break if Anthropic refactors the variable names or string formats.
- **Backup before patch**: `ensure_backup()` is idempotent — it creates a one-time backup and never overwrites it. The original binary must always be recoverable.

### Data flow

```
/buddy evolve
  → Reads current buddy from ~/.claude.json
  → Collects choices (species, rarity, emoji, name, personality, stats)
  → Runs: python3 $CLAUDE_PLUGIN_ROOT/scripts/patch-buddy.py --species X --rarity Y ...
  → Script backs up binary + soul, patches binary, re-signs, saves metadata
  → User restarts Claude Code

/buddy reset
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

macOS only. Requires `codesign` and Python 3.

## Automations

### Hook: byte-length protection

A `PreToolUse` hook in `.claude/settings.json` fires when editing `patch-buddy.py`. It injects a reminder about the byte-length invariant into Claude's context. This is a prompt-based hook (awareness, not enforcement).

### Skill: /test-patch

Runs the patching script in `--dry-run` mode with all patch types to verify anchor patterns still match the current binary. Use after Claude Code updates.

### Skill: /update-species-map

Investigates the binary when patterns break. Searches for the anchor pattern, extracts variable names, compares against `SPECIES_VAR_MAP`, and suggests updates. Use when `/test-patch` reports failures.

## Modifying the script

When adding new patch types:
- Always use `find_all()` to locate patterns (never hardcode offsets)
- Assert byte length equality before writing
- Add a `[DRY RUN]` branch for `--dry-run` mode
- Save new fields to metadata via `save_metadata()`
- Handle the "already patched" case (script should be re-runnable)

When updating for new Claude Code versions:
- Check if anchor patterns still exist in the new binary
- Variable names may change — update `SPECIES_VAR_MAP` if needed
- Test with `--dry-run` first
