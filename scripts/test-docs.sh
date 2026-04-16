#!/bin/bash
# Documentation consistency tests.
#
# Fills gaps that doc-sync (ci-quality.yml) doesn't cover:
#   1. Architecture tree paths in CLAUDE.md exist on disk
#   2. Swift source layout paths in CLAUDE.md exist on disk
#   3. Markdown file-path links in key docs resolve
#   4. Anti-drift: no stale test counts in live docs
#   5. Makefile targets referenced in docs exist in Makefile
#   6. CHANGELOG has an entry for the current plugin.json version
#   7. skills/ directories each have a SKILL.md file
#   8. hooks/hooks.json shell scripts exist on disk
#   9. Session workflow skills (session-end, session-deploy) only reference real files
#  10. Retired skills (buddy, test-patch, update-species-map) stay retired
#  11. session-execute agent model table matches all agent frontmatter
#
# Output: "Results: N passed, M failed" on the last line.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 1

PASSED=0
FAILED=0

# ── Helpers ────────────────────────────────────────────────────────

assert_pass() {
    local description="$1"
    local ok="$2"   # "0" = pass, non-zero = fail
    if [ "$ok" = "0" ]; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description"
        FAILED=$((FAILED + 1))
    fi
}

echo
echo "  Docs Test Suite"
echo "  ═══════════════"
echo

# ── Group 1: Architecture tree paths in CLAUDE.md ─────────────────

echo "  --- Group 1: CLAUDE.md architecture tree ---"
echo

missing_arch=0
missing_list=""
while IFS= read -r path; do
    # Strip trailing slash (for directory entries)
    clean="${path%/}"
    if [ ! -e "$clean" ]; then
        missing_list="$missing_list\n    $path"
        missing_arch=$((missing_arch + 1))
    fi
done < <(python3 - <<'PY'
import re, pathlib

content = pathlib.Path("CLAUDE.md").read_text()
match = re.search(r'## Architecture\n\n```\n(.+?)```', content, re.DOTALL)
if match:
    for line in match.group(1).strip().splitlines():
        parts = line.split()
        if parts and not parts[0].startswith('#'):
            print(parts[0])
PY
)

if [ "$missing_arch" -eq 0 ]; then
    assert_pass "All CLAUDE.md architecture tree paths exist on disk" "0"
else
    echo "  [FAIL] CLAUDE.md architecture tree: $missing_arch path(s) missing:"
    printf '%b\n' "$missing_list"
    FAILED=$((FAILED + 1))
fi

echo

# ── Group 2: Swift source layout paths in CLAUDE.md ───────────────

echo "  --- Group 2: CLAUDE.md Swift source layout ---"
echo

missing_swift=0
missing_swift_list=""
# The Swift source layout block uses an indented tree; extract bare
# filenames and check they exist anywhere under scripts/BuddyPatcher/Sources/.
swift_filenames=$(python3 - <<'PY'
import re, pathlib

content = pathlib.Path("CLAUDE.md").read_text()
match = re.search(r'### Swift source layout\n\n```\n(.+?)```', content, re.DOTALL)
if match:
    for line in match.group(1).strip().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("scripts/") or stripped.startswith("Sources/"):
            continue
        parts = stripped.split()
        if parts and ('.' in parts[0]):
            print(parts[0])
PY
)
while IFS= read -r fname; do
    [ -z "$fname" ] && continue
    if ! find scripts/BuddyPatcher -name "$fname" -type f 2>/dev/null | grep -q .; then
        missing_swift_list="$missing_swift_list\n    $fname"
        missing_swift=$((missing_swift + 1))
    fi
done <<< "$swift_filenames"

if [ "$missing_swift" -eq 0 ]; then
    assert_pass "All CLAUDE.md Swift source layout paths exist on disk" "0"
else
    echo "  [FAIL] CLAUDE.md Swift source layout: $missing_swift path(s) missing:"
    printf '%b\n' "$missing_swift_list"
    FAILED=$((FAILED + 1))
fi

echo

# ── Group 3: Markdown file-path links resolve ─────────────────────

echo "  --- Group 3: Markdown link targets ---"
echo

