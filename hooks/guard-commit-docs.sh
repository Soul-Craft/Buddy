#!/usr/bin/env bash
# guard-commit-docs.sh — Pre-commit hook that checks if code files were
# staged without corresponding documentation updates.
#
# Reads JSON tool input from stdin. If the command contains "git commit",
# checks staged files for code changes without CLAUDE.md/README.md updates.
# Outputs a systemMessage reminder if drift is detected.
#
# Always exits 0 (advisory, never blocks commits).

set -euo pipefail

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only check on git commit commands
if ! echo "$cmd" | grep -qE 'git commit'; then
  exit 0
fi

# Get staged files
staged=$(git diff --cached --name-only 2>/dev/null || true)

if [ -z "$staged" ]; then
  exit 0
fi

# Check if any code files were staged
code_changed=false
for pattern in "skills/" "agents/" ".claude-plugin/agents/" "hooks/" "scripts/"; do
  if echo "$staged" | grep -q "^${pattern}"; then
    code_changed=true
    break
  fi
done

if [ "$code_changed" = false ]; then
  exit 0
fi

# Check if docs were also staged
docs_changed=false
if echo "$staged" | grep -qE '^(CLAUDE\.md|README\.md)$'; then
  docs_changed=true
fi

if [ "$docs_changed" = false ]; then
  echo '{"systemMessage": "Code files (skills, agents, hooks, or scripts) were modified but CLAUDE.md/README.md were not updated. Consider running /sync-docs before committing to keep documentation in sync."}'
fi

exit 0
