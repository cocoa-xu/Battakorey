import Cocoa

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarItem: NSStatusItem
    private let battakorey: BattakoreyImage
    private let menu: BattakoreyMenu
    private let batteryProvider: BatteryInfoProviding
    private let preferencesModel: BatteryPreferencesModel
    private lazy var preferencesController = BattakoreyPreferencesWindowController(
        model: preferencesModel
    )
    private var latestBattery: BatterySnapshot?
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
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        updateTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(refreshBattery),
            userInfo: nil,
            repeats: true
        )
        updateBattery()
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
    }

    @objc private func refreshBattery() {
        updateBattery()
    }

    private func updateBattery() {
        guard let battery = batteryProvider.snapshot() else { return }
        latestBattery = battery
        let percentage = CGFloat(battery.chargePercentage)
        if battakorey.percentage != percentage {
            battakorey.percentage = percentage
        }
        if battakorey.isCharging != battery.isCharging {
            battakorey.isCharging = battery.isCharging
        }
        menu.update(with: battery, visibility: preferencesModel.visibility)
    }
}
