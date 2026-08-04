import XCTest
@testable import battakorey

final class BatterySnapshotTests: XCTestCase {
    func testParsesMockedRegistryAndPowerSourceData() throws {
        let battery = try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.discharging))

        XCTAssertEqual(battery.chargePercentage, 64)
        XCTAssertEqual(battery.powerSource, .battery)
        XCTAssertFalse(battery.isCharging)
        XCTAssertFalse(battery.isExternallyPowered)
        XCTAssertEqual(battery.timeRemainingMinutes, 125)
        XCTAssertEqual(battery.currentCapacityMAh, 4_800)
        XCTAssertEqual(battery.fullChargeCapacityMAh, 6_550)
        XCTAssertEqual(battery.rawMaximumCapacityMAh, 6_400)
        XCTAssertEqual(battery.nominalChargeCapacityMAh, 6_550)
        XCTAssertEqual(battery.designCapacityMAh, 8_000)
        XCTAssertEqual(try XCTUnwrap(battery.capacityRetentionPercentage), 81.875, accuracy: 0.001)
        XCTAssertEqual(battery.cycleCount, 250)
        XCTAssertEqual(battery.designCycleCount, 1_000)
        XCTAssertEqual(try XCTUnwrap(battery.temperatureCelsius), 31.25, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.voltageVolts), 11.84, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.currentAmps), -2.15, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.batteryPowerWatts), -30.25, accuracy: 0.001)
        XCTAssertEqual(battery.cellDetails?.voltages, [3.950, 3.947, 3.952])
        XCTAssertEqual(battery.cellDetails?.voltageDeltaMillivolts, 5)
        XCTAssertEqual(battery.cellDetails?.learnedCapacitiesMAh, [7_900, 7_850, 7_920])
        XCTAssertEqual(battery.cellDetails?.learnedCapacityDeltaMAh, 70)
        XCTAssertEqual(battery.cellDetails?.resistances, [45, 50, 47])
        XCTAssertEqual(battery.cellDetails?.resistanceDelta, 5)
        XCTAssertEqual(battery.cellDetails?.dailyMinimumCharge, 18)
        XCTAssertEqual(battery.cellDetails?.dailyMaximumCharge, 91)
        XCTAssertEqual(battery.cellDetails?.cycleCountAtLastRelearn, 240)
        XCTAssertEqual(battery.cellDetails?.dataFlashWriteCount, 320)
        XCTAssertEqual(battery.cellDetails?.resistanceSenseOpenCount, 2)
        XCTAssertEqual(battery.cellDetails?.qmaxDisqualificationReason, 0)
        XCTAssertEqual(battery.lifetimeDetails?.minimumTemperatureCelsius, 10)
        XCTAssertEqual(battery.lifetimeDetails?.averageTemperatureCelsius, 28.7)
        XCTAssertEqual(battery.lifetimeDetails?.maximumTemperatureCelsius, 45)
        XCTAssertEqual(battery.lifetimeDetails?.minimumPackVoltageVolts, 10.5)
        XCTAssertEqual(battery.lifetimeDetails?.maximumPackVoltageVolts, 13)
        XCTAssertEqual(battery.lifetimeDetails?.maximumChargeCurrentAmps, 6)
        XCTAssertEqual(battery.lifetimeDetails?.maximumDischargeCurrentAmps, 9.5)
        XCTAssertEqual(battery.lifetimeDetails?.operatingTimeHours, 12_345)
        XCTAssertEqual(try XCTUnwrap(battery.systemPowerWatts), 25.456, accuracy: 0.001)
        XCTAssertEqual(battery.lowPowerModeActive, true)
        XCTAssertEqual(battery.optimizedChargingActive, false)
        XCTAssertEqual(battery.permanentFailureStatus, 0)
        XCTAssertEqual(battery.cellDisconnectCount, 0)
        XCTAssertEqual(battery.notChargingReason, 4_194_305)
        XCTAssertEqual(battery.slowChargingReason, 0)
    }

    func testUsesPublicTimeEstimateAndAdapterDetailsWhenCharging() throws {
        let battery = try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.charging))

        XCTAssertTrue(battery.isCharging)
        XCTAssertTrue(battery.isExternallyPowered)
        XCTAssertEqual(battery.powerSource, .ac)
        XCTAssertEqual(battery.timeRemainingMinutes, 48)
        XCTAssertEqual(battery.adapterWatts, 96)
        XCTAssertEqual(try XCTUnwrap(battery.adapterVoltageVolts), 20, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.adapterCurrentAmps), 4.8, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.batteryPowerWatts), 36.6, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.inputVoltageVolts), 20.1, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.inputCurrentAmps), 3.5, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.inputPowerWatts), 70.35, accuracy: 0.001)
    }

    func testMissingOptionalFieldsRemainNil() throws {
        let rawData = BatteryRawData(
            registry: [:],
            powerSource: [
                "Current Capacity": 42,
                "Power Source State": "Battery Power"
            ],
            adapter: nil
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))

        XCTAssertEqual(battery.chargePercentage, 42)
        XCTAssertEqual(battery.powerSource, .battery)
        XCTAssertNil(battery.currentCapacityMAh)
        XCTAssertNil(battery.temperatureCelsius)
        XCTAssertNil(battery.batteryPowerWatts)
        XCTAssertNil(battery.cellDetails)
    }

    func testMissingChargePercentageRejectsSnapshot() {
        let rawData = BatteryRawData(registry: [:], powerSource: [:], adapter: nil)

        XCTAssertNil(BatterySnapshot(rawData: rawData))
    }

    func testMalformedPrivateValuesAreIgnoredWithoutOverflow() throws {
        let rawData = BatteryRawData(
            registry: [
                "CurrentCapacity": 50,
                "IsCharging": true,
                "ChargerData": [
                    "ChargingVoltage": Int.max,
                    "ChargingCurrent": Int.max,
                    "NotChargingReason": Int.min,
                    "SlowChargingReason": Int.min
                ],
                "BatteryData": [
                    "CellVoltage": [Int.min, Int.max],
                    "Qmax": [Int.min, Int.max],
                    "WeightedRa": [Int.min, Int.max],
                    "DataFlashWriteCount": Int.min,
                    "BatteryRsenseOpenCount": Int.min,
                    "QmaxDisqualificationReason": Int.min,
                    "LifetimeData": [
                        "MaximumChargeCurrent": Int.min,
                        "MaximumDischargeCurrent": Int.min
                    ]
                ]
            ],
            powerSource: ["Power Source State": "AC Power"],
            adapter: nil
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))

        XCTAssertNil(battery.batteryPowerWatts)
        XCTAssertNil(battery.cellDetails)
        XCTAssertNil(battery.lifetimeDetails)
        XCTAssertNil(battery.notChargingReason)
        XCTAssertNil(battery.slowChargingReason)
    }
}
