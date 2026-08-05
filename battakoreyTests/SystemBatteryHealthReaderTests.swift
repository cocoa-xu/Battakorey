import XCTest
@testable import battakorey

final class SystemBatteryHealthReaderTests: XCTestCase {
    func testDecodesSystemInformationHealth() throws {
        let data = try XCTUnwrap(Self.fixture.data(using: .utf8))
        let date = Date(timeIntervalSince1970: 1_000)
        let reading = try XCTUnwrap(SystemBatteryHealthDecoder.decode(data, sampledAt: date))

        XCTAssertEqual(reading.condition, "Good")
        XCTAssertEqual(reading.maximumCapacityPercentage, 82)
        XCTAssertEqual(reading.sampledAt, date)
    }

    func testRejectsMalformedOrOutOfRangeHealth() throws {
        let data = try XCTUnwrap(Self.outOfRangeFixture.data(using: .utf8))

        XCTAssertNil(SystemBatteryHealthDecoder.decode(Data("{}".utf8), sampledAt: Date()))
        XCTAssertNil(SystemBatteryHealthDecoder.decode(data, sampledAt: Date()))
    }

    func testRateLimitsFailedReads() {
        var readCount = 0
        let reader = SystemBatteryHealthReader(cacheDuration: 300) {
            readCount += 1
            return nil
        }
        let firstAttempt = Date(timeIntervalSince1970: 1_000)

        XCTAssertNil(reader.read(at: firstAttempt))
        XCTAssertNil(reader.read(at: firstAttempt.addingTimeInterval(1)))
        XCTAssertEqual(readCount, 1)

        XCTAssertNil(reader.read(at: firstAttempt.addingTimeInterval(300)))
        XCTAssertEqual(readCount, 2)
    }

    private static let fixture = #"""
    {
      "SPPowerDataType": [
        {
          "_name": "spbattery_information",
          "sppower_battery_health_info": {
            "sppower_battery_health": "Good",
            "sppower_battery_health_maximum_capacity": "82%"
          }
        }
      ]
    }
    """#

    private static let outOfRangeFixture = #"""
    {
      "SPPowerDataType": [
        {
          "_name": "spbattery_information",
          "sppower_battery_health_info": {
            "sppower_battery_health_maximum_capacity": "101%"
          }
        }
      ]
    }
    """#
}
