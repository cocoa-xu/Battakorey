import Foundation

struct BatteryRawData {
    let registry: [String: Any]
    let powerSource: [String: Any]
    let adapter: [String: Any]?
    let smcPower: SMCPowerReading?

    init(
        registry: [String: Any],
        powerSource: [String: Any],
        adapter: [String: Any]?,
        smcPower: SMCPowerReading? = nil
    ) {
        self.registry = registry
        self.powerSource = powerSource
        self.adapter = adapter
        self.smcPower = smcPower
    }
}

struct BatteryCellDetails: Equatable {
    let voltages: [Double]
    let learnedCapacitiesMAh: [Int]
    let resistances: [Int]
    let dailyMinimumCharge: Int?
    let dailyMaximumCharge: Int?
    let cycleCountAtLastRelearn: Int?
    let dataFlashWriteCount: Int?
    let resistanceSenseOpenCount: Int?
    let qmaxDisqualificationReason: Int?

    var voltageDeltaMillivolts: Int? {
        guard voltages.count > 1, let minimum = voltages.min(), let maximum = voltages.max() else {
            return nil
        }
        return Int(((maximum - minimum) * 1_000).rounded())
    }

    var learnedCapacityDeltaMAh: Int? {
        spread(in: learnedCapacitiesMAh)
    }

    var resistanceDelta: Int? {
        spread(in: resistances)
    }

    private func spread(in values: [Int]) -> Int? {
        guard values.count > 1, let minimum = values.min(), let maximum = values.max() else {
            return nil
        }
        return maximum - minimum
    }
}

struct BatteryLifetimeDetails: Equatable {
    let minimumTemperatureCelsius: Double?
    let averageTemperatureCelsius: Double?
    let maximumTemperatureCelsius: Double?
    let minimumPackVoltageVolts: Double?
    let maximumPackVoltageVolts: Double?
    let maximumChargeCurrentAmps: Double?
    let maximumDischargeCurrentAmps: Double?
    let operatingTimeHours: Int?
}

struct BatterySnapshot: Equatable {
    enum PowerSource: Equatable {
        case ac
        case battery
        case ups
        case unknown(String)
    }

    let chargePercentage: Int
    let isCharging: Bool
    let isFullyCharged: Bool
    let isExternallyPowered: Bool
    let powerSource: PowerSource
    let timeRemainingMinutes: Int?
    let currentCapacityMAh: Int?
    let fullChargeCapacityMAh: Int?
    let rawMaximumCapacityMAh: Int?
    let nominalChargeCapacityMAh: Int?
    let designCapacityMAh: Int?
    let cycleCount: Int?
    let designCycleCount: Int?
    let temperatureCelsius: Double?
    let voltageVolts: Double?
    let currentAmps: Double?
    let cellDetails: BatteryCellDetails?
    let lifetimeDetails: BatteryLifetimeDetails?
    let batteryPowerWatts: Double?
    let systemPowerWatts: Double?
    let adapterWatts: Int?
    let adapterVoltageVolts: Double?
    let adapterCurrentAmps: Double?
    let inputVoltageVolts: Double?
    let inputCurrentAmps: Double?
    let inputPowerWatts: Double?
    let optimizedChargingActive: Bool?
    let lowPowerModeActive: Bool?
    let permanentFailureStatus: Int?
    let cellDisconnectCount: Int?
    let notChargingReason: Int?
    let slowChargingReason: Int?

    var capacityRetentionPercentage: Double? {
        guard let fullChargeCapacityMAh, let designCapacityMAh, designCapacityMAh > 0 else {
            return nil
        }
        return Double(fullChargeCapacityMAh) / Double(designCapacityMAh) * 100
    }

