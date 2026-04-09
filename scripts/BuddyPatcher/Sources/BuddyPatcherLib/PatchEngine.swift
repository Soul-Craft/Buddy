import Foundation

/// Replace ALL species variable refs in Trq arrays with the target species.
public func patchSpecies(_ data: inout [UInt8], target: String, anchor: [UInt8], varMap: [String: String]) -> Int {
    guard let targetVar = varMap[target] else {
        print("  [!] WARNING: Unknown species '\(target)'")
        return 0
    }
    let targetBytes = utf8Bytes(targetVar)
    assert(targetBytes.count == 3, "Species var must be 3 bytes, got \(targetBytes.count)")

    let anchors = findAll(in: data, pattern: anchor)
    if anchors.isEmpty {
        print("  [!] WARNING: Could not find species array — binary may have changed")
        return 0
    }

    var patches = 0
    let openBracket: UInt8 = 0x5B  // [
    let closeBracket: UInt8 = 0x5D // ]
    let comma: UInt8 = 0x2C        // ,

    for anchorIdx in anchors {
        // Scan backward to find '['
        var start = anchorIdx
        while start > 0 && data[start] != openBracket {
            start -= 1
        }
        // Only patch if '[' is within 2 bytes of the anchor (real array literal)
        if anchorIdx - start > 2 {
            continue
        }
        // Scan forward to find closing ']'
        var end = anchorIdx
        while end < data.count && data[end] != closeBracket {
            end += 1
        }
        end += 1 // include the ']'

        // Work on the array region
        var region = Array(data[start..<end])

        // Replace each known species variable ref with the target
        for (_, varName) in varMap {
            let varBytes = utf8Bytes(varName)
            var regionPos = 0
            while regionPos <= region.count - varBytes.count {
                let slice = region[regionPos..<(regionPos + varBytes.count)]
                if slice.elementsEqual(varBytes) {
                    // Verify it's a variable ref (preceded by comma or bracket)
                    if regionPos > 0 && (region[regionPos - 1] == comma || region[regionPos - 1] == openBracket) {
                        region.replaceSubrange(regionPos..<(regionPos + 3), with: targetBytes)
                        patches += 1
                    }
                    regionPos += 3
                } else {
                    regionPos += 1
                }
            }
        }

        // Write modified region back
        data.replaceSubrange(start..<end, with: region)
    }

    print("  [+] Species: \(patches) variable refs → \(target) (\(targetVar))")
    return patches
}

/// Zero all rarity weights except the target.
public func patchRarity(_ data: inout [UInt8], target: String) -> Int {
    let rarityWeights: [(String, String)] = [
        ("common", "60"), ("uncommon", "25"), ("rare", "10"), ("epic", "4"), ("legendary", "1")
    ]

    // Build old and new patterns
    var oldParts: [String] = []
    var newParts: [String] = []
    for (rarity, weight) in rarityWeights {
        oldParts.append("\(rarity):\(weight)")
        if rarity == target {
            let newWeight = weight.count == 2 ? "01" : "1"
            newParts.append("\(rarity):\(newWeight)")
        } else {
            let newWeight = weight.count == 2 ? "00" : "0"
            newParts.append("\(rarity):\(newWeight)")
        }
    }

    var oldPattern = utf8Bytes(oldParts.joined(separator: ","))
    let newPattern = utf8Bytes(newParts.joined(separator: ","))
    assert(oldPattern.count == newPattern.count, "Rarity length mismatch: \(oldPattern.count) vs \(newPattern.count)")

    var locations = findAll(in: data, pattern: oldPattern)

    if locations.isEmpty {
        // Try matching already-patched state
        for r in validRarities {
            var altParts: [String] = []
            for (rarity, weight) in rarityWeights {
                if rarity == r {
                    altParts.append("\(rarity):\(weight.count == 2 ? "01" : "1")")
                } else {
                    altParts.append("\(rarity):\(weight.count == 2 ? "00" : "0")")
                }
            }
            let altPattern = utf8Bytes(altParts.joined(separator: ","))
            let altLocs = findAll(in: data, pattern: altPattern)
            if !altLocs.isEmpty {
                locations = altLocs
                oldPattern = altPattern
                break
            }
        }
    }

    if locations.isEmpty {
        print("  [!] WARNING: Could not find rarity weights (LN6) — binary may have changed")
        return 0
    }

    for idx in locations {
        data.replaceSubrange(idx..<(idx + newPattern.count), with: newPattern)
    }

    print("  [+] Rarity: \(locations.count) weight tables → \(target)")
    return locations.count
}

