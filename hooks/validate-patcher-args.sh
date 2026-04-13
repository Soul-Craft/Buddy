#!/bin/bash
# Security hook: validates buddy-patcher arguments before shell execution.
# Intercepts Bash tool calls and checks for dangerous inputs.
set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract the command field from JSON
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" 2>/dev/null || echo "")

# Only validate buddy-patcher invocations
if [[ "$COMMAND" != *"buddy-patcher"* ]] && [[ "$COMMAND" != *"run-buddy-patcher.sh"* ]]; then
  exit 0
fi

# ── Shell metacharacter check ──────────────────────────────────────
# These characters could enable command injection if interpolated unsafely.
# shellcheck disable=SC2034  # documents what check_metachar guards against
DANGEROUS_CHARS=';|&$`'

check_metachar() {
  local label="$1"
  local value="$2"
  local max_len="$3"

  # Check for shell metacharacters using python for reliable detection
  if python3 -c "
import sys
dangerous = set(';|&\$\`')
if any(c in dangerous for c in sys.argv[1]):
    sys.exit(1)
sys.exit(0)
" "$value" 2>/dev/null; then
    : # clean
  else
    echo "{\"decision\": \"deny\", \"reason\": \"$label contains shell metacharacter — potential injection\"}" >&2
    exit 2
  fi

  # Check length
  if [ "${#value}" -gt "$max_len" ]; then
    echo "{\"decision\": \"deny\", \"reason\": \"$label too long (${#value} chars, max $max_len)\"}" >&2
    exit 2
  fi
}

# ── Whole-command metacharacter scan ───────────────────────────────
# Quick scan of the entire command for backticks and $() subshells
# that could execute arbitrary code regardless of argument position.
if python3 -c "
import sys
cmd = sys.argv[1]
if '\`' in cmd or '\$(' in cmd:
    sys.exit(1)
sys.exit(0)
" "$COMMAND" 2>/dev/null; then
  : # clean
else
  echo '{"decision": "deny", "reason": "Command contains backtick or subshell — potential injection"}' >&2
  exit 2
fi

# ── Extract and validate arguments ─────────────────────────────────

# Extract --meta-emoji value (between quotes after --meta-emoji)
EMOJI=$(echo "$COMMAND" | python3 -c "
import sys, re
cmd = sys.stdin.read()
m = re.search(r'--meta-emoji\s+\"([^\"]*?)\"', cmd) or re.search(r'--meta-emoji\s+(\S+)', cmd)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")

if [ -n "$EMOJI" ]; then
  check_metachar "--meta-emoji" "$EMOJI" 20
  # Check grapheme cluster count (should be 1 emoji)
  GRAPHEME_COUNT=$(python3 -c "
import unicodedata, sys
e = sys.argv[1]
# Count grapheme clusters using text segmentation heuristic
print(len(e))
" "$EMOJI" 2>/dev/null || echo "0")
  if [ "$GRAPHEME_COUNT" -gt 2 ]; then
    echo "{\"decision\": \"deny\", \"reason\": \"--meta-emoji should be a single emoji, got $GRAPHEME_COUNT characters\"}" >&2
    exit 2
  fi
fi

# Extract --name value
NAME=$(echo "$COMMAND" | python3 -c "
import sys, re
cmd = sys.stdin.read()
m = re.search(r'--name\s+\"([^\"]*?)\"', cmd) or re.search(r'--name\s+(\S+)', cmd)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")

if [ -n "$NAME" ]; then
  check_metachar "--name" "$NAME" 100
fi

# Extract --personality value
PERSONALITY=$(echo "$COMMAND" | python3 -c "
import sys, re
cmd = sys.stdin.read()
m = re.search(r'--personality\s+\"([^\"]*?)\"', cmd) or re.search(r'--personality\s+(\S+)', cmd)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")

if [ -n "$PERSONALITY" ]; then
  check_metachar "--personality" "$PERSONALITY" 500
fi

# All checks passed
exit 0
