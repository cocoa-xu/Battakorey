import Foundation
import IOKit.pwr_mgt

enum ThermalPressure: Equatable {
    case nominal
    case fair
    case serious
    case critical
}

enum ThermalWarning: Equatable {
    case normal
    case warning
    case critical
}

struct CPUPowerLimits: Equatable {
    let processorSpeedPercentage: Int?
    let availableCPUCount: Int?
    let schedulerTimePercentage: Int?
}

struct PowerConditionReading: Equatable {
    let thermalPressure: ThermalPressure?
    let thermalWarning: ThermalWarning?
    let cpuPowerLimits: CPUPowerLimits?
    let sampledAt: Date
}

struct PowerConditionReader {
    func read(at date: Date = Date()) -> PowerConditionReading {
        PowerConditionReading(
            thermalPressure: thermalPressure(ProcessInfo.processInfo.thermalState),
            thermalWarning: thermalWarning(),
            cpuPowerLimits: cpuPowerLimits(),
            sampledAt: date
        )
    }

    private func thermalPressure(_ state: ProcessInfo.ThermalState) -> ThermalPressure? {
        switch state {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return nil
        }
    }

    private func thermalWarning() -> ThermalWarning? {
        var level: UInt32 = 0
        guard IOPMGetThermalWarningLevel(&level) == kIOReturnSuccess else { return nil }
        switch level {
        case UInt32(kIOPMThermalLevelNormal): return .normal
        case UInt32(kIOPMThermalLevelWarning): return .warning
        case UInt32(kIOPMThermalLevelCritical): return .critical
        default: return nil
        }
    }

    private func cpuPowerLimits() -> CPUPowerLimits? {
        var unmanaged: Unmanaged<CFDictionary>?
        guard IOPMCopyCPUPowerStatus(&unmanaged) == kIOReturnSuccess,
              let values = unmanaged?.takeRetainedValue() as? [String: Any] else {
            return nil
        }
        let reading = CPUPowerLimits(
            processorSpeedPercentage: integer(kIOPMCPUPowerLimitProcessorSpeedKey, in: values),
            availableCPUCount: integer(kIOPMCPUPowerLimitProcessorCountKey, in: values),
            schedulerTimePercentage: integer(kIOPMCPUPowerLimitSchedulerTimeKey, in: values)
        )
        guard reading.processorSpeedPercentage != nil
            || reading.availableCPUCount != nil
            || reading.schedulerTimePercentage != nil else {
            return nil
        }
        return reading
    }

    private func integer(_ key: String, in values: [String: Any]) -> Int? {
        (values[key] as? NSNumber)?.intValue
    }
}
