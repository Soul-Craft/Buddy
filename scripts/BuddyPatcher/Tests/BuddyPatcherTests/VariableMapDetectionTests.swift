import XCTest
@testable import BuddyPatcherLib

final class VariableMapDetectionTests: XCTestCase {

    // MARK: - anchorForMap

    func testAnchorForMapV90() {
        let anchor = anchorForMap(knownVarMaps[0])
        let expected = utf8Bytes("GL_,ZL_,LL_,kL_,")
        XCTAssertEqual(anchor, expected)
    }

    func testAnchorForMapV89() {
        let anchor = anchorForMap(knownVarMaps[1])
        let expected = utf8Bytes("b0_,I0_,x0_,u0_,")
        XCTAssertEqual(anchor, expected)
    }

    func testAnchorConsistency() {
        // All anchors should be 16 bytes: 4 * (3 byte var + 1 comma)
        for varMap in knownVarMaps {
            let anchor = anchorForMap(varMap)
            XCTAssertEqual(anchor.count, 16, "Anchor should be exactly 16 bytes")
        }
    }

    // MARK: - detectVarMap

    func testDetectVarMapFindsNewestFirst() {
        // Data contains both anchors — should return v90 (first in knownVarMaps)
        let v90Anchor = anchorForMap(knownVarMaps[0])
        let v89Anchor = anchorForMap(knownVarMaps[1])
        let data = syntheticBinary(with: [v89Anchor, v90Anchor])

        let result = detectVarMap(in: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.varMap["duck"], "GL_") // v90
    }

    func testDetectVarMapFindsV89Only() {
        let v89Anchor = anchorForMap(knownVarMaps[1])
        let data = syntheticBinary(with: [v89Anchor])

        let result = detectVarMap(in: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.varMap["duck"], "b0_") // v89
    }

    func testDetectVarMapReturnsNilForUnknown() {
        let data: [UInt8] = [UInt8](repeating: 0x42, count: 1000)
        XCTAssertNil(detectVarMap(in: data))
    }

    func testDetectVarMapEmptyData() {
        XCTAssertNil(detectVarMap(in: []))
    }

    // MARK: - Structural validation

    func testAllSpeciesInEveryMap() {
        for (i, varMap) in knownVarMaps.enumerated() {
            for species in allSpecies {
                XCTAssertNotNil(varMap[species], "Map \(i) missing species '\(species)'")
            }
        }
    }

    func testVarMapValuesAreThreeBytes() {
        for (i, varMap) in knownVarMaps.enumerated() {
            for (species, varName) in varMap {
                let bytes = utf8Bytes(varName)
                XCTAssertEqual(bytes.count, 3, "Map \(i): '\(species)' var '\(varName)' is \(bytes.count) bytes, expected 3")
            }
        }
    }

    func testVarMapValuesAreUnique() {
        for (i, varMap) in knownVarMaps.enumerated() {
            let values = Array(varMap.values)
            let unique = Set(values)
            XCTAssertEqual(values.count, unique.count, "Map \(i) has duplicate variable names")
        }
    }
}
