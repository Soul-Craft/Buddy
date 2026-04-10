#!/bin/bash
# Compatibility tests — verifies knownVarMaps entries are internally consistent.
#
# NOT part of test-all.sh. Run on-demand after Claude Code updates:
#   make test-compat
#
# Unlike integration tests, this script does NOT patch anything. It uses
# --dry-run and --analyze to verify that every knownVarMap entry can locate
# its anchor in the test binary and that all 18 species variables are present.
#
# Output: "Results: N passed, M failed" on the last line.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG="$REPO_ROOT/scripts/BuddyPatcher"
BIN="$PKG/.build/release/buddy-patcher"
TEST_DIR="/tmp/buddy-compat-$$"
TEST_BIN="$TEST_DIR/claude-test"

PASSED=0
FAILED=0

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

# ── Helpers ────────────────────────────────────────────────────────

assert_exit() {
    local description="$1"
    local expected="$2"
    shift 2
    "$@" >/dev/null 2>&1
    local actual=$?
    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description (expected exit $expected, got $actual)"
        FAILED=$((FAILED + 1))
    fi
}

assert_contains() {
    local description="$1"
    local needle="$2"
    shift 2
    local output
    output=$("$@" 2>&1 || true)
    if echo "$output" | grep -qF "$needle"; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description (missing: '$needle')"
        echo "  output was: $(echo "$output" | head -5)"
        FAILED=$((FAILED + 1))
    fi
}

echo
echo "  Compatibility Test Suite"
echo "  ════════════════════════"
echo
echo "  Purpose: verify knownVarMaps anchor patterns work against the"
echo "  current test binary. Run after Claude Code updates if --analyze"
echo "  or --dry-run starts failing."
echo

# ── Build binary if needed ─────────────────────────────────────────

if [ ! -f "$BIN" ]; then
    echo "  Building buddy-patcher..."
    swift build -c release --package-path "$PKG" 2>&1 | tail -3
    echo
fi

# ── Build test binary ──────────────────────────────────────────────

mkdir -p "$TEST_DIR"
if ! bash "$REPO_ROOT/scripts/build-test-binary.sh" "$TEST_BIN" >/dev/null 2>&1; then
    echo "  [!] Failed to build test binary — aborting"
    echo
    echo "Results: 0 passed, 1 failed"
    exit 1
fi

# ── Group 1: Basic binary analysis ────────────────────────────────

echo "  --- Group 1: Basic binary analysis ---"
echo

assert_exit "--analyze exits 0 on test binary" 0 \
    "$BIN" --analyze --binary "$TEST_BIN"

assert_contains "--analyze reports detected variable format" "GL_" \
    "$BIN" --analyze --binary "$TEST_BIN"

assert_contains "--analyze reports anchor pattern" "GL_,ZL_,LL_,kL_," \
    "$BIN" --analyze --binary "$TEST_BIN"

echo

# ── Group 2: Dry-run for each patch type ──────────────────────────

echo "  --- Group 2: Dry-run patch types ---"
echo

assert_exit "--dry-run species exits 0" 0 \
    "$BIN" --dry-run --species duck --binary "$TEST_BIN"

assert_contains "--dry-run species reports correct var" "vL_" \
    "$BIN" --dry-run --species dragon --binary "$TEST_BIN"

assert_exit "--dry-run rarity exits 0" 0 \
    "$BIN" --dry-run --rarity legendary --binary "$TEST_BIN"

assert_contains "--dry-run rarity mentions legendary" "legendary" \
    "$BIN" --dry-run --rarity legendary --binary "$TEST_BIN"

assert_exit "--dry-run shiny exits 0" 0 \
    "$BIN" --dry-run --shiny --binary "$TEST_BIN"

assert_contains "--dry-run shiny mentions 'shiny'" "shiny" \
    "$BIN" --dry-run --shiny --binary "$TEST_BIN"

echo

# ── Group 3: knownVarMaps consistency ─────────────────────────────
#
# Verify that VariableMapDetection.swift's 18-species list is complete
# by checking each known species can be dry-run patched.

echo "  --- Group 3: All 18 species patchable ---"
echo

SPECIES="duck goose blob cat dragon octopus owl penguin turtle snail axolotl ghost robot mushroom cactus rabbit chonk capybara"
for species in $SPECIES; do
    assert_exit "--dry-run --species $species exits 0" 0 \
        "$BIN" --dry-run --species "$species" --binary "$TEST_BIN"
done

echo

# ── Summary ────────────────────────────────────────────────────────

echo "Results: $PASSED passed, $FAILED failed"
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
