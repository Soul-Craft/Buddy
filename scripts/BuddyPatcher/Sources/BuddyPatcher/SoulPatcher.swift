import Foundation

private let claudeJSON = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude.json")

/// Update the companion soul in ~/.claude.json.
func patchSoul(name: String?, personality: String?) -> Bool {
    guard name != nil || personality != nil else { return true }

    let fm = FileManager.default
    guard fm.fileExists(atPath: claudeJSON.path) else {
        print("  [!] WARNING: ~/.claude.json not found — skipping soul patch")
        return false
    }

    guard let jsonData = fm.contents(atPath: claudeJSON.path),
          var config = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
        print("  [!] WARNING: ~/.claude.json is not valid JSON — skipping soul patch")
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
        print("  [!] WARNING: Failed to serialize ~/.claude.json")
        return false
    }

    // Write with trailing newline
    var output = outputData
    output.append(0x0A) // \n
    do {
        try output.write(to: claudeJSON)
    } catch {
        print("  [!] WARNING: Failed to write ~/.claude.json: \(error)")
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
