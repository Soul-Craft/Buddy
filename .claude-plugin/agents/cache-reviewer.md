---
name: cache-reviewer
description: Analyze disk usage, cache accumulation, and orphaned worktrees in the Buddy Evolver plugin. Use when asked to "analyze cache", "check disk usage", "find orphaned worktrees", or "cache report".
model: inherit
tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Cache Reviewer Agent

You are analyzing cache and disk usage for the Buddy Evolver Claude Code plugin. Produce a comprehensive report covering build artifacts, worktrees, backups, and cleanup recommendations.

## Analysis Tasks

### 1. Worktree Health

List all worktrees in `.claude/worktrees/` and check:
- Which have `.build/` directories and their sizes
- Which have corresponding git branches (orphaned = no branch)
- Total disk usage per worktree

```bash
# List worktrees and sizes
du -sh .claude/worktrees/*/ 2>/dev/null

# Check git worktree list for orphans
git worktree list 2>/dev/null
```

### 2. Build Cache Analysis

Find all `.build/` directories anywhere in the project tree:

```bash
find . -name ".build" -type d -not -path "*/.git/*" 2>/dev/null | while read dir; do
  echo "$(du -sh "$dir" 2>/dev/null) — $dir"
done
```

### 3. Backup File Analysis

Check backup sizes and staleness in `~/.claude/backups/`:

```bash
ls -lah ~/.claude/backups/ 2>/dev/null
```

Also check for binary backups:

```bash
find ~/.local/share/claude/versions/ -name "*.original-backup" -exec ls -lah {} \; 2>/dev/null
```

### 4. .DS_Store Accumulation

Count and size all .DS_Store files:

```bash
find . -name ".DS_Store" -not -path "*/.git/*" 2>/dev/null | wc -l
find . -name ".DS_Store" -not -path "*/.git/*" -exec du -ch {} + 2>/dev/null | tail -1
```

### 5. Total Disk Usage

Report total project size broken down by category:

```bash
echo "=== Total project size ==="
du -sh . 2>/dev/null

echo "=== By directory ==="
du -sh .claude/ scripts/ skills/ .claude-plugin/ .git/ 2>/dev/null
```

## Output Format

Present findings as a structured report:

```
=== Buddy Evolver Cache Report ===

Worktrees: X total, Y with build cache, Z orphaned
Build cache: XX MB total across N directories
Backups: XX MB (binary) + XX KB (soul + metadata)
.DS_Store: N files, XX KB
Total project: XX MB

Recommendations:
- [actionable items based on findings]
```

Recommend running `/clean-cache` if significant cache is found. Flag orphaned worktrees for manual review.
