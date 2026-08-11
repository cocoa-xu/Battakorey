import XCTest
@testable import battakorey

final class BatteryMenuPresenterTests: XCTestCase {
    private let presenter = BatteryMenuPresenter()

    func testFormatsDischargingBatteryDetails() throws {
        let battery = try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.discharging))
        let rows = rowValues(
            in: presenter.sections(for: battery) + presenter.detailSections(for: battery)
        )

        XCTAssertEqual(rows["Battery"], "64%")
        XCTAssertEqual(rows["Status"], "Discharging")
        XCTAssertEqual(rows["Power Source"], "Battery Power")
        XCTAssertEqual(rows["Time to Empty"], "2 h 5 m")
        XCTAssertEqual(rows["Raw Capacity Ratio"], "81.9%")
        XCTAssertEqual(rows["Cycles"], "250 / 1000 (25.0%)")
        XCTAssertEqual(rows["Temperature"], "31.2 °C")
        XCTAssertEqual(rows["Voltage"], "11.840 V")
        XCTAssertEqual(rows["Current"], "-2.150 A")
        XCTAssertEqual(rows["Battery Flow"], "-30.2 W")
        XCTAssertEqual(rows["Voltages"], "3.950 · 3.947 · 3.952 V")
        XCTAssertEqual(rows["Voltage Delta"], "5 mV")
        XCTAssertEqual(rows["Learned Qmax"], "7900 · 7850 · 7920 mAh")
        XCTAssertEqual(rows["Qmax Delta"], "70 mAh")
        XCTAssertEqual(rows["Resistance"], "45 · 50 · 47")
        XCTAssertEqual(rows["Daily Charge Range"], "18% – 91%")
        XCTAssertEqual(rows["Last Gauge Relearn"], "Cycle 240")
        XCTAssertEqual(rows["Data Flash Writes"], "320")
        XCTAssertEqual(rows["Rsense Open Events"], "2")
        XCTAssertEqual(rows["Qmax Disqualification"], "0x00000000")
        XCTAssertEqual(rows["Min / Avg / Max Temp"], "10.0 / 28.7 / 45.0 °C")
        XCTAssertEqual(rows["Pack Voltage Range"], "10.500 – 13.000 V")
        XCTAssertEqual(rows["Peak Charge / Discharge"], "+6.000 / -9.500 A")
        XCTAssertEqual(rows["Operating Time"], "12345 h")
        XCTAssertEqual(rows["Controller System Load"], "25.5 W")
        XCTAssertEqual(rows["CPU"], "4.25 W")
        XCTAssertEqual(rows["GPU"], "1.50 W")
        XCTAssertEqual(rows["Neural Engine"], "0.00 W")
        XCTAssertEqual(rows["Memory"], "0.85 W")
        XCTAssertEqual(rows["GPU SRAM"], "0.12 W")
        XCTAssertEqual(rows["Built-in Display"], "0.70 W")
        XCTAssertEqual(rows["External Displays"], "1.10 W")
        XCTAssertEqual(rows["Low Power Mode"], "On")
        XCTAssertEqual(rows["Failure Status"], "0x00000000")
        XCTAssertEqual(rows["Not Charging Reason"], "0x00400001")
    }

    func testFormatsChargingAndAdapterDetails() throws {
        let battery = try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.charging))
        let rows = rowValues(in: presenter.sections(for: battery))

        XCTAssertEqual(rows["Status"], "Charging")
        XCTAssertEqual(rows["Time to Full"], "0 h 48 m")
        XCTAssertEqual(rows["Adapter Rating"], "96 W")
        XCTAssertEqual(rows["Adapter Electrical Capability"], "20.0V @ 4.8A · 96 W")
        XCTAssertEqual(rows["USB-C PD Contract"], "Port 2 · 20.0V @ 4.5A · 90 W")
        XCTAssertEqual(rows["Live Input"], "70.3 W")
        XCTAssertEqual(rows["DC Input Rail"], "20.10V @ 3.50A")
        XCTAssertEqual(rows["Maximum Capacity"], "82%")
        XCTAssertEqual(rows["Condition"], "Good")
        XCTAssertEqual(rows["Controller Charge Target"], "36.6 W")
    }

    func testOmitsUnavailableOptionalRows() throws {
        let rawData = BatteryRawData(
            registry: ["CurrentCapacity": 50],
            powerSource: ["Power Source State": "Battery Power"],
            adapter: nil
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))
        let sections = presenter.sections(for: battery)
        let rows = rowValues(in: sections)

        XCTAssertEqual(sections.map(\.title), [nil])
        XCTAssertEqual(rows["Time to Empty"], "Calculating…")
        XCTAssertNil(rows["Temperature"])
        XCTAssertNil(rows["Adapter Rating"])
    }

    func testOmitsBatteryOnlyRowsOnBatteryFreeDevice() throws {
        let rawData = BatteryRawData(
            registry: [
                "BatteryInstalled": false,
                "ExternalConnected": true,
                "CurrentCapacity": 0,
                "CycleCount": 0,
                "Voltage": 0,
                "Amperage": 0,
                "PowerTelemetryData": ["SystemLoad": 8_358]
            ],
            powerSource: [:],
            adapter: nil,
            hasBattery: false,
            smcPower: SMCPowerReading(
                batteryWatts: 0,
                inputVolts: nil,
                inputAmps: nil,
                inputWatts: 7.1
            )
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))
        let sections = presenter.sections(for: battery)
        let rows = rowValues(in: sections)

        XCTAssertEqual(rows["Status"], "On AC Power")
        XCTAssertEqual(rows["Power Source"], "AC Power")
        XCTAssertEqual(rows["Controller System Load"], "8.4 W")
        XCTAssertEqual(rows["Live Input"], "7.1 W")
        XCTAssertNil(rows["Battery"])
        XCTAssertNil(rows["Cycles"])
        XCTAssertNil(rows["Battery Flow"])
        XCTAssertNil(rows["Voltage"])
        XCTAssertTrue(presenter.detailSections(for: battery).isEmpty)
    }

    func testDoesNotRetainEmptySectionsAfterFilteringBatteryOnlyRows() throws {
        let rawData = BatteryRawData(
            registry: [
                "BatteryInstalled": false,
                "ExternalConnected": true,
                "CurrentCapacity": 0,
                "CycleCount": 0,
                "BatteryData": ["CellVoltage": [4_100, 4_095]]
            ],
            powerSource: [:],
            adapter: nil,
            hasBattery: false
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))
        let batteryOnlyVisibility = BatteryMenuVisibility(
            visibleItemIDs: [.batteryLevel, .cycles, .cellVoltages]
        )

        XCTAssertTrue(presenter.sections(
            for: battery,
            visibility: batteryOnlyVisibility
        ).isEmpty)
        XCTAssertTrue(presenter.detailSections(
            for: battery,
            visibility: batteryOnlyVisibility
        ).isEmpty)
    }

    func testMissingBatteryWarningCanBeHiddenOnConfirmedMacBook() throws {
        let rawData = BatteryRawData(
            registry: ["ExternalConnected": true],
            powerSource: [:],
            adapter: nil,
            hasBattery: false,
            hardwareProfile: HardwareProfile(machineName: "MacBook Pro")
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))

        let visibleRows = rowValues(in: presenter.sections(for: battery))
        let hiddenRows = rowValues(in: presenter.sections(
            for: battery,
            visibility: BatteryMenuVisibility(
                visibleItemIDs: [.status, .powerSource]
            )
        ))

        XCTAssertEqual(visibleRows["Battery Warning"], "No Battery Detected")
        XCTAssertNil(hiddenRows["Battery Warning"])
    }

    func testFiltersMainAndInternalRowsWithMockedVisibility() throws {
        let battery = try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.discharging))
        let visibility = BatteryMenuVisibility(visibleItemIDs: [.temperature, .cellVoltages])
        let sections = presenter.sections(for: battery, visibility: visibility)
        let detailSections = presenter.detailSections(for: battery, visibility: visibility)

        XCTAssertEqual(sections.map(\.title), ["Electrical"])
        XCTAssertEqual(sections.flatMap(\.rows).map(\.id), [.temperature])
        XCTAssertEqual(detailSections.map(\.title), ["Cells"])
        XCTAssertEqual(detailSections.flatMap(\.rows).map(\.id), [.cellVoltages])
    }

    func testHidesSectionTitlesWithoutChangingRowOrder() throws {
        let battery = try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.discharging))
        let visibility = BatteryMenuVisibility(
            visibleItemIDs: [.currentCharge, .temperature, .cellVoltages],
            showsSectionTitles: false
        )
        let sections = presenter.sections(for: battery, visibility: visibility)
        let detailSections = presenter.detailSections(for: battery, visibility: visibility)

        XCTAssertEqual(sections.map(\.title), [nil, nil])
        XCTAssertEqual(sections.flatMap(\.rows).map(\.id), [.currentCharge, .temperature])
        XCTAssertEqual(detailSections.map(\.title), [nil])
        XCTAssertEqual(detailSections.flatMap(\.rows).map(\.id), [.cellVoltages])
    }

    private func rowValues(in sections: [BatteryMenuSection]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: sections.flatMap(\.rows).map { ($0.title, $0.value) })
    }
}
