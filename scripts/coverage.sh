#!/bin/bash
# Local code coverage report generator.
#
# Runs swift test with coverage enabled and generates an HTML report at
# test-results/coverage/index.html. Open it in a browser to explore line-by-line
# coverage for all BuddyPatcherLib sources.
#
# Usage:
#   make coverage
#   open test-results/coverage/index.html
#
# Notes:
#   - Local only — no CI integration, no Codecov, no secrets required.
#   - Coverage data is written under scripts/BuddyPatcher/.build/ (gitignored).
#   - The HTML report is written to test-results/coverage/ (also gitignored).
#   - Re-running this script overwrites the previous report.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG="$REPO_ROOT/scripts/BuddyPatcher"
OUT="$REPO_ROOT/test-results/coverage"

echo
echo "  Coverage Report"
echo "  ═══════════════"
echo

mkdir -p "$OUT"

# ── 1. Run swift test with coverage profiling ──────────────────────

echo "  Running swift test with --enable-code-coverage..."
if ! swift test --package-path "$PKG" --enable-code-coverage 2>&1 | tail -5; then
    echo
    echo "  [!] Tests failed — coverage report not generated"
    exit 1
fi
echo

# ── 2. Locate coverage artifacts ──────────────────────────────────

# SPM writes .profdata under .build/debug/codecov/ or .build/arm64-apple-macosx/debug/
PROFDATA=$(find "$PKG/.build" -name "default.profdata" -not -path "*/__build/*" | head -1)

if [ -z "$PROFDATA" ] || [ ! -f "$PROFDATA" ]; then
    echo "  [!] Could not locate default.profdata under $PKG/.build"
    echo "      Tried: $(find "$PKG/.build" -name '*.profdata' 2>/dev/null | head -5)"
    exit 1
fi
echo "  Profdata: $PROFDATA"

# The test binary that has the instrumented code
TEST_BIN=$(find "$PKG/.build" \
    \( -name "BuddyPatcherPackageTests.xctest" -o -name "BuddyPatcherPackageTests" \) \
    -not -path "*/__build/*" | head -1)

if [ -z "$TEST_BIN" ]; then
    echo "  [!] Could not locate test binary under $PKG/.build"
    exit 1
fi

# On macOS, XCTest bundles have a binary inside Contents/MacOS/
if [ -d "$TEST_BIN" ]; then
    BINARY_PATH="$TEST_BIN/Contents/MacOS/$(basename "$TEST_BIN" .xctest)"
else
    BINARY_PATH="$TEST_BIN"
fi

if [ ! -f "$BINARY_PATH" ]; then
    echo "  [!] Test binary not found at expected path: $BINARY_PATH"
    exit 1
fi
echo "  Test binary: $BINARY_PATH"
echo

# ── 3. Generate text summary ───────────────────────────────────────

echo "  Generating coverage summary..."
xcrun llvm-cov report "$BINARY_PATH" \
    -instr-profile="$PROFDATA" \
    -ignore-filename-regex=".build|Tests" \
    > "$OUT/summary.txt" 2>&1 || {
    echo "  [!] llvm-cov report failed — xcrun llvm-cov may not be available"
    exit 1
}

# ── 4. Generate HTML report ────────────────────────────────────────

echo "  Generating HTML report..."
xcrun llvm-cov show "$BINARY_PATH" \
    -instr-profile="$PROFDATA" \
    -ignore-filename-regex=".build|Tests" \
    -format=html \
    -output-dir="$OUT" \
    > /dev/null 2>&1 || {
    echo "  [!] llvm-cov show failed"
    exit 1
}

# ── 5. Print summary ───────────────────────────────────────────────

echo
echo "  Coverage Summary:"
echo "  ─────────────────────────────────────────────────────"
tail -n +3 "$OUT/summary.txt" | head -30 | sed 's/^/  /'
echo
echo "  Full report: $OUT/index.html"
echo "  Summary:     $OUT/summary.txt"
echo
echo "  Run: open \"$OUT/index.html\""
