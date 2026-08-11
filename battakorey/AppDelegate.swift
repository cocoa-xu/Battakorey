import Cocoa

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarItem: NSStatusItem
    private let battakorey: BattakoreyImage
    private let menu: BattakoreyMenu
    private let batteryMonitor: BatteryMonitor
    private let preferencesModel: BatteryPreferencesModel
    private lazy var preferencesController = BattakoreyPreferencesWindowController(
        model: preferencesModel
    )
    private var latestBattery: BatterySnapshot?

    override init() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: BattakoreyImage.baseWidth)
        battakorey = BattakoreyImage(frame: NSRect(
            origin: .zero,
            size: NSSize(width: BattakoreyImage.baseWidth, height: BattakoreyImage.baseHeight)
        ))
        menu = BattakoreyMenu()
        batteryMonitor = BatteryMonitor()
        preferencesModel = BatteryPreferencesModel()
        super.init()

        statusBarItem.menu = menu
        statusBarItem.button?.addSubview(battakorey)
        menu.preferencesHandler = { [weak self] in
            self?.preferencesController.show()
        }
        menu.prepare()
        preferencesModel.onChange = { [weak self] visibility in
            guard let self, let battery = self.latestBattery else { return }
            self.menu.update(with: battery, visibility: visibility)
        }
        batteryMonitor.onSnapshot = { [weak self] battery in
            self?.update(with: battery)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        batteryMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        batteryMonitor.stop()
    }

    private func update(with battery: BatterySnapshot) {
        latestBattery = battery
        let percentage = CGFloat(battery.statusBarChargePercentage)
        if battakorey.percentage != percentage {
            battakorey.percentage = percentage
        }
        let isCharging = battery.hasBattery && battery.isCharging
        if battakorey.isCharging != isCharging {
            battakorey.isCharging = isCharging
        }
        menu.update(with: battery, visibility: preferencesModel.visibility)
    }
}