check_md_links() {
    local doc_file="$1"
    local missing=0
    local missing_links=""
    while IFS= read -r link_target; do
        # Strip leading "./" and trailing "#anchor"
        clean="${link_target#./}"
        clean="${clean%%#*}"
        [ -z "$clean" ] && continue
        if [ ! -e "$clean" ]; then
            missing_links="$missing_links\n    $link_target"
            missing=$((missing + 1))
        fi
    done < <(grep -oE '\[([^]]+)\]\(([^)]+)\)' "$doc_file" 2>/dev/null \
             | grep -oE '\(([^)]+)\)' \
             | sed 's/^(//;s/)$//' \
             | grep -v '^https\?://' \
             | grep -v '^#' \
             | grep -v '^mailto:')
    if [ "$missing" -eq 0 ]; then
        assert_pass "All links in $doc_file resolve" "0"
    else
        echo "  [FAIL] $doc_file: $missing broken link(s):"
        printf '%b\n' "$missing_links"
        FAILED=$((FAILED + 1))
    fi
}

check_md_links "README.md"
check_md_links "CLAUDE.md"
check_md_links "CONTRIBUTING.md"
check_md_links ".github/PULL_REQUEST_TEMPLATE.md"

echo

# ── Group 4: Anti-drift (no stale test counts) ────────────────────

echo "  --- Group 4: Anti-drift checks ---"
echo

# Exclude CHANGELOG.md — it's a historical record, not live docs.
# Exclude test-results/ — not a doc.
LIVE_DOCS=$(git ls-files '*.md' | grep -v '^CHANGELOG.md' | grep -v '^test-results/')

