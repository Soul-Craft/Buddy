import XCTest
@testable import BuddyPatcherLib

final class PatchEngineTests: XCTestCase {

    let v90 = knownVarMaps[0]
    lazy var v90Anchor = anchorForMap(v90)

    // MARK: - patchSpecies

    func testPatchSpeciesReplacesAllRefs() {
        let speciesArray = buildSpeciesArray(v90)
        var data = syntheticBinary(with: [speciesArray])
        let count = patchSpecies(&data, target: "penguin", anchor: v90Anchor, varMap: v90)

        XCTAssertGreaterThan(count, 0)
        // After patching, only "NL_" (penguin) should appear as a variable ref
        let penguinVar = utf8Bytes("NL_")
        let duckVar = utf8Bytes("GL_")
        XCTAssertGreaterThan(findAll(in: data, pattern: penguinVar).count, 0)
        // Other species should be gone (replaced with penguin)
        // Check that duck var no longer appears in the array region
        let arrayStart = findFirst(in: data, pattern: [0x5B])! // [
        let arrayEnd = findFirst(in: data, pattern: [0x5D], from: arrayStart)! // ]
        let region = Array(data[arrayStart...arrayEnd])
        XCTAssertEqual(findAll(in: region, pattern: duckVar).count, 0)
    }

    func testPatchSpeciesPreservesLength() {
        let speciesArray = buildSpeciesArray(v90)
        var data = syntheticBinary(with: [speciesArray])
        let originalLen = data.count
        _ = patchSpecies(&data, target: "dragon", anchor: v90Anchor, varMap: v90)
        XCTAssertEqual(data.count, originalLen)
    }

    func testPatchSpeciesPreservesSurroundingData() {
        let speciesArray = buildSpeciesArray(v90)
        let padding: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
        var data = padding + speciesArray + padding
        let anchor = anchorForMap(v90)

        _ = patchSpecies(&data, target: "cat", anchor: anchor, varMap: v90)

        // First and last 4 bytes should be untouched
        XCTAssertEqual(Array(data[0..<4]), padding)
        XCTAssertEqual(Array(data[(data.count - 4)...]), padding)
    }

    func testPatchSpeciesIdempotent() {
        let speciesArray = buildSpeciesArray(v90)
        var data = syntheticBinary(with: [speciesArray])
        _ = patchSpecies(&data, target: "owl", anchor: v90Anchor, varMap: v90)
        let afterFirst = data

        _ = patchSpecies(&data, target: "owl", anchor: v90Anchor, varMap: v90)
        XCTAssertEqual(data, afterFirst)
    }

    func testPatchSpeciesNoAnchor() {
        var data: [UInt8] = [UInt8](repeating: 0x42, count: 500)
        let count = patchSpecies(&data, target: "penguin", anchor: v90Anchor, varMap: v90)
        XCTAssertEqual(count, 0)
    }

    func testPatchSpeciesInvalidSpecies() {
        let speciesArray = buildSpeciesArray(v90)
        var data = syntheticBinary(with: [speciesArray])
        let count = patchSpecies(&data, target: "unicorn", anchor: v90Anchor, varMap: v90)
        XCTAssertEqual(count, 0)
    }

    // MARK: - patchRarity

    func testPatchRarityToLegendary() {
        let rarity = buildRarityString()
        var data = syntheticBinary(with: [rarity])
        let count = patchRarity(&data, target: "legendary")

        XCTAssertGreaterThan(count, 0)
        let expected = utf8Bytes("common:00,uncommon:00,rare:00,epic:0,legendary:1")
        XCTAssertGreaterThan(findAll(in: data, pattern: expected).count, 0)
    }

    func testPatchRarityToCommon() {
        let rarity = buildRarityString()
        var data = syntheticBinary(with: [rarity])
        _ = patchRarity(&data, target: "common")

        let expected = utf8Bytes("common:01,uncommon:00,rare:00,epic:0,legendary:0")
        XCTAssertGreaterThan(findAll(in: data, pattern: expected).count, 0)
    }

    func testPatchRarityPreservesLength() {
        let rarity = buildRarityString()
        var data = syntheticBinary(with: [rarity])
        let originalLen = data.count
        _ = patchRarity(&data, target: "epic")
        XCTAssertEqual(data.count, originalLen)
    }

    func testPatchRarityAlreadyPatched() {
        // Pre-patch to "rare", then re-patch to "epic"
        let rarity = buildRarityString()
        var data = syntheticBinary(with: [rarity])
        _ = patchRarity(&data, target: "rare")
        let count = patchRarity(&data, target: "epic")

        XCTAssertGreaterThan(count, 0, "Should detect already-patched state and re-patch")
        let expected = utf8Bytes("common:00,uncommon:00,rare:00,epic:1,legendary:0")
        XCTAssertGreaterThan(findAll(in: data, pattern: expected).count, 0)
    }