    init?(rawData: BatteryRawData) {
        let registry = rawData.registry
        let powerSourceData = rawData.powerSource

        guard let chargePercentage = Self.integer(in: registry, key: "CurrentCapacity")
            ?? Self.integer(in: powerSourceData, key: "Current Capacity") else {
            return nil
        }

        let sourceName = Self.string(in: powerSourceData, key: "Power Source State")
        let externalConnected = Self.boolean(in: registry, key: "ExternalConnected")
            ?? Self.boolean(in: registry, key: "AppleRawExternalConnected")
            ?? (sourceName == "AC Power")
        let isCharging = Self.boolean(in: registry, key: "IsCharging")
            ?? Self.boolean(in: powerSourceData, key: "Is Charging")
            ?? false

        self.chargePercentage = min(max(chargePercentage, 0), 100)
        self.isCharging = isCharging
        self.isFullyCharged = Self.boolean(in: registry, key: "FullyCharged")
            ?? Self.boolean(in: powerSourceData, key: "Is Charged")
            ?? false
        self.isExternallyPowered = externalConnected
        self.powerSource = Self.powerSource(from: sourceName, isExternallyPowered: externalConnected)

        let registryTime = Self.validTime(Self.integer(in: registry, key: "TimeRemaining"))
        let publicTimeKey = isCharging ? "Time to Full Charge" : "Time to Empty"
        self.timeRemainingMinutes = registryTime
            ?? Self.validTime(Self.integer(in: powerSourceData, key: publicTimeKey))

        self.currentCapacityMAh = Self.integer(in: registry, key: "AppleRawCurrentCapacity")
        let rawMaximumCapacityMAh = Self.integer(in: registry, key: "AppleRawMaxCapacity")
        let nominalChargeCapacityMAh = Self.integer(in: registry, key: "NominalChargeCapacity")
        self.fullChargeCapacityMAh = nominalChargeCapacityMAh ?? rawMaximumCapacityMAh
        self.rawMaximumCapacityMAh = rawMaximumCapacityMAh
        self.nominalChargeCapacityMAh = nominalChargeCapacityMAh
        self.designCapacityMAh = Self.integer(in: registry, key: "DesignCapacity")
        self.cycleCount = Self.integer(in: registry, key: "CycleCount")
        self.designCycleCount = Self.integer(in: registry, key: "DesignCycleCount9C")
            ?? Self.integer(in: powerSourceData, key: "DesignCycleCount")

        self.temperatureCelsius = Self.integer(in: registry, key: "Temperature").map { Double($0) / 100 }
        let voltageMillivolts = Self.integer(in: registry, key: "Voltage")
            ?? Self.integer(in: registry, key: "AppleRawBatteryVoltage")
        let voltageVolts = voltageMillivolts.map { Double($0) / 1_000 }
        self.voltageVolts = voltageVolts
        let currentMilliamps = Self.integer(in: registry, key: "InstantAmperage")
            ?? Self.integer(in: registry, key: "Amperage")
            ?? Self.integer(in: powerSourceData, key: "Current")
        let currentAmps = currentMilliamps.map { Double($0) / 1_000 }
        self.currentAmps = currentAmps

        let batteryData = Self.dictionary(in: registry, key: "BatteryData")
        let lifetimeData = Self.dictionary(in: batteryData ?? [:], key: "LifetimeData")
        self.cellDetails = Self.cellDetails(from: batteryData, lifetimeData: lifetimeData)
        self.lifetimeDetails = Self.lifetimeDetails(from: lifetimeData)

        let chargerData = Self.dictionary(in: registry, key: "ChargerData")
        let gaugePower = voltageVolts.flatMap { voltage in
            currentAmps.map { voltage * $0 }
        }
        if isCharging {
            let chargingVoltage = Self.integer(in: chargerData ?? [:], key: "ChargingVoltage")
            let chargingCurrent = Self.integer(in: chargerData ?? [:], key: "ChargingCurrent")
            if let chargingVoltage,
               let chargingCurrent,
               (1...100_000).contains(chargingVoltage),
               (1...100_000).contains(chargingCurrent) {
                self.batteryPowerWatts = Double(chargingVoltage) * Double(chargingCurrent) / 1_000_000
            } else {
                self.batteryPowerWatts = gaugePower.map(abs)
            }
        } else if !externalConnected {
            if let power = rawData.smcPower?.batteryWatts ?? gaugePower.map(abs) {
                self.batteryPowerWatts = -power
            } else {
                self.batteryPowerWatts = nil
            }
        } else {
            self.batteryPowerWatts = 0
        }

        let telemetry = Self.dictionary(in: registry, key: "PowerTelemetryData")
        self.systemPowerWatts = Self.integer(in: telemetry ?? [:], key: "SystemLoad")
            .map { Double($0) / 1_000 }

        let adapter = rawData.adapter ?? Self.dictionary(in: registry, key: "AdapterDetails")
        self.adapterWatts = Self.integer(in: adapter ?? [:], key: "Watts")
        self.adapterVoltageVolts = Self.integer(in: adapter ?? [:], key: "AdapterVoltage")
            .map { Double($0) / 1_000 }
        self.adapterCurrentAmps = Self.integer(in: adapter ?? [:], key: "Current")
            .map { Double($0) / 1_000 }
        self.inputVoltageVolts = rawData.smcPower?.inputVolts
        self.inputCurrentAmps = rawData.smcPower?.inputAmps
        self.inputPowerWatts = rawData.smcPower?.inputWatts

        self.optimizedChargingActive = Self.boolean(
            in: powerSourceData,
            key: "Optimized Battery Charging Engaged"
        )
        self.lowPowerModeActive = Self.boolean(in: powerSourceData, key: "LPM Active")
        self.permanentFailureStatus = Self.nonNegativeInteger(
            in: registry,
            key: "PermanentFailureStatus"
        )
        self.cellDisconnectCount = Self.nonNegativeInteger(
            in: registry,
            key: "BatteryCellDisconnectCount"
        )
        self.notChargingReason = Self.nonNegativeInteger(in: chargerData ?? [:], key: "NotChargingReason")
        self.slowChargingReason = Self.nonNegativeInteger(in: chargerData ?? [:], key: "SlowChargingReason")
    }

