import Cocoa

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarItem: NSStatusItem
    private let battakorey: BattakoreyImage
    private let menu: BattakoreyMenu
    private let batteryMonitor: BatteryMonitor
    private let preferencesModel: BatteryPreferencesModel
    private let automationSettings: BatteryAutomationSettings
    private let automationState: BatteryAutomationState
    private let automationServer: BatteryAutomationServer
    private lazy var preferencesController = BattakoreyPreferencesWindowController(
        model: preferencesModel,
        automationSettings: automationSettings
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
        let preferencesModel = BatteryPreferencesModel()
        self.preferencesModel = preferencesModel
        automationSettings = BatteryAutomationSettings()
        let automationState = BatteryAutomationState(visibility: preferencesModel.visibility)
        self.automationState = automationState
        automationServer = BatteryAutomationServer(state: automationState)
        super.init()

        statusBarItem.menu = menu
        statusBarItem.button?.addSubview(battakorey)
        menu.preferencesHandler = { [weak self] in
            self?.preferencesController.show()
        }
        menu.prepare()
        preferencesModel.onChange = { [weak self] visibility in
            guard let self else { return }
            self.automationState.update(visibility: visibility)
            self.automationSettings.refreshExposure()
            guard let battery = self.latestBattery else { return }
            self.menu.update(with: battery, visibility: visibility)
        }
        batteryMonitor.onSnapshot = { [weak self] battery in
            self?.update(with: battery)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        automationSettings.attach(server: automationServer)
        batteryMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        batteryMonitor.stop()
        automationSettings.stop()
    }

    private func update(with battery: BatterySnapshot) {
        latestBattery = battery
        automationState.update(snapshot: battery)
        preferencesModel.updateAvailability(
            hasBattery: battery.hasBattery,
            hardwareProfile: battery.hardwareProfile
        )
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
