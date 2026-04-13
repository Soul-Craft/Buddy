#!/bin/bash
# Master test runner for Buddy Evolver.
#
# Runs all automated test tiers (smoke, unit, security, integration,
# functional, UI) and produces machine-readable output for
# upload-test-results.sh.
#
# Outputs:
#   test-results/results.json   — summary (tier counts, pass/fail, duration)
#   test-results/junit.xml      — JUnit XML for GitHub reporting
#   test-results/full-output.log — concatenated output from all tiers
#
# Exit codes:
#   0 — all tiers passed
#   1 — one or more tiers failed
#
# The visual smoke test is NOT run here (interactive). Run separately.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$REPO_ROOT/test-results"
JSON_FILE="$RESULTS_DIR/results.json"
JUNIT_FILE="$RESULTS_DIR/junit.xml"
LOG_FILE="$RESULTS_DIR/full-output.log"

mkdir -p "$RESULTS_DIR"
: > "$LOG_FILE"

OVERALL_START=$(date +%s)
OVERALL_RESULT=0

# Tier results: name | passed | failed | duration_seconds | exit_code
declare -a TIER_RESULTS

# ── Helpers ────────────────────────────────────────────────────────

run_tier() {
    local name="$1"
    local description="$2"
    shift 2
    echo
    echo "══════════════════════════════════════════════════════════════"
    echo "  TIER: $name"
    echo "  $description"
    echo "══════════════════════════════════════════════════════════════"

    local start
    start=$(date +%s)
    # Append a marker so we can find this tier's output in the log later
    echo "### TIER_START: $name ###" >> "$LOG_FILE"

    "$@" 2>&1 | tee -a "$LOG_FILE"
    local tier_exit=${PIPESTATUS[0]}

    echo "### TIER_END: $name exit=$tier_exit ###" >> "$LOG_FILE"

    local end
    end=$(date +%s)
    local duration=$((end - start))

    # Extract counts from the last few lines of THIS tier's output
    # Swift tests: "Executed N tests, with M failures"
    # Bash tiers:  "Results: N passed, M failed"  or  "Results: N/M passed"
    local tier_log
    tier_log=$(awk "/### TIER_START: $name ###/,/### TIER_END: $name /" "$LOG_FILE")

    local passed=0
    local failed=0
    # Swift test output: "Test Suite 'All tests' passed at ..." followed by
    # the next line "Executed N tests, with M failures ...".
    local swift_summary
    swift_summary=$(echo "$tier_log" | grep -A 1 "Test Suite 'All tests'" | grep -E "Executed [0-9]+ tests" | tail -1)
    if [ -n "$swift_summary" ]; then
        local total
        total=$(echo "$swift_summary" | sed -nE 's/.*Executed ([0-9]+) tests.*/\1/p')
        failed=$(echo "$swift_summary" | sed -nE 's/.*with ([0-9]+) failures.*/\1/p')
        failed=${failed:-0}
        total=${total:-0}
        passed=$((total - failed))
    else
        # "Results: 27/27 passed"
        local slash
        slash=$(echo "$tier_log" | grep -E "Results: [0-9]+/[0-9]+" | tail -1)
        if [ -n "$slash" ]; then
            passed=$(echo "$slash" | sed -nE 's/.*Results: ([0-9]+)\/[0-9]+.*/\1/p')
            local total
            total=$(echo "$slash" | sed -nE 's/.*Results: [0-9]+\/([0-9]+).*/\1/p')
            failed=$((total - passed))
        else
            # "Results: N passed, M failed"
            local line
            line=$(echo "$tier_log" | grep -E "Results: [0-9]+ passed" | tail -1)
            passed=$(echo "$line" | sed -nE 's/.*Results: ([0-9]+) passed.*/\1/p')
            failed=$(echo "$line" | sed -nE 's/.*Results: [0-9]+ passed, ([0-9]+) failed.*/\1/p')
        fi
    fi
    passed=${passed:-0}
    failed=${failed:-0}

    TIER_RESULTS+=("$name|$passed|$failed|$duration|$tier_exit")

    if [ "$tier_exit" -ne 0 ]; then
        OVERALL_RESULT=1
        echo
        echo "  [!] TIER '$name' FAILED (exit=$tier_exit, $passed passed / $failed failed)"
    else
        echo
        echo "  [+] TIER '$name' PASSED ($passed tests in ${duration}s)"
    fi
}

# ── Run all tiers ──────────────────────────────────────────────────
#
# Tiers are ordered cheapest-and-fastest first so broken builds fail
# before expensive tiers waste time. Smoke must run first.

run_tier "smoke" "Build verification + CLI contract (<30s)" \
    bash "$SCRIPT_DIR/test-smoke.sh"

run_tier "unit" "Swift XCTest suite" \
    swift test --package-path "$SCRIPT_DIR/BuddyPatcher"

run_tier "security" "Input validation, hook, injection checks" \
    bash "$SCRIPT_DIR/test-security.sh"

run_tier "ui" "Buddy card rendering against fixtures" \
    bash "$SCRIPT_DIR/test-ui.sh"

run_tier "snapshots" "Golden file comparison for CLI output" \
    bash "$SCRIPT_DIR/test-snapshots.sh"

