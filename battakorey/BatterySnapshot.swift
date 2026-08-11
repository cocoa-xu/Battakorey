import Foundation

struct BatteryRawData {
    let registry: [String: Any]
    let powerSource: [String: Any]
    let adapter: [String: Any]?
    let hasBattery: Bool
    let batteryIsExpected: Bool
    let smcPower: SMCPowerReading?
    let ioReportPower: IOReportPowerReading?
    let systemHealth: SystemBatteryHealthReading?
    let portPower: PortPowerReading?
    let powerCondition: PowerConditionReading?
    let sampledAt: Date

    init(
        registry: [String: Any],
        powerSource: [String: Any],
        adapter: [String: Any]?,
        hasBattery: Bool = true,
        batteryIsExpected: Bool = false,
        smcPower: SMCPowerReading? = nil,
        ioReportPower: IOReportPowerReading? = nil,
        systemHealth: SystemBatteryHealthReading? = nil,
        portPower: PortPowerReading? = nil,
        powerCondition: PowerConditionReading? = nil,
        sampledAt: Date = Date()
    ) {
        self.registry = registry
        self.powerSource = powerSource
        self.adapter = adapter
        self.hasBattery = hasBattery
        self.batteryIsExpected = batteryIsExpected
        self.smcPower = smcPower
        self.ioReportPower = ioReportPower
        self.systemHealth = systemHealth
        self.portPower = portPower
        self.powerCondition = powerCondition
        self.sampledAt = sampledAt
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
        guard voltages.count >= BatteryCellPolicy.minimumComparableValueCount,
              let minimum = voltages.min(),
              let maximum = voltages.max() else {
            return nil
        }
        return Int(((maximum - minimum) * PowerUnitConversion.milliUnitsPerUnit).rounded())
    }

    var learnedCapacityDeltaMAh: Int? {
        spread(in: learnedCapacitiesMAh)
    }

    var resistanceDelta: Int? {
        spread(in: resistances)
    }

