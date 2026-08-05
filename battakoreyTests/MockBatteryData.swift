import Foundation
@testable import battakorey

enum MockBatteryData {
    static var discharging: BatteryRawData {
        let sampledAt = Date(timeIntervalSince1970: 1_000)
        return BatteryRawData(
            registry: [
                "CurrentCapacity": 64,
                "IsCharging": false,
                "FullyCharged": false,
                "ExternalConnected": false,
                "TimeRemaining": 125,
                "AppleRawCurrentCapacity": 4_800,
                "AppleRawMaxCapacity": 6_400,
                "NominalChargeCapacity": 6_550,
                "DesignCapacity": 8_000,
                "CycleCount": 250,
                "DesignCycleCount9C": 1_000,
                "Temperature": 3_125,
                "Voltage": 11_840,
                "InstantAmperage": -2_150,
                "BatteryData": [
                    "CellVoltage": [3_950, 3_947, 3_952],
                    "Qmax": [7_900, 7_850, 7_920],
                    "WeightedRa": [45, 50, 47],
                    "DailyMinSoc": 18,
                    "DailyMaxSoc": 91,
                    "DataFlashWriteCount": 320,
                    "BatteryRsenseOpenCount": 2,
                    "QmaxDisqualificationReason": 0,
                    "LifetimeData": [
                        "CycleCountLastQmax": 240,
                        "MinimumTemperature": 10,
                        "AverageTemperature": 287,
                        "MaximumTemperature": 45,
                        "MinimumPackVoltage": 10_500,
                        "MaximumPackVoltage": 13_000,
                        "MaximumChargeCurrent": 6_000,
                        "MaximumDischargeCurrent": -9_500,
                        "TotalOperatingTime": 12_345
                    ]
                ],
                "PowerTelemetryData": [
                    "SystemLoad": 25_456
                ],
                "ChargerData": [
                    "NotChargingReason": 4_194_305,
                    "SlowChargingReason": 0
                ],
                "PermanentFailureStatus": 0,
                "BatteryCellDisconnectCount": 0
            ],
            powerSource: [
                "Power Source State": "Battery Power",
                "Current Capacity": 64,
                "Is Charging": false,
                "LPM Active": true,
                "Optimized Battery Charging Engaged": false
            ],
            adapter: nil,
            smcPower: SMCPowerReading(
                batteryWatts: 30.25,
                inputVolts: nil,
                inputAmps: nil,
                inputWatts: nil
            ),
            ioReportPower: IOReportPowerReading(
                cpuWatts: 4.25,
                gpuWatts: 1.5,
                aneWatts: 0,
                memoryWatts: 0.85,
                gpuMemoryWatts: 0.12,
                displayWatts: 0.7,
                externalDisplayWatts: 1.1,
                sampledAt: sampledAt,
                measurementWindow: 1
            ),
            sampledAt: sampledAt
        )
    }

    static var charging: BatteryRawData {
        let sampledAt = Date(timeIntervalSince1970: 1_000)
        return BatteryRawData(
            registry: [
                "CurrentCapacity": 72,
                "IsCharging": true,
                "ExternalConnected": true,
                "TimeRemaining": 65_535,
                "AppleRawCurrentCapacity": 5_760,
                "AppleRawMaxCapacity": 7_600,
                "DesignCapacity": 8_000,
                "CycleCount": 100,
                "Temperature": 2_980,
                "Voltage": 12_200,
                "Amperage": 3_000,
                "ChargerData": [
                    "ChargingVoltage": 12_200,
                    "ChargingCurrent": 3_000
                ]
            ],
            powerSource: [
                "Power Source State": "AC Power",
                "Is Charging": true,
                "Time to Full Charge": 48
            ],
            adapter: [
                "Watts": 96,
                "AdapterVoltage": 20_000,
                "Current": 4_800
            ],
            smcPower: SMCPowerReading(
                batteryWatts: nil,
                inputVolts: 20.1,
                inputAmps: 3.5,
                inputWatts: 70.35
            ),
            systemHealth: SystemBatteryHealthReading(
                condition: "Good",
                maximumCapacityPercentage: 82,
                sampledAt: sampledAt
            ),
            portPower: PortPowerReading(
                sources: [
                    PortPowerSourceReading(
                        portNumber: 2,
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
                            maximumCurrentAmps: 4.5,
                            maximumPowerWatts: 90
                        ),
                        connectionActive: true
                    )
                ],
                sampledAt: sampledAt
            ),
            sampledAt: sampledAt
        )
    }
}
