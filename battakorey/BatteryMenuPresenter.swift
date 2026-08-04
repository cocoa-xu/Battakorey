import Foundation

struct BatteryMenuRow: Equatable {
    let title: String
    let value: String
}

struct BatteryMenuSection: Equatable {
    let title: String?
    let rows: [BatteryMenuRow]
}

struct BatteryMenuPresenter {
    func sections(for battery: BatterySnapshot) -> [BatteryMenuSection] {
        var sections = [
            BatteryMenuSection(title: nil, rows: statusRows(for: battery)),
            BatteryMenuSection(title: "Capacity", rows: capacityRows(for: battery)),
            BatteryMenuSection(title: "Electrical", rows: electricalRows(for: battery))
        ]

        let adapterRows = adapterRows(for: battery)
        if !adapterRows.isEmpty {
            sections.append(BatteryMenuSection(title: "Power Adapter", rows: adapterRows))
        }

        let diagnosticRows = diagnosticRows(for: battery)
        if !diagnosticRows.isEmpty {
            sections.append(BatteryMenuSection(title: "Diagnostics", rows: diagnosticRows))
        }
        return sections.filter { !$0.rows.isEmpty }
    }

    func detailSections(for battery: BatterySnapshot) -> [BatteryMenuSection] {
        [
            BatteryMenuSection(title: "Cells", rows: cellRows(for: battery)),
            BatteryMenuSection(title: "Lifetime", rows: lifetimeRows(for: battery))
        ].filter { !$0.rows.isEmpty }
    }

    private func statusRows(for battery: BatterySnapshot) -> [BatteryMenuRow] {
        var rows = [
            BatteryMenuRow(title: "Battery", value: "\(battery.chargePercentage)%"),
            BatteryMenuRow(title: "Status", value: status(for: battery)),
            BatteryMenuRow(title: "Power Source", value: powerSource(for: battery.powerSource))
        ]

        if battery.isCharging {
            rows.append(BatteryMenuRow(
                title: "Time to Full",
                value: formattedTime(battery.timeRemainingMinutes)
            ))
        } else if battery.powerSource == .battery {
            rows.append(BatteryMenuRow(
                title: "Time to Empty",
                value: formattedTime(battery.timeRemainingMinutes)
            ))
        }
        return rows
    }

    private func capacityRows(for battery: BatterySnapshot) -> [BatteryMenuRow] {
        var rows: [BatteryMenuRow] = []
        appendCapacity(battery.currentCapacityMAh, title: "Current Charge", to: &rows)
        appendCapacity(battery.fullChargeCapacityMAh, title: "Full Charge", to: &rows)
        if battery.rawMaximumCapacityMAh != battery.fullChargeCapacityMAh {
            appendCapacity(battery.rawMaximumCapacityMAh, title: "Raw Maximum", to: &rows)
        }
        appendCapacity(battery.designCapacityMAh, title: "Design Capacity", to: &rows)

        if let retention = battery.capacityRetentionPercentage {
            rows.append(BatteryMenuRow(
                title: "Capacity Retention",
                value: String(format: "%.1f%%", retention)
            ))
        }

        if let cycles = battery.cycleCount {
            let value: String
            if let designCycles = battery.designCycleCount, designCycles > 0 {
                value = String(
                    format: "%d / %d (%.1f%%)",
                    cycles,
                    designCycles,
                    Double(cycles) / Double(designCycles) * 100
                )
            } else {
                value = "\(cycles)"
            }
            rows.append(BatteryMenuRow(title: "Cycles", value: value))
        }
        return rows
    }

