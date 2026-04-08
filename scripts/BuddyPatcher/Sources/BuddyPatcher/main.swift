import Foundation

// ── Argument Parsing ─────────────────────────────────────────────────

struct Options {
    var species: String?
    var rarity: String?
    var shiny: Bool = false
    var noShiny: Bool = false
    var emoji: String?
    var name: String?
    var personality: String?
    var stats: String?
    var restore: Bool = false
    var dryRun: Bool = false
    var binary: String?
    var analyze: Bool = false
    var help: Bool = false
}

func printUsage() {
    let usage = """
    Buddy Customizer — evolve your Claude Code terminal pet

    USAGE:
      buddy-patcher [OPTIONS]

    OPTIONS:
      --species <name>        Target species (\(allSpecies.joined(separator: ", ")))
      --rarity <tier>         Target rarity (common, uncommon, rare, epic, legendary)
      --shiny                 Make buddy shiny (always)
      --no-shiny              Remove shiny (restore 1% probability)
      --emoji <emoji>         Custom emoji for buddy art (requires --species)
      --name <name>           Buddy name (written to ~/.claude.json)
      --personality <text>    Buddy personality description
      --stats <json>          Stats as JSON: {"debugging":99,...}
      --restore               Restore original buddy from backup
      --dry-run               Show what would change without applying
      --analyze               Analyze binary for pattern locations
      --binary <path>         Override binary path (for testing)
      --help                  Show this help message
    """
    print(usage)
}

func parseArgs() -> Options {
    var opts = Options()
    let args = CommandLine.arguments
    var i = 1 // skip program name
    while i < args.count {
        switch args[i] {
        case "--species":
            i += 1; guard i < args.count else { fputs("Error: --species requires a value\n", stderr); exit(1) }
            let val = args[i]
            guard allSpecies.contains(val) else {
                fputs("Error: invalid species '\(val)'. Valid: \(allSpecies.joined(separator: ", "))\n", stderr); exit(1)
            }
            opts.species = val
        case "--rarity":
            i += 1; guard i < args.count else { fputs("Error: --rarity requires a value\n", stderr); exit(1) }
            let val = args[i]
            guard validRarities.contains(val) else {
                fputs("Error: invalid rarity '\(val)'. Valid: \(validRarities.joined(separator: ", "))\n", stderr); exit(1)
            }
            opts.rarity = val
        case "--shiny":
            opts.shiny = true
        case "--no-shiny":
            opts.noShiny = true
        case "--emoji":
            i += 1; guard i < args.count else { fputs("Error: --emoji requires a value\n", stderr); exit(1) }
            opts.emoji = args[i]
        case "--name":
            i += 1; guard i < args.count else { fputs("Error: --name requires a value\n", stderr); exit(1) }
            opts.name = args[i]
        case "--personality":
            i += 1; guard i < args.count else { fputs("Error: --personality requires a value\n", stderr); exit(1) }
            opts.personality = args[i]
        case "--stats":
            i += 1; guard i < args.count else { fputs("Error: --stats requires a value\n", stderr); exit(1) }
            opts.stats = args[i]
        case "--restore":
            opts.restore = true
        case "--dry-run":
            opts.dryRun = true
        case "--binary":
            i += 1; guard i < args.count else { fputs("Error: --binary requires a value\n", stderr); exit(1) }
            opts.binary = args[i]
        case "--analyze":
            opts.analyze = true
        case "--help", "-h":
            opts.help = true
        default:
            fputs("Error: unknown option '\(args[i])'\n", stderr)
            printUsage()
            exit(1)
        }
        i += 1
    }
    return opts
}

// ── Analyze Mode ─────────────────────────────────────────────────────

