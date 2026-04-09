import Foundation

private let defaultClaudeJSON = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude.json")

/// Update the companion soul in ~/.claude.json (or a custom path for testing).
@discardableResult
public func patchSoul(name: String?, personality: String?, configPath: URL? = nil) -> Bool {
    guard name != nil || personality != nil else { return true }

    let target = configPath ?? defaultClaudeJSON
    let fm = FileManager.default
    guard fm.fileExists(atPath: target.path) else {
        print("  [!] WARNING: \(target.path) not found — skipping soul patch")
        return false
    }

    guard let jsonData = fm.contents(atPath: target.path),
          var config = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
        print("  [!] WARNING: \(target.path) is not valid JSON — skipping soul patch")
        return false
    }

    var companion = config["companion"] as? [String: Any] ?? [:]
    if let name = name {
        companion["name"] = name
    }
    if let personality = personality {
        companion["personality"] = personality
    }
    config["companion"] = companion

    guard let outputData = try? JSONSerialization.data(
        withJSONObject: config,
        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    ) else {
        print("  [!] WARNING: Failed to serialize config")
        return false
    }

    // Write with trailing newline
    var output = outputData
    output.append(0x0A) // \n
    do {
        try output.write(to: target, options: .atomic)
    } catch {
        print("  [!] WARNING: Failed to write \(target.path): \(error)")
        return false
    }

    var updates: [String] = []
    if let name = name { updates.append("name=\(name)") }
    if let personality = personality {
        let truncated = personality.count > 50 ? String(personality.prefix(50)) + "..." : personality
        updates.append("personality=\(truncated)")
    }
    print("  [+] Soul: \(updates.joined(separator: ", "))")
    return true
}
