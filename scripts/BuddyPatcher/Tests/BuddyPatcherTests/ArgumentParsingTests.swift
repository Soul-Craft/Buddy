import XCTest
@testable import BuddyPatcherLib

final class ArgumentParsingTests: XCTestCase {

    // MARK: - Valid flags

    func testParseSpecies() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--species", "penguin"])
        XCTAssertEqual(opts.species, "penguin")
    }

    func testParseRarity() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--rarity", "legendary"])
        XCTAssertEqual(opts.rarity, "legendary")
    }

    func testParseShiny() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--shiny"])
        XCTAssertTrue(opts.shiny)
    }

    func testParseNoShiny() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--no-shiny"])
        XCTAssertTrue(opts.noShiny)
    }

    func testParseEmoji() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--emoji", "🍄"])
        XCTAssertEqual(opts.emoji, "🍄")
    }

    func testParseName() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--name", "Aethos"])
        XCTAssertEqual(opts.name, "Aethos")
    }

    func testParsePersonality() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--personality", "a wise old penguin"])
        XCTAssertEqual(opts.personality, "a wise old penguin")
    }

    func testParseStats() throws {
        let json = "{\"debugging\":99}"
        let opts = try parseArgs(from: ["buddy-patcher", "--stats", json])
        XCTAssertEqual(opts.stats, json)
    }

    func testParseRestore() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--restore"])
        XCTAssertTrue(opts.restore)
    }

    func testParseDryRun() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--dry-run"])
        XCTAssertTrue(opts.dryRun)
    }

    func testParseBinary() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--binary", "/tmp/test"])
        XCTAssertEqual(opts.binary, "/tmp/test")
    }

    func testParseAnalyze() throws {
        let opts = try parseArgs(from: ["buddy-patcher", "--analyze"])
        XCTAssertTrue(opts.analyze)
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
            "--species", "penguin",
            "--rarity", "legendary",
            "--shiny",
            "--emoji", "🐧",
            "--dry-run"
        ])
        XCTAssertEqual(opts.species, "penguin")
        XCTAssertEqual(opts.rarity, "legendary")
        XCTAssertTrue(opts.shiny)
        XCTAssertEqual(opts.emoji, "🐧")
        XCTAssertTrue(opts.dryRun)
    }

    func testParseNoArgs() throws {
        let opts = try parseArgs(from: ["buddy-patcher"])
        XCTAssertNil(opts.species)
        XCTAssertNil(opts.rarity)
        XCTAssertFalse(opts.shiny)
        XCTAssertFalse(opts.restore)
    }

    // MARK: - Error cases

    func testParseMissingSpeciesValue() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--species"])) { error in
            XCTAssertTrue(error is ParseError)
        }
    }

    func testParseInvalidSpecies() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--species", "unicorn"])) { error in
            guard let parseError = error as? ParseError else {
                XCTFail("Expected ParseError"); return
            }
            XCTAssertTrue(parseError.description.contains("invalid species"))
        }
    }

    func testParseInvalidRarity() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--rarity", "mythic"])) { error in
            guard let parseError = error as? ParseError else {
                XCTFail("Expected ParseError"); return
            }
            XCTAssertTrue(parseError.description.contains("invalid rarity"))
        }
    }

    func testParseUnknownFlag() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--bogus"])) { error in
            guard let parseError = error as? ParseError else {
                XCTFail("Expected ParseError"); return
            }
            XCTAssertTrue(parseError.description.contains("unknown option"))
        }
    }

    func testParseMissingRarityValue() {
        XCTAssertThrowsError(try parseArgs(from: ["buddy-patcher", "--rarity"])) { error in
            XCTAssertTrue(error is ParseError)
        }
    }
}
