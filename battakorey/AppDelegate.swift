import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarItem: NSStatusItem
    private let battakorey: BattakoreyImage
    private let menu: BattakoreyMenu
    private let batteryProvider: BatteryInfoProviding
    private var updateTimer: Timer?

    override init() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: BattakoreyImage.baseWidth)
        battakorey = BattakoreyImage(frame: NSRect(
            x: 0,
            y: 0,
            width: BattakoreyImage.baseWidth,
            height: BattakoreyImage.baseHeight
        ))
        menu = BattakoreyMenu()
        batteryProvider = IOKitBatteryInfoProvider()
        super.init()

        statusBarItem.menu = menu
        statusBarItem.button?.addSubview(battakorey)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateBattery()
        }
        updateBattery()
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
    }

    private func updateBattery() {
        guard let battery = batteryProvider.snapshot() else { return }
        let percentage = CGFloat(battery.chargePercentage)
        if battakorey.percentage != percentage {
            battakorey.percentage = percentage
        }
        if battakorey.isCharging != battery.isCharging {
            battakorey.isCharging = battery.isCharging
        }
        menu.update(with: battery)
    }
}
