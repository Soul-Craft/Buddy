---
name: sync-docs
description: This skill should be used when the user asks to "sync docs", "update docs", "sync documentation", "update readme", "update claude md", "docs out of date", "check documentation", or "fix docs".
---

# Sync Docs — Keep Documentation in Sync with Code

Compare the actual project structure against CLAUDE.md and README.md, identify gaps and stale references, and apply fixes.

## Steps

### 1. Run the docs-reviewer agent

Dispatch the `docs-reviewer` agent to analyze documentation accuracy:

```
Use the Agent tool with subagent_type unset (general-purpose) and instruct it to follow
the docs-reviewer agent prompt at .claude-plugin/agents/docs-reviewer.md
```

The agent will return a structured report with categories: `MISSING_FROM_DOCS`, `STALE_IN_DOCS`, `PATH_MISMATCH`, `DESCRIPTION_OUTDATED`.

### 2. Report findings

If the agent reports `status: CLEAN`:
- Tell the user "Documentation is up to date" and stop

If drift is detected, show the user a summary table:

```
| Category          | Count | Details                    |
|-------------------|-------|----------------------------|
| Missing from docs | N     | [list items]               |
| Stale in docs     | N     | [list items]               |
| Path mismatches   | N     | [list items]               |
| Outdated desc.    | N     | [list items]               |
```

### 3. Apply fixes to CLAUDE.md

For each gap found, apply the appropriate fix:

**MISSING_FROM_DOCS (skill):**
- Add entry to the file tree section (match existing format: `skills/<name>/    Description (/skill-name)`)
- Add a `### Skill: /skill-name` entry in the Automations section — read the skill's SKILL.md to write an accurate one-line description
- If user-facing (buddy-evolve, buddy-reset, buddy-status, audit-security), also add to README.md Commands section

**MISSING_FROM_DOCS (agent):**
- Add entry to the file tree section
- Add a `### Agent: agent-name` entry in the Automations section — read the agent file to write an accurate description

**MISSING_FROM_DOCS (hook):**
- Add entry to the file tree section (if it's a new script)
- Add a `### Hook: hook-name` entry in the Automations section — read the hook config to write an accurate description

**MISSING_FROM_DOCS (Swift source):**
- Add entry to the Swift source layout section with correct path and description

**STALE_IN_DOCS:**
- Remove the stale entry from the relevant section

**PATH_MISMATCH:**
- Update the path in the relevant section to match actual location

**DESCRIPTION_OUTDATED:**
- Read the actual file and update the description

### 4. Ask user to confirm descriptions

For any NEW skill or agent that needs a description added to CLAUDE.md, show the user the proposed one-line description and ask if they'd like to adjust it before applying.

### 5. Show summary

After applying fixes, show:
- Number of edits applied to CLAUDE.md
- Number of edits applied to README.md
- Suggest committing with a message like: "Update documentation to match current codebase"
