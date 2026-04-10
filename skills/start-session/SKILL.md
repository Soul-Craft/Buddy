---
name: start-session
description: Use when starting a dev session on Buddy Evolver, or to refresh project context. Use when the user says "start session", "refresh context", "what tools do I have", or "session status".
---

# Start Session — Dev Context Check

Gather live project state and present a session readiness summary. This is the manual version of the SessionStart hook — use it to refresh context mid-session or when the hook output has scrolled out of context.

## Step 1: Git state

```bash
echo "=== Git State ==="
git rev-parse --abbrev-ref HEAD
git log --oneline -5
git status --short
git rev-parse --abbrev-ref '@{u}' 2>/dev/null && {
  echo "Ahead: $(git rev-list --count '@{u}..HEAD')"
  echo "Behind: $(git rev-list --count 'HEAD..@{u}')"
} || echo "No upstream tracked"
```

## Step 2: Binary and patch status

```bash
echo "=== Binary Status ==="
BINARY=$(readlink ~/.local/bin/claude 2>/dev/null || echo "NOT_FOUND")
echo "Binary: $BINARY"
echo "Version: $(basename "$BINARY" 2>/dev/null || echo 'unknown')"
test -f "$BINARY" && echo "Exists: yes" || echo "Exists: NO"
test -f "${BINARY}.original-backup" && echo "Backup: yes" || echo "Backup: NO"
test -f ~/.claude/backups/buddy-patch-meta.json && echo "Metadata: yes" || echo "Metadata: NO"
```

## Step 3: Compatibility dry-run

Run only if the patcher binary is already compiled. If not compiled, skip and note it.

```bash
PATCHER="${CLAUDE_PLUGIN_ROOT}/scripts/BuddyPatcher/.build/release/buddy-patcher"
if [ -f "$PATCHER" ]; then
  echo "=== Compatibility Check ==="
  "${CLAUDE_PLUGIN_ROOT}/scripts/run-buddy-patcher.sh" \
    --dry-run --species dragon --rarity legendary --shiny \
    --emoji "🐲" --name "Test" --personality "Test" 2>&1
else
  echo "=== Compatibility Check ==="
  echo "Patcher not compiled yet. Run /test-patch to build and check."
fi
```

Check the output:
- `[DRY RUN]` lines = patterns found (good)
- `[!] WARNING` lines = patterns NOT found (needs attention)

## Step 4: Present session summary

Combine all gathered info into a concise readiness report:

```
Session Readiness
═════════════════

  Branch:        [branch name]
  Uncommitted:   [N files] or "clean"
  Remote sync:   [ahead/behind or up to date]
  Last work:     [most recent commit message]

  Binary:        [found/not found] (v[version])
  Backup:        [yes/no]
  Compatibility: [all match / warnings / not checked]

  Available Dev Tools:
  ────────────────────
  /run-tests         Swift test suite (178 tests)
  /run-all-tests     Full 9-tier pipeline (326 tests)
  /buddy-e2e-test    E2E flow validation (real binary)
  /test-patch        Binary compatibility dry-run
  /security-audit    Integrity + permissions check
  /token-review      Context footprint audit
  /cache-clean       Build artifact cleanup
  /update-species-map  Binary pattern investigation
  /end-session       Automated session wrap-up

  Agents:
  ───────
  security-reviewer  Swift code security review
  test-runner        Automated test execution
  cache-analyzer     Disk usage analysis

  Ready to go. Key constraints to remember:
  • Byte-length invariant on all binary patches
  • 3-byte species variable refs
  • Atomic writes only (.atomic option)
  • Validate inputs in Validation.swift
```

If any health checks show warnings (backup missing, compatibility issues), highlight them at the top and suggest the relevant skill (`/security-audit`, `/test-patch`, `/update-species-map`).
