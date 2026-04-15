#!/usr/bin/env bash
# bump-version.sh — Atomically bump version across plugin.json, marketplace.json, and README.md badge.
#
# Usage: bump-version.sh [patch|minor|major]
#
# Reads current version from .claude-plugin/plugin.json, computes the next version
# via semver arithmetic, and writes it to all three files. Writes are atomic
# (temp file + mv) so a mid-script failure cannot leave files in an inconsistent state.
#
# Stdout: "<old_version> <new_version>" on success — parseable by /session-deploy.
# Exit:   0 on success; 1 on any error.

set -euo pipefail

# --- Parse arguments ---
BUMP_TYPE="${1:-}"
case "$BUMP_TYPE" in
  patch|minor|major) ;;
  *)
    echo "Usage: bump-version.sh [patch|minor|major]" >&2
    exit 1
    ;;
esac

# --- Resolve project root ---
PROJECT_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PROJECT_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

PLUGIN_JSON="$PROJECT_ROOT/.claude-plugin/plugin.json"
MARKET_JSON="$PROJECT_ROOT/.claude-plugin/marketplace.json"
README="$PROJECT_ROOT/README.md"

for f in "$PLUGIN_JSON" "$MARKET_JSON" "$README"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: missing file $f" >&2
    exit 1
  fi
done

# --- Read current version + compute next ---
# Use python3 for reliable JSON + semver arithmetic
read -r OLD_VERSION NEW_VERSION < <(python3 - "$PLUGIN_JSON" "$BUMP_TYPE" <<'PY'
import json, sys
plugin_path, bump = sys.argv[1], sys.argv[2]
with open(plugin_path) as f:
    data = json.load(f)
old = data["version"]
parts = [int(x) for x in old.split(".")]
if len(parts) != 3:
    print(f"Error: version {old!r} is not X.Y.Z", file=sys.stderr)
    sys.exit(1)
major, minor, patch = parts
if bump == "major":
    major, minor, patch = major + 1, 0, 0
elif bump == "minor":
    minor, patch = minor + 1, 0
else:
    patch += 1
new = f"{major}.{minor}.{patch}"
print(f"{old} {new}")
PY
)

if [[ -z "$NEW_VERSION" ]]; then
  echo "Error: could not compute new version" >&2
  exit 1
fi

# --- Atomic write helper: stage to temp file, then mv ---
atomic_write() {
  local target="$1"
  local content="$2"
  local tmp
  tmp=$(mktemp "${target}.XXXXXX")
  printf '%s' "$content" > "$tmp"
  mv "$tmp" "$target"
}

# --- Update plugin.json ---
new_plugin=$(python3 - "$PLUGIN_JSON" "$NEW_VERSION" <<'PY'
import json, sys
path, new_version = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
data["version"] = new_version
print(json.dumps(data, indent=2))
PY
)
atomic_write "$PLUGIN_JSON" "$new_plugin
"

# --- Update marketplace.json (plugins[0].version) ---
new_market=$(python3 - "$MARKET_JSON" "$NEW_VERSION" <<'PY'
import json, sys
path, new_version = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
if "plugins" not in data or not data["plugins"]:
    print("Error: marketplace.json has no plugins array", file=sys.stderr)
    sys.exit(1)
data["plugins"][0]["version"] = new_version
print(json.dumps(data, indent=2))
PY
)
atomic_write "$MARKET_JSON" "$new_market
"

# --- Update README.md badge ---
# Badge format: ![Version](https://img.shields.io/badge/version-X.Y.Z-blue)
python3 - "$README" "$OLD_VERSION" "$NEW_VERSION" <<'PY'
import re, sys, os, tempfile
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    text = f.read()
pattern = re.compile(r"(version-)" + re.escape(old) + r"(-blue\))")
new_text, n = pattern.subn(r"\g<1>" + new + r"\g<2>", text)
if n == 0:
    print(f"Warning: README version badge for {old} not found — skipping badge update", file=sys.stderr)
    sys.exit(0)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
try:
    with os.fdopen(fd, "w") as f:
        f.write(new_text)
    os.replace(tmp, path)
except Exception:
    os.unlink(tmp)
    raise
PY

# --- Output for caller ---
echo "$OLD_VERSION $NEW_VERSION"
