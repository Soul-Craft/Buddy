import Foundation

/// Resolve the Claude Code binary path from the symlink.
func findBinary() throws -> URL {
    let fm = FileManager.default
    let symlink = fm.homeDirectoryForCurrentUser
        .appendingPathComponent(".local/bin/claude")

    guard fm.fileExists(atPath: symlink.path) else {
        throw PatchError.binaryNotFound("Claude Code symlink not found at \(symlink.path)")
    }

    let resolved = symlink.resolvingSymlinksInPath()
    guard fm.fileExists(atPath: resolved.path) else {
        throw PatchError.binaryNotFound("Claude Code binary not found at \(resolved.path)")
    }
    return resolved
}

/// Extract version from binary path (last component, e.g. "2.1.89").
func getVersion(_ binaryPath: URL) -> String {
    binaryPath.lastPathComponent
}

enum PatchError: Error, CustomStringConvertible {
    case binaryNotFound(String)
    case patchFailed(String)
    case verificationFailed

    var description: String {
        switch self {
        case .binaryNotFound(let msg): return msg
        case .patchFailed(let msg): return msg
        case .verificationFailed: return "Binary verification failed"
        }
    }
}
