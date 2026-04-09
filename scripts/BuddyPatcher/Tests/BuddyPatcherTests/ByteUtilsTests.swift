import XCTest
@testable import BuddyPatcherLib

final class ByteUtilsTests: XCTestCase {

    // MARK: - findAll

    func testFindAllMultipleMatches() {
        let data: [UInt8] = [1, 2, 3, 1, 2, 3, 1, 2]
        let results = findAll(in: data, pattern: [1, 2, 3])
        XCTAssertEqual(results, [0, 3])
    }

    func testFindAllNoMatch() {
        let data: [UInt8] = [1, 2, 3, 4, 5]
        let results = findAll(in: data, pattern: [9, 9])
        XCTAssertEqual(results, [])
    }

    func testFindAllEmptyPattern() {
        let data: [UInt8] = [1, 2, 3]
        let results = findAll(in: data, pattern: [])
        XCTAssertEqual(results, [])
    }

    func testFindAllPatternLongerThanData() {
        let data: [UInt8] = [1, 2]
        let results = findAll(in: data, pattern: [1, 2, 3])
        XCTAssertEqual(results, [])
    }

    func testFindAllOverlapping() {
        // Pattern "ABA" in "ABABA" should find positions 0 and 2
        let data: [UInt8] = [0x41, 0x42, 0x41, 0x42, 0x41] // ABABA
        let results = findAll(in: data, pattern: [0x41, 0x42, 0x41])
        XCTAssertEqual(results, [0, 2])
    }

    func testFindAllAtBoundaries() {
        let data: [UInt8] = [0xAA, 0xBB, 0x00, 0x00, 0xAA, 0xBB]
        let results = findAll(in: data, pattern: [0xAA, 0xBB])
        XCTAssertEqual(results, [0, 4])
    }

    func testFindAllSingleByte() {
        let data: [UInt8] = [5, 3, 5, 7, 5]
        let results = findAll(in: data, pattern: [5])
        XCTAssertEqual(results, [0, 2, 4])
    }

    // MARK: - findFirst

    func testFindFirstBasic() {
        let data: [UInt8] = [0, 0, 1, 2, 3, 0, 1, 2, 3]
        XCTAssertEqual(findFirst(in: data, pattern: [1, 2, 3]), 2)
    }

    func testFindFirstFromOffset() {
        let data: [UInt8] = [0, 0, 1, 2, 3, 0, 1, 2, 3]
        XCTAssertEqual(findFirst(in: data, pattern: [1, 2, 3], from: 3), 6)
    }

    func testFindFirstNoMatch() {
        let data: [UInt8] = [1, 2, 3]
        XCTAssertNil(findFirst(in: data, pattern: [9, 9]))
    }

    func testFindFirstEmptyPattern() {
        let data: [UInt8] = [1, 2, 3]
        XCTAssertNil(findFirst(in: data, pattern: []))
    }

    func testFindFirstStartBeyondLimit() {
        let data: [UInt8] = [1, 2, 3]
        XCTAssertNil(findFirst(in: data, pattern: [1], from: 100))
    }

    func testFindFirstAtExactEnd() {
        let data: [UInt8] = [0, 0, 0, 1, 2]
        XCTAssertEqual(findFirst(in: data, pattern: [1, 2]), 3)
    }

    // MARK: - utf8Bytes

    func testUtf8BytesASCII() {
        let bytes = utf8Bytes("abc")
        XCTAssertEqual(bytes, [0x61, 0x62, 0x63])
    }

    func testUtf8BytesEmpty() {
        XCTAssertEqual(utf8Bytes(""), [])
    }

    func testUtf8BytesSpecialChars() {
        let bytes = utf8Bytes("H()<0.01")
        XCTAssertEqual(bytes.count, 8)
        XCTAssertEqual(bytes[0], 0x48) // H
    }

    func testUtf8BytesEmoji() {
        let bytes = utf8Bytes("🐧")
        XCTAssertEqual(bytes.count, 4) // penguin emoji is 4 UTF-8 bytes
    }
}