    private func spread(in values: [Int]) -> Int? {
        guard values.count >= BatteryCellPolicy.minimumComparableValueCount,
              let minimum = values.min(),
              let maximum = values.max() else {
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

enum ChargeInterruption: Equatable {
    case highTemperature
    case lowTemperature
    case highOrLowTemperature
    case temperatureGradient
    case unknown(String)
}

enum AdapterError: Equatable {
    case insufficientAvailablePower
    case foreignObjectDetected
    case needsRepositioning
    case unknown(Int)
}

struct BatterySnapshot: Equatable {
    enum PowerSource: Equatable {
        case ac
        case battery
        case ups
        case unknown(String)
    }

    let hasBattery: Bool
    let batteryIsExpected: Bool
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
    let batteryTemperature: ElectricalObservation?
    let voltageVolts: Double?
    let currentAmps: Double?
    let cellDetails: BatteryCellDetails?
    let lifetimeDetails: BatteryLifetimeDetails?
    let batteryFlow: ElectricalObservation?
    let chargingTargetPower: ElectricalObservation?
    let controllerSystemLoad: ElectricalObservation?
    let adapterRating: ElectricalObservation?
    let adapterCapability: PowerContract?
    let inputVoltage: ElectricalObservation?
    let inputCurrent: ElectricalObservation?
    let liveInputPower: ElectricalObservation?
    let offeredPowerContracts: [PowerContract]
    let negotiatedPowerContracts: [PowerContract]
    let ioReportPower: IOReportPowerReading?
    let officialCondition: String?
    let officialMaximumCapacityPercentage: Int?
    let publicHealthHint: String?
    let publicHealthCondition: String?
    let publicHealthConfidence: String?
    let batteryFailureModes: [String]
    let capacityIsEstimated: Bool?
    let chargeInterruption: ChargeInterruption?
    let adapterErrors: [AdapterError]
    let powerCondition: PowerConditionReading?
    let optimizedChargingActive: Bool?
    let lowPowerModeActive: Bool?
    let permanentFailureStatus: Int?
    let cellDisconnectCount: Int?
    let notChargingReason: Int?
    let slowChargingReason: Int?

    var rawCapacityRatioPercentage: Double? {
        guard let fullChargeCapacityMAh, let designCapacityMAh, designCapacityMAh > 0 else {
            return nil
        }
        return Double(fullChargeCapacityMAh) / Double(designCapacityMAh)
            * PowerPercentage.fullScale
    }

    var temperatureCelsius: Double? {
        batteryTemperature?.value
    }

    var shouldWarnAboutMissingBattery: Bool {
        batteryIsExpected && !hasBattery
    }

    var statusBarChargePercentage: Int {
        hasBattery ? chargePercentage : PowerPercentage.validRange.upperBound
    }

    init?(rawData: BatteryRawData) {
        let registry = rawData.registry
        let powerSourceData = rawData.powerSource

        let reportedChargePercentage = Self.integer(in: registry, key: "CurrentCapacity")
            ?? Self.integer(in: powerSourceData, key: "Current Capacity")
        if rawData.hasBattery, reportedChargePercentage == nil {
            return nil
        }

        let sourceName = Self.string(in: powerSourceData, key: "Power Source State")
        let reportedExternalConnected = Self.boolean(in: registry, key: "ExternalConnected")
            ?? Self.boolean(in: registry, key: "AppleRawExternalConnected")
            ?? (sourceName == "AC Power")
        let externalConnected = rawData.hasBattery ? reportedExternalConnected : true
        let isCharging = Self.boolean(in: registry, key: "IsCharging")
            ?? Self.boolean(in: powerSourceData, key: "Is Charging")
            ?? false

        self.hasBattery = rawData.hasBattery
        self.batteryIsExpected = rawData.batteryIsExpected
        self.chargePercentage = min(
            max(reportedChargePercentage ?? 0, PowerPercentage.validRange.lowerBound),
            PowerPercentage.validRange.upperBound
        )
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

        let registryTemperature = Self.scaledInteger(
            in: registry,
            key: "Temperature",
            divisor: BatteryRegistryScale.temperatureHundredthsPerCelsius,
            range: BatteryValueLimits.temperatureCelsius
        )
        if let temperature = rawData.smcPower?.batteryTemperatureCelsius {
            self.batteryTemperature = Self.observation(
                temperature,
                unit: .celsius,
                kind: .measured,
                domain: .battery,
                source: .smc,
                sampledAt: rawData.smcPower?.sampledAt ?? rawData.sampledAt,
                freshnessLimit: PowerObservationFreshness.live,
                stability: .privateABI,
                accessTier: .enhanced,
                confidence: .medium
            )
        } else if let registryTemperature {
            self.batteryTemperature = Self.observation(
                registryTemperature,
                unit: .celsius,
                kind: .measured,
                domain: .battery,
                source: .batteryRegistry,
                sampledAt: rawData.sampledAt,
                freshnessLimit: PowerObservationFreshness.controller,
                stability: .undocumentedSchema,
                confidence: .medium
            )
        } else {
            self.batteryTemperature = nil
        }
        let voltageMillivolts = Self.integer(in: registry, key: "Voltage")
            ?? Self.integer(in: registry, key: "AppleRawBatteryVoltage")
        let voltageVolts = voltageMillivolts.map {
            Double($0) / PowerUnitConversion.milliUnitsPerUnit
        }
        self.voltageVolts = voltageVolts
        let currentMilliamps = Self.integer(in: registry, key: "InstantAmperage")
            ?? Self.integer(in: registry, key: "Amperage")
            ?? Self.integer(in: powerSourceData, key: "Current")
        let currentAmps = currentMilliamps.map {
            Double($0) / PowerUnitConversion.milliUnitsPerUnit
        }
        self.currentAmps = currentAmps

        let batteryData = Self.dictionary(in: registry, key: "BatteryData")
        let lifetimeData = Self.dictionary(in: batteryData ?? [:], key: "LifetimeData")
        self.cellDetails = Self.cellDetails(from: batteryData, lifetimeData: lifetimeData)
        self.lifetimeDetails = Self.lifetimeDetails(from: lifetimeData)

        let chargerData = Self.dictionary(in: registry, key: "ChargerData")
        let gaugePower = Self.product(
            voltageVolts,
            currentAmps,
            range: BatteryValueLimits.batteryPowerWatts
        )
        self.batteryFlow = Self.batteryFlow(
            smc: rawData.smcPower,
            gaugePower: gaugePower,
            currentAmps: currentAmps,
            isCharging: isCharging,
            isExternallyPowered: externalConnected,
            sampledAt: rawData.sampledAt
        )

        let chargingVoltage = Self.integer(
            in: chargerData ?? [:],
            key: "ChargingVoltage",
            range: BatteryValueLimits.chargingVoltageMillivolts
        )
        let chargingCurrent = Self.integer(
            in: chargerData ?? [:],
            key: "ChargingCurrent",
            range: BatteryValueLimits.chargingCurrentMilliamps
        )
        if let chargingVoltage, let chargingCurrent {
            self.chargingTargetPower = Self.observation(
                Double(chargingVoltage) * Double(chargingCurrent)
                    / PowerUnitConversion.milliVoltMilliAmpPerWatt,
                unit: .watts,
                kind: .estimated,
                domain: .battery,
                direction: .charge,
                source: .batteryController,
                sampledAt: rawData.sampledAt,
                freshnessLimit: PowerObservationFreshness.live,
                stability: .undocumentedSchema,
                confidence: .low
            )
        } else {
            self.chargingTargetPower = nil
        }

        let telemetry = Self.dictionary(in: registry, key: "PowerTelemetryData")
        if let systemLoad = Self.integer(in: telemetry ?? [:], key: "SystemLoad"),
           BatteryValueLimits.controllerSystemLoadMilliwatts.contains(systemLoad) {
            self.controllerSystemLoad = Self.observation(
                Double(systemLoad) / PowerUnitConversion.milliUnitsPerUnit,
                unit: .watts,
                kind: .estimated,
                domain: .system,
                source: .batteryController,
                sampledAt: rawData.sampledAt,
                freshnessLimit: PowerObservationFreshness.controller,
                stability: .undocumentedSchema,
                confidence: .low
            )
        } else {
            self.controllerSystemLoad = nil
        }

        let adapter = rawData.adapter ?? Self.dictionary(in: registry, key: "AdapterDetails")
        let adapterWatts = Self.integer(
            in: adapter ?? [:],
            key: "Watts",
            range: BatteryValueLimits.adapterWatts
        )
        self.adapterRating = adapterWatts.map {
            Self.observation(
                Double($0),
                unit: .watts,
                kind: .rated,
                domain: .adapter,
                direction: .input,
                source: .powerSources,
                sampledAt: rawData.sampledAt,
                freshnessLimit: PowerObservationFreshness.capability,
                stability: .publicAPI,
                confidence: .high
            )
        }
        let adapterVoltage = Self.scaledInteger(
            in: adapter ?? [:],
            key: "AdapterVoltage",
            divisor: PowerUnitConversion.milliUnitsPerUnit,
            rawRange: BatteryValueLimits.adapterVoltageMillivolts
        )
        let adapterCurrent = Self.scaledInteger(
            in: adapter ?? [:],
            key: "Current",
            divisor: PowerUnitConversion.milliUnitsPerUnit,
            rawRange: BatteryValueLimits.adapterCurrentMilliamps
        )
        if let adapterVoltage {
            self.adapterCapability = PowerContract(
                portNumber: nil,
                voltageVolts: adapterVoltage,
                currentAmps: adapterCurrent,
                maximumPowerWatts: adapterWatts.map(Double.init)
                    ?? adapterCurrent.map { adapterVoltage * $0 },
                kind: .rated,
                direction: .input,
                source: .powerSources,
                sampledAt: rawData.sampledAt,
                freshnessLimit: PowerObservationFreshness.capability,
                stability: .publicAPI,
                accessTier: .base,
                confidence: .high
            )
        } else {
            self.adapterCapability = nil
        }

        let smcSampledAt = rawData.smcPower?.sampledAt ?? rawData.sampledAt
        self.inputVoltage = rawData.smcPower?.inputVolts.map {
            Self.observation(
                $0,
                unit: .volts,
                kind: .measured,
                domain: .input,
                direction: .input,
                source: .smc,
                sampledAt: smcSampledAt,
                freshnessLimit: PowerObservationFreshness.live,
                stability: .privateABI,
                accessTier: .enhanced,
                confidence: .medium
            )
        }
        self.inputCurrent = rawData.smcPower?.inputAmps.map {
            Self.observation(
                $0,
                unit: .amperes,
                kind: .measured,
                domain: .input,
                direction: .input,
                source: .smc,
                sampledAt: smcSampledAt,
                freshnessLimit: PowerObservationFreshness.live,
                stability: .privateABI,
                accessTier: .enhanced,
                confidence: .medium
            )
        }
        self.liveInputPower = rawData.smcPower?.inputWatts.map {
            Self.observation(
                $0,
                unit: .watts,
                kind: .measured,
                domain: .input,
                direction: .input,
                source: .smc,
                sampledAt: smcSampledAt,
                freshnessLimit: PowerObservationFreshness.live,
                stability: .privateABI,
                accessTier: .enhanced,
                confidence: .medium
            )
        }
        self.offeredPowerContracts = Self.offeredContracts(
            from: rawData.portPower,
            isExternallyPowered: externalConnected,
            at: rawData.sampledAt
        )
        self.negotiatedPowerContracts = Self.negotiatedContracts(
            from: rawData.portPower,
            isExternallyPowered: externalConnected,
            at: rawData.sampledAt
        )
        self.ioReportPower = rawData.ioReportPower

        self.officialCondition = rawData.systemHealth?.condition
        self.officialMaximumCapacityPercentage = rawData.systemHealth?.maximumCapacityPercentage
        self.publicHealthHint = Self.string(in: powerSourceData, key: "BatteryHealth")
        self.publicHealthCondition = Self.string(in: powerSourceData, key: "BatteryHealthCondition")
        self.publicHealthConfidence = Self.healthConfidence(
            powerSourceData["HealthConfidence"]
        )
        self.batteryFailureModes = Self.stringArray(
            in: powerSourceData,
            key: "BatteryFailureModes"
        )
        self.capacityIsEstimated = Self.boolean(in: powerSourceData, key: "CapacityEstimated")
        self.chargeInterruption = Self.chargeInterruption(
            Self.string(in: powerSourceData, key: "ChargeStatus")
                ?? Self.string(in: registry, key: "ChargeStatus")
        )
        self.adapterErrors = Self.adapterErrors(
            Self.nonNegativeInteger(in: adapter ?? [:], key: "ErrorFlags") ?? 0
        )
        self.powerCondition = rawData.powerCondition

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

    private static func observation(
        _ value: Double,
        unit: ElectricalUnit,
        kind: ElectricalObservationKind,
        domain: ElectricalDomain,
        direction: ElectricalDirection? = nil,
        source: ElectricalObservationSource,
        sampledAt: Date,
        measurementWindow: TimeInterval? = nil,
        freshnessLimit: TimeInterval,
        stability: ObservationStability,
        accessTier: ObservationAccessTier = .base,
        confidence: ObservationConfidence
    ) -> ElectricalObservation {
        ElectricalObservation(
            value: value,
            unit: unit,
            kind: kind,
            domain: domain,
            direction: direction,
            source: source,
            sampledAt: sampledAt,
            measurementWindow: measurementWindow,
            freshnessLimit: freshnessLimit,
            stability: stability,
            accessTier: accessTier,
            confidence: confidence
        )
    }

    private static func batteryFlow(
        smc: SMCPowerReading?,
        gaugePower: Double?,
        currentAmps: Double?,
        isCharging: Bool,
        isExternallyPowered: Bool,
        sampledAt: Date
    ) -> ElectricalObservation? {
        if let smcPower = smc?.batteryWatts {
            let signedPower: Double
            if smcPower < 0 {
                signedPower = smcPower
            } else if let currentAmps, abs(currentAmps) >= BatteryValueLimits.minimumDirectionalCurrentAmps {
                signedPower = currentAmps < 0 ? -smcPower : smcPower
            } else if isCharging {
                signedPower = smcPower
            } else if !isExternallyPowered {
                signedPower = -smcPower
            } else {
                signedPower = smcPower
            }
            return observation(
                signedPower,
                unit: .watts,
                kind: .measured,
                domain: .battery,
                direction: direction(forBatteryPower: signedPower),
                source: .smc,
                sampledAt: smc?.sampledAt ?? sampledAt,
                freshnessLimit: PowerObservationFreshness.live,
                stability: .privateABI,
                accessTier: .enhanced,
                confidence: .medium
            )
        }
        guard let gaugePower else { return nil }
        return observation(
            gaugePower,
            unit: .watts,
            kind: .measured,
            domain: .battery,
            direction: direction(forBatteryPower: gaugePower),
            source: .batteryRegistry,
            sampledAt: sampledAt,
            freshnessLimit: PowerObservationFreshness.controller,
            stability: .undocumentedSchema,
            confidence: .medium
        )
    }

    private static func direction(forBatteryPower power: Double) -> ElectricalDirection? {
        if power > 0 { return .charge }
        if power < 0 { return .discharge }
        return nil
    }

    private static func negotiatedContracts(
        from reading: PortPowerReading?,
        isExternallyPowered: Bool,
        at date: Date
    ) -> [PowerContract] {
        guard isExternallyPowered,
              let reading,
              portReadingIsFresh(reading, at: date) else {
            return []
        }
        return reading.sources.compactMap { source in
            guard source.kind == .usbPD,
                  source.connectionActive == true,
                  let option = source.selectedOption else {
                return nil
            }
            return PowerContract(
                portNumber: source.portNumber,
                voltageVolts: option.voltageVolts,
                currentAmps: option.maximumCurrentAmps,
                maximumPowerWatts: option.maximumPowerWatts,
                kind: .contracted,
                direction: .input,
                source: .portRegistry,
                sampledAt: reading.sampledAt,
                freshnessLimit: PowerObservationFreshness.live,
                stability: .undocumentedSchema,
                accessTier: .enhanced,
                confidence: .medium
            )
        }
    }

    private static func offeredContracts(
        from reading: PortPowerReading?,
        isExternallyPowered: Bool,
        at date: Date
    ) -> [PowerContract] {
        guard isExternallyPowered,
              let reading,
              portReadingIsFresh(reading, at: date) else {
            return []
        }
        return reading.sources.flatMap { source -> [PowerContract] in
            guard source.kind == .usbPD, source.connectionActive == true else { return [] }
            return source.advertisedOptions.map { option in
                PowerContract(
                    portNumber: source.portNumber,
                    voltageVolts: option.voltageVolts,
                    currentAmps: option.maximumCurrentAmps,
                    maximumPowerWatts: option.maximumPowerWatts,
                    kind: .rated,
                    direction: .input,
                    source: .portRegistry,
                    sampledAt: reading.sampledAt,
                    freshnessLimit: PowerObservationFreshness.capability,
                    stability: .undocumentedSchema,
                    accessTier: .enhanced,
                    confidence: .medium
                )
            }
        }
    }

    private static func portReadingIsFresh(_ reading: PortPowerReading, at date: Date) -> Bool {
        let age = date.timeIntervalSince(reading.sampledAt)
        return age >= 0 && age <= PowerObservationFreshness.live
    }

    private static func healthConfidence(_ value: Any?) -> String? {
        if let value = value as? String, !value.isEmpty { return value }
        guard let value = value as? NSNumber else { return nil }
        switch value.intValue {
        case BatteryHealthConfidenceValue.poor: return "Poor"
        case BatteryHealthConfidenceValue.fair: return "Fair"
        case BatteryHealthConfidenceValue.good: return "Good"
        default: return nil
        }
    }

    private static func stringArray(in dictionary: [String: Any], key: String) -> [String] {
        (dictionary[key] as? [Any])?.compactMap { $0 as? String } ?? []
    }

    private static func chargeInterruption(_ value: String?) -> ChargeInterruption? {
        switch value {
        case "HighTemperature": return .highTemperature
        case "LowTemperature": return .lowTemperature
        case "HighOrLowTemperature": return .highOrLowTemperature
        case "BatteryTemperatureGradient": return .temperatureGradient
        case let value? where !value.isEmpty: return .unknown(value)
        default: return nil
        }
    }

    private static func adapterErrors(_ flags: Int) -> [AdapterError] {
        guard flags != 0 else { return [] }
        var errors: [AdapterError] = []
        if flags & AdapterErrorFlag.insufficientAvailablePower != 0 {
            errors.append(.insufficientAvailablePower)
        }
        if flags & AdapterErrorFlag.foreignObjectDetected != 0 {
            errors.append(.foreignObjectDetected)
        }
        if flags & AdapterErrorFlag.needsRepositioning != 0 {
            errors.append(.needsRepositioning)
        }
        let unknownFlags = flags & ~AdapterErrorFlag.known
        if unknownFlags != 0 {
            errors.append(.unknown(unknownFlags))
        }
        return errors
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
        guard let value, BatteryTimeEstimate.validMinutes.contains(value) else { return nil }
        return value
    }

    private static func integer(in dictionary: [String: Any], key: String) -> Int? {
        (dictionary[key] as? NSNumber)?.intValue
    }

    private static func integer(
        in dictionary: [String: Any],
        key: String,
        range: ClosedRange<Int>
    ) -> Int? {
        guard let value = integer(in: dictionary, key: key), range.contains(value) else {
            return nil
        }
        return value
    }

    private static func scaledInteger(
        in dictionary: [String: Any],
        key: String,
        divisor: Double,
        rawRange: ClosedRange<Int>
    ) -> Double? {
        integer(in: dictionary, key: key, range: rawRange).map { Double($0) / divisor }
    }

    private static func scaledInteger(
        in dictionary: [String: Any],
        key: String,
        divisor: Double,
        range: ClosedRange<Double>
    ) -> Double? {
        guard let value = integer(in: dictionary, key: key) else { return nil }
        let scaledValue = Double(value) / divisor
        return range.contains(scaledValue) ? scaledValue : nil
    }

    private static func product(
        _ left: Double?,
        _ right: Double?,
        range: ClosedRange<Double>
    ) -> Double? {
        guard let left, let right else { return nil }
        let product = left * right
        return range.contains(product) ? product : nil
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
        let voltages = integerArray(
            in: data,
            key: "CellVoltage",
            range: BatteryValueLimits.cellVoltageMillivolts
        ).map { Double($0) / PowerUnitConversion.milliUnitsPerUnit }
        let learnedCapacities = integerArray(
            in: data,
            key: "Qmax",
            range: BatteryValueLimits.learnedCellCapacityMAh
        )
        let resistances = integerArray(
            in: data,
            key: "WeightedRa",
            range: BatteryValueLimits.cellResistanceRaw
        )
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
        let minimumTemperature = plausibleDouble(
            in: data,
            key: "MinimumTemperature",
            range: BatteryValueLimits.lifetimeTemperatureCelsius
        )
        let maximumTemperature = plausibleDouble(
            in: data,
            key: "MaximumTemperature",
            range: BatteryValueLimits.lifetimeTemperatureCelsius
        )
        let averageTemperature = averageTemperature(
            integer(in: data, key: "AverageTemperature"),
            minimum: minimumTemperature,
            maximum: maximumTemperature
        )
        let minimumVoltage = plausibleDouble(
            in: data,
            key: "MinimumPackVoltage",
            range: BatteryValueLimits.packVoltageMillivolts
        ).map { $0 / PowerUnitConversion.milliUnitsPerUnit }
        let maximumVoltage = plausibleDouble(
            in: data,
            key: "MaximumPackVoltage",
            range: BatteryValueLimits.packVoltageMillivolts
        ).map { $0 / PowerUnitConversion.milliUnitsPerUnit }
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
        guard let value = integer(in: dictionary, key: key),
              PowerPercentage.validRange.contains(value) else {
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
        guard BatteryValueLimits.lifetimeCurrentMilliamps.contains(magnitude) else { return nil }
        return Double(magnitude) / PowerUnitConversion.milliUnitsPerUnit
    }

    private static func averageTemperature(
        _ rawValue: Int?,
        minimum: Double?,
        maximum: Double?
    ) -> Double? {
        guard let rawValue, let minimum, let maximum else { return nil }
        let candidates = [
            Double(rawValue),
            Double(rawValue) / BatteryRegistryScale.temperatureTenthsPerCelsius
        ]
            .filter { $0 >= minimum && $0 <= maximum }
        return candidates.count == BatteryValuePolicy.unambiguousCandidateCount
            ? candidates.first
            : nil
    }
}

private enum BatteryValueLimits {
    static let temperatureCelsius = -20.0...120.0
    static let batteryPowerWatts = -200.0...200.0
    static let chargingVoltageMillivolts = 1...100_000
    static let chargingCurrentMilliamps = 0...100_000
    static let controllerSystemLoadMilliwatts = 0...500_000
    static let adapterWatts = 1...500
    static let adapterVoltageMillivolts = 1...100_000
    static let adapterCurrentMilliamps = 1...20_000
    static let minimumDirectionalCurrentAmps = 0.01
    static let cellVoltageMillivolts = 0...10_000
    static let learnedCellCapacityMAh = 0...100_000
    static let cellResistanceRaw = 0...1_000_000
    static let lifetimeTemperatureCelsius = -50.0...100.0
    static let packVoltageMillivolts = 1_000.0...100_000.0
    static let lifetimeCurrentMilliamps: Range<UInt> = 1..<100_000
}

private enum BatteryRegistryScale {
    static let temperatureHundredthsPerCelsius = 100.0
    static let temperatureTenthsPerCelsius = 10.0
}

private enum BatteryCellPolicy {
    static let minimumComparableValueCount = 2
}

private enum BatteryTimeEstimate {
    static let invalidSentinel = 65_535
    static let validMinutes = 1..<invalidSentinel
}

private enum BatteryValuePolicy {
    static let unambiguousCandidateCount = 1
}

private enum BatteryHealthConfidenceValue {
    static let poor = 1
    static let fair = 2
    static let good = 3
}

private enum AdapterErrorFlag {
    static let insufficientAvailablePower = 1 << 1
    static let foreignObjectDetected = 1 << 2
    static let needsRepositioning = 1 << 3
    static let known = insufficientAvailablePower | foreignObjectDetected | needsRepositioning
}