    private static func powerSource(from name: String?, isExternallyPowered: Bool) -> PowerSource {
        switch name {
        case "AC Power":
            return .ac
        case "Battery Power":
            return .battery
        case "UPS Power":
            return .ups
        case let name?:
            return .unknown(name)
        case nil:
            return isExternallyPowered ? .ac : .battery
        }
    }

    private static func validTime(_ value: Int?) -> Int? {
        guard let value, value > 0, value < 65_535 else { return nil }
        return value
    }

    private static func integer(in dictionary: [String: Any], key: String) -> Int? {
        (dictionary[key] as? NSNumber)?.intValue
    }

    private static func boolean(in dictionary: [String: Any], key: String) -> Bool? {
        (dictionary[key] as? NSNumber)?.boolValue
    }

    private static func string(in dictionary: [String: Any], key: String) -> String? {
        dictionary[key] as? String
    }

    private static func dictionary(in dictionary: [String: Any], key: String) -> [String: Any]? {
        dictionary[key] as? [String: Any]
    }

    private static func integerArray(in dictionary: [String: Any], key: String) -> [Int] {
        guard let values = dictionary[key] as? [Any] else { return [] }
        var result: [Int] = []
        for value in values {
            guard let number = value as? NSNumber else { return [] }
            result.append(number.intValue)
        }
        return result
    }

    private static func integerArray(
        in dictionary: [String: Any],
        key: String,
        range: ClosedRange<Int>
    ) -> [Int] {
        let values = integerArray(in: dictionary, key: key)
        return values.allSatisfy(range.contains) ? values : []
    }

    private static func cellDetails(
        from data: [String: Any]?,
        lifetimeData: [String: Any]?
    ) -> BatteryCellDetails? {
        guard let data else { return nil }
        let voltages = integerArray(in: data, key: "CellVoltage", range: 0...10_000)
            .map { Double($0) / 1_000 }
        let learnedCapacities = integerArray(in: data, key: "Qmax", range: 0...100_000)
        let resistances = integerArray(in: data, key: "WeightedRa", range: 0...1_000_000)
        let minimumCharge = percentage(in: data, key: "DailyMinSoc")
        let maximumCharge = percentage(in: data, key: "DailyMaxSoc")
        let lastRelearn = positiveInteger(in: data, key: "CycleCountLastQmax")
            ?? positiveInteger(in: lifetimeData ?? [:], key: "CycleCountLastQmax")
        let dataFlashWriteCount = nonNegativeInteger(in: data, key: "DataFlashWriteCount")
        let resistanceSenseOpenCount = nonNegativeInteger(in: data, key: "BatteryRsenseOpenCount")
        let qmaxDisqualificationReason = nonNegativeInteger(in: data, key: "QmaxDisqualificationReason")

        guard !voltages.isEmpty
            || !learnedCapacities.isEmpty
            || !resistances.isEmpty
            || minimumCharge != nil
            || maximumCharge != nil
            || lastRelearn != nil
            || dataFlashWriteCount != nil
            || resistanceSenseOpenCount != nil
            || qmaxDisqualificationReason != nil else {
            return nil
        }
        return BatteryCellDetails(
            voltages: voltages,
            learnedCapacitiesMAh: learnedCapacities,
            resistances: resistances,
            dailyMinimumCharge: minimumCharge,
            dailyMaximumCharge: maximumCharge,
            cycleCountAtLastRelearn: lastRelearn,
            dataFlashWriteCount: dataFlashWriteCount,
            resistanceSenseOpenCount: resistanceSenseOpenCount,
            qmaxDisqualificationReason: qmaxDisqualificationReason
        )
    }

