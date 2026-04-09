import Foundation
import CryptoKit

private let fm = FileManager.default
private let claudeJSON = fm.homeDirectoryForCurrentUser.appendingPathComponent(".claude.json")
private let backupDir = fm.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude/backups")

/// Compute SHA-256 hex digest of a file.
public func sha256Hex(_ url: URL) -> String? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
}

private let hashFile = backupDir.appendingPathComponent("binary-sha256.txt")

/// Create backups if they don't exist (idempotent).
public func ensureBackup(_ binaryPath: URL) {
    let backup = binaryPath.deletingLastPathComponent()
        .appendingPathComponent("\(binaryPath.lastPathComponent).original-backup")

    try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
    try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: backupDir.path)

    if !fm.fileExists(atPath: backup.path) {
        do {
            try fm.copyItem(at: binaryPath, to: backup)
            try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backup.path)
            print("  [+] Binary backed up to \(backup.path)")

            // Store SHA-256 of original binary
            if let hash = sha256Hex(binaryPath) {
                try? hash.write(to: hashFile, atomically: true, encoding: .utf8)
                try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: hashFile.path)
                print("  [+] Binary SHA-256: \(hash.prefix(16))...")
            }
        } catch {
            print("  [!] WARNING: Failed to backup binary: \(error)")
        }
    } else {
        print("  [=] Binary backup already exists at \(backup.path)")
    }

    let soulBackup = backupDir.appendingPathComponent(".claude.json.pre-customize")
    if !fm.fileExists(atPath: soulBackup.path) && fm.fileExists(atPath: claudeJSON.path) {
        do {
            try fm.copyItem(at: claudeJSON, to: soulBackup)
            try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: soulBackup.path)
            print("  [+] Soul backed up to \(soulBackup.path)")
        } catch {
            print("  [!] WARNING: Failed to backup soul: \(error)")
        }
    }
}

/// Run patched binary with --version to verify it's not corrupted.
public func verifyBinary(_ binaryPath: URL) -> Bool {
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
public func restoreBackup(_ binaryPath: URL) -> Bool {
    let backup = binaryPath.deletingLastPathComponent()
        .appendingPathComponent("\(binaryPath.lastPathComponent).original-backup")

    guard fm.fileExists(atPath: backup.path) else {
        print("  [!] No binary backup found — nothing to restore")
        return false
    }

    // Verify backup integrity if hash file exists
    if fm.fileExists(atPath: hashFile.path),
       let storedHash = try? String(contentsOf: hashFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
       let backupHash = sha256Hex(backup) {
        if storedHash != backupHash {
            print("  [!] ERROR: Backup integrity check failed!")
            print("  [!]   Expected: \(storedHash.prefix(16))...")
            print("  [!]   Got:      \(backupHash.prefix(16))...")
            print("  [!] Backup may be corrupted. Refusing to restore.")
            return false
        }
        print("  [+] Backup integrity verified (SHA-256 match)")
    } else if !fm.fileExists(atPath: hashFile.path) {
        print("  [~] No hash file found — skipping integrity check (pre-security backup)")
    }

    do {
        let backupData = try Data(contentsOf: backup)
        try backupData.write(to: binaryPath, options: .atomic)
        print("  [+] Binary restored from \(backup.path)")
    } catch {
        print("  [!] ERROR: Failed to restore binary: \(error)")
        return false
    }

    let soulBackup = backupDir.appendingPathComponent(".claude.json.pre-customize")
    if fm.fileExists(atPath: soulBackup.path) {
        do {
            let soulData = try Data(contentsOf: soulBackup)
            try soulData.write(to: claudeJSON, options: .atomic)
            print("  [+] Soul restored from \(soulBackup.path)")
        } catch {
            print("  [!] WARNING: Failed to restore soul: \(error)")
        }
    }

    if !resignBinary(binaryPath) {
        print("  [!] WARNING: Re-signing restored binary failed. Run manually:")
        print("      codesign --force --sign - \(binaryPath.path)")
    }
    print("\n  Buddy restored to original! Restart Claude Code to see your OG buddy.")
    return true
}

/// Re-sign the binary with an ad-hoc codesign.
@discardableResult
public func resignBinary(_ binaryPath: URL) -> Bool {
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
