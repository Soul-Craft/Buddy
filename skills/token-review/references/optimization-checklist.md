# Token Optimization Checklist

Evaluate each check against the current state of the plugin files. For each finding, report: check ID, status (PASS/OPPORTUNITY), estimated tokens recoverable, and suggested action.

## Category A: Static Content Extraction

Move static visual content from SKILL.md files to reference files. Reference files are only loaded when explicitly read, saving tokens in the skill's base context.

### A1: ASCII art in buddy-evolve
- **Target:** `skills/buddy-evolve/SKILL.md`
- **Pattern:** Look for multi-line ASCII art blocks (3+ lines of art per species)
- **Action:** Move to `skills/buddy-evolve/references/species-ascii-art.md`. Replace with: "Read species ASCII art from `${CLAUDE_PLUGIN_ROOT}/skills/buddy-evolve/references/species-ascii-art.md` and use the block matching the current species."
- **Savings:** ~285 tokens

### A2: Card templates in buddy-status
- **Target:** `skills/buddy-status/SKILL.md`
- **Pattern:** Look for box-drawing character templates (lines with `║`, `╔`, `╚`, `╠`)
- **Action:** Move to `skills/buddy-status/references/card-templates.md`. Replace with a read instruction.
- **Savings:** ~350 tokens

### A3: Evolution animation in buddy-evolve
- **Target:** `skills/buddy-evolve/SKILL.md`
- **Pattern:** Look for sparkle-decorated ASCII art (lines with `✨` alongside species art)
- **Action:** Move to `skills/buddy-evolve/references/species-ascii-art.md` as "sparkle variants". Replace with a read instruction.
- **Savings:** ~100 tokens

### A4: Swift development guide in CLAUDE.md
- **Target:** `CLAUDE.md`
- **Pattern:** Sections titled "Modifying the Swift source" or "Swift source layout"
- **Action:** Move to `references/swift-development-guide.md`. Replace with: "For Swift modification guidelines, see `references/swift-development-guide.md`."
- **Savings:** ~340 tokens

## Category B: Deduplication

Consolidate repeated data into a single canonical source.

### B1: Species list duplication
- **Target:** `skills/buddy-evolve/SKILL.md`
- **Canonical source:** `skills/buddy-evolve/references/species-map.md`
- **Pattern:** Inline list of all 18 species names
- **Action:** Replace with: "Read the full species list from `${CLAUDE_PLUGIN_ROOT}/skills/buddy-evolve/references/species-map.md`."
- **Savings:** ~50 tokens

### B2: Rarity tier duplication
- **Targets:** `skills/buddy-evolve/SKILL.md`, `skills/buddy-status/SKILL.md`
- **Pattern:** Repeated rarity tier names with descriptions or flair mappings
- **Action:** Consolidate into species-map.md, reference from both skills.
- **Savings:** ~40 tokens

## Category C: Prose Compression

Reduce verbose explanatory text without losing functional information.

### C1: Architecture tree descriptions
- **Target:** `CLAUDE.md`
- **Pattern:** Parenthetical descriptions in the architecture tree (e.g., "Plugin manifest (name, version, metadata)")
- **Action:** Remove parentheticals — filenames are self-documenting.
- **Savings:** ~60 tokens

### C2: Patching explanation prose
- **Target:** `CLAUDE.md`
- **Pattern:** Multi-sentence explanations of each patch type
- **Action:** Compress to a compact table: `| Patch | Target | Method |`
- **Savings:** ~80 tokens

### C3: Instruction prefix verbosity
- **Target:** `skills/buddy-evolve/SKILL.md`
- **Pattern:** Repeated phrases like "Use AskUserQuestion:", "Ask in conversation (freeform):"
- **Action:** Shorten to structured notation: "AskUserQuestion:" or "Freeform:"
- **Savings:** ~30 tokens

## Category D: Hook Optimization

### D1: Hook warning message length
- **Target:** `.claude/settings.json`
- **Pattern:** Long inline warning string in PreToolUse hook
- **Action:** Shorten to essential message: "BYTE-LENGTH INVARIANT: Patches must match original byte length. Test with --dry-run."
- **Savings:** ~15 tokens

### D2: Hook grep pattern correctness
- **Target:** `.claude/settings.json`
- **Pattern:** grep for `patch-buddy.py` (old Python script name)
- **Action:** Update to grep for `BuddyPatcher` (current Swift source directory)
- **Type:** Correctness fix (not token savings)

## Category E: Always-Loaded Minimization

### E1: Swift source layout verbosity
- **Target:** `CLAUDE.md`
- **Pattern:** File tree with inline descriptions for each Swift file
- **Action:** List filenames only, remove descriptions (function names are self-documenting).
- **Savings:** ~80 tokens

## Evaluation Rules

- **PASS:** Content is already optimized or has been moved to a reference file
- **OPPORTUNITY:** Content matches the pattern and can be optimized
- **N/A:** Target file or pattern no longer exists (skip)
- Only count tokens for content that is loaded into context (not README.md, not compiled Swift)
- Token estimate: characters / 4 (rough heuristic)
