#!/usr/bin/env bash
# update-changelog.sh — Move [Unreleased] content into a dated [X.Y.Z] section.
#
# Usage: update-changelog.sh X.Y.Z
#
# Reads CHANGELOG.md, finds the "## [Unreleased]" section, moves its content
# under a new "## [X.Y.Z] - YYYY-MM-DD" section, and leaves a fresh empty
# "## [Unreleased]" section at the top.
#
# Exit 0: CHANGELOG updated successfully.
# Exit 1: No [Unreleased] section, or Unreleased is empty, or write failed.
#
# The calling skill is responsible for prompting the user if Unreleased is empty
# (so they can inline the changes). This script treats empty-Unreleased as an error.

set -euo pipefail

NEW_VERSION="${1:-}"
if [[ -z "$NEW_VERSION" ]]; then
  echo "Usage: update-changelog.sh X.Y.Z" >&2
  exit 1
fi

if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: version must be X.Y.Z (got: $NEW_VERSION)" >&2
  exit 1
fi

# --- Resolve project root ---
PROJECT_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PROJECT_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

CHANGELOG="$PROJECT_ROOT/CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
  echo "Error: $CHANGELOG not found" >&2
  exit 1
fi

TODAY=$(date -u '+%Y-%m-%d')

python3 - "$CHANGELOG" "$NEW_VERSION" "$TODAY" <<'PY'
import re, sys, os, tempfile

path, new_version, today = sys.argv[1], sys.argv[2], sys.argv[3]

with open(path) as f:
    text = f.read()

# Split into lines for safer manipulation
lines = text.splitlines(keepends=True)

# Find [Unreleased] section: starts at "## [Unreleased]" line,
# ends at next "## [" line or EOF.
start = end = None
for i, line in enumerate(lines):
    if line.strip().startswith("## [Unreleased]"):
        start = i
    elif start is not None and line.startswith("## ["):
        end = i
        break
if start is None:
    print("Error: no ## [Unreleased] section found in CHANGELOG.md", file=sys.stderr)
    sys.exit(1)
if end is None:
    end = len(lines)

# Extract unreleased body (everything after the header line, before next section).
# Strip leading blank lines from body for the new versioned section.
body = "".join(lines[start + 1 : end])
stripped_body = body.strip("\n")

if not stripped_body:
    print("Error: [Unreleased] section is empty", file=sys.stderr)
    sys.exit(1)

# Construct new content:
#   ## [Unreleased]
#   <blank>
#   ## [X.Y.Z] - YYYY-MM-DD
#   <previous unreleased body>
new_section = (
    f"## [Unreleased]\n"
    f"\n"
    f"## [{new_version}] - {today}\n"
    f"\n"
    f"{stripped_body}\n"
)

# If the section ended at EOF, ensure we keep trailing newline structure;
# otherwise preserve whatever blank lines existed between sections.
trailing = "\n" if end < len(lines) else ""

new_text = "".join(lines[:start]) + new_section + trailing + "".join(lines[end:])

fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
try:
    with os.fdopen(fd, "w") as f:
        f.write(new_text)
    os.replace(tmp, path)
except Exception:
    os.unlink(tmp)
    raise
PY
