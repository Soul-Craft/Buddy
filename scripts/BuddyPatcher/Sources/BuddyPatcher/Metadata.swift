import Foundation

private let fm = FileManager.default
private let backupDir = fm.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude/backups")
let metaFile = backupDir.appendingPathComponent("buddy-patch-meta.json")

/// Save patch metadata for auto-update recovery.
func saveMetadata(binaryPath: URL, species: String?, rarity: String?, shiny: Bool,
                  emoji: String?, name: String?, personality: String?,
                  stats: [String: Any]?) {
    try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)

    var meta: [String: Any] = [
        "version": getVersion(binaryPath),
        "binary_path": binaryPath.path,
    ]
    if let species = species { meta["species"] = species }
    if let rarity = rarity { meta["rarity"] = rarity }
    meta["shiny"] = shiny
    if let emoji = emoji { meta["emoji"] = emoji }
    if let name = name { meta["name"] = name }
    if let personality = personality { meta["personality"] = personality }
    if let stats = stats { meta["stats"] = stats }

    guard let data = try? JSONSerialization.data(
        withJSONObject: meta,
        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    ) else {
        print("  [!] WARNING: Failed to serialize metadata")
        return
    }

    do {
        try data.write(to: metaFile)
        print("  [+] Metadata saved to \(metaFile.path)")
    } catch {
        print("  [!] WARNING: Failed to save metadata: \(error)")
    }
}

/// Load saved patch metadata.
func loadMetadata() -> [String: Any]? {
    guard fm.fileExists(atPath: metaFile.path),
          let data = fm.contents(atPath: metaFile.path),
          let meta = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return nil
    }
    return meta
}
