import XCTest
@testable import battakorey

final class HardwareProfileReaderTests: XCTestCase {
    func testRecognizesMacBookFamilyNames() {
        XCTAssertTrue(HardwareProfileDecoder.isMacBook(profile(machineName: "MacBook Air")))
        XCTAssertTrue(HardwareProfileDecoder.isMacBook(profile(machineName: "MacBook Pro")))
        XCTAssertTrue(HardwareProfileDecoder.isMacBook(profile(machineName: "MacBook")))
    }

    func testDoesNotTreatDesktopOrUnknownProfilesAsMacBooks() {
        XCTAssertFalse(HardwareProfileDecoder.isMacBook(profile(machineName: "Mac mini")))
        XCTAssertFalse(HardwareProfileDecoder.isMacBook(profile(machineName: "Mac Studio")))
        XCTAssertFalse(HardwareProfileDecoder.isMacBook(profile(machineName: "iMac")))
        XCTAssertFalse(HardwareProfileDecoder.isMacBook(Data("{}".utf8)))
    }

    func testReaderCachesHardwareProfile() {
        var readCount = 0
        let reader = HardwareProfileReader {
            readCount += 1
            return self.profile(machineName: "MacBook Pro")
        }

        XCTAssertTrue(reader.isMacBook())
        XCTAssertTrue(reader.isMacBook())
        XCTAssertEqual(readCount, 1)
    }

    private func profile(machineName: String) -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "SPHardwareDataType": [["machine_name": machineName]]
        ])
    }
}