run_tier "docs" "Documentation path + link + count consistency" \
    bash "$SCRIPT_DIR/test-docs.sh"

OVERALL_END=$(date +%s)
OVERALL_DURATION=$((OVERALL_END - OVERALL_START))

# ── Emit results.json ──────────────────────────────────────────────

TOTAL_PASSED=0
TOTAL_FAILED=0
python3 - <<PY > "$JSON_FILE"
import json
import platform
import subprocess
import sys
from datetime import datetime, timezone

# Schema v2: per-tier "stage" field groups tiers into pipeline stages.
# upload-test-results.sh reads this to render a staged summary table.
# Unknown tiers default to stage=None for forward compatibility.
STAGE_MAP = {
    "smoke": "smoke",
    "unit": "core",
    "security": "core",
    "ui": "real-world",
    "snapshots": "full-system",
    "docs": "peripheral",
}

tiers = []
total_passed = 0
total_failed = 0
overall_exit = 0

rows = """$(for row in "${TIER_RESULTS[@]}"; do echo "$row"; done)""".strip().splitlines()
for row in rows:
    parts = row.split("|")
    if len(parts) != 5:
        continue
    name, passed, failed, duration, exit_code = parts
    passed = int(passed); failed = int(failed)
    duration = int(duration); exit_code = int(exit_code)
    total_passed += passed
    total_failed += failed
    if exit_code != 0:
        overall_exit = 1
    tiers.append({
        "name": name,
        "stage": STAGE_MAP.get(name),
        "passed": passed,
        "failed": failed,
        "duration_seconds": duration,
        "exit_code": exit_code,
    })

def sh(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except Exception:
        return ""

summary = {
    "schema_version": 2,
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "duration_seconds": $OVERALL_DURATION,
    "environment": {
        "os": platform.system(),
        "os_version": platform.release(),
        "machine": platform.machine(),
        "swift_version": sh("swift --version | head -1"),
        "python_version": platform.python_version(),
    },
    "git": {
        "commit": sh("git rev-parse HEAD"),
        "branch": sh("git rev-parse --abbrev-ref HEAD"),
        "dirty": bool(sh("git status --porcelain")),
    },
    "tiers": tiers,
    "totals": {
        "passed": total_passed,
        "failed": total_failed,
        "exit_code": overall_exit,
    },
}
print(json.dumps(summary, indent=2))
PY

# ── Emit junit.xml ─────────────────────────────────────────────────

python3 - <<PY > "$JUNIT_FILE"
import xml.etree.ElementTree as ET
from xml.dom import minidom

testsuites = ET.Element("testsuites", name="buddy-evolver")

rows = """$(for row in "${TIER_RESULTS[@]}"; do echo "$row"; done)""".strip().splitlines()

total_tests = 0
total_failures = 0
total_time = 0.0

for row in rows:
    parts = row.split("|")
    if len(parts) != 5:
        continue
    name, passed, failed, duration, exit_code = parts
    passed = int(passed); failed = int(failed)
    duration = float(duration)
    suite = ET.SubElement(testsuites, "testsuite",
                          name=name,
                          tests=str(passed + failed),
                          failures=str(failed),
                          time=str(duration))
    total_tests += passed + failed
    total_failures += failed
    total_time += duration

    # One testcase representing the whole tier (granularity could be improved)
    tc = ET.SubElement(suite, "testcase",
                       name=f"{name}-tier",
                       classname="buddy-evolver",
                       time=str(duration))
    if int(exit_code) != 0:
        failure = ET.SubElement(tc, "failure",
                                message=f"{failed} test(s) failed in tier")
        failure.text = f"See full-output.log for details"

testsuites.set("tests", str(total_tests))
testsuites.set("failures", str(total_failures))
testsuites.set("time", str(total_time))

xml_str = minidom.parseString(ET.tostring(testsuites)).toprettyxml(indent="  ")
print(xml_str)
PY

# ── Print summary ──────────────────────────────────────────────────

echo
echo
echo "══════════════════════════════════════════════════════════════"
echo "  TEST SUMMARY"
echo "══════════════════════════════════════════════════════════════"
printf "  %-15s %-10s %-10s %s\n" "TIER" "PASSED" "FAILED" "DURATION"
echo "  ──────────────────────────────────────────────────────"
for row in "${TIER_RESULTS[@]}"; do
    IFS='|' read -r name passed failed duration exit_code <<< "$row"
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    if [ "$exit_code" -eq 0 ]; then
        marker="[+]"
    else
        marker="[!]"
    fi
    printf "  %s %-12s %-10s %-10s %ss\n" "$marker" "$name" "$passed" "$failed" "$duration"
done
echo "  ──────────────────────────────────────────────────────"
printf "  %-15s %-10s %-10s %ss\n" "TOTAL" "$TOTAL_PASSED" "$TOTAL_FAILED" "$OVERALL_DURATION"
echo
echo "  Results: $JSON_FILE"
echo "  JUnit:   $JUNIT_FILE"
echo "  Log:     $LOG_FILE"
echo

if [ "$OVERALL_RESULT" -ne 0 ]; then
    echo "  [!] ONE OR MORE TIERS FAILED"
    exit 1
fi

echo "  [+] ALL TIERS PASSED"
exit 0
