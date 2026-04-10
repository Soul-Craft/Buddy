#!/bin/bash
# Local lint — mirrors the jobs in .github/workflows/ci-quality.yml so
# contributors can run the same checks before pushing.
#
# Checks:
#   1. Shellcheck all scripts in scripts/ and hooks/
#   2. Validate JSON config files
#   3. Validate skill SKILL.md YAML frontmatter
#   4. Repo hygiene (no .build/, no .DS_Store, no committed test-results)
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 1

failed=0

# Keep local shellcheck behavior aligned with CI.
# CI's ubuntu-latest installs shellcheck via apt, which is ~0.8.x.
# Homebrew ships 0.11.x, which introduced SC2319 ("$? refers to a
# condition"). Existing test scripts use `assert_pass "..." $?` after
# a test command or function call, which is structurally correct —
# $? unambiguously refers to the prior line. Excluding SC2319 keeps
# local and CI results consistent; revisit when CI upgrades shellcheck.
SHELLCHECK_FLAGS=(-S warning -e SC2319)

echo
echo "  Lint Suite"
echo "  ══════════"
echo

# ── 1. Shellcheck ─────────────────────────────────────────────────
echo "  --- Shellcheck ---"
if command -v shellcheck >/dev/null 2>&1; then
    scripts_checked=0
    while IFS= read -r -d '' f; do
        scripts_checked=$((scripts_checked + 1))
        if ! shellcheck "${SHELLCHECK_FLAGS[@]}" "$f"; then
            echo "  [FAIL] shellcheck: $f"
            failed=$((failed + 1))
        fi
    done < <(find scripts hooks -name "*.sh" -type f -print0)
    echo "  Checked $scripts_checked shell script(s)"
else
    echo "  [WARN] shellcheck not installed — skipping (install: brew install shellcheck)"
fi
echo

# ── 2. JSON validation ────────────────────────────────────────────
echo "  --- JSON validation ---"
for f in \
    .claude-plugin/plugin.json \
    .claude-plugin/marketplace.json \
    hooks/hooks.json \
    .claude/settings.json; do
    if [ -f "$f" ]; then
        if python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$f" 2>/dev/null; then
            echo "  [PASS] $f"
        else
            echo "  [FAIL] $f (invalid JSON)"
            failed=$((failed + 1))
        fi
    fi
done
echo

# ── 3. Skill frontmatter (YAML) ───────────────────────────────────
echo "  --- Skill frontmatter ---"
if ! python3 - "$REPO_ROOT" <<'PY'
import pathlib
import sys

try:
    import yaml
except ImportError:
    print("  [WARN] PyYAML not installed — skipping frontmatter check (pip install pyyaml)")
    sys.exit(0)

repo_root = pathlib.Path(sys.argv[1])
failed = []
for skill in sorted(repo_root.glob("skills/*/SKILL.md")):
    content = skill.read_text()
    if not content.startswith("---"):
        failed.append(f"{skill.relative_to(repo_root)}: missing frontmatter")
        continue
    try:
        _, fm, _body = content.split("---", 2)
    except ValueError:
        failed.append(f"{skill.relative_to(repo_root)}: malformed frontmatter")
        continue
    try:
        meta = yaml.safe_load(fm)
    except yaml.YAMLError as e:
        failed.append(f"{skill.relative_to(repo_root)}: invalid YAML -- {e}")
        continue
    if not isinstance(meta, dict):
        failed.append(f"{skill.relative_to(repo_root)}: frontmatter is not a mapping")
        continue
    for required in ("name", "description"):
        if required not in meta:
            failed.append(f"{skill.relative_to(repo_root)}: missing '{required}' field")

if failed:
    for m in failed:
        print(f"  [FAIL] {m}")
    sys.exit(1)
print("  [PASS] all skill frontmatter valid")
sys.exit(0)
PY
then
    failed=$((failed + 1))
fi
echo

# ── 4. Repo hygiene ───────────────────────────────────────────────
#
# All hygiene checks scope to tracked files only (via `git ls-files`).
# The CI hygiene job in ci-quality.yml uses `find` because Ubuntu
# runners never have .DS_Store on disk — on macOS, Finder constantly
# creates ignored .DS_Store files and scanning the filesystem would
# produce false positives. `git ls-files` asks the load-bearing
# question: "would any of this end up in a PR?"
echo "  --- Repo hygiene ---"

# No committed build artifacts
bad=$(git ls-files | grep -E '(^|/)(\.build|__pycache__)(/|$)' || true)
if [ -n "$bad" ]; then
    echo "  [FAIL] committed build artifacts:"
    echo "$bad" | sed 's/^/    /'
    failed=$((failed + 1))
else
    echo "  [PASS] no committed build artifacts"
fi

# No committed .DS_Store files
bad=$(git ls-files | grep -E '(^|/)\.DS_Store$' || true)
if [ -n "$bad" ]; then
    echo "  [FAIL] .DS_Store files committed:"
    echo "$bad" | sed 's/^/    /'
    failed=$((failed + 1))
else
    echo "  [PASS] no committed .DS_Store files"
fi

# No committed test-results (local runs produce this directory but
# .gitignore should keep it out of the index)
tracked=$(git ls-files test-results 2>/dev/null || true)
if [ -n "$tracked" ]; then
    echo "  [FAIL] test-results/ has tracked files:"
    echo "$tracked" | sed 's/^/    /'
    failed=$((failed + 1))
else
    echo "  [PASS] no tracked test-results files"
fi

echo

# ── Summary ───────────────────────────────────────────────────────
if [ "$failed" -eq 0 ]; then
    echo "Results: lint passed"
    exit 0
else
    echo "Results: $failed lint check(s) failed"
    exit 1
fi