    private func electricalRows(for battery: BatterySnapshot) -> [BatteryMenuRow] {
        var rows: [BatteryMenuRow] = []
        if let temperature = battery.temperatureCelsius {
            rows.append(BatteryMenuRow(
                title: "Temperature",
                value: String(format: "%.1f °C", temperature)
            ))
        }
        if let voltage = battery.voltageVolts {
            rows.append(BatteryMenuRow(title: "Voltage", value: String(format: "%.3f V", voltage)))
        }
        if let current = battery.currentAmps {
            rows.append(BatteryMenuRow(title: "Current", value: String(format: "%+.3f A", current)))
        }
        if let power = battery.batteryPowerWatts {
            rows.append(BatteryMenuRow(title: "Battery Power", value: String(format: "%+.1f W", power)))
        }
        if let systemPower = battery.systemPowerWatts {
            rows.append(BatteryMenuRow(
                title: "System Draw",
                value: String(format: "%.1f W", systemPower)
            ))
        }
        return rows
    }

    private func adapterRows(for battery: BatterySnapshot) -> [BatteryMenuRow] {
        var rows: [BatteryMenuRow] = []
        if let watts = battery.adapterWatts {
            rows.append(BatteryMenuRow(title: "Adapter Rating", value: "\(watts) W"))
        }
        if let voltage = battery.adapterVoltageVolts, let current = battery.adapterCurrentAmps {
            rows.append(BatteryMenuRow(
                title: "Power Contract",
                value: String(format: "%.1f V × %.1f A", voltage, current)
            ))
        }
        if let inputPower = battery.inputPowerWatts {
            rows.append(BatteryMenuRow(title: "Live Input", value: String(format: "%.1f W", inputPower)))
        }
        if let voltage = battery.inputVoltageVolts, let current = battery.inputCurrentAmps {
            rows.append(BatteryMenuRow(
                title: "DC Input Rail",
                value: String(format: "%.2f V × %.2f A", voltage, current)
            ))
        }
        return rows
    }

    private func cellRows(for battery: BatterySnapshot) -> [BatteryMenuRow] {
        guard let cells = battery.cellDetails else { return [] }
        var rows: [BatteryMenuRow] = []
        if !cells.voltages.isEmpty {
            let values = cells.voltages.map { String(format: "%.3f", $0) }.joined(separator: " · ")
            rows.append(BatteryMenuRow(title: "Voltages", value: "\(values) V"))
        }
        if let delta = cells.voltageDeltaMillivolts {
            rows.append(BatteryMenuRow(title: "Voltage Delta", value: "\(delta) mV"))
        }
        if !cells.learnedCapacitiesMAh.isEmpty {
            let values = cells.learnedCapacitiesMAh.map(String.init).joined(separator: " · ")
            rows.append(BatteryMenuRow(title: "Learned Qmax", value: "\(values) mAh"))
        }
        if let delta = cells.learnedCapacityDeltaMAh {
            rows.append(BatteryMenuRow(title: "Qmax Delta", value: "\(delta) mAh"))
        }
        if !cells.resistances.isEmpty {
            rows.append(BatteryMenuRow(
                title: "Resistance",
                value: cells.resistances.map(String.init).joined(separator: " · ")
            ))
        }
        if let delta = cells.resistanceDelta {
            rows.append(BatteryMenuRow(title: "Resistance Delta", value: "\(delta)"))
        }
        if let minimum = cells.dailyMinimumCharge, let maximum = cells.dailyMaximumCharge {
            rows.append(BatteryMenuRow(title: "Daily Charge Range", value: "\(minimum)% – \(maximum)%"))
        }
        if let cycle = cells.cycleCountAtLastRelearn {
            rows.append(BatteryMenuRow(title: "Last Gauge Relearn", value: "Cycle \(cycle)"))
        }
        if let writes = cells.dataFlashWriteCount {
            rows.append(BatteryMenuRow(title: "Data Flash Writes", value: "\(writes)"))
        }
        if let events = cells.resistanceSenseOpenCount {
            rows.append(BatteryMenuRow(title: "Rsense Open Events", value: "\(events)"))
        }
        if let reason = cells.qmaxDisqualificationReason {
            rows.append(BatteryMenuRow(
                title: "Qmax Disqualification",
                value: formattedHex(reason)
            ))
        }
        return rows
    }

