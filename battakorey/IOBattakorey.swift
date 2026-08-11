import Foundation
import IOKit
import IOKit.ps

protocol BatteryInfoProviding: AnyObject {
    func snapshot() -> BatterySnapshot?
    func powerSourceDidChange()
}

extension BatteryInfoProviding {
    func powerSourceDidChange() {}
}

final class IOKitBatteryInfoProvider: BatteryInfoProviding {
    private let smcPowerReader = SMCPowerReader()
    private let ioReportPowerReader = IOReportPowerReader()
    private let systemHealthReader = SystemBatteryHealthReader()
    private let portPowerReader = PortPowerReader()
    private let powerConditionReader = PowerConditionReader()
    private let hardwareProfileReader = HardwareProfileReader()
    private var cachedSlowRegistry: [String: Any] = [:]
    private var slowRegistryReadAt: TimeInterval?
    private var cachedDiagnosticRegistry: [String: Any] = [:]
    private var diagnosticRegistryReadAt: TimeInterval?
    private var cachedPortPower: PortPowerReading?
    private var portPowerReadAt: TimeInterval?

    private let liveRegistryKeys = [
        "CurrentCapacity",
        "BatteryInstalled",
        "ExternalConnected",
        "AppleRawExternalConnected",
        "IsCharging",
        "FullyCharged",
        "TimeRemaining",
        "AppleRawCurrentCapacity",
        "Temperature",
        "Voltage",
        "AppleRawBatteryVoltage",
        "InstantAmperage",
        "Amperage",
        "ChargerData",
        "PowerTelemetryData",
        "AdapterDetails",
        "ChargeStatus"
    ]

    private let slowRegistryKeys = [
        "AppleRawMaxCapacity",
        "NominalChargeCapacity",
        "DesignCapacity",
        "CycleCount",
        "DesignCycleCount9C",
        "PermanentFailureStatus",
        "BatteryCellDisconnectCount"
    ]

    private let diagnosticRegistryKeys = [
        "BatteryData"
    ]

    func snapshot() -> BatterySnapshot? {
        let date = Date()
        let uptime = ProcessInfo.processInfo.systemUptime
        let registry = registryProperties(at: uptime) ?? [:]
        let powerSource = powerSourceDescription()
        let hasBattery = (registry["BatteryInstalled"] as? NSNumber)?.boolValue == true
            || powerSource != nil
        let rawData = BatteryRawData(
            registry: registry,
            powerSource: powerSource ?? [:],
            adapter: externalPowerAdapterDetails(),
            hasBattery: hasBattery,
            hardwareProfile: hardwareProfileReader.profile(),
            smcPower: smcPowerReader.read(at: date),
            ioReportPower: ioReportPowerReader?.read(),
            systemHealth: systemHealthReader.read(at: date),
            portPower: portPower(at: date, uptime: uptime),
            powerCondition: powerConditionReader.read(at: date),
            sampledAt: date
        )
        return BatterySnapshot(rawData: rawData)
    }

    func powerSourceDidChange() {
        portPowerReadAt = nil
    }

    private func registryProperties(at uptime: TimeInterval) -> [String: Any]? {
        guard let matching = IOServiceMatching("AppleSmartBattery") else { return nil }
        let service = IOServiceGetMatchingService(mach_port_t(MACH_PORT_NULL), matching)
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        var properties = readProperties(liveRegistryKeys, from: service)
        if slowRegistryReadAt.map({ uptime - $0 >= BatteryProviderPolicy.slowRegistryInterval })
            ?? true {
            cachedSlowRegistry = readProperties(slowRegistryKeys, from: service)
            slowRegistryReadAt = uptime
        }
        if diagnosticRegistryReadAt.map({
            uptime - $0 >= BatteryProviderPolicy.diagnosticRegistryInterval
        }) ?? true {
            cachedDiagnosticRegistry = readProperties(diagnosticRegistryKeys, from: service)
            diagnosticRegistryReadAt = uptime
        }
        properties.merge(cachedSlowRegistry) { live, _ in live }
        properties.merge(cachedDiagnosticRegistry) { live, _ in live }
        return properties.isEmpty ? nil : properties
    }

    private func readProperties(_ keys: [String], from service: io_service_t) -> [String: Any] {
        var properties: [String: Any] = [:]
        for key in keys {
            guard let value = IORegistryEntryCreateCFProperty(
                service,
                key as CFString,
                kCFAllocatorDefault,
                BatteryRegistryReadOption.none
            )?.takeRetainedValue() else {
                continue
            }
            properties[key] = value
        }
        return properties
    }

    private func portPower(at date: Date, uptime: TimeInterval) -> PortPowerReading? {
        if portPowerReadAt.map({ uptime - $0 >= BatteryProviderPolicy.portPowerInterval }) ?? true {
            cachedPortPower = portPowerReader.read(at: date)
            portPowerReadAt = uptime
        }
        return cachedPortPower
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

private enum BatteryProviderPolicy {
    static let diagnosticRegistryInterval: TimeInterval = 10
    static let slowRegistryInterval: TimeInterval = 60
    static let portPowerInterval: TimeInterval = 5
}

private enum BatteryRegistryReadOption {
    static let none: IOOptionBits = 0
}
