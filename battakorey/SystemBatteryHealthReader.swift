import Foundation

struct SystemBatteryHealthReading: Equatable {
    let condition: String?
    let maximumCapacityPercentage: Int?
    let sampledAt: Date
}

enum SystemBatteryHealthDecoder {
    static func decode(_ data: Data, sampledAt: Date) -> SystemBatteryHealthReading? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = root["SPPowerDataType"] as? [[String: Any]],
              let battery = items.first(where: { $0["_name"] as? String == "spbattery_information" }),
              let health = battery["sppower_battery_health_info"] as? [String: Any] else {
            return nil
        }

        let condition = health["sppower_battery_health"] as? String
        let maximumCapacity = maximumCapacity(
            from: health["sppower_battery_health_maximum_capacity"]
        )
        guard condition != nil || maximumCapacity != nil else { return nil }
        return SystemBatteryHealthReading(
            condition: condition,
            maximumCapacityPercentage: maximumCapacity,
            sampledAt: sampledAt
        )
    }

    private static func maximumCapacity(from value: Any?) -> Int? {
        let percentage: Int?
        if let number = value as? NSNumber {
            percentage = number.intValue
        } else if let text = value as? String {
            percentage = Int(text.trimmingCharacters(in: CharacterSet(charactersIn: "%")))
        } else {
            percentage = nil
        }
        guard let percentage,
              PowerPercentage.validRange.contains(percentage) else {
            return nil
        }
        return percentage
    }
}

final class SystemBatteryHealthReader {
    private let cacheDuration: TimeInterval
    private let dataProvider: () -> Data?
    private var cachedReading: SystemBatteryHealthReading?
    private var lastAttemptAt: Date?

    init(
        cacheDuration: TimeInterval = SystemBatteryHealthPolicy.defaultCacheDuration,
        timeout: TimeInterval = SystemBatteryHealthPolicy.processTimeout,
        dataProvider: (() -> Data?)? = nil
    ) {
        self.cacheDuration = cacheDuration
        self.dataProvider = dataProvider ?? {
            Self.runSystemProfiler(timeout: timeout)
        }
    }

    func read(at date: Date = Date()) -> SystemBatteryHealthReading? {
        if let lastAttemptAt,
           date.timeIntervalSince(lastAttemptAt) < cacheDuration {
            return cachedReading
        }
        lastAttemptAt = date
        guard let data = dataProvider(),
              let reading = SystemBatteryHealthDecoder.decode(data, sampledAt: date) else {
            return cachedReading
        }
        cachedReading = reading
        return reading
    }

    private static func runSystemProfiler(timeout: TimeInterval) -> Data? {
        let process = Process()
        let pipe = Pipe()
        let completion = DispatchSemaphore(value: 0)
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPPowerDataType", "-json"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.environment = ProcessInfo.processInfo.environment.merging([
            "LANG": "C",
            "LC_ALL": "C"
        ]) { _, forced in forced }
        process.terminationHandler = { _ in completion.signal() }

        do {
            try process.run()
        } catch {
            return nil
        }
        guard completion.wait(timeout: .now() + timeout) == .success else {
            process.terminate()
            return nil
        }
        guard process.terminationStatus == ProcessTerminationStatus.success else { return nil }
        return pipe.fileHandleForReading.readDataToEndOfFile()
    }
}

private enum SystemBatteryHealthPolicy {
    static let defaultCacheDuration: TimeInterval = 300
    static let processTimeout: TimeInterval = 2
}

private enum ProcessTerminationStatus {
    static let success: Int32 = 0
}
