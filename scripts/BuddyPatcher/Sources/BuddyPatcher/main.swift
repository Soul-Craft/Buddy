import Foundation
import BuddyPatcherLib

// ── Main ─────────────────────────────────────────────────────────────

var opts = parseArgs()

if opts.help {
    printUsage()
    exit(0)
}

// ── Input Validation ────────────────────────────────────────────────

if let emoji = opts.emoji {
    guard let validated = validateEmoji(emoji) else { exit(1) }
    opts.emoji = validated
}

if let name = opts.name {
    guard let validated = validateName(name) else { exit(1) }
    opts.name = validated
}

if let personality = opts.personality {
    guard let validated = validatePersonality(personality) else { exit(1) }
    opts.personality = validated
}

if let statsJSON = opts.stats {
    guard validateStats(statsJSON) != nil else { exit(1) }
    // Keep original JSON string; it's re-parsed later in saveMetadata
}

print()
print("  🍄 Buddy Customizer v1.0.0")
print("  ═══════════════════════════")
print()

// Find binary
let binaryPath: URL
do {
    if let override = opts.binary {
        guard let validated = validateBinaryPath(override) else { exit(1) }
        binaryPath = validated
    } else {
        binaryPath = try findBinary()
    }
} catch {
    print("  [!] ERROR: \(error)")
    exit(1)
}

print("  Binary: \(binaryPath.path)")
print("  Version: \(getVersion(binaryPath))")
print()

// Analyze mode
if opts.analyze {
    guard let rawData = FileManager.default.contents(atPath: binaryPath.path) else {
        print("  [!] ERROR: Could not read binary")
        exit(1)
    }
    let data = [UInt8](rawData)
    print("  Read \(formatNumber(data.count)) bytes")
    print()
    runAnalyze(data: data, binaryPath: binaryPath)
    exit(0)
}

// Restore mode
if opts.restore {
    if opts.dryRun {
        print("  [DRY RUN] Would restore from backup")
        exit(0)
    }
    if restoreBackup(binaryPath) {
        if FileManager.default.fileExists(atPath: metaFile.path) {
            try? FileManager.default.removeItem(at: metaFile)
        }
        exit(0)
    } else {
        exit(1)
    }
}

// Validate we have something to do
let hasWork = opts.species != nil || opts.rarity != nil || opts.shiny || opts.noShiny ||
    opts.emoji != nil || opts.name != nil || opts.personality != nil || opts.stats != nil
if !hasWork {
    print("  [!] Nothing to customize. Use --species, --rarity, --shiny, --emoji, --name, --personality, or --stats")
    printUsage()
    exit(1)
}

if opts.dryRun {
    print("  [DRY RUN MODE — no changes will be applied]")
    print()
}

// Backup
if !opts.dryRun {
    ensureBackup(binaryPath)
    print()
}

// Read binary
guard let rawData = FileManager.default.contents(atPath: binaryPath.path) else {
    print("  [!] ERROR: Could not read binary at \(binaryPath.path)")
    exit(1)
}
var data = [UInt8](rawData)
print("  Read \(formatNumber(data.count)) bytes")

// Detect variable map
var activeVarMap: [String: String]
var activeAnchor: [UInt8]

if let detected = detectVarMap(in: data) {
    activeVarMap = detected.varMap
    activeAnchor = detected.anchor
    let sampleVar = activeVarMap["duck"] ?? "?"
    let anchorStr = String(bytes: activeAnchor, encoding: .utf8) ?? "?"
    print("  Detected variable format: \(sampleVar) (anchor: \(anchorStr)...)")
} else {
    activeVarMap = knownVarMaps[0]
    activeAnchor = anchorForMap(activeVarMap)
    print("  [!] WARNING: No known anchor matched — using newest variable map as fallback")
}
print()

var totalPatches = 0

// Apply patches
if let species = opts.species {
    if opts.dryRun {
        print("  [DRY RUN] Would patch species → \(species) (\(activeVarMap[species] ?? "?"))")
    } else {
        totalPatches += patchSpecies(&data, target: species, anchor: activeAnchor, varMap: activeVarMap)
    }
}

if let rarity = opts.rarity {
    if opts.dryRun {
        print("  [DRY RUN] Would patch rarity → \(rarity)")
    } else {
        totalPatches += patchRarity(&data, target: rarity)
    }
}

if opts.shiny {
    if opts.dryRun {
        print("  [DRY RUN] Would patch shiny → always true")
    } else {
        totalPatches += patchShiny(&data, makeShiny: true)
    }
} else if opts.noShiny {
    if opts.dryRun {
        print("  [DRY RUN] Would patch shiny → normal (1%)")
    } else {
        totalPatches += patchShiny(&data, makeShiny: false)
    }
}

if let emoji = opts.emoji, let species = opts.species {
    if opts.dryRun {
        print("  [DRY RUN] Would patch art → \(emoji)")
    } else {
        totalPatches += patchArt(&data, target: species, emoji: emoji, varMap: activeVarMap)
    }
} else if opts.emoji != nil && opts.species == nil {
    print("  [!] WARNING: --emoji requires --species to know which art to replace")
}

// Write binary
if !opts.dryRun && totalPatches > 0 {
    print()
    let outputData = Data(data)
    do {
        try outputData.write(to: binaryPath, options: .atomic)
    } catch {
        print("  [!] ERROR: Failed to write binary: \(error)")
        exit(1)
    }
    print("  [+] Wrote \(formatNumber(data.count)) bytes with \(totalPatches) patches")

    if !resignBinary(binaryPath) {
        print()
        print("  [!] Codesign failed — restoring backup to prevent unsigned binary...")
        let _ = restoreBackup(binaryPath)
        print("  [!] Restored original binary. Codesign is required for macOS to run the binary.")
        exit(1)
    }

    // Verify patched binary still works
    print("  [~] Verifying patched binary...")
    if verifyBinary(binaryPath) {
        print("  [+] Binary verification passed")
    } else {
        print()
        print("  [!] Patched binary failed verification — restoring backup...")
        let _ = restoreBackup(binaryPath)
        print("  [!] Your original buddy has been restored. No harm done.")
        print("  [!] Run /test-patch to check if anchor patterns need updating.")
        exit(1)
    }
}

// Patch soul (separate from binary)
if opts.name != nil || opts.personality != nil {
    print()
    if opts.dryRun {
        if let name = opts.name {
            print("  [DRY RUN] Would set name → \(name)")
        }
        if let personality = opts.personality {
            print("  [DRY RUN] Would set personality → \(personality)")
        }
    } else {
        let _ = patchSoul(name: opts.name, personality: opts.personality)
    }
}

// Save metadata
if !opts.dryRun {
    print()
    var statsDict: [String: Any]?
    if let statsJSON = opts.stats,
       let statsData = statsJSON.data(using: .utf8),
       let parsed = try? JSONSerialization.jsonObject(with: statsData) as? [String: Any] {
        statsDict = parsed
    }
    saveMetadata(
        binaryPath: binaryPath,
        species: opts.species,
        rarity: opts.rarity,
        shiny: opts.shiny,
        emoji: opts.emoji,
        name: opts.name,
        personality: opts.personality,
        stats: statsDict
    )
}

print()
if opts.dryRun {
    print("  [DRY RUN] No changes were made.")
} else {
    print("  ✅ Evolution complete! \(totalPatches) binary patches applied.")
    print()
    print("  ⚠️  Restart Claude Code to see your evolved buddy:")
    print("     pkill -f claude && claude")
    print()
    print("  To revert: run-buddy-patcher.sh --restore")
}
