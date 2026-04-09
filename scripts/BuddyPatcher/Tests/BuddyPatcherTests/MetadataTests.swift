import XCTest
@testable import BuddyPatcherLib

final class MetadataTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuddyPatcherMetaTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func metaPath() -> URL {
        tempDir.appendingPathComponent("buddy-patch-meta.json")
    }

    func testSaveAndLoadRoundTrip() {
        let binaryPath = URL(fileURLWithPath: "/fake/path/2.1.90")
        saveMetadata(
            binaryPath: binaryPath,
            species: "penguin",
            rarity: "legendary",
            shiny: true,
            emoji: "🐧",
            name: "Aethos",
            personality: "wise",
            stats: ["debugging": 99],
            metaPath: metaPath()
        )

        let loaded = loadMetadata(metaPath: metaPath())
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?["species"] as? String, "penguin")
        XCTAssertEqual(loaded?["rarity"] as? String, "legendary")
        XCTAssertEqual(loaded?["shiny"] as? Bool, true)
        XCTAssertEqual(loaded?["emoji"] as? String, "🐧")
        XCTAssertEqual(loaded?["name"] as? String, "Aethos")
        XCTAssertEqual(loaded?["personality"] as? String, "wise")
        XCTAssertEqual(loaded?["version"] as? String, "2.1.90")
    }

    func testSavePartialFields() {
        let binaryPath = URL(fileURLWithPath: "/fake/path/2.1.90")
        saveMetadata(
            binaryPath: binaryPath,
            species: "duck",
            rarity: nil,
            shiny: false,
            emoji: nil,
            name: nil,
            personality: nil,
            stats: nil,
            metaPath: metaPath()
        )

        let loaded = loadMetadata(metaPath: metaPath())
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?["species"] as? String, "duck")
        XCTAssertNil(loaded?["rarity"])
        XCTAssertEqual(loaded?["shiny"] as? Bool, false)
    }

    func testLoadMissingFile() {
        let loaded = loadMetadata(metaPath: metaPath())
        XCTAssertNil(loaded)
    }

    func testLoadInvalidJSON() {
        try! "not json".data(using: .utf8)!.write(to: metaPath())
        let loaded = loadMetadata(metaPath: metaPath())
        XCTAssertNil(loaded)
    }
}
