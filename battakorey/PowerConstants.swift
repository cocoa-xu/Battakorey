import Foundation

enum PowerUnitConversion {
    static let milliUnitsPerUnit = 1_000.0
    static let milliVoltMilliAmpPerWatt = 1_000_000.0
}

enum PowerObservationFreshness {
    static let live: TimeInterval = 5
    static let controller: TimeInterval = 10
    static let capability: TimeInterval = 30
}

enum PowerPercentage {
    static let validRange = 0...100
    static let fullScale = 100.0
}
