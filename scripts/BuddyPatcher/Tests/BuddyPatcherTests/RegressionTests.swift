import XCTest
@testable import BuddyPatcherLib

/// Regression tests — one per previously-fixed bug.
///
/// Convention:
///   - Each test is named `testPR<N>_<shortDescription>()` referencing the
///     PR that fixed the bug.
///   - A comment above each test describes the original bug symptom and
///     which commit introduced the fix.
///   - The test asserts the CORRECT behavior. If someone reverts the fix,
///     this test must fail immediately and loudly.
///
/// Adding tests: when fixing any bug, add a test here before merging.
final class RegressionTests: XCTestCase {

    let v90 = knownVarMaps[0]
    lazy var v90Anchor = anchorForMap(v90)

    // MARK: - PR #7 regressions (commit a2bef29)
    //
    // "fix: multi-version variable map detection, art patch corruption,
    //  and species-specific ASCII art"

    /// Bug: backward scan for '[' in patchSpecies could overshoot 50+ bytes
    /// and land on '[' inside a var declaration. This replaced variable names
    /// INSIDE declarations (not just the species array), corrupting the binary.
    ///
    /// Fix: only accept '[' when it is within 2 bytes of the anchor start.
    ///
    /// Regression: given a decoy '[' at distance 3 from the anchor, patchSpecies
    /// must return 0 patches (the decoy is rejected, the data is unchanged).
    func testPR7_speciesAnchorIgnoresBracketBeyond2Bytes() {
        // Construct data: [50 null bytes][decoy-bracket][3 garbage bytes][anchor][50 null bytes]
        // The '[' is 3 bytes before the anchor start → distance 3 > 2 → must be rejected.
        var data: [UInt8] = Array(repeating: 0x00, count: 50)
        data.append(0x5B)                                  // decoy '[' at offset 50
        data.append(contentsOf: [0x61, 0x62, 0x63])        // 3 garbage bytes
        data.append(contentsOf: v90Anchor)                 // anchor at offset 54
        data.append(contentsOf: Array(repeating: 0x00, count: 50))

        let patches = patchSpecies(&data, target: "duck", anchor: v90Anchor, varMap: v90)

        XCTAssertEqual(patches, 0,
            "patchSpecies must not apply when the only '[' is 3 bytes from the anchor " +
            "(2-byte proximity guard regression, PR #7)")
    }

    /// Bug: in the Python predecessor, patchArt's replacement string ended with
    /// ']]' (variant close + outer array close), but old_art only captured up to
    /// the first ']'. The outer ']' at art_end was preserved, producing ']]]'
    /// which corrupted the JavaScript structure and changed the file size.
    ///
    /// Fix: the replacement string omits the outer array close; the outer ']'
    /// already present in the data provides the close.
    ///
    /// Regression: after patchArt with a 1-codepoint emoji:
    ///   1. Byte count must be identical (no extra brackets injected).
    ///   2. The data must not contain the ']]]' corruption signature.
    func testPR7_artPatchNoBracketCorruption() {
        let targetVar = v90["duck"]!
        let nextVar   = v90["goose"]!
        let artBlock  = buildArtBlock(targetVar: targetVar, varMap: v90, size: 300)
        let endMarker = buildArtEndMarker(nextVar)
        var data = syntheticBinary(with: [artBlock, endMarker])
        let originalCount = data.count

        let patches = patchArt(&data, target: "duck", emoji: "🦆", varMap: v90)

        XCTAssertGreaterThan(patches, 0, "patchArt must apply at least one patch")

        // Primary invariant: identical byte count (any extra bracket adds ≥1 byte)
        XCTAssertEqual(data.count, originalCount,
            "Art patch must not change data length (bracket corruption regression, PR #7)")

        // Secondary check: the specific ']]]' corruption signature must be absent
        let tripleClose = Array("]]]".utf8)
        XCTAssertTrue(findAll(in: data, pattern: tripleClose).isEmpty,
            "Art patch must not produce ']]]' sequence (outer bracket corruption, PR #7)")
    }

    // MARK: - PR #6 regression (commit 4cb8b9d)
    //
    // "Add post-patch binary verification and auto-restore on failure"

    /// Bug context: ensureBackup() was added in PR #6 to protect the original
    /// binary before patching. The critical invariant: a SECOND call to
    /// ensureBackup (i.e., a re-patch) must NOT overwrite the existing backup —
    /// if it did, the "original" backup would contain the already-patched binary
    /// and restore would be unable to recover the true original.
    ///
    /// Fix: ensureBackup checks `if !fm.fileExists(atPath: backup.path)` and
    /// only copies if no backup exists yet.
    ///
    /// Regression: after ensureBackup → modify binary → ensureBackup again,
    /// the backup file must still contain the ORIGINAL bytes, not the modified ones.
    func testPR6_backupPreservesOriginalContentAcrossRepatches() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("regression-pr6-\(UUID().uuidString)")
        let binaryPath = tempDir.appendingPathComponent("claude-test")
        let backupPath = binaryPath.appendingPathExtension("original-backup")
        let backupDir  = tempDir.appendingPathComponent("backups")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Write the "original" binary with a distinctive payload
        let originalBytes: [UInt8] = Array("ORIGINAL_BINARY_CONTENT".utf8)
        try! Data(originalBytes).write(to: binaryPath)

        // First call: backup is created, containing the original bytes
        ensureBackup(binaryPath,
                     backupDir: backupDir,
                     soulPath: tempDir.appendingPathComponent("no-soul.json"))

        // Simulate a patch: overwrite the binary with different content
        // (different length makes an accidental pass impossible)
        let patchedBytes: [UInt8] = Array("PATCHED_BINARY_CONTENT_LONGER_THAN_ORIGINAL".utf8)
        try! Data(patchedBytes).write(to: binaryPath)

        // Second call: backup already exists — must NOT be overwritten
        ensureBackup(binaryPath,
                     backupDir: backupDir,
                     soulPath: tempDir.appendingPathComponent("no-soul.json"))

        let backupContent = Array(try! Data(contentsOf: backupPath))
        XCTAssertEqual(backupContent, originalBytes,
            "Backup must contain original bytes after a re-patch; " +
            "ensureBackup idempotency regression (PR #6)")
        XCTAssertNotEqual(backupContent, patchedBytes,
            "Backup must NOT contain patched bytes (would destroy restore ability)")
    }
}
