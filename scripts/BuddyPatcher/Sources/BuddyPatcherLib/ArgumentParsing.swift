import Foundation

// ── Constants (previously in VariableMapDetection.swift) ─────────────

public let allSpecies: [String] = [
    "duck", "goose", "blob", "cat", "dragon", "octopus", "owl", "penguin",
    "turtle", "snail", "axolotl", "ghost", "robot", "mushroom", "cactus",
    "rabbit", "chonk", "capybara",
]
public let validRarities = ["common", "uncommon", "rare", "epic", "legendary"]
public let statNames = ["debugging", "patience", "chaos", "wisdom", "snark"]
public let buddyPatcherVersion = "2.0.0"

// ── Options ──────────────────────────────────────────────────────────

public struct Options {
    // Soul (written to ~/.claude.json — Claude Code reads these)
    public var name: String?
    public var personality: String?

    // Card metadata (plugin-local — drives the /buddy-status card)
    public var metaSpecies: String?
    public var metaRarity: String?
    public var metaShiny: Bool = false
    public var metaNoShiny: Bool = false
    public var metaEmoji: String?
    public var metaStats: String?

    // Control
    public var restore: Bool = false
    public var dryRun: Bool = false
    public var help: Bool = false
    public var showVersion: Bool = false

    public init() {}
}

// ── Errors ───────────────────────────────────────────────────────────

public enum ParseError: Error, CustomStringConvertible {
    case missingValue(String)
    case invalidSpecies(String)
    case invalidRarity(String)
    case unknownOption(String)

    public var description: String {
        switch self {
        case .missingValue(let flag): return "\(flag) requires a value"
        case .invalidSpecies(let val):
            return "invalid species '\(val)'. Valid: \(allSpecies.joined(separator: ", "))"
        case .invalidRarity(let val):
            return "invalid rarity '\(val)'. Valid: \(validRarities.joined(separator: ", "))"
        case .unknownOption(let opt): return "unknown option '\(opt)'"
        }
    }
}

// ── Help ─────────────────────────────────────────────────────────────

public func printUsage() {
    let usage = """
    Buddy Customizer v\(buddyPatcherVersion) — evolve your Claude Code companion

    USAGE:
      buddy-patcher [OPTIONS]

    SOUL OPTIONS (written to ~/.claude.json — Claude Code reads these):
      --name <name>               Buddy name
      --personality <text>        Buddy personality description

    CARD OPTIONS (plugin-local — drive the /buddy-status card):
      --meta-species <name>       Species (\(allSpecies.joined(separator: ", ")))
      --meta-rarity <tier>        Rarity (common, uncommon, rare, epic, legendary)
      --meta-shiny                Mark buddy as shiny
      --meta-no-shiny             Remove shiny flag
      --meta-emoji <emoji>        Custom emoji for card display
      --meta-stats <json>         Stats as JSON: {"debugging":99,...}

    OTHER:
      --restore                   Restore soul from backup
      --dry-run                   Show what would change without applying
      --version                   Show version
      --help, -h                  Show this help message

    NOTE: Name and personality reach Claude Code via companion_intro.
          Species, rarity, shiny, emoji, and stats are plugin-local card flair only.
    """
    print(usage)
}

// ── Parsing ──────────────────────────────────────────────────────────

/// Parse arguments from an explicit array (testable).
public func parseArgs(from args: [String]) throws -> Options {
    var opts = Options()
    var i = 1  // skip program name
    while i < args.count {
        switch args[i] {
        case "--name":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--name") }
            opts.name = args[i]
        case "--personality":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--personality") }
            opts.personality = args[i]
        case "--meta-species":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--meta-species") }
            let val = args[i]
            guard allSpecies.contains(val) else { throw ParseError.invalidSpecies(val) }
            opts.metaSpecies = val
        case "--meta-rarity":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--meta-rarity") }
            let val = args[i]
            guard validRarities.contains(val) else { throw ParseError.invalidRarity(val) }
            opts.metaRarity = val
        case "--meta-shiny":
            opts.metaShiny = true
        case "--meta-no-shiny":
            opts.metaNoShiny = true
        case "--meta-emoji":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--meta-emoji") }
            opts.metaEmoji = args[i]
        case "--meta-stats":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--meta-stats") }
            opts.metaStats = args[i]
        case "--restore":
            opts.restore = true
        case "--dry-run":
            opts.dryRun = true
        case "--version":
            opts.showVersion = true
        case "--help", "-h":
            opts.help = true
        default:
            throw ParseError.unknownOption(args[i])
        }
        i += 1
    }
    return opts
}

/// Parse arguments from CommandLine (convenience for the executable).
public func parseArgs() -> Options {
    do {
        return try parseArgs(from: CommandLine.arguments)
    } catch {
        fputs("Error: \(error)\n", stderr)
        printUsage()
        exit(1)
    }
}
