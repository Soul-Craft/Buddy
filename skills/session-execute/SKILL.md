---
name: session-execute
description: Use when transitioning from Plan Mode to code execution after a plan has been approved. Prints model/effort recommendations per component and summarizes the approved plan. Use when the user says "execute session", "start building", "plan approved", "begin implementation", or "let's code".
---

# Session Execute — Plan → Code Transition

Invoke this skill after the plan has been approved (typically via Plan Mode + ExitPlanMode or `/superpowers:write-plan`). It serves as a checkpoint that:

1. Confirms a plan exists to execute
2. Surfaces the recommended model/effort per component
3. Summarizes the approved plan for final scope confirmation
4. Transitions cleanly into coding

This skill is **advisory only**. Claude Code has no API to switch models programmatically; the user selects the model via the Desktop App dropdown. The skill gives clear guidance so the right choice is obvious.

## Step 1: Confirm a plan exists

Scan the recent conversation for a plan. Plans come from several places:

- A file under `~/.claude/plans/*.md` (from Claude Code Plan Mode)
- Output of `/superpowers:write-plan`
- A user-described specification earlier in the session

If no plan is evident, stop and suggest:
> "No plan detected. Return to Plan Mode (Opus 4.6 Max recommended) or run `/superpowers:write-plan` to design the implementation before starting."

If a plan exists, note its location (file path or turn reference) and proceed.

## Step 2: Display model/effort recommendations

Print this reference table verbatim:

```
Component Model Recommendations
═══════════════════════════════════════════════════════════
Phase         Recommended Model   Why
─────────────────────────────────────────────────────────
Planning      Opus 4.6 Max        Deep architectural reasoning
Coding        Sonnet (high)       Fast, accurate code generation
Testing       Sonnet (high)       Adequate for output parsing
─────────────────────────────────────────────────────────
Agent              Model         Configured in
─────────────────────────────────────────────────────────
comment-reviewer   haiku         agents/comment-reviewer.md
test-runner        haiku         agents/test-runner.md
token-review       haiku         .claude-plugin/agents/token-review.md
docs-reviewer      haiku         .claude-plugin/agents/docs-reviewer.md
security-reviewer  inherit       agents/security-reviewer.md
cache-analyzer     inherit       .claude-plugin/agents/cache-analyzer.md
─────────────────────────────────────────────────────────
```

The agent model fields are already configured in the agent markdown files; they run at the right model automatically. The top block is the user's choice — what model the **main** session runs at during each phase.

## Step 3: Summarize the approved plan

Restate the 3–5 key implementation targets so the user can confirm scope before coding begins. Pull these from the plan directly:
- Which files will be created
- Which files will be modified
- What verification steps will run

Keep it to a short bulleted list (≤10 bullets). If the plan is too large to summarize, show just the top-level section headers.

Then ask: **"Is this the scope you want me to implement? Reply 'yes' to proceed, or describe adjustments."**

## Step 4: Transition message

Once scope is confirmed, print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 2: Execute
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Model: switch to Sonnet (high) in the Desktop App dropdown
        if you are currently on Opus.
Next:  begin implementing the plan.
End:   run /session-end when code is ready for review.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes for future maintenance

- **This skill is purely advisory.** Do not attempt to enforce model selection — Claude Code has no API for that and the Desktop App dropdown is the right interface.
- **The agent model table is the source of truth.** If an agent's `model:` field changes in its markdown file, update the table here too. Keep them in sync.
- **Keep the plan summary short.** The user already read the plan once; this is just a scope-confirmation reminder, not a re-reading.