# Stale number: 94 unit tests (pre-2026 count — superseded by 175)
stale_94=$(echo "$LIVE_DOCS" | xargs grep -lE '\b94 tests?\b' 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')
assert_pass "No live docs reference '94 tests' (stale count)" "$([ "$stale_94" -eq 0 ] && echo 0 || echo 1)"
if [ "$stale_94" -gt 0 ]; then
    echo "$LIVE_DOCS" | xargs grep -lE '\b94 tests?\b' 2>/dev/null | sed 's/^/    /'
fi

# Stale phrasing: "8 suites" (matched 8-suite era)
stale_8suites=$(echo "$LIVE_DOCS" | xargs grep -lE '\b8 suites?\b' 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')
assert_pass "No live docs reference '8 suites' (stale count)" "$([ "$stale_8suites" -eq 0 ] && echo 0 || echo 1)"

# Stale phrasing: "11 suites" (incorrect count for 12-file suite)
stale_11suites=$(echo "$LIVE_DOCS" | xargs grep -lE '\b11 suites?\b' 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')
assert_pass "No live docs reference '11 suites' (stale count)" "$([ "$stale_11suites" -eq 0 ] && echo 0 || echo 1)"

# Unit test count in docs matches actual Swift test functions.
# Dynamically checks that docs mention the actual count (not hardcoded).
actual_unit=$(grep -r '^\s*func test' scripts/BuddyPatcher/Tests/BuddyPatcherTests/*.swift 2>/dev/null | wc -l | tr -d ' ')
docs_mention_count=$(echo "$LIVE_DOCS" | xargs grep -l "${actual_unit} tests" 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')
assert_pass "Actual Swift unit count ($actual_unit) documented in live docs" \
    "$([ "$docs_mention_count" -gt 0 ] && echo 0 || echo 1)"

echo

# ── Group 5: Makefile targets referenced in docs exist ────────────

echo "  --- Group 5: Makefile targets ---"
echo

# Get defined targets from Makefile
defined_targets=$(grep -oE '^[a-zA-Z_-]+:' Makefile | tr -d ':' | sort)

# Extract 'make <target>' from docs; filter English false positives.
# Using a variable + while-heredoc avoids nested-pipe case syntax issues.
doc_targets_raw=$(grep -hoE 'make [a-z][a-z-]+' README.md CLAUDE.md CONTRIBUTING.md 2>/dev/null \
                  | awk '{print $2}' | sort -u)

missing_targets=0
missing_target_list=""
while IFS= read -r target; do
    # Skip common English words that aren't make targets
    case "$target" in
        sure|it|a|an|the|no|this|that|clean|note|up|down) continue ;;
    esac
    if ! echo "$defined_targets" | grep -qxF "$target"; then
        missing_target_list="$missing_target_list\n    make $target"
        missing_targets=$((missing_targets + 1))
    fi
done <<< "$doc_targets_raw"

if [ "$missing_targets" -eq 0 ]; then
    assert_pass "All 'make <target>' doc references match defined Makefile targets" "0"
else
    echo "  [FAIL] Docs reference undefined Makefile targets:"
    printf '%b\n' "$missing_target_list"
    FAILED=$((FAILED + 1))
fi

echo

# ── Group 6: CHANGELOG has entry for current plugin version ───────

echo "  --- Group 6: CHANGELOG version ---"
echo

plugin_version=$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "unknown")
changelog_has_version=$(grep -cE "^## \[$plugin_version\]" CHANGELOG.md 2>/dev/null || echo "0")
assert_pass "CHANGELOG.md has entry for plugin.json version ($plugin_version)" \
    "$([ "${changelog_has_version:-0}" -gt 0 ] && echo 0 || echo 1)"

echo

# ── Group 7: skills/ directories have SKILL.md ────────────────────

echo "  --- Group 7: Skill completeness ---"
echo

missing_skills=0
missing_skill_list=""
for skill_dir in skills/*/; do
    skill_name="${skill_dir%/}"
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        missing_skill_list="$missing_skill_list\n    $skill_name (missing SKILL.md)"
        missing_skills=$((missing_skills + 1))
    fi
done

if [ "$missing_skills" -eq 0 ]; then
    assert_pass "All skills/ directories contain SKILL.md" "0"
else
    echo "  [FAIL] Skills missing SKILL.md:"
    printf '%b\n' "$missing_skill_list"
    FAILED=$((FAILED + 1))
fi

echo

# ── Group 8: hooks.json shell scripts exist ────────────────────────

echo "  --- Group 8: Hook scripts ---"
echo

missing_hooks=0
missing_hook_list=""
while IFS= read -r hook_script; do
    # Remove ${CLAUDE_PLUGIN_ROOT}/ prefix if present
    clean_path="${hook_script/\$\{CLAUDE_PLUGIN_ROOT\}\//}"
    clean_path="${clean_path/\$CLAUDE_PLUGIN_ROOT\//}"
    # Strip surrounding quotes if any
    clean_path="${clean_path#\"}"
    clean_path="${clean_path%\"}"
    if [ -n "$clean_path" ] && [[ "$clean_path" == hooks/* ]] && [ ! -f "$clean_path" ]; then
        missing_hook_list="$missing_hook_list\n    $hook_script"
        missing_hooks=$((missing_hooks + 1))
    fi
done < <(python3 - <<'PY'
import json, pathlib

# hooks.json structure: {"hooks": {"EventType": [{"hooks": [{"command": "..."}]}]}}
data = json.loads(pathlib.Path("hooks/hooks.json").read_text())
event_map = data.get("hooks", {})
if isinstance(event_map, dict):
    for event_hooks in event_map.values():
        for entry in event_hooks:
            for hook in entry.get("hooks", []):
                cmd = hook.get("command", "")
                if "bash " in cmd:
                    # Extract path after 'bash '
                    parts = cmd.split("bash ", 1)[1].strip().split()
                    if parts:
                        print(parts[0])
PY
)

if [ "$missing_hooks" -eq 0 ]; then
    assert_pass "All hooks.json shell scripts exist on disk" "0"
else
    echo "  [FAIL] hooks.json references missing scripts:"
    printf '%b\n' "$missing_hook_list"
    FAILED=$((FAILED + 1))
fi

echo

# ── Group 9: Session workflow skills reference real files ────────
#
# /session-end and /session-deploy orchestrate multiple scripts, skills, and
# agents. If any of those references rot (script renamed, skill deleted, agent
# moved), the workflow silently falls apart. This check asserts every referenced
# path resolves at test time — much faster than discovering the break at commit.

echo "  --- Group 9: Session workflow references ---"
echo

# The references below are the files each skill explicitly depends on.
# Keep these lists in sync if the skills' dependencies change.
END_SESSION_REFS=(
    "scripts/test-all.sh"
    "scripts/upload-test-results.sh"
    "skills/token-review/SKILL.md"
    "skills/sync-docs/SKILL.md"
    "agents/comment-reviewer.md"
)

SESSION_DEPLOY_REFS=(
    "scripts/test-smoke.sh"
    "scripts/cache-clean.sh"
    "scripts/process-pending-cleanup.sh"
    "hooks/session-end.sh"
)

# check_refs SKILL_NAME SKILL_MD_PATH REF1 REF2 ...
# Verifies that SKILL_MD_PATH exists and that all listed REFs exist on disk.
# Reports a single PASS/FAIL line for the named skill.
check_refs() {
    local skill_name="$1"
    local skill_md="$2"
    shift 2
    local refs=("$@")

    if [ ! -f "$skill_md" ]; then
        echo "  [FAIL] $skill_name SKILL.md missing at $skill_md"
        FAILED=$((FAILED + 1))
        return
    fi

    local missing=0
    local missing_ref_list=""
    for ref in "${refs[@]}"; do
        if [ ! -e "$ref" ]; then
            missing_ref_list="$missing_ref_list\n    $ref"
            missing=$((missing + 1))
        fi
    done

    if [ "$missing" -eq 0 ]; then
        assert_pass "$skill_name references (${#refs[@]}) all exist on disk" "0"
    else
        echo "  [FAIL] $skill_name references $missing missing file(s):"
        printf '%b\n' "$missing_ref_list"
        FAILED=$((FAILED + 1))
    fi
}

check_refs "/session-end" "skills/session-end/SKILL.md" "${END_SESSION_REFS[@]}"
check_refs "/session-deploy" "skills/session-deploy/SKILL.md" "${SESSION_DEPLOY_REFS[@]}"

echo

# ── Group 10: Retired skill guard ──────────────────────────────────
#
# Claude Code v2.1.104 shipped a native /buddy command. A plugin skill named
# `buddy` shadows it. /test-patch and /update-species-map were retired with the
# binary-patching layer in v2.0.0. None of these names may reappear as skills
# (neither as a directory under skills/ nor as a SKILL.md frontmatter name:).

echo "  --- Group 10: Retired skill guard ---"
echo

forbidden_hits=0
forbidden_list=""

for name in buddy test-patch update-species-map; do
    if [ -d "skills/$name" ]; then
        forbidden_list="$forbidden_list\n    skills/$name/ exists"
        forbidden_hits=$((forbidden_hits + 1))
    fi
done

if compgen -G "skills/*/SKILL.md" >/dev/null 2>&1; then
    bad_frontmatter=$(grep -lE '^name:[[:space:]]+(buddy|test-patch|update-species-map)[[:space:]]*$' skills/*/SKILL.md 2>/dev/null || true)
    if [ -n "$bad_frontmatter" ]; then
        while IFS= read -r f; do
            forbidden_list="$forbidden_list\n    $f uses a forbidden frontmatter name"
            forbidden_hits=$((forbidden_hits + 1))
        done <<< "$bad_frontmatter"
    fi
fi

if [ "$forbidden_hits" -eq 0 ]; then
    assert_pass "No retired skills present (buddy, test-patch, update-species-map)" "0"
else
    echo "  [FAIL] Retired skills must not return ($forbidden_hits finding(s)):"
    printf '%b\n' "$forbidden_list"
    FAILED=$((FAILED + 1))
fi

echo

# ── Group 11: Agent model table drift check ──────────────────────
#
# Validates that the agent model table in skills/session-execute/SKILL.md
# matches the actual model: fields in each agent's frontmatter.
# Prevents the table from silently drifting when an agent's model is changed.

echo "  --- Group 11: Agent model table drift ---"
echo

drift_output=$(python3 - <<'PY'
import re, pathlib, sys

content = pathlib.Path("skills/session-execute/SKILL.md").read_text()

# Find the code block that starts with "Component Model Recommendations"
code_block_match = re.search(
    r'```\nComponent Model Recommendations\n(.*?)```',
    content, re.DOTALL
)
if not code_block_match:
    print("ERROR: Could not find model table in skills/session-execute/SKILL.md")
    sys.exit(1)

table_text = code_block_match.group(1)

# Agent rows follow the "Agent  Model  Configured in" header and its rule line,
# and end before the next box-drawing rule line.
agent_section_match = re.search(
    r'Agent\s+Model\s+Configured in\n.+\n((?:.+\n)+)',
    table_text
)
if not agent_section_match:
    print("ERROR: Could not parse agent section from model table")
    sys.exit(1)

rows = []
for line in agent_section_match.group(1).splitlines():
    line = line.strip()
    if not line or not line[0].isalpha():
        break  # stop at closing rule line (box-drawing chars are not alpha)
    parts = line.split()
    if len(parts) >= 3:
        rows.append((parts[0], parts[1], parts[2]))

mismatches = []
for agent_name, expected_model, agent_file in rows:
    try:
        agent_content = pathlib.Path(agent_file).read_text()
        m = re.search(r'^model:\s*(\S+)', agent_content, re.MULTILINE)
        actual = m.group(1) if m else "inherit"
        if actual != expected_model:
            mismatches.append(
                f"{agent_name}: table={expected_model!r} frontmatter={actual!r} ({agent_file})"
            )
    except FileNotFoundError:
        mismatches.append(f"{agent_name}: agent file missing: {agent_file}")

for msg in mismatches:
    print(f"  {msg}")
sys.exit(1 if mismatches else 0)
PY
)
drift_exit=$?

if [ "$drift_exit" -eq 0 ]; then
    assert_pass "Agent model table in /session-execute matches all agent frontmatter" "0"
else
    echo "  [FAIL] Agent model table drift detected:"
    echo "$drift_output"
    FAILED=$((FAILED + 1))
fi

echo

# ── Summary ────────────────────────────────────────────────────────

echo "Results: $PASSED passed, $FAILED failed"
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
