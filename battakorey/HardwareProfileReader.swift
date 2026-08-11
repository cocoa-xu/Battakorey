import Foundation

enum HardwareProfileDecoder {
    static func isMacBook(_ data: Data) -> Bool {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = root["SPHardwareDataType"] as? [[String: Any]],
              let machineName = items.first?["machine_name"] as? String else {
            return false
        }
        return machineName == "MacBook" || machineName.hasPrefix("MacBook ")
    }
}

final class HardwareProfileReader {
    private let dataProvider: () -> Data?
    private var cachedIsMacBook: Bool?

    init(
        timeout: TimeInterval = HardwareProfilePolicy.processTimeout,
        dataProvider: (() -> Data?)? = nil
    ) {
        self.dataProvider = dataProvider ?? {
            Self.runSystemProfiler(timeout: timeout)
        }
    }

    func isMacBook() -> Bool {
        if let cachedIsMacBook {
            return cachedIsMacBook
        }
        let isMacBook = dataProvider().map(HardwareProfileDecoder.isMacBook) ?? false
        cachedIsMacBook = isMacBook
        return isMacBook
    }

    private static func runSystemProfiler(timeout: TimeInterval) -> Data? {
        let process = Process()
        let pipe = Pipe()
        let completion = DispatchSemaphore(value: 0)
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPHardwareDataType", "-json"]
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
        guard process.terminationStatus == HardwareProfileProcessStatus.success else { return nil }
        return pipe.fileHandleForReading.readDataToEndOfFile()
    }
}

private enum HardwareProfilePolicy {
    static let processTimeout: TimeInterval = 2
}

private enum HardwareProfileProcessStatus {
    static let success: Int32 = 0
}
