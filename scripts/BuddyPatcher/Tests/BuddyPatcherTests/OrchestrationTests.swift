import XCTest
@testable import BuddyPatcherLib

final class OrchestrationTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrchestrationTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func configPath() -> URL { tempDir.appendingPathComponent(".claude.json") }
    private func metaPath() -> URL { tempDir.appendingPathComponent("buddy-patch-meta.json") }

    private func writeConfig(_ json: String) {
        try! json.data(using: .utf8)!.write(to: configPath())
    }

    // MARK: - hasPatchWork

    func testHasPatchWorkDetectsName() {
        var opts = Options()
        opts.name = "Aethos"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsPersonality() {
        var opts = Options()
        opts.personality = "wise"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsMetaSpecies() {
        var opts = Options()
        opts.metaSpecies = "penguin"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsMetaRarity() {
        var opts = Options()
        opts.metaRarity = "legendary"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsMetaShiny() {
        var opts = Options()
        opts.metaShiny = true
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsMetaNoShiny() {
        var opts = Options()
        opts.metaNoShiny = true
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsMetaEmoji() {
        var opts = Options()
        opts.metaEmoji = "🔥"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsMetaStats() {
        var opts = Options()
        opts.metaStats = "{\"debugging\":50}"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkFalseForEmpty() {
        let opts = Options()
        XCTAssertFalse(hasPatchWork(opts))
    }

    // MARK: - runSoulPipeline — soul writes

    func testPipelineWritesSoul() {
        writeConfig("{\"companion\":{}}")
        var opts = Options()
        opts.name = "Aethos"
        opts.personality = "wise"

        let result = runSoulPipeline(opts: opts, configPath: configPath(), metaPath: metaPath())

        XCTAssertTrue(result.soulWritten)
        XCTAssertTrue(result.warnings.isEmpty)

        let data = try! Data(contentsOf: configPath())
        let config = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let companion = config["companion"] as! [String: Any]
        XCTAssertEqual(companion["name"] as? String, "Aethos")
        XCTAssertEqual(companion["personality"] as? String, "wise")
    }

    func testPipelineWritesMetadata() {
        writeConfig("{\"companion\":{}}")
        var opts = Options()
        opts.metaSpecies = "dragon"
        opts.metaRarity = "legendary"
        opts.metaShiny = true

        let result = runSoulPipeline(opts: opts, configPath: configPath(), metaPath: metaPath())

        XCTAssertTrue(result.metadataWritten)
        XCTAssertTrue(result.warnings.isEmpty)

        let meta = loadMetadata(metaPath: metaPath())
        XCTAssertNotNil(meta)
        XCTAssertEqual(meta?["species"] as? String, "dragon")
        XCTAssertEqual(meta?["rarity"] as? String, "legendary")
        XCTAssertEqual(meta?["shiny"] as? Bool, true)
        XCTAssertEqual(meta?["schema_version"] as? Int, 2)
    }

    func testPipelineWarnsWhenSoulWriteFails() {
        // configPath doesn't exist → patchSoul returns false → warning recorded
        var opts = Options()
        opts.name = "Test"

        let result = runSoulPipeline(opts: opts, configPath: configPath(), metaPath: metaPath())

        XCTAssertFalse(result.soulWritten)
        XCTAssertTrue(result.warnings.contains { $0.contains("Soul write failed") })
    }

    func testPipelineNoOpWhenNoWork() {
        let opts = Options()
        let result = runSoulPipeline(opts: opts, configPath: configPath(), metaPath: metaPath())

        XCTAssertFalse(result.soulWritten)
        XCTAssertFalse(result.metadataWritten)
        XCTAssertTrue(result.warnings.isEmpty)
    }

    func testPipelineShinyPrecedesNoShiny() {
        writeConfig("{\"companion\":{}}")
        var opts = Options()
        opts.metaShiny = true
        opts.metaNoShiny = true  // metaShiny wins

        let result = runSoulPipeline(opts: opts, configPath: configPath(), metaPath: metaPath())

        XCTAssertTrue(result.metadataWritten)
        let meta = loadMetadata(metaPath: metaPath())
        XCTAssertEqual(meta?["shiny"] as? Bool, true, "metaShiny should take precedence over metaNoShiny")
    }

    func testPipelineSchemaVersionIsTwo() {
        writeConfig("{\"companion\":{}}")
        var opts = Options()
        opts.name = "Buddy"

        let result = runSoulPipeline(opts: opts, configPath: configPath(), metaPath: metaPath())

        XCTAssertTrue(result.metadataWritten)
        let meta = loadMetadata(metaPath: metaPath())
        XCTAssertEqual(meta?["schema_version"] as? Int, 2)
    }
}
