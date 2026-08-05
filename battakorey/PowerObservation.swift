import Foundation

enum ElectricalObservationKind: Equatable {
    case rated
    case contracted
    case measured
    case estimated
    case accumulated
    case state
}

enum ElectricalDomain: Equatable {
    case adapter
    case input
    case battery
    case system
    case component
    case port
    case accessory
}

enum ElectricalUnit: Equatable {
    case watts
    case volts
    case amperes
    case celsius
    case percent
}

enum ElectricalDirection: Equatable {
    case input
    case charge
    case discharge
    case output
}

enum ElectricalObservationSource: Equatable {
    case powerSources
    case batteryRegistry
    case batteryController
    case smc
    case ioReport
    case systemInformation
    case portRegistry
}

enum ObservationStability: Equatable {
    case publicAPI
    case undocumentedSchema
    case privateABI
}

enum ObservationAccessTier: Equatable {
    case base
    case enhanced
}

enum ObservationConfidence: Equatable {
    case high
    case medium
    case low
}

struct ElectricalObservation: Equatable {
    let value: Double
    let unit: ElectricalUnit
    let kind: ElectricalObservationKind
    let domain: ElectricalDomain
    let direction: ElectricalDirection?
    let source: ElectricalObservationSource
    let sampledAt: Date
    let measurementWindow: TimeInterval?
    let freshnessLimit: TimeInterval
    let stability: ObservationStability
    let accessTier: ObservationAccessTier
    let confidence: ObservationConfidence

    func isFresh(at date: Date = Date()) -> Bool {
        let age = date.timeIntervalSince(sampledAt)
        return age >= 0 && age <= freshnessLimit
    }
}

struct PowerContract: Equatable {
    let portNumber: Int?
    let voltageVolts: Double
    let currentAmps: Double?
    let maximumPowerWatts: Double?
    let kind: ElectricalObservationKind
    let direction: ElectricalDirection
    let source: ElectricalObservationSource
    let sampledAt: Date
    let freshnessLimit: TimeInterval
    let stability: ObservationStability
    let accessTier: ObservationAccessTier
    let confidence: ObservationConfidence

    func isFresh(at date: Date = Date()) -> Bool {
        let age = date.timeIntervalSince(sampledAt)
        return age >= 0 && age <= freshnessLimit
    }
}
