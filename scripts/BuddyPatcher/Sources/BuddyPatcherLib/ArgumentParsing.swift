import Foundation

public struct Options {
    public var species: String?
    public var rarity: String?
    public var shiny: Bool = false
    public var noShiny: Bool = false
    public var emoji: String?
    public var name: String?
    public var personality: String?
    public var stats: String?
    public var restore: Bool = false
    public var dryRun: Bool = false
    public var binary: String?
    public var analyze: Bool = false
    public var help: Bool = false

    public init() {}
}

public enum ParseError: Error, CustomStringConvertible {
    case missingValue(String)
    case invalidSpecies(String)
    case invalidRarity(String)
    case unknownOption(String)

    public var description: String {
        switch self {
        case .missingValue(let flag): return "\(flag) requires a value"
        case .invalidSpecies(let val): return "invalid species '\(val)'. Valid: \(allSpecies.joined(separator: ", "))"
        case .invalidRarity(let val): return "invalid rarity '\(val)'. Valid: \(validRarities.joined(separator: ", "))"
        case .unknownOption(let opt): return "unknown option '\(opt)'"
        }
    }
}

public func printUsage() {
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

/// Parse arguments from an explicit array (testable).
public func parseArgs(from args: [String]) throws -> Options {
    var opts = Options()
    var i = 1 // skip program name
    while i < args.count {
        switch args[i] {
        case "--species":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--species") }
            let val = args[i]
            guard allSpecies.contains(val) else { throw ParseError.invalidSpecies(val) }
            opts.species = val
        case "--rarity":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--rarity") }
            let val = args[i]
            guard validRarities.contains(val) else { throw ParseError.invalidRarity(val) }
            opts.rarity = val
        case "--shiny":
            opts.shiny = true
        case "--no-shiny":
            opts.noShiny = true
        case "--emoji":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--emoji") }
            opts.emoji = args[i]
        case "--name":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--name") }
            opts.name = args[i]
        case "--personality":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--personality") }
            opts.personality = args[i]
        case "--stats":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--stats") }
            opts.stats = args[i]
        case "--restore":
            opts.restore = true
        case "--dry-run":
            opts.dryRun = true
        case "--binary":
            i += 1; guard i < args.count else { throw ParseError.missingValue("--binary") }
            opts.binary = args[i]
        case "--analyze":
            opts.analyze = true
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
