import Foundation
import IOKit.ps

final class BatteryMonitor {
    var onSnapshot: ((BatterySnapshot) -> Void)?

    private let provider: BatteryInfoProviding
    private let queue = DispatchQueue(label: "moe.uwucocoa.battakorey.power", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var powerSourceNotification: CFRunLoopSource?

    init(provider: BatteryInfoProviding = IOKitBatteryInfoProvider()) {
        self.provider = provider
    }

    func start() {
        guard timer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now(),
            repeating: BatteryMonitorPolicy.refreshInterval,
            leeway: BatteryMonitorPolicy.timerLeeway
        )
        timer.setEventHandler { [weak self] in
            self?.sample()
        }
        self.timer = timer
        timer.resume()

        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let unmanagedSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.queue.async {
                monitor.provider.powerSourceDidChange()
                monitor.sample()
            }
        }, context) else {
            return
        }
        let source = unmanagedSource.takeRetainedValue()
        powerSourceNotification = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    func stop() {
        timer?.cancel()
        timer = nil
        if let powerSourceNotification {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), powerSourceNotification, .commonModes)
            self.powerSourceNotification = nil
        }
    }

    private func sample() {
        guard let snapshot = provider.snapshot() else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onSnapshot?(snapshot)
        }
    }
}

private enum BatteryMonitorPolicy {
    static let refreshInterval: TimeInterval = 1
    static let timerLeeway = DispatchTimeInterval.milliseconds(100)
}