    private func lifetimeRows(for battery: BatterySnapshot) -> [BatteryMenuRow] {
        guard let lifetime = battery.lifetimeDetails else { return [] }
        var rows: [BatteryMenuRow] = []

        let temperatures = [
            lifetime.minimumTemperatureCelsius,
            lifetime.averageTemperatureCelsius,
            lifetime.maximumTemperatureCelsius
        ]
        if temperatures.contains(where: { $0 != nil }) {
            let value = temperatures
                .map { $0.map { String(format: "%.1f", $0) } ?? "—" }
                .joined(separator: " / ")
            rows.append(BatteryMenuRow(title: "Min / Avg / Max Temp", value: "\(value) °C"))
        }
        if let minimum = lifetime.minimumPackVoltageVolts,
           let maximum = lifetime.maximumPackVoltageVolts {
            rows.append(BatteryMenuRow(
                title: "Pack Voltage Range",
                value: String(format: "%.3f – %.3f V", minimum, maximum)
            ))
        }
        if lifetime.maximumChargeCurrentAmps != nil || lifetime.maximumDischargeCurrentAmps != nil {
            let charge = lifetime.maximumChargeCurrentAmps
                .map { String(format: "+%.3f", $0) } ?? "—"
            let discharge = lifetime.maximumDischargeCurrentAmps
                .map { String(format: "-%.3f", $0) } ?? "—"
            rows.append(BatteryMenuRow(title: "Peak Charge / Discharge", value: "\(charge) / \(discharge) A"))
        }
        if let hours = lifetime.operatingTimeHours {
            rows.append(BatteryMenuRow(title: "Operating Time", value: "\(hours) h"))
        }
        return rows
    }

    private func diagnosticRows(for battery: BatterySnapshot) -> [BatteryMenuRow] {
        var rows: [BatteryMenuRow] = []
        if let active = battery.optimizedChargingActive {
            rows.append(BatteryMenuRow(
                title: "Optimized Charging",
                value: active ? "Active" : "Inactive"
            ))
        }
        if let active = battery.lowPowerModeActive {
            rows.append(BatteryMenuRow(title: "Low Power Mode", value: active ? "On" : "Off"))
        }
        if let status = battery.permanentFailureStatus {
            rows.append(BatteryMenuRow(
                title: "Failure Status",
                value: formattedHex(status)
            ))
        }
        if let disconnects = battery.cellDisconnectCount {
            rows.append(BatteryMenuRow(title: "Cell Disconnects", value: "\(disconnects)"))
        }
        if let reason = battery.notChargingReason, reason != 0 {
            rows.append(BatteryMenuRow(
                title: "Not Charging Reason",
                value: formattedHex(reason)
            ))
        }
        if let reason = battery.slowChargingReason, reason != 0 {
            rows.append(BatteryMenuRow(
                title: "Slow Charging Reason",
                value: formattedHex(reason)
            ))
        }
        return rows
    }

    private func appendCapacity(_ capacity: Int?, title: String, to rows: inout [BatteryMenuRow]) {
        guard let capacity else { return }
        rows.append(BatteryMenuRow(title: title, value: "\(capacity) mAh"))
    }

    private func status(for battery: BatterySnapshot) -> String {
        if battery.isCharging {
            return "Charging"
        }
        if battery.isFullyCharged {
            return "Fully Charged"
        }
        if battery.isExternallyPowered {
            return "On AC Power"
        }
        return "Discharging"
    }

    private func powerSource(for source: BatterySnapshot.PowerSource) -> String {
        switch source {
        case .ac:
            return "AC Power"
        case .battery:
            return "Battery Power"
        case .ups:
            return "UPS Power"
        case let .unknown(name):
            return name
        }
    }

    private func formattedTime(_ minutes: Int?) -> String {
        guard let minutes else { return "Calculating…" }
        return "\(minutes / 60) h \(minutes % 60) m"
    }

    private func formattedHex(_ value: Int) -> String {
        let digits = String(value, radix: 16, uppercase: true)
        return "0x\(String(repeating: "0", count: max(0, 8 - digits.count)))\(digits)"
    }
}