    func testPatchRarityNoMatch() {
        var data: [UInt8] = [UInt8](repeating: 0x42, count: 500)
        let count = patchRarity(&data, target: "legendary")
        XCTAssertEqual(count, 0)
    }

    func testPatchRarityIdempotent() {
        let rarity = buildRarityString()
        var data = syntheticBinary(with: [rarity])
        _ = patchRarity(&data, target: "legendary")
        let afterFirst = data
        _ = patchRarity(&data, target: "legendary")
        XCTAssertEqual(data, afterFirst)
    }

    // MARK: - patchShiny

    func testPatchShinyMakeTrue() {
        let threshold = buildShinyThreshold()
        var data = syntheticBinary(with: [threshold])
        let count = patchShiny(&data, makeShiny: true)

        XCTAssertGreaterThan(count, 0)
        XCTAssertGreaterThan(findAll(in: data, pattern: utf8Bytes("H()<1.01")).count, 0)
        XCTAssertEqual(findAll(in: data, pattern: utf8Bytes("H()<0.01")).count, 0)
    }

    func testPatchShinyMakeFalse() {
        // Start with shiny state
        let threshold = utf8Bytes("H()<1.01")
        var data = syntheticBinary(with: [threshold])
        let count = patchShiny(&data, makeShiny: false)

        XCTAssertGreaterThan(count, 0)
        XCTAssertGreaterThan(findAll(in: data, pattern: utf8Bytes("H()<0.01")).count, 0)
    }

    func testPatchShinyPreservesLength() {
        let threshold = buildShinyThreshold()
        var data = syntheticBinary(with: [threshold])
        let originalLen = data.count
        _ = patchShiny(&data, makeShiny: true)
        XCTAssertEqual(data.count, originalLen)
    }

    func testPatchShinyAlreadyShiny() {
        let threshold = utf8Bytes("H()<1.01")
        var data = syntheticBinary(with: [threshold])
        let count = patchShiny(&data, makeShiny: true)
        XCTAssertEqual(count, 0, "Should detect already-shiny state")
    }

    func testPatchShinyAlreadyNormal() {
        let threshold = buildShinyThreshold()
        var data = syntheticBinary(with: [threshold])
        let count = patchShiny(&data, makeShiny: false)
        XCTAssertEqual(count, 0, "Should detect already-normal state")
    }

    func testPatchShinyNoMatch() {
        var data: [UInt8] = [UInt8](repeating: 0x42, count: 500)
        let count = patchShiny(&data, makeShiny: true)
        XCTAssertEqual(count, 0)
    }

    func testPatchShinyMultipleOccurrences() {
        let threshold = buildShinyThreshold()
        var data = syntheticBinary(with: [threshold, threshold])
        let count = patchShiny(&data, makeShiny: true)
        XCTAssertEqual(count, 2)
    }

    // MARK: - patchArt

    func testPatchArtPreservesLength() {
        let targetVar = v90["duck"]!
        let nextVar = v90["goose"]!
        let artBlock = buildArtBlock(targetVar: targetVar, varMap: v90, size: 300)
        let endMarker = buildArtEndMarker(nextVar)
        var data = syntheticBinary(with: [artBlock, endMarker])
        let originalLen = data.count

        _ = patchArt(&data, target: "duck", emoji: "🦆", varMap: v90)
        XCTAssertEqual(data.count, originalLen)
    }

    func testPatchArtUnknownSpecies() {
        let targetVar = v90["duck"]!
        let artBlock = buildArtBlock(targetVar: targetVar, varMap: v90)
        var data = syntheticBinary(with: [artBlock])
        let count = patchArt(&data, target: "unicorn", emoji: "🦄", varMap: v90)
        XCTAssertEqual(count, 0)
    }

    func testPatchArtNoMarker() {
        var data: [UInt8] = [UInt8](repeating: 0x42, count: 500)
        let count = patchArt(&data, target: "duck", emoji: "🦆", varMap: v90)
        XCTAssertEqual(count, 0)
    }

    func testPatchArtReplacesWithEmoji() {
        let targetVar = v90["duck"]!
        let nextVar = v90["goose"]!
        let artBlock = buildArtBlock(targetVar: targetVar, varMap: v90, size: 300)
        let endMarker = buildArtEndMarker(nextVar)
        var data = syntheticBinary(with: [artBlock, endMarker])

        let count = patchArt(&data, target: "duck", emoji: "🦆", varMap: v90)
        XCTAssertGreaterThan(count, 0)

        // The emoji should now be in the data
        let emojiBytes = utf8Bytes("🦆")
        XCTAssertGreaterThan(findAll(in: data, pattern: emojiBytes).count, 0)
    }
}
