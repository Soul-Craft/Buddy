import Foundation

private let fm = FileManager.default
private let claudeJSON = fm.homeDirectoryForCurrentUser.appendingPathComponent(".claude.json")
private let backupDir = fm.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude/backups")

/// Create backups if they don't exist (idempotent).
func ensureBackup(_ binaryPath: URL) {
    let backup = binaryPath.deletingLastPathComponent()
        .appendingPathComponent("\(binaryPath.lastPathComponent).original-backup")

    if !fm.fileExists(atPath: backup.path) {
        do {
            try fm.copyItem(at: binaryPath, to: backup)
            print("  [+] Binary backed up to \(backup.path)")
        } catch {
            print("  [!] WARNING: Failed to backup binary: \(error)")
        }
    } else {
        print("  [=] Binary backup already exists at \(backup.path)")
    }

    try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
    let soulBackup = backupDir.appendingPathComponent(".claude.json.pre-customize")
    if !fm.fileExists(atPath: soulBackup.path) && fm.fileExists(atPath: claudeJSON.path) {
        do {
            try fm.copyItem(at: claudeJSON, to: soulBackup)
            print("  [+] Soul backed up to \(soulBackup.path)")
        } catch {
            print("  [!] WARNING: Failed to backup soul: \(error)")
        }
    }
}

/// Run patched binary with --version to verify it's not corrupted.
func verifyBinary(_ binaryPath: URL) -> Bool {
    let process = Process()
    process.executableURL = binaryPath
    process.arguments = ["--version"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
    } catch {
        return false
    }

    // Wait with 5-second timeout
    let deadline = Date().addingTimeInterval(5)
    while process.isRunning && Date() < deadline {
        Thread.sleep(forTimeInterval: 0.1)
    }
    if process.isRunning {
        process.terminate()
        return false
    }
    return process.terminationStatus == 0
}

/// Restore binary and soul from backups.
func restoreBackup(_ binaryPath: URL) -> Bool {
    let backup = binaryPath.deletingLastPathComponent()
        .appendingPathComponent("\(binaryPath.lastPathComponent).original-backup")

    guard fm.fileExists(atPath: backup.path) else {
        print("  [!] No binary backup found — nothing to restore")
        return false
    }

    do {
        try? fm.removeItem(at: binaryPath)
        try fm.copyItem(at: backup, to: binaryPath)
        print("  [+] Binary restored from \(backup.path)")
    } catch {
        print("  [!] ERROR: Failed to restore binary: \(error)")
        return false
    }

    let soulBackup = backupDir.appendingPathComponent(".claude.json.pre-customize")
    if fm.fileExists(atPath: soulBackup.path) {
        do {
            try? fm.removeItem(at: claudeJSON)
            try fm.copyItem(at: soulBackup, to: claudeJSON)
            print("  [+] Soul restored from \(soulBackup.path)")
        } catch {
            print("  [!] WARNING: Failed to restore soul: \(error)")
        }
    }

    resignBinary(binaryPath)
    print("\n  Buddy restored to original! Restart Claude Code to see your OG buddy.")
    return true
}

/// Re-sign the binary with an ad-hoc codesign.
@discardableResult
func resignBinary(_ binaryPath: URL) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
    process.arguments = ["--force", "--sign", "-", binaryPath.path]
    let errPipe = Pipe()
    process.standardOutput = FileHandle.nullDevice
    process.standardError = errPipe

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        print("  [!] WARNING: codesign failed: \(error)")
        return false
    }

    if process.terminationStatus == 0 {
        print("  [+] Binary re-signed with ad-hoc signature")
        return true
    } else {
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        print("  [!] WARNING: codesign failed: \(errStr)")
        return false
    }
}
