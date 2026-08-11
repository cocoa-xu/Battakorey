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
        XCTAssertEqual(try XCTUnwrap(battery.rawCapacityRatioPercentage), 81.875, accuracy: 0.001)
        XCTAssertEqual(battery.cycleCount, 250)
        XCTAssertEqual(battery.designCycleCount, 1_000)
        XCTAssertEqual(try XCTUnwrap(battery.temperatureCelsius), 31.25, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.voltageVolts), 11.84, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.currentAmps), -2.15, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.batteryFlow?.value), -30.25, accuracy: 0.001)
        XCTAssertEqual(battery.batteryFlow?.kind, .measured)
        XCTAssertEqual(battery.batteryFlow?.domain, .battery)
        XCTAssertEqual(battery.batteryFlow?.direction, .discharge)
        XCTAssertEqual(battery.batteryFlow?.source, .smc)
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
        XCTAssertEqual(try XCTUnwrap(battery.controllerSystemLoad?.value), 25.456, accuracy: 0.001)
        XCTAssertEqual(battery.controllerSystemLoad?.kind, .estimated)
        XCTAssertEqual(battery.controllerSystemLoad?.source, .batteryController)
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
        XCTAssertEqual(try XCTUnwrap(battery.adapterRating?.value), 96, accuracy: 0.001)
        XCTAssertEqual(battery.adapterRating?.kind, .rated)
        XCTAssertEqual(try XCTUnwrap(battery.adapterCapability?.voltageVolts), 20, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.adapterCapability?.currentAmps), 4.8, accuracy: 0.001)
        XCTAssertEqual(battery.adapterCapability?.kind, .rated)
        XCTAssertEqual(try XCTUnwrap(battery.batteryFlow?.value), 36.6, accuracy: 0.001)
        XCTAssertEqual(battery.batteryFlow?.kind, .measured)
        XCTAssertEqual(battery.batteryFlow?.source, .batteryRegistry)
        XCTAssertEqual(try XCTUnwrap(battery.chargingTargetPower?.value), 36.6, accuracy: 0.001)
        XCTAssertEqual(battery.chargingTargetPower?.kind, .estimated)
        XCTAssertEqual(battery.chargingTargetPower?.source, .batteryController)
        XCTAssertEqual(try XCTUnwrap(battery.inputVoltage?.value), 20.1, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.inputCurrent?.value), 3.5, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(battery.liveInputPower?.value), 70.35, accuracy: 0.001)
        XCTAssertEqual(battery.liveInputPower?.kind, .measured)
        XCTAssertEqual(battery.offeredPowerContracts.count, 1)
        XCTAssertEqual(battery.offeredPowerContracts.first?.kind, .rated)
        XCTAssertEqual(battery.offeredPowerContracts.first?.direction, .input)
        XCTAssertEqual(battery.offeredPowerContracts.first?.accessTier, .enhanced)
        XCTAssertEqual(battery.negotiatedPowerContracts.count, 1)
        XCTAssertEqual(battery.negotiatedPowerContracts.first?.portNumber, 2)
        XCTAssertEqual(battery.negotiatedPowerContracts.first?.kind, .contracted)
        XCTAssertEqual(battery.negotiatedPowerContracts.first?.direction, .input)
        XCTAssertEqual(battery.officialCondition, "Good")
        XCTAssertEqual(battery.officialMaximumCapacityPercentage, 82)
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
        XCTAssertNil(battery.batteryFlow)
        XCTAssertNil(battery.cellDetails)
    }

    func testMissingChargePercentageRejectsSnapshot() {
        let rawData = BatteryRawData(registry: [:], powerSource: [:], adapter: nil)

        XCTAssertNil(BatterySnapshot(rawData: rawData))
    }

    func testBatteryFreeDeviceDoesNotRequireChargePercentage() throws {
        let rawData = BatteryRawData(
            registry: ["BatteryInstalled": false, "ExternalConnected": true],
            powerSource: [:],
            adapter: nil,
            hasBattery: false
        )

        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))

        XCTAssertFalse(battery.hasBattery)
        XCTAssertFalse(battery.shouldWarnAboutMissingBattery)
        XCTAssertEqual(battery.chargePercentage, 0)
        XCTAssertEqual(battery.statusBarChargePercentage, 100)
        XCTAssertEqual(battery.powerSource, .ac)
    }

    func testMissingBatteryWarningRequiresConfirmedMacBook() throws {
        let rawData = BatteryRawData(
            registry: ["ExternalConnected": true],
            powerSource: [:],
            adapter: nil,
            hasBattery: false,
            batteryIsExpected: true
        )

        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))

        XCTAssertTrue(battery.shouldWarnAboutMissingBattery)
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

        XCTAssertNil(battery.batteryFlow)
        XCTAssertNil(battery.chargingTargetPower)
        XCTAssertNil(battery.cellDetails)
        XCTAssertNil(battery.lifetimeDetails)
        XCTAssertNil(battery.notChargingReason)
        XCTAssertNil(battery.slowChargingReason)
    }

    func testDecodesPublicChargingDiagnostics() throws {
        let rawData = BatteryRawData(
            registry: ["CurrentCapacity": 50],
            powerSource: [
                "Power Source State": "AC Power",
                "BatteryHealth": "Check Battery",
                "BatteryHealthCondition": "Service Recommended",
                "HealthConfidence": 2,
                "BatteryFailureModes": ["Cell Imbalance"],
                "CapacityEstimated": true,
                "ChargeStatus": "HighTemperature"
            ],
            adapter: [
                "ErrorFlags": TestAdapterErrorFlag.insufficientPower
                    | TestAdapterErrorFlag.needsRepositioning
            ]
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))

        XCTAssertEqual(battery.publicHealthHint, "Check Battery")
        XCTAssertEqual(battery.publicHealthCondition, "Service Recommended")
        XCTAssertEqual(battery.publicHealthConfidence, "Fair")
        XCTAssertEqual(battery.batteryFailureModes, ["Cell Imbalance"])
        XCTAssertEqual(battery.capacityIsEstimated, true)
        XCTAssertEqual(battery.chargeInterruption, .highTemperature)
        XCTAssertEqual(battery.adapterErrors, [
            .insufficientAvailablePower,
            .needsRepositioning
        ])
    }

    func testSuppressesSelectedPDContractWhenPortIsInactive() throws {
        let rawData = BatteryRawData(
            registry: ["CurrentCapacity": 50, "ExternalConnected": true],
            powerSource: ["Power Source State": "AC Power"],
            adapter: nil,
            portPower: PortPowerReading(
                sources: [
                    PortPowerSourceReading(
                        portNumber: 1,
                        kind: .usbPD,
                        advertisedOptions: [],
                        selectedOption: PortPowerOption(
                            voltageVolts: 20,
                            maximumCurrentAmps: 5,
                            maximumPowerWatts: 100
                        ),
                        connectionActive: false
                    )
                ],
                sampledAt: Date()
            )
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))

        XCTAssertTrue(battery.negotiatedPowerContracts.isEmpty)
    }

    func testSuppressesStalePDContracts() throws {
        let sampledAt = Date(timeIntervalSince1970: 1_000)
        let rawData = BatteryRawData(
            registry: ["CurrentCapacity": 50, "ExternalConnected": true],
            powerSource: ["Power Source State": "AC Power"],
            adapter: nil,
            portPower: PortPowerReading(
                sources: [
                    PortPowerSourceReading(
                        portNumber: 1,
                        kind: .usbPD,
                        advertisedOptions: [
                            PortPowerOption(
                                voltageVolts: 20,
                                maximumCurrentAmps: 5,
                                maximumPowerWatts: 100
                            )
                        ],
                        selectedOption: PortPowerOption(
                            voltageVolts: 20,
                            maximumCurrentAmps: 5,
                            maximumPowerWatts: 100
                        ),
                        connectionActive: true
                    )
                ],
                sampledAt: sampledAt
            ),
            sampledAt: sampledAt.addingTimeInterval(PowerObservationFreshness.live + 1)
        )
        let battery = try XCTUnwrap(BatterySnapshot(rawData: rawData))

        XCTAssertTrue(battery.offeredPowerContracts.isEmpty)
        XCTAssertTrue(battery.negotiatedPowerContracts.isEmpty)
    }
}

private enum TestAdapterErrorFlag {
    static let insufficientPower = 1 << 1
    static let needsRepositioning = 1 << 3
}
