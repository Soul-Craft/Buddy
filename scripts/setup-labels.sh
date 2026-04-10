#!/usr/bin/env bash
# Setup GitHub labels for the buddy-evolver repository.
# Run once after forking or setting up a new repo:
#   bash scripts/setup-labels.sh
#
# Requires: gh CLI authenticated with write access to the repo.

set -euo pipefail

REPO="Soul-Craft/buddy-evolver"

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"
  gh label create "$name" \
    --repo "$REPO" \
    --color "$color" \
    --description "$description" \
    --force 2>/dev/null || true
}

echo "Setting up labels for $REPO..."

create_label "bug"            "d73a4a" "Something is broken"
create_label "enhancement"    "a2eeef" "New feature or improvement"
create_label "documentation"  "0075ca" "Documentation changes"
create_label "good first issue" "7057ff" "Good for newcomers"
create_label "help wanted"    "008672" "Looking for contributors"
create_label "security"       "e11d48" "Security-related"
create_label "swift"          "f05138" "Swift patcher changes"
create_label "skills"         "6366f1" "Skill, agent, or hook changes"
create_label "wontfix"        "ffffff" "Not planned"
create_label "duplicate"      "cfd3d7" "Duplicate issue or PR"

echo "Done."
