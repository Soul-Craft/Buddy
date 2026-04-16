---
name: clean-cache
description: This skill should be used when the user asks to "clean cache", "cache clean", "clear build cache", "free disk space", "clean up", "remove build artifacts", "clean .build", "manage cache", or "show cache size".
---

# Cache Clean — Manage Build Artifacts and Cache

Clean up Swift `.build/` directories, `.DS_Store` files, and other accumulated artifacts from Buddy Evolver worktrees.

## Steps

### 1. Preview what will be cleaned

Run a dry-run first to show the user what will be removed:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cache-clean.sh" --dry-run --verbose
```

Show the output to the user. Explain:
- Swift `.build/` directories are build cache (~33MB each) that rebuild in ~5 seconds on next use
- `.DS_Store` files are macOS Finder metadata with no impact
- The current worktree's `.build/` is preserved by default (mention `--all` if they want total cleanup)

### 2. Ask to proceed

Ask the user if they want to proceed with cleanup. If they want to also clean the current worktree's build cache, add `--all`.

### 3. Execute cleanup

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cache-clean.sh" --verbose
```

Or with `--all` if the user requested full cleanup:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cache-clean.sh" --verbose --all
```

### 4. Report results

Show the user:
- How much space was freed
- How many items were cleaned
- Remind them that Swift builds will recompile on next use (~5 seconds)
