import Foundation
import IOKit
import IOKit.ps

protocol BatteryInfoProviding {
    func snapshot() -> BatterySnapshot?
}

final class IOKitBatteryInfoProvider: BatteryInfoProviding {
    private let smcPowerReader = SMCPowerReader()
    private let registryKeys = [
        "CurrentCapacity",
        "ExternalConnected",
        "AppleRawExternalConnected",
        "IsCharging",
        "FullyCharged",
        "TimeRemaining",
        "AppleRawCurrentCapacity",
        "AppleRawMaxCapacity",
        "NominalChargeCapacity",
        "DesignCapacity",
        "CycleCount",
        "DesignCycleCount9C",
        "Temperature",
        "Voltage",
        "AppleRawBatteryVoltage",
        "InstantAmperage",
        "Amperage",
        "BatteryData",
        "ChargerData",
        "PowerTelemetryData",
        "AdapterDetails",
        "PermanentFailureStatus",
        "BatteryCellDisconnectCount"
    ]

    func snapshot() -> BatterySnapshot? {
        guard let registry = registryProperties() else { return nil }
        let rawData = BatteryRawData(
            registry: registry,
            powerSource: powerSourceDescription() ?? [:],
            adapter: externalPowerAdapterDetails(),
            smcPower: smcPowerReader.read()
        )
        return BatterySnapshot(rawData: rawData)
    }

    private func registryProperties() -> [String: Any]? {
        guard let matching = IOServiceMatching("AppleSmartBattery") else { return nil }
        let service = IOServiceGetMatchingService(mach_port_t(MACH_PORT_NULL), matching)
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        var properties: [String: Any] = [:]
        for key in registryKeys {
            guard let value = IORegistryEntryCreateCFProperty(
                service,
                key as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() else {
                continue
            }
            properties[key] = value
        }
        return properties.isEmpty ? nil : properties
    }

    private func powerSourceDescription() -> [String: Any]? {
        let blob = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(blob).takeRetainedValue() as [AnyObject]

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue()
                as? [String: Any] else {
                continue
            }
            if description["Type"] as? String == "InternalBattery" {
                return description
            }
        }
        return nil
    }

    private func externalPowerAdapterDetails() -> [String: Any]? {
        IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any]
    }
}
