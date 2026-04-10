#!/bin/bash
# Performance benchmarks — on-demand, NOT part of test-all.sh.
#
# Asserts on generous thresholds to catch catastrophic regressions only.
# Run manually or in scheduled CI to detect performance cliffs:
#   make test-perf
#
# Output: "Results: N passed, M failed" on the last line.
#
# Thresholds are intentionally generous to avoid false failures on slow
# machines or under load. Tighten per-benchmark if a stable baseline
# emerges (e.g., from repeated runs on a dedicated CI host).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG="$REPO_ROOT/scripts/BuddyPatcher"
BIN="$PKG/.build/release/buddy-patcher"
TEST_DIR="/tmp/buddy-perf-$$"
TEST_BIN="$TEST_DIR/claude-test"

PASSED=0
FAILED=0

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

# ── Helpers ────────────────────────────────────────────────────────

# Returns elapsed milliseconds for a command.
time_ms() {
    local start end
    start=$(python3 -c "import time; print(int(time.time()*1000))")
    "$@" >/dev/null 2>&1
    end=$(python3 -c "import time; print(int(time.time()*1000))")
    echo $((end - start))
}

assert_under_ms() {
    local name="$1"
    local threshold_ms="$2"
    local actual_ms="$3"
    if [ "$actual_ms" -lt "$threshold_ms" ]; then
        echo "  [PASS] $name — ${actual_ms}ms (threshold: ${threshold_ms}ms)"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $name — ${actual_ms}ms EXCEEDED threshold ${threshold_ms}ms"
        FAILED=$((FAILED + 1))
    fi
}

echo
echo "  Performance Benchmark Suite"
echo "  ═══════════════════════════"
echo
echo "  Note: thresholds are generous (2-4× typical time) to avoid"
echo "  false failures on loaded machines. Catastrophic regressions only."
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

# ── Benchmarks ─────────────────────────────────────────────────────

echo "  --- Startup benchmarks ---"
echo

# Perf 1: --help output (pure startup + arg parsing, no I/O)
t=$(time_ms "$BIN" --help)
assert_under_ms "--help response time" 500 "$t"

# Perf 2: --analyze (reads binary, reports patterns, no writes)
t=$(time_ms "$BIN" --analyze --binary "$TEST_BIN")
assert_under_ms "--analyze on test binary" 1000 "$t"

echo

echo "  --- Dry-run benchmarks ---"
echo

# Perf 3: single --dry-run (full patch-path code without writes)
t=$(time_ms "$BIN" --dry-run --species duck --binary "$TEST_BIN")
assert_under_ms "--dry-run species only" 1000 "$t"

# Perf 4: full --dry-run (all four patch types in one pass)
t=$(time_ms "$BIN" --dry-run \
    --species dragon --rarity legendary --shiny --emoji "🐲" \
    --binary "$TEST_BIN")
assert_under_ms "--dry-run all patch types" 1500 "$t"

echo

echo "  --- Full patch + restore benchmarks ---"
echo

# Perf 5: full patch (writes + codesign)
PATCH_BIN="$TEST_DIR/claude-patch-target"
cp "$TEST_BIN" "$PATCH_BIN"
t=$(time_ms "$BIN" --species dragon --rarity legendary --shiny \
    --binary "$PATCH_BIN")
assert_under_ms "Full patch (write + codesign)" 3000 "$t"

# Perf 6: verify patch didn't change file size (defensive check)
original_size=$(wc -c < "$TEST_BIN" | tr -d ' ')
patched_size=$(wc -c < "$PATCH_BIN" | tr -d ' ')
if [ "$original_size" -eq "$patched_size" ]; then
    echo "  [PASS] Patch preserves file size (${patched_size} bytes)"
    PASSED=$((PASSED + 1))
else
    echo "  [FAIL] Patch changed file size: ${original_size} → ${patched_size} bytes"
    FAILED=$((FAILED + 1))
fi

# Perf 7: restore (reads backup, writes binary, codesign)
t=$(time_ms "$BIN" --restore --binary "$PATCH_BIN")
assert_under_ms "Restore from backup" 2000 "$t"

echo

# ── Summary ────────────────────────────────────────────────────────

echo "Results: $PASSED passed, $FAILED failed"
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
