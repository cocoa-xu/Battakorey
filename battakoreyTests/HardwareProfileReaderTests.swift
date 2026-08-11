import XCTest
@testable import battakorey

final class HardwareProfileReaderTests: XCTestCase {
    func testRecognizesMacBookFamilyNames() {
        XCTAssertTrue(decodedProfile(machineName: "MacBook Air")?.isMacBook == true)
        XCTAssertTrue(decodedProfile(machineName: "MacBook Pro")?.isMacBook == true)
        XCTAssertTrue(decodedProfile(machineName: "MacBook")?.isMacBook == true)
    }

    func testRecognizesDesktopMacNames() {
        let names = ["Mac mini", "Mac Studio", "Mac Pro", "iMac", "iMac Pro"]

        for name in names {
            let profile = decodedProfile(machineName: name)
            XCTAssertEqual(profile?.machineName, name)
            XCTAssertTrue(profile?.isDesktopMac == true)
            XCTAssertFalse(profile?.isMacBook == true)
        }
    }

    func testDoesNotClassifyUnknownProfiles() {
        let unknown = decodedProfile(machineName: "Future Mac")

        XCTAssertFalse(unknown?.isMacBook == true)
        XCTAssertFalse(unknown?.isDesktopMac == true)
        XCTAssertNil(HardwareProfileDecoder.decode(Data("{}".utf8)))
    }

    func testReaderCachesHardwareProfile() {
        var readCount = 0
        let reader = HardwareProfileReader {
            readCount += 1
            return self.profile(machineName: "MacBook Pro")
        }

        XCTAssertEqual(reader.profile(), HardwareProfile(machineName: "MacBook Pro"))
        XCTAssertEqual(reader.profile(), HardwareProfile(machineName: "MacBook Pro"))
        XCTAssertEqual(readCount, 1)
    }

    func testReaderCachesAnUnavailableProfile() {
        var readCount = 0
        let reader = HardwareProfileReader {
            readCount += 1
            return nil
        }

        XCTAssertNil(reader.profile())
        XCTAssertNil(reader.profile())
        XCTAssertEqual(readCount, 1)
    }

    private func decodedProfile(machineName: String) -> HardwareProfile? {
        HardwareProfileDecoder.decode(profile(machineName: machineName))
    }

    private func profile(machineName: String) -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "SPHardwareDataType": [["machine_name": machineName]]
        ])
    }
}
