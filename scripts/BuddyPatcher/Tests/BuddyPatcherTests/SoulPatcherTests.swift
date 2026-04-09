import XCTest
@testable import BuddyPatcherLib

final class SoulPatcherTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuddyPatcherTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func configPath() -> URL {
        tempDir.appendingPathComponent(".claude.json")
    }

    private func writeConfig(_ json: String) {
        try! json.data(using: .utf8)!.write(to: configPath())
    }

    // MARK: - Tests

    func testPatchSoulSetsName() {
        writeConfig("{\"companion\":{}}")
        let result = patchSoul(name: "Aethos", personality: nil, configPath: configPath())
        XCTAssertTrue(result)

        let data = try! Data(contentsOf: configPath())
        let config = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let companion = config["companion"] as! [String: Any]
        XCTAssertEqual(companion["name"] as? String, "Aethos")
    }

    func testPatchSoulSetsPersonality() {
        writeConfig("{\"companion\":{}}")
        let result = patchSoul(name: nil, personality: "wise and kind", configPath: configPath())
        XCTAssertTrue(result)

        let data = try! Data(contentsOf: configPath())
        let config = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let companion = config["companion"] as! [String: Any]
        XCTAssertEqual(companion["personality"] as? String, "wise and kind")
    }

    func testPatchSoulSetsBoth() {
        writeConfig("{\"companion\":{}}")
        let result = patchSoul(name: "Buddy", personality: "cheerful", configPath: configPath())
        XCTAssertTrue(result)

        let data = try! Data(contentsOf: configPath())
        let config = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let companion = config["companion"] as! [String: Any]
        XCTAssertEqual(companion["name"] as? String, "Buddy")
        XCTAssertEqual(companion["personality"] as? String, "cheerful")
    }

    func testPatchSoulPreservesExistingFields() {
        writeConfig("{\"other_key\":\"preserved\",\"companion\":{\"existing\":true}}")
        let result = patchSoul(name: "Test", personality: nil, configPath: configPath())
        XCTAssertTrue(result)

        let data = try! Data(contentsOf: configPath())
        let config = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(config["other_key"] as? String, "preserved")
        let companion = config["companion"] as! [String: Any]
        XCTAssertEqual(companion["existing"] as? Bool, true)
        XCTAssertEqual(companion["name"] as? String, "Test")
    }

    func testPatchSoulCreatesCompanionSection() {
        writeConfig("{\"some_key\":\"value\"}")
        let result = patchSoul(name: "New", personality: nil, configPath: configPath())
        XCTAssertTrue(result)

        let data = try! Data(contentsOf: configPath())
        let config = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNotNil(config["companion"])
    }

    func testPatchSoulNilBothSkips() {
        let result = patchSoul(name: nil, personality: nil, configPath: configPath())
        XCTAssertTrue(result, "Should return true when both are nil (no-op)")
    }

    func testPatchSoulMissingFile() {
        let missing = tempDir.appendingPathComponent("nonexistent.json")
        let result = patchSoul(name: "Test", personality: nil, configPath: missing)
        XCTAssertFalse(result)
    }

    func testPatchSoulInvalidJSON() {
        writeConfig("not json at all {{{")
        let result = patchSoul(name: "Test", personality: nil, configPath: configPath())
        XCTAssertFalse(result)
    }

    func testPatchSoulOutputHasTrailingNewline() {
        writeConfig("{\"companion\":{}}")
        _ = patchSoul(name: "Test", personality: nil, configPath: configPath())

        let raw = try! Data(contentsOf: configPath())
        XCTAssertEqual(raw.last, 0x0A, "Output should end with newline")
    }
}
