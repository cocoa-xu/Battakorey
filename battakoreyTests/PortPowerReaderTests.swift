import XCTest
@testable import battakorey

final class PortPowerReaderTests: XCTestCase {
    func testDecodesAndSortsPowerOptions() throws {
        let options = PortPowerDecoder.options(from: [
            ["Voltage (mV)": 5_000, "Max Current (mA)": 3_000],
            ["Voltage (mV)": 20_000, "Max Current (mA)": 5_000, "Max Power (mW)": 100_000],
            ["Voltage (mV)": 0]
        ])

        XCTAssertEqual(options.count, 2)
        XCTAssertEqual(options[0].voltageVolts, 20)
        XCTAssertEqual(options[0].maximumCurrentAmps, 5)
        XCTAssertEqual(options[0].maximumPowerWatts, 100)
        XCTAssertEqual(options[1].maximumPowerWatts, 15)
    }

    func testPreservesMissingSelectedContractFields() throws {
        let option = try XCTUnwrap(PortPowerDecoder.option(from: [
            "Voltage (mV)": 9_000
        ]))

        XCTAssertEqual(option.voltageVolts, 9)
        XCTAssertNil(option.maximumCurrentAmps)
        XCTAssertNil(option.maximumPowerWatts)
        XCTAssertNil(PortPowerDecoder.option(from: ["Voltage (mV)": 0]))
    }

    func testClassifiesPowerSourceNames() {
        XCTAssertEqual(PortPowerDecoder.kind(from: "USB-PD"), .usbPD)
        XCTAssertEqual(PortPowerDecoder.kind(from: "TypeC"), .usbTypeC)
        XCTAssertEqual(PortPowerDecoder.kind(from: "Brick ID"), .brickIdentity)
        XCTAssertEqual(PortPowerDecoder.kind(from: "Future Source"), .unknown("Future Source"))
    }
}
