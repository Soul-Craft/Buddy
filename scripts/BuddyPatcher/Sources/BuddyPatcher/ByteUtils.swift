import Foundation

/// Find all occurrences of `pattern` in `data`, returning their start indices.
func findAll(in data: [UInt8], pattern: [UInt8]) -> [Int] {
    guard !pattern.isEmpty, pattern.count <= data.count else { return [] }
    var results: [Int] = []
    var pos = 0
    let limit = data.count - pattern.count
    while pos <= limit {
        let slice = data[pos..<(pos + pattern.count)]
        if slice.elementsEqual(pattern) {
            results.append(pos)
            pos += 1
        } else {
            pos += 1
        }
    }
    return results
}

/// Find the first occurrence of `pattern` in `data` starting from `start`.
/// Returns the index or nil if not found.
func findFirst(in data: [UInt8], pattern: [UInt8], from start: Int = 0) -> Int? {
    guard !pattern.isEmpty, start >= 0 else { return nil }
    let limit = data.count - pattern.count
    guard start <= limit else { return nil }
    for pos in start...limit {
        if data[pos..<(pos + pattern.count)].elementsEqual(pattern) {
            return pos
        }
    }
    return nil
}

/// Convert a Swift String to its UTF-8 byte array.
func utf8Bytes(_ s: String) -> [UInt8] {
    Array(s.utf8)
}
