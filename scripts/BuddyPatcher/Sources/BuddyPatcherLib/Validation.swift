import Foundation

// ── Input Validation ────────────────────────────────────────────────

/// Validate emoji: exactly 1 grapheme cluster, all scalars are emoji, max 16 UTF-8 bytes.
public func validateEmoji(_ input: String) -> String? {
    guard input.count == 1 else {
        fputs("Error: emoji must be exactly one character (got \(input.count))\n", stderr)
        return nil
    }

    for scalar in input.unicodeScalars {
        guard scalar.properties.isEmoji else {
            fputs("Error: '\(input)' contains non-emoji character (U+\(String(scalar.value, radix: 16, uppercase: true)))\n", stderr)
            return nil
        }
    }

    guard input.utf8.count <= 16 else {
        fputs("Error: emoji UTF-8 encoding too long (\(input.utf8.count) bytes, max 16)\n", stderr)
        return nil
    }

    return input
}

/// Validate name: trimmed, non-empty, max 100 chars, no control characters.
public func validateName(_ input: String) -> String? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
        fputs("Error: name cannot be empty\n", stderr)
        return nil
    }

    guard trimmed.count <= 100 else {
        fputs("Error: name too long (\(trimmed.count) chars, max 100)\n", stderr)
        return nil
    }

    for char in trimmed.unicodeScalars {
        if char.value < 0x20 && char.value != 0x09 { // allow tab, reject other control chars
            fputs("Error: name contains control character (U+\(String(char.value, radix: 16, uppercase: true)))\n", stderr)
            return nil
        }
    }

    return trimmed
}

/// Validate personality: trimmed, non-empty, max 500 chars, no control characters.
public func validatePersonality(_ input: String) -> String? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
        fputs("Error: personality cannot be empty\n", stderr)
        return nil
    }

    guard trimmed.count <= 500 else {
        fputs("Error: personality too long (\(trimmed.count) chars, max 500)\n", stderr)
        return nil
    }

    for char in trimmed.unicodeScalars {
        if char.value < 0x20 && char.value != 0x09 {
            fputs("Error: personality contains control character (U+\(String(char.value, radix: 16, uppercase: true)))\n", stderr)
            return nil
        }
    }

    return trimmed
}

/// Validate stats JSON: keys must be known stat names, values must be Int 0-100.
public func validateStats(_ json: String) -> [String: Any]? {
    guard let jsonData = json.data(using: .utf8),
          let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
        fputs("Error: stats is not valid JSON\n", stderr)
        return nil
    }

    for (key, value) in parsed {
        guard statNames.contains(key) else {
            fputs("Error: unknown stat '\(key)'. Valid: \(statNames.joined(separator: ", "))\n", stderr)
            return nil
        }
        guard let num = value as? NSNumber, num.intValue >= 0, num.intValue <= 100 else {
            fputs("Error: stat '\(key)' must be an integer 0-100\n", stderr)
            return nil
        }
    }

    return parsed
}

/// Validate --binary path: must exist, be a regular file, and be a Mach-O binary.
public func validateBinaryPath(_ path: String) -> URL? {
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        .standardizedFileURL
        .resolvingSymlinksInPath()

    let fm = FileManager.default
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue else {
        fputs("Error: binary not found or is a directory: \(url.path)\n", stderr)
        return nil
    }

    // Check Mach-O magic bytes
    guard let handle = FileHandle(forReadingAtPath: url.path) else {
        fputs("Error: cannot read binary: \(url.path)\n", stderr)
        return nil
    }
    defer { handle.closeFile() }

    let header = handle.readData(ofLength: 4)
    guard header.count == 4 else {
        fputs("Error: binary too small to be Mach-O: \(url.path)\n", stderr)
        return nil
    }

    let magic = header.withUnsafeBytes { $0.load(as: UInt32.self) }
    let validMagic: Set<UInt32> = [
        0xFEEDFACE, // MH_MAGIC (32-bit)
        0xFEEDFACF, // MH_MAGIC_64 (64-bit)
        0xCEFAEDFE, // MH_CIGAM (32-bit, swapped)
        0xCFFAEDFE, // MH_CIGAM_64 (64-bit, swapped)
        0xCAFEBABE, // FAT_MAGIC (universal)
        0xBEBAFECA, // FAT_CIGAM (universal, swapped)
    ]

    guard validMagic.contains(magic) else {
        fputs("Error: not a Mach-O binary (magic: 0x\(String(magic, radix: 16))): \(url.path)\n", stderr)
        return nil
    }

    return url
}
