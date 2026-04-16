#!/bin/bash
# Security validation test suite for buddy-patcher.
# Tests input validation, hook validation, and basic integrity checks.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$SCRIPT_DIR/BuddyPatcher/.build/release/buddy-patcher"
HOOK="$SCRIPT_DIR/../hooks/guard-patcher-args.sh"
PASS=0
FAIL=0

run_test() {
  local description="$1"
  local expected_exit="$2"
  shift 2

  "$@" >/dev/null 2>&1
  local actual_exit=$?

  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "  [PASS] $description"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $description (expected exit $expected_exit, got $actual_exit)"
    FAIL=$((FAIL + 1))
  fi
}

run_hook_test() {
  local description="$1"
  local expected_exit="$2"
  local json_input="$3"

  echo "$json_input" | bash "$HOOK" >/dev/null 2>&1
  local actual_exit=$?

  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "  [PASS] $description"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $description (expected exit $expected_exit, got $actual_exit)"
    FAIL=$((FAIL + 1))
  fi
}

# ── Build if needed ────────────────────────────────────────────────
if [ ! -f "$BIN" ]; then
  echo "  Building buddy-patcher..."
  swift build -c release --package-path "$SCRIPT_DIR/BuddyPatcher" 2>&1 | tail -3
fi

echo
echo "  Security Test Suite"
echo "  ═══════════════════"
echo

# ── Swift-level input validation ───────────────────────────────────
echo "  --- Input Validation (Swift binary) ---"
echo

# Emoji validation
run_test "Reject multi-char emoji" 1 "$BIN" --meta-emoji "AB" --dry-run
run_test "Reject ASCII letter as emoji" 1 "$BIN" --meta-emoji "X" --dry-run
run_test "Reject long string as emoji" 1 "$BIN" --meta-emoji "hello world" --dry-run
run_test "Accept valid single emoji" 0 "$BIN" --meta-emoji "🔥" --dry-run
run_test "Accept complex emoji (flag)" 0 "$BIN" --meta-emoji "🇺🇸" --dry-run

echo

# Name validation
run_test "Reject empty name" 1 "$BIN" --name "" --dry-run
LONG_NAME=$(python3 -c "print('A' * 200)")
run_test "Reject name over 100 chars" 1 "$BIN" --name "$LONG_NAME" --dry-run
run_test "Accept valid name" 0 "$BIN" --name "Flamey" --dry-run

echo

# Personality validation
run_test "Reject empty personality" 1 "$BIN" --personality "" --dry-run
LONG_PERS=$(python3 -c "print('B' * 600)")
run_test "Reject personality over 500 chars" 1 "$BIN" --personality "$LONG_PERS" --dry-run
run_test "Accept valid personality" 0 "$BIN" --personality "A fiery friend who loves warmth" --dry-run

echo

# Stats validation
run_test "Reject unknown stat key" 1 "$BIN" --meta-stats '{"hacking":99}' --dry-run
run_test "Reject stat value over 100" 1 "$BIN" --meta-stats '{"debugging":999}' --dry-run
run_test "Reject stat negative value" 1 "$BIN" --meta-stats '{"chaos":-5}' --dry-run
run_test "Reject invalid JSON" 1 "$BIN" --meta-stats 'not json' --dry-run
run_test "Accept valid stats" 0 "$BIN" --meta-stats '{"debugging":80,"chaos":50}' --dry-run

echo

# Combined valid run
run_test "Full valid dry-run" 0 "$BIN" \
  --meta-species dragon --meta-rarity legendary --meta-shiny \
  --meta-emoji "🐲" --name "Drake" --personality "Fierce and loyal" \
  --meta-stats '{"debugging":99,"chaos":75}' --dry-run

echo

# ── Hook validation ────────────────────────────────────────────────
if [ -f "$HOOK" ]; then
  echo "  --- Hook Validation (guard-patcher-args.sh) ---"
  echo

  # Non-patcher commands pass through
  run_hook_test "Pass non-patcher command" 0 '{"command": "ls -la"}'
  run_hook_test "Pass unrelated bash command" 0 '{"command": "git status"}'

  # Valid patcher commands pass
  run_hook_test "Pass valid patcher command" 0 '{"command": "buddy-patcher --meta-emoji \"🔥\" --dry-run"}'

  # Shell metacharacters blocked
  run_hook_test "Block semicolon in emoji" 2 '{"command": "buddy-patcher --meta-emoji \"X;rm -rf /\" --meta-species duck"}'
  run_hook_test "Block pipe in name" 2 '{"command": "buddy-patcher --name \"test|cat /etc/passwd\" --dry-run"}'
  run_hook_test "Block dollar in personality" 2 '{"command": "buddy-patcher --personality \"$(whoami)\" --dry-run"}'
  run_hook_test "Block backtick in name (unquoted)" 2 '{"command": "buddy-patcher --name `id` --dry-run"}'

  # Length limits
  LONG_HOOK_NAME=$(python3 -c "print('A' * 150)")
  run_hook_test "Block long name in hook" 2 "{\"command\": \"buddy-patcher --name \\\"$LONG_HOOK_NAME\\\" --dry-run\"}"

  echo
else
  echo "  [SKIP] Hook script not found at $HOOK"
  echo
fi

# ── Summary ────────────────────────────────────────────────────────
echo "  ═══════════════════"
TOTAL=$((PASS + FAIL))
echo "  Results: $PASS/$TOTAL passed"
if [ "$FAIL" -gt 0 ]; then
  echo "  $FAIL FAILURES"
  exit 1
else
  echo "  ALL PASSED"
  exit 0
fi
