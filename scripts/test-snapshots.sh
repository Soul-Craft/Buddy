#!/bin/bash
# Snapshot / golden-file tests for CLI output.
#
# Verifies that buddy-patcher's output matches pinned golden files in
# scripts/BuddyPatcher/Tests/Fixtures/GoldenFiles/.
#
# Volatile output (version strings, temp paths) is normalized before
# comparison so tests are stable across environments.
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

PASSED=0
FAILED=0

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

# ── Normalization ──────────────────────────────────────────────────
#
# Replace all volatile fields with stable placeholders:
#   <VERSION>  — semver strings (2.0.0)
#   <TMPDIR>   — macOS/Linux temp directory paths

normalize() {
    sed -E \
        -e 's/v[0-9]+\.[0-9]+\.[0-9]+/<VERSION>/g' \
        -e 's/[0-9]+\.[0-9]+\.[0-9]+/<VERSION>/g' \
        -e 's#/var/folders/[^ ]*#<TMPDIR>#g' \
        -e 's#/tmp/[^ ]*#<TMPDIR>#g'
}

# ── Golden file checker ────────────────────────────────────────────
#
# Runs a command, normalizes stdout+stderr, then either:
#   UPDATE_MODE=1: writes to the golden file (regen mode)
#   UPDATE_MODE=0: diffs against existing golden file (test mode)

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
    "$BIN"
echo

echo "  --- Error: invalid species ---"
check_golden "error-invalid-species.txt" \
    "$BIN" --meta-species unicorn
echo

echo "  --- Error: invalid rarity ---"
check_golden "error-invalid-rarity.txt" \
    "$BIN" --meta-rarity mythic
echo

echo "  --- Error: invalid emoji ---"
check_golden "error-invalid-emoji.txt" \
    "$BIN" --meta-emoji "AB" --dry-run
echo

echo "  --- Dry-run full output ---"
check_golden "dry-run-full.txt" \
    "$BIN" --meta-species dragon --meta-rarity legendary --meta-shiny \
           --meta-emoji "🐲" --dry-run
echo

# ── Summary ────────────────────────────────────────────────────────

echo "Results: $PASSED passed, $FAILED failed"
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