func runAnalyze(data: [UInt8], binaryPath: URL) {
    print("  Binary Analysis")
    print("  ═══════════════")
    print()

    // Species anchor search
    print("  --- Species Anchor ---")
    var foundAnchor = false
    for varMap in knownVarMaps {
        let anchor = anchorForMap(varMap)
        let anchorStr = String(bytes: anchor, encoding: .utf8) ?? "?"
        if let idx = findFirst(in: data, pattern: anchor) {
            print("  [+] Anchor found at offset 0x\(String(idx, radix: 16)): \(anchorStr)")
            // Extract surrounding context
            let start = max(0, idx - 20)
            let end = min(data.count, idx + 200)
            let region = Array(data[start..<end])
            // Find array bounds
            if let arrStart = region.lastIndex(of: 0x5B), // [
               let arrEnd = region.firstIndex(of: 0x5D) { // ]
                let arrContent = Array(region[arrStart...arrEnd])
                if let str = String(bytes: arrContent, encoding: .utf8) {
                    print("  [+] Species array: \(str)")
                }
            }
            foundAnchor = true
            break
        }
    }
    if !foundAnchor {
        print("  [!] Anchor NOT FOUND — binary structure has changed")
        // Search for 3-char variable ref patterns
        var candidates = Set<String>()
        for i in 0..<(data.count - 2) {
            let c0 = data[i], c1 = data[i+1], c2 = data[i+2]
            // Pattern: [A-Za-z][0-9]_ (e.g., GL_, b0_)
            let isLetter = (c0 >= 0x41 && c0 <= 0x5A) || (c0 >= 0x61 && c0 <= 0x7A)
            let isDigit = c1 >= 0x30 && c1 <= 0x39
            let isUnder = c2 == 0x5F // _
            if isLetter && isDigit && isUnder {
                if let s = String(bytes: [c0, c1, c2], encoding: .utf8) {
                    candidates.insert(s)
                }
            }
        }
        // Also check [A-Za-z][A-Z]_ pattern (e.g., GL_, VL_)
        for i in 0..<(data.count - 2) {
            let c0 = data[i], c1 = data[i+1], c2 = data[i+2]
            let isLetter = (c0 >= 0x41 && c0 <= 0x5A) || (c0 >= 0x61 && c0 <= 0x7A)
            let isUpper = c1 >= 0x41 && c1 <= 0x5A
            let isUnder = c2 == 0x5F
            if isLetter && isUpper && isUnder {
                if let s = String(bytes: [c0, c1, c2], encoding: .utf8) {
                    candidates.insert(s)
                }
            }
        }
        let sorted = candidates.sorted()
        print("  [?] Found \(sorted.count) potential 3-byte variable refs:")
        for c in sorted.prefix(30) {
            print("      \(c)")
        }
    }

    print()

    // Rarity weight search
    print("  --- Rarity Weights ---")
    let originalWeights = utf8Bytes("common:60,uncommon:25,rare:10,epic:4,legendary:1")
    if let idx = findFirst(in: data, pattern: originalWeights) {
        print("  [+] Original rarity weights found at 0x\(String(idx, radix: 16))")
    } else {
        // Try patched variants
        var foundRarity = false
        for r in validRarities {
            let rarityWeights: [(String, String)] = [
                ("common", "60"), ("uncommon", "25"), ("rare", "10"), ("epic", "4"), ("legendary", "1")
            ]
            var parts: [String] = []
            for (rarity, weight) in rarityWeights {
                if rarity == r {
                    parts.append("\(rarity):\(weight.count == 2 ? "01" : "1")")
                } else {
                    parts.append("\(rarity):\(weight.count == 2 ? "00" : "0")")
                }
            }
            let pattern = utf8Bytes(parts.joined(separator: ","))
            if let idx = findFirst(in: data, pattern: pattern) {
                let patternStr = String(bytes: pattern, encoding: .utf8) ?? "?"
                print("  [+] Rarity weights (patched) found at 0x\(String(idx, radix: 16)): \(patternStr)")
                foundRarity = true
                break
            }
        }
        if !foundRarity {
            print("  [!] Rarity weights NOT FOUND")
        }
    }

    print()

    // Shiny threshold search
    print("  --- Shiny Threshold ---")
    var foundShiny = false
    for pattern in [utf8Bytes("H()<0.01"), utf8Bytes("H()<1.01")] {
        if let idx = findFirst(in: data, pattern: pattern) {
            let patternStr = String(bytes: pattern, encoding: .utf8) ?? "?"
            print("  [+] Shiny threshold found at 0x\(String(idx, radix: 16)): \(patternStr)")
            foundShiny = true
            break
        }
    }
    if !foundShiny {
        print("  [!] Shiny threshold NOT FOUND")
    }
}

// ── Main ─────────────────────────────────────────────────────────────

let opts = parseArgs()

if opts.help {
    printUsage()
    exit(0)
}

print()
print("  🍄 Buddy Customizer v1.0.0")
print("  ═══════════════════════════")
print()

// Find binary
let binaryPath: URL
do {
    if let override = opts.binary {
        binaryPath = URL(fileURLWithPath: override)
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
        try outputData.write(to: binaryPath)
    } catch {
        print("  [!] ERROR: Failed to write binary: \(error)")
        exit(1)
    }
    print("  [+] Wrote \(formatNumber(data.count)) bytes with \(totalPatches) patches")
    resignBinary(binaryPath)

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

// ── Helpers ──────────────────────────────────────────────────────────

func formatNumber(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
}
