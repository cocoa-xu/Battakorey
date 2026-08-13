import Foundation

enum BatteryAutomationCapability: String, CaseIterable, Identifiable {
    case status
    case capacity
    case electrical
    case powerAdapter = "power-adapter"
    case componentPower = "component-power"
    case diagnostics
    case batteryInternals = "battery-internals"

    var id: String { rawValue }

    var bondryID: String { "battery.\(rawValue)" }

    var title: String {
        switch self {
        case .status: "Status"
        case .capacity: "Capacity"
        case .electrical: "Electrical"
        case .powerAdapter: "Power Adapter"
        case .componentPower: "Component Power"
        case .diagnostics: "Diagnostics"
        case .batteryInternals: "Battery Internals"
        }
    }

    var description: String {
        switch self {
        case .status:
            "Current charge, charging state, power source, and time remaining."
        case .capacity:
            "Charge capacity, battery health, and cycle information."
        case .electrical:
            "Battery voltage, current, temperature, and power flow."
        case .powerAdapter:
            "Adapter capability, negotiated contracts, and live input readings."
        case .componentPower:
            "CPU, GPU, memory, and display power estimates."
        case .diagnostics:
            "Charging, thermal, health, and controller diagnostics."
        case .batteryInternals:
            "Cell, gauge history, and lifetime controller readings."
        }
    }

    var itemIDs: Set<BatteryMenuItemID> {
        switch self {
        case .status:
            [
                .missingBatteryWarning, .batteryLevel, .status, .powerSource,
                .timeRemaining
            ]
        case .capacity:
            [
                .currentCharge, .fullCharge, .rawMaximum, .designCapacity,
                .capacityRetention, .maximumCapacity, .batteryCondition, .cycles
            ]
        case .electrical:
            [
                .temperature, .voltage, .current, .batteryPower, .chargeTarget,
                .systemDraw
            ]
        case .powerAdapter:
            [
                .adapterRating, .powerContract, .liveInput, .dcInputRail,
                .pdContract
            ]
        case .componentPower:
            [
                .cpuPower, .gpuPower, .anePower, .memoryPower, .gpuMemoryPower,
                .displayPower, .externalDisplayPower
            ]
        case .diagnostics:
            [
                .optimizedCharging, .lowPowerMode, .failureStatus,
                .cellDisconnects, .notChargingReason, .slowChargingReason,
                .chargeInterruption, .adapterErrors, .publicHealthHint,
                .capacityEstimated, .batteryFailureModes, .thermalPressure,
                .cpuPowerLimits
            ]
        case .batteryInternals:
            [
                .cellVoltages, .cellVoltageDelta, .learnedQmax, .qmaxDelta,
                .resistance, .resistanceDelta, .dailyChargeRange,
                .lastGaugeRelearn, .dataFlashWrites, .rsenseOpenEvents,
                .qmaxDisqualification, .lifetimeTemperatures, .packVoltageRange,
                .peakCurrent, .operatingTime
            ]
        }
    }

}

final class BatteryAutomationState: @unchecked Sendable {
    private struct StoredSnapshot {
        let battery: BatterySnapshot
        let sampledAt: Date
    }

    private let lock = NSLock()
    private var snapshot: StoredSnapshot?
    private var visibility: BatteryMenuVisibility
    private let presenter = BatteryMenuPresenter()

    init(visibility: BatteryMenuVisibility = .recommended) {
        self.visibility = visibility
    }

    func update(snapshot: BatterySnapshot, sampledAt: Date = Date()) {
        lock.withLock {
            self.snapshot = StoredSnapshot(battery: snapshot, sampledAt: sampledAt)
        }
    }

    func update(visibility: BatteryMenuVisibility) {
        lock.withLock { self.visibility = visibility }
    }

    func exposedCapabilities(
        allowedCapabilities: Set<BatteryAutomationCapability>
    ) -> [BatteryAutomationCapability] {
        let visibleItemIDs = lock.withLock { visibility.visibleItemIDs }
        return exposedCapabilities(
            allowedCapabilities: allowedCapabilities,
            visibleItemIDs: visibleItemIDs
        )
    }

    func payload(for capability: BatteryAutomationCapability) -> [String: Any]? {
        let values = lock.withLock { (snapshot, visibility) }
        guard let snapshot = values.0 else { return nil }
        return payload(
            for: capability,
            snapshot: snapshot,
            visibility: values.1
        )
    }

    func snapshotPayload(
        allowedCapabilities: Set<BatteryAutomationCapability>
    ) -> [String: Any]? {
        let values = lock.withLock { (snapshot, visibility) }
        let capabilities = exposedCapabilities(
            allowedCapabilities: allowedCapabilities,
            visibleItemIDs: values.1.visibleItemIDs
        )
        guard !capabilities.isEmpty else {
            return ["capabilities": []]
        }
        guard let snapshot = values.0 else { return nil }
        let payloads = capabilities.map {
            payload(for: $0, snapshot: snapshot, visibility: values.1)
        }
        return [
            "sampledAt": Self.timestamp(snapshot.sampledAt),
            "capabilities": payloads.map { payload in
                var payload = payload
                payload.removeValue(forKey: "sampledAt")
                return payload
            }
        ]
    }