    private static func lifetimeDetails(from data: [String: Any]?) -> BatteryLifetimeDetails? {
        guard let data else { return nil }
        let minimumTemperature = plausibleDouble(in: data, key: "MinimumTemperature", range: -50...100)
        let maximumTemperature = plausibleDouble(in: data, key: "MaximumTemperature", range: -50...100)
        let averageTemperature = averageTemperature(
            integer(in: data, key: "AverageTemperature"),
            minimum: minimumTemperature,
            maximum: maximumTemperature
        )
        let minimumVoltage = plausibleDouble(in: data, key: "MinimumPackVoltage", range: 1_000...100_000)
            .map { $0 / 1_000 }
        let maximumVoltage = plausibleDouble(in: data, key: "MaximumPackVoltage", range: 1_000...100_000)
            .map { $0 / 1_000 }
        let maximumChargeCurrent = plausibleCurrent(in: data, key: "MaximumChargeCurrent")
        let maximumDischargeCurrent = plausibleCurrent(in: data, key: "MaximumDischargeCurrent")
        let operatingTime = positiveInteger(in: data, key: "TotalOperatingTime")

        guard minimumTemperature != nil
            || averageTemperature != nil
            || maximumTemperature != nil
            || minimumVoltage != nil
            || maximumVoltage != nil
            || maximumChargeCurrent != nil
            || maximumDischargeCurrent != nil
            || operatingTime != nil else {
            return nil
        }
        return BatteryLifetimeDetails(
            minimumTemperatureCelsius: minimumTemperature,
            averageTemperatureCelsius: averageTemperature,
            maximumTemperatureCelsius: maximumTemperature,
            minimumPackVoltageVolts: minimumVoltage,
            maximumPackVoltageVolts: maximumVoltage,
            maximumChargeCurrentAmps: maximumChargeCurrent,
            maximumDischargeCurrentAmps: maximumDischargeCurrent,
            operatingTimeHours: operatingTime
        )
    }

    private static func percentage(in dictionary: [String: Any], key: String) -> Int? {
        guard let value = integer(in: dictionary, key: key), (0...100).contains(value) else {
            return nil
        }
        return value
    }

    private static func positiveInteger(in dictionary: [String: Any], key: String) -> Int? {
        guard let value = integer(in: dictionary, key: key), value > 0 else { return nil }
        return value
    }

    private static func nonNegativeInteger(in dictionary: [String: Any], key: String) -> Int? {
        guard let value = integer(in: dictionary, key: key), value >= 0 else { return nil }
        return value
    }

    private static func plausibleDouble(
        in dictionary: [String: Any],
        key: String,
        range: ClosedRange<Double>
    ) -> Double? {
        guard let value = dictionary[key] as? NSNumber else { return nil }
        let doubleValue = value.doubleValue
        return range.contains(doubleValue) ? doubleValue : nil
    }

    private static func plausibleCurrent(in dictionary: [String: Any], key: String) -> Double? {
        guard let value = integer(in: dictionary, key: key) else { return nil }
        let magnitude = value.magnitude
        guard (1..<100_000).contains(magnitude) else { return nil }
        return Double(magnitude) / 1_000
    }

    private static func averageTemperature(
        _ rawValue: Int?,
        minimum: Double?,
        maximum: Double?
    ) -> Double? {
        guard let rawValue, let minimum, let maximum else { return nil }
        let candidates = [Double(rawValue), Double(rawValue) / 10]
            .filter { $0 >= minimum && $0 <= maximum }
        return candidates.count == 1 ? candidates[0] : nil
    }
}
