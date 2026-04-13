import Foundation

// ── Orchestration ────────────────────────────────────────────────────
//
// Soul-only pipeline: writes companion name/personality to ~/.claude.json
// and saves plugin-local metadata for the /buddy-status card.
// No binary patching. No codesign. No restart required.

public struct SoulPipelineResult {
    public let soulWritten: Bool
    public let metadataWritten: Bool
    public let warnings: [String]

    public init(soulWritten: Bool, metadataWritten: Bool, warnings: [String]) {
        self.soulWritten = soulWritten
        self.metadataWritten = metadataWritten
        self.warnings = warnings
    }
}

/// Returns true when opts contain any soul or card metadata to write.
public func hasPatchWork(_ opts: Options) -> Bool {
    return opts.name != nil || opts.personality != nil
        || opts.metaSpecies != nil || opts.metaRarity != nil
        || opts.metaShiny || opts.metaNoShiny
        || opts.metaEmoji != nil || opts.metaStats != nil
}

/// Run the soul pipeline: patch companion in ~/.claude.json, save card metadata.
/// configPath and metaPath override defaults (for testing via BUDDY_HOME).
public func runSoulPipeline(opts: Options, configPath: URL? = nil,
                            metaPath: URL? = nil) -> SoulPipelineResult {
    var warnings: [String] = []

    // Soul write (name + personality → ~/.claude.json#companion)
    let soulWritten: Bool
    if opts.name != nil || opts.personality != nil {
        soulWritten = patchSoul(name: opts.name, personality: opts.personality, configPath: configPath)
        if !soulWritten {
            warnings.append("Soul write failed — ~/.claude.json may be missing or malformed")
        }
    } else {
        soulWritten = false
    }

    // Card metadata write (cosmetic state for /buddy-status)
    let hasMetadata = opts.metaSpecies != nil || opts.metaRarity != nil
        || opts.metaShiny || opts.metaNoShiny || opts.metaEmoji != nil
        || opts.metaStats != nil || opts.name != nil || opts.personality != nil

    let metadataWritten: Bool
    if hasMetadata {
        var statsDict: [String: Any]?
        if let statsJSON = opts.metaStats,
           let statsData = statsJSON.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: statsData) as? [String: Any] {
            statsDict = parsed
        }
        // metaShiny takes precedence over metaNoShiny when both are set
        let shiny = opts.metaShiny ? true : (opts.metaNoShiny ? false : false)
        saveMetadata(
            species: opts.metaSpecies,
            rarity: opts.metaRarity,
            shiny: shiny,
            emoji: opts.metaEmoji,
            name: opts.name,
            personality: opts.personality,
            stats: statsDict,
            metaPath: metaPath
        )
        metadataWritten = true
    } else {
        metadataWritten = false
    }

    return SoulPipelineResult(soulWritten: soulWritten, metadataWritten: metadataWritten,
                              warnings: warnings)
}
