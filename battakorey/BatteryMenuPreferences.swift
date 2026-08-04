import Combine
import Foundation

enum BatteryMenuItemID: String, CaseIterable, Hashable {
    case batteryLevel
    case status
    case powerSource
    case timeRemaining
    case currentCharge
    case fullCharge
    case rawMaximum
    case designCapacity
    case capacityRetention
    case cycles
    case temperature
    case voltage
    case current
    case batteryPower
    case systemDraw
    case adapterRating
    case powerContract
    case liveInput
    case dcInputRail
    case optimizedCharging
    case lowPowerMode
    case failureStatus
    case cellDisconnects
    case notChargingReason
    case slowChargingReason
    case cellVoltages
    case cellVoltageDelta
    case learnedQmax
    case qmaxDelta
    case resistance
    case resistanceDelta
    case dailyChargeRange
    case lastGaugeRelearn
    case dataFlashWrites
    case rsenseOpenEvents
    case qmaxDisqualification
    case lifetimeTemperatures
    case packVoltageRange
    case peakCurrent
    case operatingTime
}

struct BatteryMenuVisibility: Equatable {
    let visibleItemIDs: Set<BatteryMenuItemID>

    static let all = BatteryMenuVisibility(visibleItemIDs: Set(BatteryMenuItemID.allCases))

    static let recommended = BatteryMenuVisibility(visibleItemIDs: [
        .batteryLevel,
        .status,
        .powerSource,
        .timeRemaining,
        .capacityRetention,
        .cycles,
        .temperature,
        .batteryPower,
        .systemDraw,
        .adapterRating,
        .liveInput,
        .optimizedCharging,
        .lowPowerMode
    ])

    func contains(_ itemID: BatteryMenuItemID) -> Bool {
        visibleItemIDs.contains(itemID)
    }
}

protocol BatteryPreferencesStoring {
    func stringArray(forKey key: String) -> [String]?
    func setStringArray(_ value: [String], forKey key: String)
}

extension UserDefaults: BatteryPreferencesStoring {
    func setStringArray(_ value: [String], forKey key: String) {
        set(value, forKey: key)
    }
}

final class BatteryPreferencesModel: ObservableObject {
    static let storageKey = "VisibleBatteryMenuItems"

    @Published private(set) var visibility: BatteryMenuVisibility
    var onChange: ((BatteryMenuVisibility) -> Void)?

    private let store: BatteryPreferencesStoring
    private let storageKey: String

    init(
        store: BatteryPreferencesStoring = UserDefaults.standard,
        storageKey: String = BatteryPreferencesModel.storageKey
    ) {
        self.store = store
        self.storageKey = storageKey

        if let storedItemIDs = store.stringArray(forKey: storageKey) {
            visibility = BatteryMenuVisibility(visibleItemIDs: Set(
                storedItemIDs.compactMap(BatteryMenuItemID.init(rawValue:))
            ))
        } else {
            visibility = .recommended
        }
    }

    func isVisible(_ itemID: BatteryMenuItemID) -> Bool {
        visibility.contains(itemID)
    }

    func setVisible(_ isVisible: Bool, for itemID: BatteryMenuItemID) {
        var visibleItemIDs = visibility.visibleItemIDs
        if isVisible {
            visibleItemIDs.insert(itemID)
        } else {
            visibleItemIDs.remove(itemID)
        }
        update(BatteryMenuVisibility(visibleItemIDs: visibleItemIDs))
    }

    func useRecommendedItems() {
        update(.recommended)
    }

    func showAllItems() {
        update(.all)
    }

    private func update(_ visibility: BatteryMenuVisibility) {
        guard self.visibility != visibility else { return }
        self.visibility = visibility
        store.setStringArray(
            visibility.visibleItemIDs.map(\.rawValue).sorted(),
            forKey: storageKey
        )
        onChange?(visibility)
    }
}
