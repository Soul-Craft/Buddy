#!/bin/bash
# Smoke test suite — catches obvious breakage in <30s.
#
# Runs as the FIRST tier in test-all.sh. If the build is broken or the
# CLI contract is violated, we stop before the expensive tiers waste time.
#
# Tests fall into three groups:
#   1. Build sanity     — binary exists, is Mach-O, codesigns clean
#   2. CLI contract     — --help, --version, no-args fails, valid dry-run succeeds
#   3. Validation       — invalid inputs fail fast at exit(1)
#
# Output format matches test-all.sh's parser: "Results: N passed, M failed"
# on the last line.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG="$REPO_ROOT/scripts/BuddyPatcher"
BIN="$PKG/.build/release/buddy-patcher"

PASSED=0
FAILED=0

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

# ── Group 1: Build sanity ─────────────────────────────────────────
echo "  --- Build sanity ---"
echo

assert_executable "buddy-patcher binary exists and is executable" "$BIN"
assert_file_type "binary is Mach-O 64-bit executable" "$BIN" "Mach-O 64-bit executable"
assert_exit "codesign -v passes on built binary" 0 codesign -v "$BIN"

echo

# ── Group 2: Basic CLI contract ───────────────────────────────────
echo "  --- CLI contract ---"
echo

assert_contains "--help prints USAGE header" "USAGE:" "$BIN" --help
assert_contains "-h prints USAGE header" "USAGE:" "$BIN" -h
assert_exit "--help exits 0" 0 "$BIN" --help
assert_exit "--version exits 0" 0 "$BIN" --version
assert_exit "no args exits non-zero" 1 "$BIN"
assert_exit "--dry-run --meta-species duck exits 0" 0 \
    "$BIN" --dry-run --meta-species duck

echo

# ── Group 3: Validation fast-fail ─────────────────────────────────
echo "  --- Validation fast-fail ---"
echo

assert_exit "invalid species rejected" 1 \
    "$BIN" --meta-species unicorn --dry-run
assert_exit "invalid rarity rejected" 1 \
    "$BIN" --meta-rarity mythic --dry-run
assert_exit "multi-char emoji rejected" 1 \
    "$BIN" --meta-emoji "AB" --dry-run
assert_exit "--dry-run --name exits 0" 0 \
    "$BIN" --name "Test" --dry-run

echo

# ── Summary ───────────────────────────────────────────────────────
echo "Results: $PASSED passed, $FAILED failed"
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
