#!/bin/bash
# Smoke test suite — catches obvious breakage in <30s.
#
# Runs as the FIRST tier in test-all.sh. If the build is broken or the
# CLI contract is violated, we stop before the expensive tiers waste time.
#
# Tests fall into three groups:
#   1. Build sanity     — binary exists, is Mach-O, codesigns clean
#   2. CLI contract     — --help works, no-args fails, valid dry-run succeeds
#   3. Validation       — invalid inputs fail fast at exit(1)
#
# Output format matches test-all.sh's parser: "Results: N passed, M failed"
# on the last line.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG="$REPO_ROOT/scripts/BuddyPatcher"
BIN="$PKG/.build/release/buddy-patcher"
TEST_DIR="/tmp/buddy-smoke-$$"
TEST_BIN="$TEST_DIR/claude-test"

PASSED=0
FAILED=0

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

# ── Helpers ────────────────────────────────────────────────────────

# Run a command, assert its exit code matches expected.
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

# Run a command and grep stdout/stderr for a required substring.
assert_contains() {
    local description="$1"
    local needle="$2"
    shift 2
    local output
    output=$("$@" 2>&1 || true)
    if echo "$output" | grep -q -F "$needle"; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description (missing: '$needle')"
        FAILED=$((FAILED + 1))
    fi
}

# Assert a file exists and is executable.
assert_executable() {
    local description="$1"
    local path="$2"
    if [ -x "$path" ]; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description (not executable: $path)"
        FAILED=$((FAILED + 1))
    fi
}

# Assert file(1) output contains a substring.
assert_file_type() {
    local description="$1"
    local path="$2"
    local needle="$3"
    local out
    out=$(file "$path" 2>&1 || true)
    if echo "$out" | grep -q -F "$needle"; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description (file reports: $out)"
        FAILED=$((FAILED + 1))
    fi
}

echo
echo "  Smoke Test Suite"
echo "  ════════════════"
echo

# ── Build if needed ────────────────────────────────────────────────
if [ ! -f "$BIN" ]; then
    echo "  Building buddy-patcher..."
    swift build -c release --package-path "$PKG" 2>&1 | tail -3
    echo
fi

# ── Generate isolated test binary ──────────────────────────────────
# build-test-binary.sh accepts an output path; give it a per-run dir so
# parallel runs don't race.
mkdir -p "$TEST_DIR"
if ! bash "$REPO_ROOT/scripts/build-test-binary.sh" "$TEST_BIN" >/dev/null 2>&1; then
    echo "  [!] Failed to build test binary — aborting smoke tests"
    echo
    echo "Results: 0 passed, 1 failed"
    exit 1
fi

# ── Group 1: Build sanity ─────────────────────────────────────────
echo "  --- Build sanity ---"
echo

assert_executable "buddy-patcher binary exists and is executable" "$BIN"
assert_file_type "binary is Mach-O 64-bit executable" "$BIN" "Mach-O 64-bit executable"
assert_exit "codesign -v passes on built binary" 0 codesign -v "$BIN"
assert_file_type "test binary is Mach-O 64-bit executable" "$TEST_BIN" "Mach-O 64-bit executable"

echo

# ── Group 2: Basic CLI contract ───────────────────────────────────
echo "  --- CLI contract ---"
echo

assert_contains "--help prints USAGE header" "USAGE:" "$BIN" --help
assert_contains "-h prints USAGE header" "USAGE:" "$BIN" -h
assert_exit "--help exits 0" 0 "$BIN" --help
assert_exit "no args (no --binary) exits non-zero" 1 "$BIN"
assert_exit "--dry-run --species duck --binary <test> exits 0" 0 \
    "$BIN" --dry-run --species duck --binary "$TEST_BIN"

echo

# ── Group 3: Validation fast-fail ─────────────────────────────────
echo "  --- Validation fast-fail ---"
echo

# Invalid species is rejected at parse time (before any filesystem touch).
assert_exit "invalid species rejected" 1 \
    "$BIN" --species unicorn --binary "$TEST_BIN" --dry-run
assert_exit "invalid rarity rejected" 1 \
    "$BIN" --rarity mythic --binary "$TEST_BIN" --dry-run
# Multi-char emoji rejected by validateEmoji after parsing.
assert_exit "multi-char emoji rejected" 1 \
    "$BIN" --species duck --emoji "AB" --binary "$TEST_BIN" --dry-run
# Non-Mach-O file rejected by validateBinaryPath.
assert_exit "non-Mach-O binary path rejected" 1 \
    "$BIN" --binary /etc/hosts --analyze

echo

# ── Summary ───────────────────────────────────────────────────────
echo "Results: $PASSED passed, $FAILED failed"
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
