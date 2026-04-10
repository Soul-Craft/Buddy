#!/bin/bash
# Snapshot / golden-file tests for CLI output.
#
# Verifies that buddy-patcher's output matches pinned golden files in
# scripts/BuddyPatcher/Tests/Fixtures/GoldenFiles/.
#
# Volatile output (version strings, temp paths, byte counts) is
# normalized before comparison so tests are stable across environments.
#
# Usage:
#   bash scripts/test-snapshots.sh             # compare against golden files
#   UPDATE_GOLDEN=1 bash scripts/test-snapshots.sh  # regenerate golden files
#
# Output format: "Results: N passed, M failed" on the last line.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG="$REPO_ROOT/scripts/BuddyPatcher"
BIN="$PKG/.build/release/buddy-patcher"
GOLDEN_DIR="$PKG/Tests/Fixtures/GoldenFiles"
UPDATE_MODE="${UPDATE_GOLDEN:-0}"
TEST_DIR="/tmp/buddy-snap-$$"
TEST_BIN="$TEST_DIR/claude-test"

PASSED=0
FAILED=0

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

echo
echo "  Snapshot Test Suite"
echo "  ═══════════════════"
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
    echo "  [!] Failed to build test binary — aborting snapshot tests"
    echo
    echo "Results: 0 passed, 1 failed"
    exit 1
fi

# ── Normalization ──────────────────────────────────────────────────
#
# Replace all volatile fields with stable placeholders:
#   <VERSION>  — semver strings (v1.0.0)
#   <TESTBIN>  — full path to the runtime-generated test binary
#   <TMPDIR>   — macOS/Linux temp directory paths
#   <SIZE>     — file size in bytes (varies if test binary source changes)
#   <OFFSET>   — hex offsets from --analyze output

normalize() {
    sed -E \
        -e 's/v[0-9]+\.[0-9]+\.[0-9]+/<VERSION>/g' \
        -e "s#$TEST_BIN#<TESTBIN>#g" \
        -e 's#/var/folders/[^ ]*#<TMPDIR>#g' \
        -e 's#/tmp/[^ ]*#<TMPDIR>#g' \
        -e 's/[0-9,]+ bytes/<SIZE> bytes/g' \
        -e 's/0x[0-9a-fA-F]+/<OFFSET>/g'
}

# ── Golden file checker ────────────────────────────────────────────
#
# Runs a command, normalizes stdout+stderr, then either:
#   UPDATE_MODE=1: writes to the golden file (regen mode)
#   UPDATE_MODE=0: diffs against existing golden file (test mode)
#
# The command is always run regardless of expected exit code; errors
# are captured in the output, not treated as test failures themselves.

check_golden() {
    local name="$1"
    shift
    local golden="$GOLDEN_DIR/$name"
    local actual
    actual=$("$@" 2>&1 | normalize || true)

    if [ "$UPDATE_MODE" = "1" ]; then
        mkdir -p "$GOLDEN_DIR"
        printf '%s\n' "$actual" > "$golden"
        echo "  [UPDATED] $name"
        PASSED=$((PASSED + 1))
        return
    fi

    if [ ! -f "$golden" ]; then
        echo "  [FAIL] $name — no golden file (run UPDATE_GOLDEN=1 to create)"
        FAILED=$((FAILED + 1))
        return
    fi

    local expected
    expected=$(cat "$golden")

    if [ "$actual" = "$expected" ]; then
        echo "  [PASS] $name"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $name — output diverged from golden"
        diff <(printf '%s\n' "$actual") <(printf '%s\n' "$expected") | head -20 | sed 's/^/    /'
        FAILED=$((FAILED + 1))
    fi
}

# ── Test cases ─────────────────────────────────────────────────────

echo "  --- Help output ---"
check_golden "help-output.txt" \
    "$BIN" --help
echo

echo "  --- Error: no action flags ---"
check_golden "error-no-args.txt" \
    "$BIN" --binary "$TEST_BIN"
echo

echo "  --- Error: invalid species ---"
check_golden "error-invalid-species.txt" \
    "$BIN" --species unicorn --binary "$TEST_BIN"
echo

echo "  --- Error: invalid rarity ---"
check_golden "error-invalid-rarity.txt" \
    "$BIN" --rarity mythic --binary "$TEST_BIN"
echo

echo "  --- Error: invalid emoji ---"
check_golden "error-invalid-emoji.txt" \
    "$BIN" --species duck --emoji "AB" --binary "$TEST_BIN" --dry-run
echo

echo "  --- Dry-run full output ---"
check_golden "dry-run-full.txt" \
    "$BIN" --species dragon --rarity legendary --shiny --emoji "🐲" \
           --dry-run --binary "$TEST_BIN"
echo

# ── Summary ────────────────────────────────────────────────────────

echo "Results: $PASSED passed, $FAILED failed"
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
