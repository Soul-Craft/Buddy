#!/bin/bash
# Upload local test results as a GitHub Check Run.
#
# Reads test-results/results.json (produced by test-all.sh) and creates a
# Check Run on the current commit via the GitHub Checks API. This is the
# local-to-CI bridge: macOS-dependent tests run on the contributor's machine,
# but GitHub sees the pass/fail state alongside the Ubuntu-side quality checks.
#
# Requires:
#   - gh CLI authenticated with a token that has `checks:write` on the repo
#   - test-results/results.json from a prior test-all.sh run
#   - Must be run from inside the repo (git rev-parse used to locate commit)
#
# Usage:
#   scripts/upload-test-results.sh              # create Check Run on HEAD
#   scripts/upload-test-results.sh --dry-run    # print payload, don't POST
#
# Fallback: if the Checks API isn't available (missing perms, no PR), the
# script tries to comment on the current PR instead (gh pr comment).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_JSON="$REPO_ROOT/test-results/results.json"
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            sed -n '2,21p' "$0"
            exit 0
            ;;
    esac
done

# ── Prerequisites ──────────────────────────────────────────────────

if [ ! -f "$RESULTS_JSON" ]; then
    echo "  [!] ERROR: $RESULTS_JSON not found" >&2
    echo "      Run scripts/test-all.sh first." >&2
    exit 1
fi

if ! command -v gh &>/dev/null; then
    echo "  [!] ERROR: gh CLI not found" >&2
    echo "      Install from https://cli.github.com/" >&2
    exit 1
fi

if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
    echo "  [!] ERROR: need jq or python3 to parse results.json" >&2
    exit 1
fi

if ! gh auth status &>/dev/null; then
    echo "  [!] ERROR: gh is not authenticated (run: gh auth login)" >&2
    exit 1
fi

# ── Gather context ─────────────────────────────────────────────────

COMMIT_SHA=$(git -C "$REPO_ROOT" rev-parse HEAD)
REPO_SLUG=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")

if [ -z "$REPO_SLUG" ]; then
    echo "  [!] ERROR: unable to determine repo slug" >&2
    echo "      Are you inside a cloned GitHub repo?" >&2
    exit 1
fi

# ── Build summary from results.json ────────────────────────────────
# Done in Python so we don't hard-require jq.

SUMMARY_JSON=$(python3 - <<'PY' "$RESULTS_JSON"
import json
import sys

with open(sys.argv[1]) as f:
    data = json.load(f)

tiers = data.get("tiers", [])
totals = data.get("totals", {})
env = data.get("environment", {})
git = data.get("git", {})

overall_pass = totals.get("exit_code", 1) == 0
conclusion = "success" if overall_pass else "failure"

total_passed = totals.get("passed", 0)
total_failed = totals.get("failed", 0)
total_tests = total_passed + total_failed
duration = data.get("duration_seconds", 0)

title = f"Local Tests (macOS) — {total_passed}/{total_tests} passed"

schema_version = data.get("schema_version", 1)

# Markdown summary body with tier breakdown
lines = []
lines.append(f"**Commit:** `{git.get('commit', '?')[:12]}` on `{git.get('branch', '?')}`")
lines.append(f"**Duration:** {duration}s")
lines.append(f"**Environment:** {env.get('os', '?')} {env.get('os_version', '?')} ({env.get('machine', '?')})")
lines.append(f"**Swift:** {env.get('swift_version', '?')}")
lines.append("")

if schema_version >= 2:
    # Group tiers by stage for a richer breakdown
    STAGE_LABELS = {
        "smoke": "Smoke",
        "core": "Core",
        "real-world": "Real-world",
        "full-system": "Full system",
        "peripheral": "Peripheral",
    }
    current_stage = None
    lines.append("| Tier | Passed | Failed | Duration |")
    lines.append("|------|--------|--------|----------|")
    for tier in tiers:
        stage = tier.get("stage") or ""
        if stage and stage != current_stage:
            label = STAGE_LABELS.get(stage, stage.title())
            lines.append(f"| **{label}** | | | |")
            current_stage = stage
        marker = "✅" if tier.get("exit_code", 1) == 0 else "❌"
        lines.append(
            f"| {marker} {tier['name']} | {tier['passed']} | {tier['failed']} | {tier['duration_seconds']}s |"
        )
else:
    # Schema v1: flat table
    lines.append("| Tier | Passed | Failed | Duration |")
    lines.append("|------|--------|--------|----------|")
    for tier in tiers:
        marker = "✅" if tier.get("exit_code", 1) == 0 else "❌"
        lines.append(
            f"| {marker} {tier['name']} | {tier['passed']} | {tier['failed']} | {tier['duration_seconds']}s |"
        )

lines.append(f"| **TOTAL** | **{total_passed}** | **{total_failed}** | **{duration}s** |")
lines.append("")
if git.get("dirty"):
    lines.append("> ⚠️  Working tree was dirty when tests ran.")

summary = "\n".join(lines)

out = {
    "title": title,
    "summary": summary,
    "conclusion": conclusion,
    "total_tests": total_tests,
    "total_passed": total_passed,
    "total_failed": total_failed,
}
print(json.dumps(out))
PY
)

TITLE=$(echo "$SUMMARY_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['title'])")
SUMMARY=$(echo "$SUMMARY_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['summary'])")
CONCLUSION=$(echo "$SUMMARY_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['conclusion'])")

echo
echo "  Uploading test results for:"
echo "    repo:       $REPO_SLUG"
echo "    commit:     $COMMIT_SHA"
echo "    conclusion: $CONCLUSION"
echo "    title:      $TITLE"
echo

if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] would POST to /repos/$REPO_SLUG/check-runs"
    echo
    echo "  Summary body:"
    echo "  ─────────────"
    echo "$SUMMARY"
    echo "  ─────────────"
    exit 0
fi

# ── Create Check Run via Checks API ────────────────────────────────

CHECK_RUN_PAYLOAD=$(python3 - <<PY
import json
print(json.dumps({
    "name": "Local Tests (macOS)",
    "head_sha": "$COMMIT_SHA",
    "status": "completed",
    "conclusion": "$CONCLUSION",
    "output": {
        "title": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$TITLE"),
        "summary": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$SUMMARY"),
    },
}))
PY
)

# POST to Checks API. Capture response to detect permission failures.
RESPONSE=$(echo "$CHECK_RUN_PAYLOAD" | gh api \
    "repos/$REPO_SLUG/check-runs" \
    --method POST \
    --input - 2>&1)
STATUS=$?

if [ "$STATUS" -eq 0 ]; then
    CHECK_URL=$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('html_url', ''))" 2>/dev/null || echo "")
    echo "  [+] Check Run created"
    [ -n "$CHECK_URL" ] && echo "      $CHECK_URL"
    exit 0
fi

# ── Fallback: PR comment ────────────────────────────────────────────

echo "  [!] Checks API failed (likely missing checks:write perm)"
echo "      Response: $RESPONSE" | head -3
echo "  [~] Falling back to PR comment..."

# Find the PR for the current branch, if any.
PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null || echo "")

if [ -z "$PR_NUMBER" ]; then
    echo "  [!] No PR found for current branch — cannot post comment" >&2
    echo "      Results saved locally at: $RESULTS_JSON" >&2
    exit 1
fi

COMMENT_BODY="## Local Tests (macOS)

$SUMMARY

<sub>Posted by scripts/upload-test-results.sh — Check Run API unavailable.</sub>"

echo "$COMMENT_BODY" | gh pr comment "$PR_NUMBER" --body-file -
echo "  [+] Comment posted to PR #$PR_NUMBER"