    private func exposedCapabilities(
        allowedCapabilities: Set<BatteryAutomationCapability>,
        visibleItemIDs: Set<BatteryMenuItemID>
    ) -> [BatteryAutomationCapability] {
        BatteryAutomationCapability.allCases.filter {
            allowedCapabilities.contains($0) && !$0.itemIDs.isDisjoint(with: visibleItemIDs)
        }
    }

    private func payload(
        for capability: BatteryAutomationCapability,
        snapshot: StoredSnapshot,
        visibility: BatteryMenuVisibility
    ) -> [String: Any] {
        let visibleItemIDs = visibility.visibleItemIDs.intersection(capability.itemIDs)
        let filteredVisibility = BatteryMenuVisibility(
            visibleItemIDs: visibleItemIDs,
            showsSectionTitles: true
        )
        let sections: [BatteryMenuSection]
        if capability == .batteryInternals {
            sections = presenter.detailSections(
                for: snapshot.battery,
                visibility: filteredVisibility
            )
        } else {
            sections = presenter.sections(
                for: snapshot.battery,
                visibility: filteredVisibility
            )
        }
        var occurrences: [BatteryMenuItemID: Int] = [:]
        let readings = sections.flatMap(\.rows).map { row in
            let occurrence = occurrences[row.id, default: 0]
            occurrences[row.id] = occurrence + 1
            var reading: [String: Any] = [
                "id": row.id.rawValue,
                "label": row.title,
                "formattedValue": row.value
            ]
            if let machineValue = machineValue(
                for: row,
                occurrence: occurrence,
                battery: snapshot.battery
            ) {
                reading["value"] = machineValue.value
                if let unit = machineValue.unit {
                    reading["unit"] = unit
                }
            }
            return reading
        }
        return [
            "capability": capability.bondryID,
            "sampledAt": Self.timestamp(snapshot.sampledAt),
            "readings": readings
        ]
    }

