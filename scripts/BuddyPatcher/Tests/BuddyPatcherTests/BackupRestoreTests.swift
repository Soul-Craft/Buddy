import XCTest
@testable import BuddyPatcherLib

final class BackupRestoreTests: XCTestCase {

    var tempDir: URL!
    var backupDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuddyPatcherTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        backupDir = tempDir.appendingPathComponent("backups")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func soulPath() -> URL { tempDir.appendingPathComponent("soul.json") }
    private func soulBackupPath() -> URL { backupDir.appendingPathComponent(".claude.json.pre-customize") }
    private func writeSoul(_ json: String) { try! json.data(using: .utf8)!.write(to: soulPath()) }

    // MARK: - ensureSoulBackup

    func testEnsureSoulBackupCreatesSoulBackup() {
        writeSoul("{\"companion\":{\"name\":\"Test\"}}")
        ensureSoulBackup(backupDir: backupDir, soulPath: soulPath())

        XCTAssertTrue(FileManager.default.fileExists(atPath: soulBackupPath().path))
    }

    func testEnsureSoulBackupIdempotent() {
        writeSoul("{\"companion\":{\"name\":\"Original\"}}")
        ensureSoulBackup(backupDir: backupDir, soulPath: soulPath())

        let firstMtime = (try? FileManager.default.attributesOfItem(
            atPath: soulBackupPath().path)[.modificationDate]) as? Date
        Thread.sleep(forTimeInterval: 0.05)

        // Modify soul and call again — backup must NOT be overwritten
        writeSoul("{\"companion\":{\"name\":\"Modified\"}}")
        ensureSoulBackup(backupDir: backupDir, soulPath: soulPath())

        let secondMtime = (try? FileManager.default.attributesOfItem(
            atPath: soulBackupPath().path)[.modificationDate]) as? Date
        XCTAssertEqual(firstMtime, secondMtime, "Soul backup must not be overwritten on second call")
    }

    func testEnsureSoulBackupSetsPermissions() {
        writeSoul("{\"companion\":{}}")
        ensureSoulBackup(backupDir: backupDir, soulPath: soulPath())

        let dirAttrs = try? FileManager.default.attributesOfItem(atPath: backupDir.path)
        let dirPerms = (dirAttrs?[.posixPermissions] as? NSNumber)?.uint16Value
        XCTAssertEqual(dirPerms, 0o700)

        let fileAttrs = try? FileManager.default.attributesOfItem(atPath: soulBackupPath().path)
        let filePerms = (fileAttrs?[.posixPermissions] as? NSNumber)?.uint16Value
        XCTAssertEqual(filePerms, 0o600)
    }

    func testEnsureSoulBackupSkipsWhenSoulMissing() {
        // No soul file present — backup directory should remain empty
        ensureSoulBackup(backupDir: backupDir, soulPath: soulPath())
        XCTAssertFalse(FileManager.default.fileExists(atPath: soulBackupPath().path))
    }

    func testEnsureSoulBackupPreservesContent() {
        let originalJSON = "{\"companion\":{\"name\":\"Astraeon\"}}"
        writeSoul(originalJSON)
        ensureSoulBackup(backupDir: backupDir, soulPath: soulPath())

        let backupData = try? Data(contentsOf: soulBackupPath())
        XCTAssertEqual(String(data: backupData!, encoding: .utf8), originalJSON)
    }

    // MARK: - restoreSoulBackup

    func testRestoreSoulBackupSucceeds() {
        let originalSoul = "{\"companion\":{\"name\":\"Original\"}}"
        writeSoul(originalSoul)
        ensureSoulBackup(backupDir: backupDir, soulPath: soulPath())

        writeSoul("{\"companion\":{\"name\":\"Modified\"}}")

        let success = restoreSoulBackup(backupDir: backupDir, soulPath: soulPath())
        XCTAssertTrue(success)

        let restored = try? String(contentsOf: soulPath(), encoding: .utf8)
        XCTAssertEqual(restored, originalSoul)
    }

    func testRestoreSoulBackupFailsWithoutBackup() {
        let success = restoreSoulBackup(backupDir: backupDir, soulPath: soulPath())
        XCTAssertFalse(success)
    }

    func testRestoreSoulBackupRestoresSoul() {
        let originalSoul = "{\"companion\":{\"name\":\"Aethos\"}}"
        writeSoul(originalSoul)
        ensureSoulBackup(backupDir: backupDir, soulPath: soulPath())

        writeSoul("{\"companion\":{\"name\":\"Different\"}}")
        let success = restoreSoulBackup(backupDir: backupDir, soulPath: soulPath())
        XCTAssertTrue(success)

        let restored = try? String(contentsOf: soulPath(), encoding: .utf8)
        XCTAssertEqual(restored, originalSoul)
    }
}
