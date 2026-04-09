import Foundation
@testable import BuddyPatcherLib

/// Build a species array like `[GL_,ZL_,LL_,kL_,vL_,...,bL_]` from a var map.
func buildSpeciesArray(_ varMap: [String: String]) -> [UInt8] {
    // Use the canonical species order
    let ordered = allSpecies.compactMap { varMap[$0] }
    let inner = ordered.joined(separator: ",")
    return utf8Bytes("[\(inner)]")
}

/// Build the original rarity weight string as bytes.
func buildRarityString() -> [UInt8] {
    return utf8Bytes("common:60,uncommon:25,rare:10,epic:4,legendary:1")
}

/// Build the original shiny threshold as bytes.
func buildShinyThreshold() -> [UInt8] {
    return utf8Bytes("H()<0.01")
}

/// Build a synthetic art block for a species.
/// Returns marker + art content (without the closing boundary marker).
func buildArtBlock(targetVar: String, varMap: [String: String], size: Int = 300) -> [UInt8] {
    let marker = "[\(targetVar)]:[["
    // Build realistic art content — 3 variants of 5 lines each
    let line = "\"  ^___^  \""
    let empty = "\"         \""
    let variant = "[\(empty),\(empty),\(line),\(empty),\(empty)]"
    let variantInner = String(variant.dropFirst()) // remove leading [
    var artStr = "\(marker)\(variantInner),\(variant),\(variant)"

    // Pad to desired size
    if artStr.count < size {
        let padding = String(repeating: " ", count: size - artStr.count)
        // Insert padding before the last quote's closing
        artStr = String(artStr.dropLast()) + padding + "\""
    }

    return utf8Bytes(artStr)
}

/// Build an art end boundary marker for the next species.
func buildArtEndMarker(_ nextVar: String) -> [UInt8] {
    return utf8Bytes("],[\(nextVar)]:")
}

/// Wrap patterns in padding bytes to create a synthetic binary.
func syntheticBinary(with segments: [[UInt8]], padding: Int = 50) -> [UInt8] {
    var data: [UInt8] = [UInt8](repeating: 0x00, count: padding)
    for segment in segments {
        data.append(contentsOf: segment)
        data.append(contentsOf: [UInt8](repeating: 0x00, count: padding))
    }
    return data
}
