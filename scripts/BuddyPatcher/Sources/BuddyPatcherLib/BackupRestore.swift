import Foundation

private let fm = FileManager.default
private let defaultClaudeJSON = resolvedHome.appendingPathComponent(".claude.json")
private let defaultBackupDir = resolvedHome.appendingPathComponent(".claude/backups")

/// Back up ~/.claude.json (soul) to ~/.claude/backups/.claude.json.pre-customize.
/// Idempotent — never overwrites an existing backup.
public func ensureSoulBackup(backupDir: URL? = nil, soulPath: URL? = nil) {
    let bkDir = backupDir ?? defaultBackupDir
    let soul = soulPath ?? defaultClaudeJSON

    try? fm.createDirectory(at: bkDir, withIntermediateDirectories: true)
    try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: bkDir.path)

    let soulBackup = bkDir.appendingPathComponent(".claude.json.pre-customize")
    guard !fm.fileExists(atPath: soulBackup.path) else {
        print("  [=] Soul backup already exists at \(soulBackup.path)")
        return
    }
    guard fm.fileExists(atPath: soul.path) else {
        print("  [~] No ~/.claude.json found — skipping soul backup")
        return
    }
    do {
        try fm.copyItem(at: soul, to: soulBackup)
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: soulBackup.path)
        print("  [+] Soul backed up to \(soulBackup.path)")
    } catch {
        print("  [!] WARNING: Failed to backup soul: \(error)")
    }
}

/// Restore ~/.claude.json from the soul backup.
/// Returns true on success, false if no backup exists or the restore fails.
@discardableResult
public func restoreSoulBackup(backupDir: URL? = nil, soulPath: URL? = nil) -> Bool {
    let bkDir = backupDir ?? defaultBackupDir
    let soul = soulPath ?? defaultClaudeJSON
    let soulBackup = bkDir.appendingPathComponent(".claude.json.pre-customize")

    guard fm.fileExists(atPath: soulBackup.path) else {
        print("  [!] No soul backup found — nothing to restore")
        return false
    }

    do {
        let data = try Data(contentsOf: soulBackup)
        try data.write(to: soul, options: .atomic)
        print("  [+] Soul restored from \(soulBackup.path)")
        return true
    } catch {
        print("  [!] ERROR: Failed to restore soul: \(error)")
        return false
    }
}