/// Set shiny to always-true or restore original probability.
public func patchShiny(_ data: inout [UInt8], makeShiny: Bool) -> Int {
    let old: [UInt8]
    let new: [UInt8]

    if makeShiny {
        old = utf8Bytes("H()<0.01")
        new = utf8Bytes("H()<1.01")
    } else {
        old = utf8Bytes("H()<1.01")
        new = utf8Bytes("H()<0.01")
    }

    let locations = findAll(in: data, pattern: old)
    if locations.isEmpty {
        // Already in desired state?
        let check = makeShiny ? utf8Bytes("H()<1.01") : utf8Bytes("H()<0.01")
        if !findAll(in: data, pattern: check).isEmpty {
            let state = makeShiny ? "shiny" : "normal"
            print("  [=] Shiny: already in \(state) state")
            return 0
        }
        print("  [!] WARNING: Could not find shiny threshold — binary may have changed")
        return 0
    }

    for idx in locations {
        data.replaceSubrange(idx..<(idx + new.count), with: new)
    }

    let state = makeShiny ? "always shiny ✨" : "normal (1%)"
    print("  [+] Shiny: \(locations.count) thresholds → \(state)")
    return locations.count
}

/// Replace the target species' ASCII art with a centered emoji.
public func patchArt(_ data: inout [UInt8], target: String, emoji: String, varMap: [String: String]) -> Int {
    guard let targetVar = varMap[target] else {
        print("  [!] WARNING: Unknown species '\(target)'")
        return 0
    }
    let artMarker = utf8Bytes("[\(targetVar)]:[[")

    let locations = findAll(in: data, pattern: artMarker)
    if locations.isEmpty {
        print("  [!] WARNING: Could not find art for \(target) (\(targetVar)) — skipping art patch")
        return 0
    }

    var patches = 0

    for artStart in locations {
        // Find the end of this species' art (next species marker or end of object)
        var endCandidates: [Int] = []
        for (_, vn) in varMap {
            if vn == targetVar { continue }
            let endMark = utf8Bytes("],[\(vn)]:")
            if let endIdx = findFirst(in: data, pattern: endMark, from: artStart + artMarker.count) {
                if endIdx < artStart + 2000 { // sanity bound
                    endCandidates.append(endIdx)
                }
            }
        }

        if endCandidates.isEmpty {
            // Try closing with ]}
            if let endIdx = findFirst(in: data, pattern: utf8Bytes("]}"), from: artStart + artMarker.count) {
                endCandidates.append(endIdx)
            }
        }

        if endCandidates.isEmpty {
            print("  [!] WARNING: Could not find art boundary for \(target) at 0x\(String(artStart, radix: 16))")
            continue
        }

        let artEnd = endCandidates.min()!
        let oldArt = Array(data[artStart..<artEnd])
        let oldLen = oldArt.count

        // Build new art: 3 variants, each with 5 lines, centered emoji.
        // old_art does NOT include the outer array's closing `]`
        let line = "\" \(emoji)  \""
        let empty = "\"      \""
        let variant = "[\(empty),\(empty),\(empty),\(line),\(empty)]"
        let variantInner = String(variant.dropFirst()) // remove leading [
        let newArtStr = "[\(targetVar)]:[[\(variantInner),\(variant),\(variant)"
        var newArt = utf8Bytes(newArtStr)
        var diff = oldLen - newArt.count

        if diff > 0 {
            // Pad with spaces inside the last empty string
            newArt.insert(contentsOf: [UInt8](repeating: 0x20, count: diff), at: newArt.count - 1)
        } else if diff < 0 {
            // Need to shrink — use shorter padding
            let lineS = "\" \(emoji) \""
            let emptyS = "\"    \""
            let variantS = "[\(emptyS),\(emptyS),\(emptyS),\(lineS),\(emptyS)]"
            let variantSInner = String(variantS.dropFirst())
            let newArtStrS = "[\(targetVar)]:[[\(variantSInner),\(variantS),\(variantS)"
            newArt = utf8Bytes(newArtStrS)
            diff = oldLen - newArt.count
            if diff > 0 {
                newArt.insert(contentsOf: [UInt8](repeating: 0x20, count: diff), at: newArt.count - 1)
            } else if diff < 0 {
                // Ultra-compact
                let lineU = "\"\(emoji)\""
                let emptyU = "\"  \""
                let variantU = "[\(emptyU),\(emptyU),\(emptyU),\(lineU),\(emptyU)]"
                let variantUInner = String(variantU.dropFirst())
                let newArtStrU = "[\(targetVar)]:[[\(variantUInner),\(variantU),\(variantU)"
                newArt = utf8Bytes(newArtStrU)
                diff = oldLen - newArt.count
                if diff > 0 {
                    newArt.insert(contentsOf: [UInt8](repeating: 0x20, count: diff), at: newArt.count - 1)
                }
            }
        }

        if newArt.count != oldLen {
            print("  [!] WARNING: Art size mismatch (\(newArt.count) vs \(oldLen)) — skipping")
            continue
        }

        data.replaceSubrange(artStart..<artEnd, with: newArt)
        patches += 1
        print("  [+] Art: replaced \(target) art with \(emoji) at 0x\(String(artStart, radix: 16))")
    }

    return patches
}
