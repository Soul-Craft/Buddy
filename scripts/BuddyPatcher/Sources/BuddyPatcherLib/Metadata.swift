import Foundation

private let fm = FileManager.default
private let defaultBackupDir = resolvedHome.appendingPathComponent(".claude/backups")
public let metaFile = defaultBackupDir.appendingPathComponent("buddy-patch-meta.json")

/// Save plugin-local buddy metadata (cosmetic card state, schema v2).
public func saveMetadata(species: String?, rarity: String?, shiny: Bool,
                         emoji: String?, name: String?, personality: String?,
                         stats: [String: Any]?, metaPath: URL? = nil) {
    let target = metaPath ?? metaFile
    try? fm.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)

    var meta: [String: Any] = ["schema_version": 2]
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
        try data.write(to: target, options: .atomic)
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: target.path)
        print("  [+] Metadata saved to \(target.path)")
    } catch {
        print("  [!] WARNING: Failed to save metadata: \(error)")
    }
}

/// Load saved buddy metadata.
public func loadMetadata(metaPath: URL? = nil) -> [String: Any]? {
    let target = metaPath ?? metaFile
    guard fm.fileExists(atPath: target.path),
          let data = fm.contents(atPath: target.path),
          let meta = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    return meta
}

/// Remove saved buddy metadata (called on reset).
public func removeMetadata(metaPath: URL? = nil) {
    let target = metaPath ?? metaFile
    guard fm.fileExists(atPath: target.path) else { return }
    do {
        try fm.removeItem(at: target)
        print("  [+] Metadata removed")
    } catch {
        print("  [!] WARNING: Failed to remove metadata: \(error)")
    }
}
