import XCTest
@testable import battakorey

final class IOReportPowerReaderTests: XCTestCase {
    func testConvertsAndAggregatesEnergyChannels() throws {
        let reading = try XCTUnwrap(IOReportPowerDecoder.reading(
            from: [
                IOReportEnergySample(channel: "CPU Energy", unit: "mJ", energy: 2_250),
                IOReportEnergySample(channel: "DIE_1_CPU Energy", unit: "mJ", energy: 750),
                IOReportEnergySample(channel: "GPU Energy", unit: "nJ", energy: 750_000_000),
                IOReportEnergySample(channel: "ANE0", unit: "mJ", energy: 300),
                IOReportEnergySample(channel: "DRAM0", unit: "uJ", energy: 1_500_000),
                IOReportEnergySample(channel: "GPU SRAM", unit: "mJ", energy: 75),
                IOReportEnergySample(channel: "DISP", unit: "mJ", energy: 450),
                IOReportEnergySample(channel: "DISPEXT", unit: "mJ", energy: 150)
            ],
            duration: 1.5
        ))

        XCTAssertEqual(try XCTUnwrap(reading.cpuWatts), 2, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(reading.gpuWatts), 0.5, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(reading.aneWatts), 0.2, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(reading.memoryWatts), 1, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(reading.gpuMemoryWatts), 0.05, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(reading.displayWatts), 0.3, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(reading.externalDisplayWatts), 0.1, accuracy: 0.000_001)
    }

    func testIgnoresInvalidSamplesWithoutRejectingZeroPower() throws {
        let reading = try XCTUnwrap(IOReportPowerDecoder.reading(
            from: [
                IOReportEnergySample(channel: "CPU Energy", unit: "mJ", energy: -1),
                IOReportEnergySample(channel: "GPU Energy", unit: "ticks", energy: 100),
                IOReportEnergySample(channel: "ANE", unit: "mJ", energy: 0)
            ],
            duration: 1
        ))

        XCTAssertNil(reading.cpuWatts)
        XCTAssertNil(reading.gpuWatts)
        XCTAssertEqual(reading.aneWatts, 0)
    }

    func testRejectsEmptyOrInvalidSamplingWindows() {
        let sample = IOReportEnergySample(channel: "CPU Energy", unit: "mJ", energy: 1_000)

        XCTAssertNil(IOReportPowerDecoder.reading(from: [], duration: 1))
        XCTAssertNil(IOReportPowerDecoder.reading(from: [sample], duration: 0))
        XCTAssertNil(IOReportPowerDecoder.reading(from: [sample], duration: .infinity))
    }
}
