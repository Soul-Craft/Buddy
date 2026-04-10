import XCTest
@testable import BuddyPatcherLib

final class OrchestrationTests: XCTestCase {

    let v90 = knownVarMaps[0]

    // Build a synthetic binary that contains all patchable patterns.
    private func fullSyntheticBinary() -> [UInt8] {
        let speciesArray = buildSpeciesArray(v90)
        let rarity = buildRarityString()
        let shiny = buildShinyThreshold()
        // Art block for duck (first species) + end marker pointing at goose (next species)
        let artDuck = buildArtBlock(targetVar: v90["duck"]!, varMap: v90)
        let artEnd = buildArtEndMarker(v90["goose"]!)
        return syntheticBinary(with: [speciesArray, rarity, shiny, artDuck, artEnd])
    }

    // MARK: - hasPatchWork

    func testHasPatchWorkDetectsSpecies() {
        var opts = Options()
        opts.species = "penguin"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsRarity() {
        var opts = Options()
        opts.rarity = "legendary"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsShiny() {
        var opts = Options()
        opts.shiny = true
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsNoShiny() {
        var opts = Options()
        opts.noShiny = true
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsName() {
        var opts = Options()
        opts.name = "Aethos"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsPersonality() {
        var opts = Options()
        opts.personality = "wise"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsStats() {
        var opts = Options()
        opts.stats = "{\"debugging\":50}"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkDetectsEmoji() {
        var opts = Options()
        opts.emoji = "🔥"
        XCTAssertTrue(hasPatchWork(opts))
    }

    func testHasPatchWorkFalseForEmpty() {
        let opts = Options()
        XCTAssertFalse(hasPatchWork(opts))
    }

    func testHasPatchWorkFalseForAnalyzeOnly() {
        var opts = Options()
        opts.analyze = true
        // --analyze by itself is not "patch work" — the pipeline shouldn't run
        XCTAssertFalse(hasPatchWork(opts))
    }

    // MARK: - runPatchPipeline — full application

    func testPipelineAppliesAllBinaryPatches() {
        let data = fullSyntheticBinary()
        var opts = Options()
        opts.species = "penguin"
        opts.rarity = "legendary"
        opts.shiny = true
        opts.emoji = "🔥"

        let result = runPatchPipeline(data: data, opts: opts)

        XCTAssertGreaterThan(result.totalPatches, 0)
        XCTAssertEqual(result.patchedData.count, data.count, "Pipeline must preserve byte length")
        XCTAssertTrue(result.warnings.isEmpty, "No warnings expected for fully-specified patch")

        // Verify species patch landed: penguin var (NL_) should appear
        let penguinVar = utf8Bytes(v90["penguin"]!)
        XCTAssertGreaterThan(findAll(in: result.patchedData, pattern: penguinVar).count, 0)

        // Verify shiny patch landed: "H()<1.01" should now exist
        XCTAssertNotNil(findFirst(in: result.patchedData, pattern: utf8Bytes("H()<1.01")))
    }

    // MARK: - runPatchPipeline — warnings

    func testPipelineWarnsWhenEmojiWithoutSpecies() {
        let data = fullSyntheticBinary()
        var opts = Options()
        opts.emoji = "🔥"
        // No species set

        let result = runPatchPipeline(data: data, opts: opts)

        XCTAssertTrue(
            result.warnings.contains { $0.contains("--emoji requires --species") },
            "Should warn when --emoji is given without --species"
        )
    }

    func testPipelineWarnsWhenNoAnchorMatches() {
        // A buffer that contains NONE of the known anchors
        let data: [UInt8] = [UInt8](repeating: 0x42, count: 500)
        var opts = Options()
        opts.species = "penguin"

        let result = runPatchPipeline(data: data, opts: opts)

        // Single consolidated warning instead of per-patch warnings
        XCTAssertTrue(
            result.warnings.contains { $0.contains("No matching anchor found") },
            "Should warn once when no known anchor is found"
        )
        XCTAssertEqual(result.warnings.count, 1, "Should emit exactly one warning")
        // Returns 0 patches — pipeline short-circuits on anchor miss
        XCTAssertEqual(result.totalPatches, 0)
        // Fallback is still the newest var map
        XCTAssertEqual(result.varMap["duck"], knownVarMaps[0]["duck"])
    }

    // MARK: - runPatchPipeline — precedence

    func testPipelineShinyPrecedesNoShiny() {
        let data = fullSyntheticBinary()
        var opts = Options()
        opts.shiny = true
        opts.noShiny = true  // conflicting — shiny should win

        let result = runPatchPipeline(data: data, opts: opts)

        // After a "shiny" patch the threshold becomes "H()<1.01"
        XCTAssertNotNil(findFirst(in: result.patchedData, pattern: utf8Bytes("H()<1.01")))
        // Original "H()<0.01" is gone
        XCTAssertNil(findFirst(in: result.patchedData, pattern: utf8Bytes("H()<0.01")))
    }

    // MARK: - runPatchPipeline — byte invariant

    func testPipelinePreservesLengthAcrossAllPatches() {
        let data = fullSyntheticBinary()
        let originalLen = data.count

        var opts = Options()
        opts.species = "dragon"
        opts.rarity = "epic"
        opts.shiny = true
        opts.emoji = "🔥"

        let result = runPatchPipeline(data: data, opts: opts)
        XCTAssertEqual(result.patchedData.count, originalLen,
                       "Byte-length invariant must hold for every combination of patches")
    }

    // MARK: - runPatchPipeline — no-op

    func testPipelineNoOpWhenNoOptsSet() {
        let data = fullSyntheticBinary()
        let opts = Options()

        let result = runPatchPipeline(data: data, opts: opts)

        XCTAssertEqual(result.totalPatches, 0)
        XCTAssertEqual(result.patchedData, data, "Data must be unchanged when no patch work is requested")
    }

    func testPipelineDetectsVarMapFromRealAnchor() {
        let data = fullSyntheticBinary()
        var opts = Options()
        opts.species = "cat"

        let result = runPatchPipeline(data: data, opts: opts)

        // Detected var map must be the v90 map (that's what we built the binary with)
        XCTAssertEqual(result.varMap["duck"], v90["duck"])
        XCTAssertEqual(result.anchor, anchorForMap(v90))
    }
}
