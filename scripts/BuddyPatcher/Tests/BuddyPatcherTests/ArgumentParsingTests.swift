import XCTest
@testable import BuddyPatcherLib

final class ArgumentParsingTests: XCTestCase {

    // MARK: - Soul flags

    func testParseName() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--name", "Aethos"])
        XCTAssertEqual(opts.name, "Aethos")
    }

    func testParsePersonality() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--personality", "a wise old penguin"])
        XCTAssertEqual(opts.personality, "a wise old penguin")
    }

    // MARK: - Card metadata flags

    func testParseMetaSpecies() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--meta-species", "penguin"])
        XCTAssertEqual(opts.metaSpecies, "penguin")
    }

    func testParseMetaRarity() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--meta-rarity", "legendary"])
        XCTAssertEqual(opts.metaRarity, "legendary")
    }

    func testParseMetaShiny() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--meta-shiny"])
        XCTAssertTrue(opts.metaShiny)
    }

    func testParseMetaNoShiny() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--meta-no-shiny"])
        XCTAssertTrue(opts.metaNoShiny)
    }

    func testParseMetaEmoji() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--meta-emoji", "🍄"])
        XCTAssertEqual(opts.metaEmoji, "🍄")
    }

    func testParseMetaStats() throws {
        let json = "{\"debugging\":99}"
        let opts = try parseArgs(from: ["buddy-patcher", "--meta-stats", json])
        XCTAssertEqual(opts.metaStats, json)
    }

    // MARK: - Control flags

    func testParseRestore() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--restore"])
        XCTAssertTrue(opts.restore)
    }

    func testParseDryRun() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--dry-run"])
        XCTAssertTrue(opts.dryRun)
    }

    func testParseVersion() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--version"])
        XCTAssertTrue(opts.showVersion)
    }

    func testParseHelp() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--help"])
        XCTAssertTrue(opts.help)
    }

    func testParseHelpShort() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "-h"])
        XCTAssertTrue(opts.help)
    }

    // MARK: - Combined flags

    func testParseCombined() throws {
        let opts = try parseArgs(from: [
            "buddy-patcher",
            "--name", "Aethos",
            "--meta-species", "dragon",
            "--meta-rarity", "legendary",
            "--meta-shiny",
            "--dry-run",
        ])
        XCTAssertEqual(opts.name, "Aethos")
        XCTAssertEqual(opts.metaSpecies, "dragon")
        XCTAssertEqual(opts.metaRarity, "legendary")
        XCTAssertTrue(opts.metaShiny)
        XCTAssertTrue(opts.dryRun)
    }

    func testParseNoArgs() throws {
        let opts = try parseArgs(from: ["buddy-patcher"])
        XCTAssertNil(opts.name)
        XCTAssertNil(opts.metaSpecies)
        XCTAssertFalse(opts.metaShiny)
        XCTAssertFalse(opts.restore)
    }

    // MARK: - Error cases

    func testParseMissingNameValue() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--name"])) { error in
            XCTAssertTrue(error is ParseError)
        }
    }

    func testParseInvalidMetaSpecies() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--meta-species", "unicorn"])) { error in
            guard let parseError = error as? ParseError else { XCTFail("Expected ParseError"); return }
            XCTAssertTrue(parseError.description.contains("invalid species"))
        }
    }

    func testParseInvalidMetaRarity() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--meta-rarity", "mythic"])) { error in
            guard let parseError = error as? ParseError else { XCTFail("Expected ParseError"); return }
            XCTAssertTrue(parseError.description.contains("invalid rarity"))
        }
    }

    func testParseUnknownFlag() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--bogus"])) { error in
            guard let parseError = error as? ParseError else { XCTFail("Expected ParseError"); return }
            XCTAssertTrue(parseError.description.contains("unknown option"))
        }
    }

    // Old binary-patching flags must now be rejected
    func testParseOldSpeciesFlagRejected() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--species", "penguin"])) { error in
            guard let parseError = error as? ParseError else { XCTFail("Expected ParseError"); return }
            XCTAssertTrue(parseError.description.contains("unknown option"))
        }
    }

    func testParseOldRarityFlagRejected() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--rarity", "legendary"])) { error in
            guard let parseError = error as? ParseError else { XCTFail("Expected ParseError"); return }
            XCTAssertTrue(parseError.description.contains("unknown option"))
        }
    }

    func testParseOldAnalyzeFlagRejected() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--analyze"])) { error in
            guard let parseError = error as? ParseError else { XCTFail("Expected ParseError"); return }
            XCTAssertTrue(parseError.description.contains("unknown option"))
        }
    }
}
