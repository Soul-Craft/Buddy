---
name: start-session
description: Use when starting a dev session on Buddy Evolver, or to refresh project context. Use when the user says "start session", "refresh context", "what tools do I have", or "session status".
---

# Start Session — Dev Context Refresh

Manual re-trigger of the SessionStart hook. Use this when the original hook output has scrolled out of context, or when you want a fresh snapshot of project state (binary status, git state, skills, agents, hooks, compatibility).

The SessionStart hook at `hooks/session-start.sh` is the single source of truth for session context. This skill delegates to it so there is no hardcoded list to drift.

## Step 1: Run the hook

```bash
CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" bash "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
```

Present the output verbatim to the user inside a code block.

## Step 2: Highlight warnings (if any)

Scan the hook output for these markers and, if present, surface them above the verbatim output as a short "Action needed" header:

- `⚠ STALE` in the Main line → recommend: `git pull --rebase origin main` or rebase the branch
- `backup_status: no backup` → recommend: evolve first before reset operations
- `Pending cleanup:` line with non-zero `failed` count → note that retry happens on next session

## Step 3: Offer next action (optional)

If everything is healthy, end with:
"You are in **Phase 1 (Plan)**. Describe what you want to build, and I will design the implementation plan before writing any code. Run `/session-execute` when the plan is approved."

If warnings were surfaced, ask whether the user wants to address them now or defer.

## Notes

- This skill should stay minimal. All discovery logic lives in `hooks/session-start.sh`.
- If you want to add or remove things from the session context, edit the hook, not this skill.
- The hook targets ≤60 lines of output and ≤10s runtime (typically <2s on cached fetches).
