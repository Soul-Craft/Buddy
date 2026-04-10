#!/bin/bash
# Context-aware pre-commit test reminder.
#
# Fires on Bash tool calls containing "git commit". Checks which files are
# staged and only reminds about the tiers relevant to those changes.
#
# Output: a single JSON {"systemMessage": "..."} line, or nothing if no
# reminders apply. Always exits 0 — never blocks the commit.
set -uo pipefail

input=$(cat)
cmd=$(echo "$input" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || true)

# Only fire on git commit commands
if ! echo "$cmd" | grep -qE 'git commit'; then
    exit 0
fi

# Resolve repo root from CLAUDE_PLUGIN_ROOT if set, else use git
REPO="${CLAUDE_PLUGIN_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Get staged files
staged=$(git -C "$REPO" diff --cached --name-only 2>/dev/null || true)
[ -z "$staged" ] && exit 0

reminders=()

# Swift source or tests changed → run swift test
if echo "$staged" | grep -qE '^scripts/BuddyPatcher/(Sources|Tests)/.*\.swift$'; then
    reminders+=("make test — Swift source changed (178 unit tests)")
fi

# Security-sensitive code changed → run test-security too
if echo "$staged" | grep -qE '(Validation\.swift|validate-patcher-args\.sh|test-security\.sh)'; then
    reminders+=("make test-security — security-sensitive code changed (27 tests)")
fi

# Shell scripts changed → lint
if echo "$staged" | grep -qE '\.sh$'; then
    reminders+=("make lint — shell scripts changed")
fi

# Docs changed → test-docs
if echo "$staged" | grep -qE '\.(md)$' && ! echo "$staged" | grep -qE '^CHANGELOG'; then
    reminders+=("make test-docs — documentation changed (14 tests)")
fi

# Patch logic or species maps changed → also run test-compat
if echo "$staged" | grep -qE '(PatchEngine\.swift|VariableMapDetection\.swift|knownVarMaps)'; then
    reminders+=("make test-compat — patch patterns changed (27 on-demand compat tests)")
fi

# Skill or agent files changed → check frontmatter and sync docs
if echo "$staged" | grep -qE '^(skills|agents)/'; then
    reminders+=("consider /sync-docs — skills or agents changed")
fi

# CLI output changed → snapshots may need regeneration
if echo "$staged" | grep -qE '(ArgumentParsing\.swift|main\.swift)'; then
    reminders+=("make test-snapshots — CLI output may have changed (or UPDATE_GOLDEN=1 make test-snapshots to regenerate)")
fi

[ ${#reminders[@]} -eq 0 ] && exit 0

# Build the reminder message
msg="Before committing, consider running:"
for r in "${reminders[@]}"; do
    msg="$msg\n  • $r"
done

python3 -c "
import json, sys
print(json.dumps({'systemMessage': sys.argv[1]}))
" "$msg"
