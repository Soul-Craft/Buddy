import Foundation
import BuddyPatcherLib

// ── Main ─────────────────────────────────────────────────────────────

var opts = parseArgs()

if opts.showVersion {
    print("buddy-patcher \(buddyPatcherVersion)")
    exit(0)
}

if opts.help {
    printUsage()
    exit(0)
}

// ── Input Validation ────────────────────────────────────────────────

if let emoji = opts.metaEmoji {
    guard let validated = validateEmoji(emoji) else { exit(1) }
    opts.metaEmoji = validated
}

if let name = opts.name {
    guard let validated = validateName(name) else { exit(1) }
    opts.name = validated
}

if let personality = opts.personality {
    guard let validated = validatePersonality(personality) else { exit(1) }
    opts.personality = validated
}

if let statsJSON = opts.metaStats {
    guard validateStats(statsJSON) != nil else { exit(1) }
}

print()
print("  🍄 Buddy Customizer v\(buddyPatcherVersion)")
print("  ═══════════════════════════════════")
print()

// ── Restore mode ────────────────────────────────────────────────────

if opts.restore {
    if opts.dryRun {
        print("  [DRY RUN] Would restore soul from backup and remove metadata")
        exit(0)
    }
    let success = restoreSoulBackup()
    removeMetadata()
    if success {
        print()
        print("  ✅ Buddy reset! Soul restored from backup.")
        print("     Changes take effect on your next Claude Code session.")
    } else {
        exit(1)
    }
    exit(0)
}

// ── Validate we have something to do ────────────────────────────────

if !hasPatchWork(opts) {
    print("  [!] Nothing to customize. Use --name, --personality, or --meta-* flags.")
    printUsage()
    exit(1)
}

// ── Dry-run mode ────────────────────────────────────────────────────

if opts.dryRun {
    print("  [DRY RUN MODE — no changes will be applied]")
    print()
    if let name = opts.name { print("  [DRY RUN] Would set name → \(name)") }
    if let p = opts.personality { print("  [DRY RUN] Would set personality → \(p)") }
    if let s = opts.metaSpecies { print("  [DRY RUN] Would set card species → \(s)") }
    if let r = opts.metaRarity { print("  [DRY RUN] Would set card rarity → \(r)") }
    if opts.metaShiny { print("  [DRY RUN] Would set card shiny → true") }
    if opts.metaNoShiny { print("  [DRY RUN] Would set card shiny → false") }
    if let e = opts.metaEmoji { print("  [DRY RUN] Would set card emoji → \(e)") }
    if let st = opts.metaStats { print("  [DRY RUN] Would set card stats → \(st)") }
    print()
    print("  [DRY RUN] No changes were made.")
    exit(0)
}

// ── Backup soul ──────────────────────────────────────────────────────

ensureSoulBackup()
print()

// ── Run pipeline ─────────────────────────────────────────────────────

let result = runSoulPipeline(opts: opts)

for warning in result.warnings {
    print("  [!] WARNING: \(warning)")
}

print()

var parts: [String] = []
if result.soulWritten { parts.append("soul written") }
if result.metadataWritten { parts.append("card metadata saved") }

if parts.isEmpty {
    print("  ⚠️  Nothing was written.")
} else {
    print("  ✅ Evolution complete! \(parts.joined(separator: ", ")).")
    print()
    print("  Name and personality take effect on your next Claude Code session.")
    print("  Run /buddy-status to see your updated card.")
    print()
    print("  To revert: run-buddy-patcher.sh --restore")
}
