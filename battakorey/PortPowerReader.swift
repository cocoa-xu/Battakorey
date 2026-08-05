import Foundation
import IOKit

struct PortPowerOption: Equatable {
    let voltageVolts: Double
    let maximumCurrentAmps: Double?
    let maximumPowerWatts: Double?
}

enum PortPowerSourceKind: Equatable {
    case usbPD
    case usbTypeC
    case brickIdentity
    case unknown(String)
}

struct PortPowerSourceReading: Equatable {
    let portNumber: Int
    let kind: PortPowerSourceKind
    let advertisedOptions: [PortPowerOption]
    let selectedOption: PortPowerOption?
    let connectionActive: Bool?
}

struct PortPowerReading: Equatable {
    let sources: [PortPowerSourceReading]
    let sampledAt: Date
}

enum PortPowerDecoder {
    static func option(from value: Any?) -> PortPowerOption? {
        guard let values = value as? [String: Any],
              let voltage = positiveInteger(values["Voltage (mV)"]) else {
            return nil
        }
        let current = positiveInteger(values["Max Current (mA)"])
        let reportedPower = positiveInteger(values["Max Power (mW)"])
        let power = reportedPower ?? current.map {
            voltage * $0 / PortPowerUnit.milliVoltMilliAmpPerMilliwatt
        }
        return PortPowerOption(
            voltageVolts: Double(voltage) / PowerUnitConversion.milliUnitsPerUnit,
            maximumCurrentAmps: current.map {
                Double($0) / PowerUnitConversion.milliUnitsPerUnit
            },
            maximumPowerWatts: power.map {
                Double($0) / PowerUnitConversion.milliUnitsPerUnit
            }
        )
    }

    static func options(from value: Any?) -> [PortPowerOption] {
        let values: [Any]
        if let array = value as? [Any] {
            values = array
        } else if let set = value as? NSSet {
            values = set.allObjects
        } else {
            values = []
        }
        return values.compactMap(option).sorted {
            ($0.maximumPowerWatts ?? 0, $0.voltageVolts)
                > ($1.maximumPowerWatts ?? 0, $1.voltageVolts)
        }
    }

    static func kind(from name: String?) -> PortPowerSourceKind {
        switch name {
        case "USB-PD": return .usbPD
        case "TypeC": return .usbTypeC
        case "Brick ID": return .brickIdentity
        case let name?: return .unknown(name)
        case nil: return .unknown("")
        }
    }

    private static func positiveInteger(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber, number.intValue > 0 else { return nil }
        return number.intValue
    }
}

final class PortPowerReader {
    private let portClasses = [
        "AppleHPMInterfaceType10",
        "AppleHPMInterfaceType11",
        "AppleHPMInterfaceType12",
        "AppleHPMInterfaceType18",
        "AppleTCControllerType10",
        "AppleTCControllerType11",
        "IOPort"
    ]

    func read(at date: Date = Date()) -> PortPowerReading? {
        let connections = portConnections()
        var sources: [PortPowerSourceReading] = []
        enumerate("IOPortFeaturePowerSource") { service in
            guard isUSBTypeC(service), let portNumber = portNumber(service) else { return }
            let source = PortPowerSourceReading(
                portNumber: portNumber,
                kind: PortPowerDecoder.kind(from: property("PowerSourceName", of: service) as? String),
                advertisedOptions: PortPowerDecoder.options(
                    from: property("PowerSourceOptions", of: service)
                ),
                selectedOption: PortPowerDecoder.option(
                    from: property("WinningPowerSourceOption", of: service)
                ),
                connectionActive: connections[portNumber]
            )
            if !source.advertisedOptions.isEmpty || source.selectedOption != nil {
                sources.append(source)
            }
        }
        guard !sources.isEmpty else { return nil }
        sources.sort {
            ($0.portNumber, sortOrder($0.kind)) < ($1.portNumber, sortOrder($1.kind))
        }
        return PortPowerReading(sources: sources, sampledAt: date)
    }

    private func portConnections() -> [Int: Bool] {
        var connections: [Int: Bool] = [:]
        for className in portClasses {
            enumerate(className) { service in
                guard isUSBTypeC(service), let number = portNumber(service),
                      let active = (property("ConnectionActive", of: service) as? NSNumber)?.boolValue else {
                    return
                }
                connections[number] = (connections[number] ?? false) || active
            }
        }
        return connections
    }

    private func isUSBTypeC(_ service: io_service_t) -> Bool {
        let type = integer("ParentBuiltInPortType", of: service)
            ?? integer("ParentPortType", of: service)
        if let type { return type == PortRegistryValue.usbTypeC }
        let description = property("ParentBuiltInPortTypeDescription", of: service) as? String
            ?? property("ParentPortTypeDescription", of: service) as? String
            ?? property("PortTypeDescription", of: service) as? String
        return description == "USB-C"
    }

    private func portNumber(_ service: io_service_t) -> Int? {
        let value = integer("ParentBuiltInPortNumber", of: service)
            ?? integer("ParentPortNumber", of: service)
            ?? integer("PortNumber", of: service)
        guard let value, value > 0 else { return nil }
        return value
    }

    private func integer(_ key: String, of service: io_service_t) -> Int? {
        (property(key, of: service) as? NSNumber)?.intValue
    }

    private func property(_ key: String, of service: io_service_t) -> Any? {
        IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            IORegistryReadOption.none
        )?.takeRetainedValue()
    }

    private func enumerate(_ className: String, body: (io_service_t) -> Void) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching(className),
            &iterator
        ) == kIOReturnSuccess else {
            return
        }
        defer { IOObjectRelease(iterator) }

        while true {
            let service = IOIteratorNext(iterator)
            guard service != IO_OBJECT_NULL else { break }
            body(service)
            IOObjectRelease(service)
        }
    }

    private func sortOrder(_ kind: PortPowerSourceKind) -> Int {
        switch kind {
        case .usbPD: return 0
        case .usbTypeC: return 1
        case .brickIdentity: return 2
        case .unknown: return 3
        }
    }
}

private enum PortPowerUnit {
    static let milliVoltMilliAmpPerMilliwatt = 1_000
}

private enum PortRegistryValue {
    static let usbTypeC = 2
}

private enum IORegistryReadOption {
    static let none: IOOptionBits = 0
}
