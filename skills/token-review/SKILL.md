---
name: token-review
description: This skill should be used when the user asks to "token review", "review tokens", "optimize tokens", "audit context size", "reduce token footprint", "session review", "end of session review", or "check token usage".
argument-hint: "--apply (optional, applies optimizations), --force (optional, skips dirty-worktree check — used by /session-review)"
---

# Token Review — Audit Plugin Context Footprint

Audit all context-loaded files in the Buddy Evolver plugin for token optimization opportunities. Produces a structured report. Optionally applies optimizations with `--apply`.

## Phase 1: Inventory

Measure every file that gets loaded into Claude's context window. Run:

```bash
cd "${CLAUDE_PLUGIN_ROOT}"
echo "=== Always Loaded ==="
for f in CLAUDE.md .claude-plugin/plugin.json .claude-plugin/marketplace.json .claude/settings.json .claude/settings.local.json; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f" | tr -d ' ')
    chars=$(wc -c < "$f" | tr -d ' ')
    tokens=$((chars / 4))
    printf "%-45s %4s lines  %6s chars  ~%s tokens\n" "$f" "$lines" "$chars" "$tokens"
  fi
done
echo ""
echo "=== Loaded On Skill Invocation ==="
for f in skills/*/SKILL.md; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f" | tr -d ' ')
    chars=$(wc -c < "$f" | tr -d ' ')
    tokens=$((chars / 4))
    printf "%-45s %4s lines  %6s chars  ~%s tokens\n" "$f" "$lines" "$chars" "$tokens"
  fi
done
```

Present the output as a formatted table. Calculate totals for always-loaded and per-skill.

## Phase 2: Checklist Audit

Read the optimization checklist:
```
Read ${CLAUDE_PLUGIN_ROOT}/skills/token-review/references/optimization-checklist.md
```

For each check (A1 through E1), evaluate the target file against the described pattern:
- Read the target file
- Search for the pattern described in the check
- If found: mark as **OPPORTUNITY** with estimated token savings
- If not found (already optimized or N/A): mark as **PASS**

Dispatch the `token-reviewer` agent to perform the scanning if available. Otherwise, do the analysis inline.

## Phase 3: Report

Output the report in this format:

```
Token Optimization Report
═════════════════════════

Always-loaded baseline:    ~[N] tokens
Largest skill invocation:  [skill name] (~[N] tokens)
Worst-case session total:  ~[N] tokens

File Inventory:
───────────────
[table from Phase 1]

Optimization Opportunities:
───────────────────────────
[numbered list, sorted by savings descending]

1. [ID] [description]
   File: [path]
   Pattern: [what was found]
   Savings: ~[N] tokens ([%] of file)
   Action: [what to do]

...

Checks Passing:
──────────────
[list of IDs that are already optimized]

Summary:
────────
  Total recoverable:      ~[N] tokens
  Always-loaded after:    ~[N] tokens (currently ~[N])
  Largest skill after:    ~[N] tokens (currently ~[N])
  Reduction:              [%] always-loaded, [%] largest skill
```

## Phase 4: Apply (if `--apply` requested)

Only proceed if the user passed `--apply` or explicitly confirms after seeing the report.

### Pre-flight
```bash
cd "${CLAUDE_PLUGIN_ROOT}" && git status --short
```
Warn if working tree has uncommitted changes. Ask user to confirm before proceeding.

**Skip this check entirely if `--force` was passed.** The `--force` flag is used by `/session-review` which always runs against a dirty worktree (by design — it runs before commit). In that context, the token-review edits are intentionally bundled with the session's other changes.

### For each optimization opportunity:
1. Create the target reference file (if extracting content)
2. Edit the source file to replace inline content with a read instruction
3. Verify the edit:
   - Re-read the source file and confirm frontmatter, headings, and bash blocks are intact
   - Re-read the reference file and confirm extracted content is complete
   - Re-measure the source file to confirm token reduction

### Post-apply measurement
Re-run the Phase 1 inventory to show before/after comparison.

## Phase 5: Verify

After applying optimizations:

1. **Structural check** — for each modified SKILL.md, verify:
   - YAML frontmatter with `name` and `description` fields exists
   - All original step headings (##) are preserved
   - All bash code blocks are preserved
   - Read instructions point to files that exist

2. **Functional check** — dry-run the patcher with the v2.0.0 soul + meta flags:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" --dry-run --meta-species dragon --meta-rarity legendary --meta-shiny --meta-emoji "🐲" --name "Test" --personality "Test"
```

3. **Diff summary**:
```bash
cd "${CLAUDE_PLUGIN_ROOT}" && git diff --stat
```

4. Display rollback instruction: "To revert all optimizations: `git checkout -- .`"

## If No `--apply`

End after Phase 3 (the report). Remind the user they can run `/token-review --apply` to execute the optimizations, or apply individual items manually.
