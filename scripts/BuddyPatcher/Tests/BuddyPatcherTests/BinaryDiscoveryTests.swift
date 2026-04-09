import XCTest
@testable import BuddyPatcherLib

final class BinaryDiscoveryTests: XCTestCase {

    func testGetVersionExtractsLastComponent() {
        let url = URL(fileURLWithPath: "/Users/test/.local/share/claude/versions/2.1.90")
        XCTAssertEqual(getVersion(url), "2.1.90")
    }

    func testGetVersionSingleComponent() {
        let url = URL(fileURLWithPath: "/claude")
        XCTAssertEqual(getVersion(url), "claude")
    }

    func testPatchErrorBinaryNotFoundDescription() {
        let error = PatchError.binaryNotFound("test message")
        XCTAssertEqual(error.description, "test message")
    }

    func testPatchErrorPatchFailedDescription() {
        let error = PatchError.patchFailed("patch failed")
        XCTAssertEqual(error.description, "patch failed")
    }

    func testPatchErrorVerificationFailedDescription() {
        let error = PatchError.verificationFailed
        XCTAssertEqual(error.description, "Binary verification failed")
    }
}
