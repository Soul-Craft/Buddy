import Foundation

/// Known species variable maps. Newest first so detection prefers the latest match.
/// The first 4 species (duck, goose, blob, cat) form the anchor pattern.
public let knownVarMaps: [[String: String]] = [
    [   // v2.1.90+
        "duck": "GL_",    "goose": "ZL_",   "blob": "LL_",    "cat": "kL_",
        "dragon": "vL_",  "octopus": "hL_", "owl": "yL_",     "penguin": "NL_",
        "turtle": "VL_",  "snail": "SL_",   "axolotl": "CL_", "ghost": "EL_",
        "robot": "xL_",   "mushroom": "mL_", "cactus": "IL_", "rabbit": "uL_",
        "chonk": "pL_",   "capybara": "bL_",
    ],
    [   // v2.1.89
        "duck": "b0_",    "goose": "I0_",   "blob": "x0_",    "cat": "u0_",
        "dragon": "m0_",  "octopus": "p0_", "owl": "g0_",     "penguin": "B0_",
        "turtle": "d0_",  "snail": "c0_",   "axolotl": "F0_", "ghost": "U0_",
        "robot": "Q0_",   "mushroom": "l0_", "cactus": "i0_", "rabbit": "n0_",
        "chonk": "r0_",   "capybara": "o0_",
    ],
]

/// All species names (same across all maps).
public let allSpecies: [String] = [
    "duck", "goose", "blob", "cat", "dragon", "octopus", "owl", "penguin",
    "turtle", "snail", "axolotl", "ghost", "robot", "mushroom", "cactus",
    "rabbit", "chonk", "capybara",
]

public let validRarities = ["common", "uncommon", "rare", "epic", "legendary"]
public let statNames = ["debugging", "patience", "chaos", "wisdom", "snark"]

/// Build the anchor pattern (first 4 species refs) for a given var map.
public func anchorForMap(_ varMap: [String: String]) -> [UInt8] {
    let s = "\(varMap["duck"]!),\(varMap["goose"]!),\(varMap["blob"]!),\(varMap["cat"]!),"
    return utf8Bytes(s)
}

/// Try each known var map and return the first whose anchor is found in data.
public func detectVarMap(in data: [UInt8]) -> (varMap: [String: String], anchor: [UInt8])? {
    for varMap in knownVarMaps {
        let anchor = anchorForMap(varMap)
        if findFirst(in: data, pattern: anchor) != nil {
            return (varMap, anchor)
        }
    }
    return nil
}
