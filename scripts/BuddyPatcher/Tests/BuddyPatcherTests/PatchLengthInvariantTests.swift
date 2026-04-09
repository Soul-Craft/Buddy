import XCTest
@testable import BuddyPatcherLib

final class PatchLengthInvariantTests: XCTestCase {

    let v90 = knownVarMaps[0]
    lazy var v90Anchor = anchorForMap(v90)

    // MARK: - Species length invariant

    func testSpeciesPatchLengthForAllSpecies() {
        let speciesArray = buildSpeciesArray(v90)
        for species in allSpecies {
            var data = syntheticBinary(with: [speciesArray])
            let originalLen = data.count
            _ = patchSpecies(&data, target: species, anchor: v90Anchor, varMap: v90)
            XCTAssertEqual(data.count, originalLen, "Length changed after patching species '\(species)'")
        }
    }

    // MARK: - Rarity length invariant

    func testRarityPatchLengthForAllRarities() {
        let rarity = buildRarityString()
        for r in validRarities {
            var data = syntheticBinary(with: [rarity])
            let originalLen = data.count
            _ = patchRarity(&data, target: r)
            XCTAssertEqual(data.count, originalLen, "Length changed after patching rarity '\(r)'")
        }
    }

    // MARK: - Shiny length invariant

    func testShinyPatchLengthBothDirections() {
        let threshold = buildShinyThreshold()
        var dataOn = syntheticBinary(with: [threshold])
        let originalLen = dataOn.count
        _ = patchShiny(&dataOn, makeShiny: true)
        XCTAssertEqual(dataOn.count, originalLen, "Length changed when making shiny")

        var dataOff = syntheticBinary(with: [utf8Bytes("H()<1.01")])
        _ = patchShiny(&dataOff, makeShiny: false)
        XCTAssertEqual(dataOff.count, originalLen, "Length changed when removing shiny")
    }

    // MARK: - Art length invariant

    func testArtPatchLengthVariousEmoji() {
        let targetVar = v90["duck"]!
        let nextVar = v90["goose"]!
        let artBlock = buildArtBlock(targetVar: targetVar, varMap: v90, size: 300)
        let endMarker = buildArtEndMarker(nextVar)

        let emojis = ["🦆", "🐧", "⭐", "🎉", "X"]
        for emoji in emojis {
            var data = syntheticBinary(with: [artBlock, endMarker])
            let originalLen = data.count
            _ = patchArt(&data, target: "duck", emoji: emoji, varMap: v90)
            XCTAssertEqual(data.count, originalLen, "Length changed after patching art with emoji '\(emoji)'")
        }
    }

    // MARK: - Combined patches

    func testCombinedPatchLengthInvariant() {
        // Build data with all patchable patterns
        let speciesArray = buildSpeciesArray(v90)
        let rarityStr = buildRarityString()
        let shinyStr = buildShinyThreshold()
        let targetVar = v90["duck"]!
        let nextVar = v90["goose"]!
        let artBlock = buildArtBlock(targetVar: targetVar, varMap: v90, size: 300)
        let endMarker = buildArtEndMarker(nextVar)

        var data = syntheticBinary(with: [speciesArray, rarityStr, shinyStr, artBlock, endMarker])
        let originalLen = data.count

        // Apply all patches sequentially
        _ = patchSpecies(&data, target: "penguin", anchor: v90Anchor, varMap: v90)
        XCTAssertEqual(data.count, originalLen, "Length changed after species patch")

        _ = patchRarity(&data, target: "legendary")
        XCTAssertEqual(data.count, originalLen, "Length changed after rarity patch")

        _ = patchShiny(&data, makeShiny: true)
        XCTAssertEqual(data.count, originalLen, "Length changed after shiny patch")

        _ = patchArt(&data, target: "penguin", emoji: "🐧", varMap: v90)
        XCTAssertEqual(data.count, originalLen, "Length changed after art patch")
    }
}
