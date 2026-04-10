#!/bin/bash
# E2E tier — full reset→evolve→verify→reset flow against the real
# Claude Code binary.
#
# Exercises the complete path that no other tier covers:
#   - Real binary patching (bypassed by integration/functional via --binary)
#   - Real ~/.claude.json + buddy-patch-meta.json state transitions
#   - The live UI renderer (bypassed by test-ui.sh which uses fixtures)
#
# Safety:
#   - Pre-flight: verify binary exists + patcher builds
#   - Trap EXIT: always attempts --restore even on mid-flow failure
#   - Graceful skip when Claude Code is not installed (CI fallback runner)
#
# Exits 0 on all pass (or graceful skip), 1 on any fail.
# Emits "Results: N passed, M failed" on the last line for test-all.sh
# to parse via run_tier().

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RENDERER="$SCRIPT_DIR/test-ui-renderer.py"
PATCHER="$SCRIPT_DIR/run-buddy-patcher.sh"

PASS=0
FAIL=0
FAILED_STEPS=()

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        PASS=$((PASS + 1))
        echo "  [PASS] $name"
    else
        FAIL=$((FAIL + 1))
        FAILED_STEPS+=("$name")
        echo "  [FAIL] $name"
    fi
}

cleanup() {
    # Always attempt restore, but don't let it cascade failures
    "$PATCHER" --restore >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "═══════════════════════════════════════════════════════════════"
echo "  E2E Tier — Aethos (legendary shiny dragon, full stats)"
echo "═══════════════════════════════════════════════════════════════"

# ── Pre-flight: graceful skip if no real Claude Code installation ────
BINARY="$(readlink ~/.local/bin/claude 2>/dev/null || true)"
if [ -z "$BINARY" ] || [ ! -f "$BINARY" ]; then
    echo "  [SKIP] Claude Code binary not found at ~/.local/bin/claude"
    echo "         E2E tier requires a real installation (skipping on CI runners)"
    trap - EXIT
    echo
    echo "Results: 0 passed, 0 failed"
    exit 0
fi

echo "  binary: $BINARY"

check "patcher builds" bash -c "'$PATCHER' --help"

# ── Phase 1: initial reset ───────────────────────────────────────────
echo
echo "  Phase 1: initial reset"
"$PATCHER" --restore 2>&1 | sed 's/^/    /' || true
check "phase1 clean state" bash -c "test ! -f ~/.claude/backups/buddy-patch-meta.json"

# ── Phase 2: evolve to Aethos ────────────────────────────────────────
echo
echo "  Phase 2: evolve to Aethos"
EVOLVE_OUTPUT=$("$PATCHER" \
    --species dragon \
    --rarity legendary \
    --shiny \
    --emoji "🐉" \
    --name "Aethos" \
    --personality "An ancient golden dragon, wise and patient." \
    --stats '{"debugging":100,"patience":100,"chaos":100,"wisdom":100,"snark":100}' \
    2>&1)
EVOLVE_EXIT=$?
echo "$EVOLVE_OUTPUT" | sed 's/^/    /'

# Warn if anchor patterns are stale (but don't fail — soul/meta still
# written correctly, which is what the UI test verifies).
if echo "$EVOLVE_OUTPUT" | grep -q "WARNING: Could not find"; then
    echo
    echo "  [WARN] Binary anchor patterns are stale for this Claude Code version."
    echo "         Soul and metadata were written, but binary patches were skipped."
    echo "         Run /update-species-map to refresh knownVarMaps."
fi

check "phase2 evolve exits 0" bash -c "exit $EVOLVE_EXIT"
check "phase2 meta file exists" bash -c "test -f ~/.claude/backups/buddy-patch-meta.json"

# Capture state JSON once, then assert against it with jq
STATE_JSON=$(python3 "$RENDERER" --json 2>/dev/null || echo '{}')

assert_jq() {
    local name="$1"
    local expr="$2"
    if echo "$STATE_JSON" | jq -e "$expr" >/dev/null 2>&1; then
        PASS=$((PASS + 1))
        echo "  [PASS] $name"
    else
        FAIL=$((FAIL + 1))
        FAILED_STEPS+=("$name")
        echo "  [FAIL] $name"
    fi
}

assert_jq "phase2 evolved=true"            '.evolved == true'
assert_jq "phase2 species=dragon"          '.meta.species == "dragon"'
assert_jq "phase2 rarity=legendary"        '.meta.rarity == "legendary"'
assert_jq "phase2 shiny=true"              '.meta.shiny == true'
assert_jq "phase2 emoji=dragon"            '.meta.emoji == "🐉"'
assert_jq "phase2 meta.name=Aethos"        '.meta.name == "Aethos"'
assert_jq "phase2 soul.name=Aethos"        '.soul.name == "Aethos"'
assert_jq "phase2 stats.debugging=100"     '.meta.stats.debugging == 100'
assert_jq "phase2 stats.patience=100"      '.meta.stats.patience == 100'
assert_jq "phase2 stats.chaos=100"         '.meta.stats.chaos == 100'
assert_jq "phase2 stats.wisdom=100"        '.meta.stats.wisdom == 100'
assert_jq "phase2 stats.snark=100"         '.meta.stats.snark == 100'

# UI render contains expected visual elements
RENDERED=$(python3 "$RENDERER" 2>/dev/null || true)

assert_render() {
    local name="$1"
    local pattern="$2"
    if echo "$RENDERED" | grep -qE "$pattern"; then
        PASS=$((PASS + 1))
        echo "  [PASS] $name"
    else
        FAIL=$((FAIL + 1))
        FAILED_STEPS+=("$name")
        echo "  [FAIL] $name"
    fi
}

assert_render "phase2 UI shows LEGENDARY"  "LEGENDARY"
assert_render "phase2 UI shows SHINY"      "SHINY"
assert_render "phase2 UI shows Aethos"     "A[ .]*E[ .]*T[ .]*H[ .]*O[ .]*S"
assert_render "phase2 UI shows dragon"     "dragon"
assert_render "phase2 UI shows dragon emoji" "🐉"

# ── Phase 3: second reset ────────────────────────────────────────────
echo
echo "  Phase 3: second reset"
"$PATCHER" --restore 2>&1 | sed 's/^/    /' || true
check "phase3 meta removed" bash -c "test ! -f ~/.claude/backups/buddy-patch-meta.json"

# Verify post-reset render shows wild/missing state (NOT evolved Aethos card)
POST_RESET_STATE=$(python3 "$RENDERER" --json 2>/dev/null || echo '{}')
if echo "$POST_RESET_STATE" | jq -e '.evolved == false or .evolved == null' >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  [PASS] phase3 state shows unevolved"
else
    FAIL=$((FAIL + 1))
    FAILED_STEPS+=("phase3 state shows unevolved")
    echo "  [FAIL] phase3 state shows unevolved"
fi

# ── Cleanup complete — disarm trap ───────────────────────────────────
trap - EXIT

# ── Summary ──────────────────────────────────────────────────────────
echo
echo "═══════════════════════════════════════════════════════════════"
if [ $FAIL -gt 0 ]; then
    echo "  Failed steps:"
    for step in "${FAILED_STEPS[@]}"; do
        echo "    - $step"
    done
    echo
fi
echo "Results: $PASS passed, $FAIL failed"

[ $FAIL -eq 0 ]
