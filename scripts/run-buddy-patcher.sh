#!/bin/bash
# Lazy-build wrapper for the buddy-patcher Swift binary.
# First run compiles (~5s), subsequent runs are instant.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/BuddyPatcher"
BIN="$PKG_DIR/.build/release/buddy-patcher"

# Check Swift toolchain
if ! command -v swift &>/dev/null; then
  echo "  [!] ERROR: Swift not found. Install Xcode Command Line Tools:" >&2
  echo "      xcode-select --install" >&2
  exit 1
fi

# Build if needed
if [ ! -f "$BIN" ]; then
  echo "  [~] Building buddy-patcher (first run only)..." >&2
  if ! swift build -c release --package-path "$PKG_DIR" 2>&1 | tail -3 >&2; then
    echo "  [!] ERROR: Swift build failed" >&2
    exit 1
  fi
fi

exec "$BIN" "$@"