    private static func timestamp(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func machineValue(
        for row: BatteryMenuRow,
        occurrence: Int,
        battery: BatterySnapshot
    ) -> (value: Any, unit: String?)? {
        switch row.id {
        case .missingBatteryWarning:
            return (true, nil)
        case .batteryLevel:
            return (battery.chargePercentage, "percent")
        case .status, .powerSource:
            return (row.value, nil)
        case .timeRemaining:
            return battery.timeRemainingMinutes.map { ($0, "minutes") }
        case .currentCharge:
            return battery.currentCapacityMAh.map { ($0, "mAh") }
        case .fullCharge:
            return battery.fullChargeCapacityMAh.map { ($0, "mAh") }
        case .rawMaximum:
            return battery.rawMaximumCapacityMAh.map { ($0, "mAh") }
        case .designCapacity:
            return battery.designCapacityMAh.map { ($0, "mAh") }
        case .capacityRetention:
            return battery.rawCapacityRatioPercentage.map { ($0, "percent") }
        case .maximumCapacity:
            return battery.officialMaximumCapacityPercentage.map { ($0, "percent") }
        case .batteryCondition:
            return battery.officialCondition.map { ($0, nil) }
        case .cycles:
            guard let cycles = battery.cycleCount else { return nil }
            var value: [String: Any] = ["current": cycles]
            if let rated = battery.designCycleCount { value["rated"] = rated }
            return (value, "cycles")
        case .temperature:
            return battery.temperatureCelsius.map { ($0, "celsius") }
        case .voltage:
            return battery.voltageVolts.map { ($0, "volts") }
        case .current:
            return battery.currentAmps.map { ($0, "amperes") }
        case .batteryPower:
            return battery.batteryFlow.map { ($0.value, "watts") }
        case .chargeTarget:
            return battery.chargingTargetPower.map { ($0.value, "watts") }
        case .systemDraw:
            return battery.controllerSystemLoad.map { ($0.value, "watts") }
        case .cpuPower:
            return battery.ioReportPower?.cpuWatts.map { ($0, "watts") }
        case .gpuPower:
            return battery.ioReportPower?.gpuWatts.map { ($0, "watts") }
        case .anePower:
            return battery.ioReportPower?.aneWatts.map { ($0, "watts") }
        case .memoryPower:
            return battery.ioReportPower?.memoryWatts.map { ($0, "watts") }
        case .gpuMemoryPower:
            return battery.ioReportPower?.gpuMemoryWatts.map { ($0, "watts") }
        case .displayPower:
            return battery.ioReportPower?.displayWatts.map { ($0, "watts") }
        case .externalDisplayPower:
            return battery.ioReportPower?.externalDisplayWatts.map { ($0, "watts") }
        case .adapterRating:
            return battery.adapterRating.map { ($0.value, "watts") }
        case .powerContract:
            return battery.adapterCapability.map { (contract($0), nil) }
        case .liveInput:
            return battery.liveInputPower.map { ($0.value, "watts") }
        case .dcInputRail:
            guard let voltage = battery.inputVoltage?.value,
                  let current = battery.inputCurrent?.value else {
                return nil
            }
            return (["volts": voltage, "amperes": current], nil)
        case .pdContract:
            guard battery.negotiatedPowerContracts.indices.contains(occurrence) else {
                return nil
            }
            return (contract(battery.negotiatedPowerContracts[occurrence]), nil)
        case .optimizedCharging:
            return battery.optimizedChargingActive.map { ($0, nil) }
        case .lowPowerMode:
            return battery.lowPowerModeActive.map { ($0, nil) }
        case .failureStatus:
            return battery.permanentFailureStatus.map { ($0, nil) }
        case .cellDisconnects:
            return battery.cellDisconnectCount.map { ($0, nil) }
        case .notChargingReason:
            return battery.notChargingReason.map { ($0, nil) }
        case .slowChargingReason:
            return battery.slowChargingReason.map { ($0, nil) }
        case .chargeInterruption, .thermalPressure:
            return (row.value, nil)
        case .adapterErrors:
            return (row.value.components(separatedBy: " · "), nil)
        case .publicHealthHint:
            return battery.publicHealthHint.map { ($0, nil) }
        case .capacityEstimated:
            return battery.capacityIsEstimated.map { ($0, nil) }
        case .batteryFailureModes:
            return (battery.batteryFailureModes, nil)
        case .cpuPowerLimits:
            guard let limits = battery.powerCondition?.cpuPowerLimits else { return nil }
            var value: [String: Any] = [:]
            if let speed = limits.processorSpeedPercentage {
                value["processorSpeedPercent"] = speed
            }
            if let scheduler = limits.schedulerTimePercentage {
                value["schedulerTimePercent"] = scheduler
            }
            if let count = limits.availableCPUCount {
                value["availableCPUCount"] = count
            }
            return (value, nil)
        case .cellVoltages:
            return battery.cellDetails.map { ($0.voltages, "volts") }
        case .cellVoltageDelta:
            return battery.cellDetails?.voltageDeltaMillivolts.map { ($0, "millivolts") }
        case .learnedQmax:
            return battery.cellDetails.map { ($0.learnedCapacitiesMAh, "mAh") }
        case .qmaxDelta:
            return battery.cellDetails?.learnedCapacityDeltaMAh.map { ($0, "mAh") }
        case .resistance:
            return battery.cellDetails.map { ($0.resistances, nil) }
        case .resistanceDelta:
            return battery.cellDetails?.resistanceDelta.map { ($0, nil) }
        case .dailyChargeRange:
            guard let minimum = battery.cellDetails?.dailyMinimumCharge,
                  let maximum = battery.cellDetails?.dailyMaximumCharge else {
                return nil
            }
            return (["minimum": minimum, "maximum": maximum], "percent")
        case .lastGaugeRelearn:
            return battery.cellDetails?.cycleCountAtLastRelearn.map { ($0, "cycles") }
        case .dataFlashWrites:
            return battery.cellDetails?.dataFlashWriteCount.map { ($0, nil) }
        case .rsenseOpenEvents:
            return battery.cellDetails?.resistanceSenseOpenCount.map { ($0, nil) }
        case .qmaxDisqualification:
            return battery.cellDetails?.qmaxDisqualificationReason.map { ($0, nil) }
        case .lifetimeTemperatures:
            guard let lifetime = battery.lifetimeDetails else { return nil }
            var value: [String: Any] = [:]
            if let minimum = lifetime.minimumTemperatureCelsius { value["minimum"] = minimum }
            if let average = lifetime.averageTemperatureCelsius { value["average"] = average }
            if let maximum = lifetime.maximumTemperatureCelsius { value["maximum"] = maximum }
            return (value, "celsius")
        case .packVoltageRange:
            guard let minimum = battery.lifetimeDetails?.minimumPackVoltageVolts,
                  let maximum = battery.lifetimeDetails?.maximumPackVoltageVolts else {
                return nil
            }
            return (["minimum": minimum, "maximum": maximum], "volts")
        case .peakCurrent:
            guard let lifetime = battery.lifetimeDetails else { return nil }
            var value: [String: Any] = [:]
            if let charge = lifetime.maximumChargeCurrentAmps { value["charge"] = charge }
            if let discharge = lifetime.maximumDischargeCurrentAmps {
                value["discharge"] = discharge
            }
            return (value, "amperes")
        case .operatingTime:
            return battery.lifetimeDetails?.operatingTimeHours.map { ($0, "hours") }
        }
    }

    private func contract(_ contract: PowerContract) -> [String: Any] {
        var value: [String: Any] = ["volts": contract.voltageVolts]
        if let port = contract.portNumber { value["port"] = port }
        if let current = contract.currentAmps { value["amperes"] = current }
        if let power = contract.maximumPowerWatts { value["watts"] = power }
        return value
    }
}
