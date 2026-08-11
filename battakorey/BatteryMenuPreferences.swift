import Combine
import Foundation

enum BatteryMenuItemID: String, CaseIterable, Hashable {
    case missingBatteryWarning
    case batteryLevel
    case status
    case powerSource
    case timeRemaining
    case currentCharge
    case fullCharge
    case rawMaximum
    case designCapacity
    case capacityRetention
    case maximumCapacity
    case batteryCondition
    case cycles
    case temperature
    case voltage
    case current
    case batteryPower
    case chargeTarget
    case systemDraw
    case cpuPower
    case gpuPower
    case anePower
    case memoryPower
    case gpuMemoryPower
    case displayPower
    case externalDisplayPower
    case adapterRating
    case powerContract
    case liveInput
    case dcInputRail
    case pdContract
    case optimizedCharging
    case lowPowerMode
    case failureStatus
    case cellDisconnects
    case notChargingReason
    case slowChargingReason
    case chargeInterruption
    case adapterErrors
    case publicHealthHint
    case capacityEstimated
    case batteryFailureModes
    case thermalPressure
    case cpuPowerLimits
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

extension BatteryMenuItemID {
    var requiresBattery: Bool {
        switch self {
        case .batteryLevel,
             .timeRemaining,
             .currentCharge,
             .fullCharge,
             .rawMaximum,
             .designCapacity,
             .capacityRetention,
             .maximumCapacity,
             .batteryCondition,
             .cycles,
             .temperature,
             .voltage,
             .current,
             .batteryPower,
             .chargeTarget,
             .optimizedCharging,
             .failureStatus,
             .cellDisconnects,
             .notChargingReason,
             .slowChargingReason,
             .chargeInterruption,
             .publicHealthHint,
             .capacityEstimated,
             .batteryFailureModes,
             .cellVoltages,
             .cellVoltageDelta,
             .learnedQmax,
             .qmaxDelta,
             .resistance,
             .resistanceDelta,
             .dailyChargeRange,
             .lastGaugeRelearn,
             .dataFlashWrites,
             .rsenseOpenEvents,
             .qmaxDisqualification,
             .lifetimeTemperatures,
             .packVoltageRange,
             .peakCurrent,
             .operatingTime:
            return true
        case .missingBatteryWarning,
             .status,
             .powerSource,
             .systemDraw,
             .cpuPower,
             .gpuPower,
             .anePower,
             .memoryPower,
             .gpuMemoryPower,
             .displayPower,
             .externalDisplayPower,
             .adapterRating,
             .powerContract,
             .liveInput,
             .dcInputRail,
             .pdContract,
             .lowPowerMode,
             .adapterErrors,
             .thermalPressure,
             .cpuPowerLimits:
            return false
        }
    }

    var isAvailableOnBatteryFreeDesktop: Bool {
        !requiresBattery && self != .missingBatteryWarning
    }
}

struct BatteryMenuAvailability: Equatable {
    let batteryFreeDesktopName: String?

    static let unknown = BatteryMenuAvailability(batteryFreeDesktopName: nil)

    func allows(_ itemID: BatteryMenuItemID) -> Bool {
        batteryFreeDesktopName == nil || itemID.isAvailableOnBatteryFreeDesktop
    }
}

struct BatteryMenuVisibility: Equatable {
    let visibleItemIDs: Set<BatteryMenuItemID>
    let showsSectionTitles: Bool

    init(
        visibleItemIDs: Set<BatteryMenuItemID>,
        showsSectionTitles: Bool = true
    ) {
        self.visibleItemIDs = visibleItemIDs
        self.showsSectionTitles = showsSectionTitles
    }

    static let all = BatteryMenuVisibility(
        visibleItemIDs: Set(BatteryMenuItemID.allCases),
        showsSectionTitles: true
    )

    static let recommended = BatteryMenuVisibility(
        visibleItemIDs: [
            .missingBatteryWarning,
            .batteryLevel,
            .status,
            .powerSource,
            .timeRemaining,
            .currentCharge,
            .fullCharge,
            .maximumCapacity,
            .batteryCondition,
            .batteryPower,
            .cycles,
            .systemDraw,
            .adapterRating,
            .liveInput
        ],
        showsSectionTitles: false
    )

    func contains(_ itemID: BatteryMenuItemID) -> Bool {
        visibleItemIDs.contains(itemID)
    }
}

protocol BatteryPreferencesStoring {
    func stringArray(forKey key: String) -> [String]?
    func setStringArray(_ value: [String], forKey key: String)
    func boolean(forKey key: String) -> Bool?
    func setBoolean(_ value: Bool, forKey key: String)
}

extension UserDefaults: BatteryPreferencesStoring {
    func setStringArray(_ value: [String], forKey key: String) {
        set(value, forKey: key)
    }

    func boolean(forKey key: String) -> Bool? {
        object(forKey: key) as? Bool
    }

    func setBoolean(_ value: Bool, forKey key: String) {
        set(value, forKey: key)
    }
}

final class BatteryPreferencesModel: ObservableObject {
    static let storageKey = "VisibleBatteryMenuItems"
    static let sectionTitlesStorageKey = "ShowsBatteryMenuSectionTitles"
    static let missingBatteryWarningStorageKey = "ShowsMissingBatteryWarning"

    @Published private(set) var visibility: BatteryMenuVisibility
    @Published private(set) var availability = BatteryMenuAvailability.unknown
    var onChange: ((BatteryMenuVisibility) -> Void)?

    private let store: BatteryPreferencesStoring
    private let storageKey: String

    init(
        store: BatteryPreferencesStoring = UserDefaults.standard,
        storageKey: String = BatteryPreferencesModel.storageKey
    ) {
        self.store = store
        self.storageKey = storageKey

        let storedItemIDs = store.stringArray(forKey: storageKey)
        var visibleItemIDs = storedItemIDs.map {
            Set($0.compactMap(BatteryMenuItemID.init(rawValue:)))
        } ?? BatteryMenuVisibility.recommended.visibleItemIDs
        if store.boolean(forKey: Self.missingBatteryWarningStorageKey) ?? true {
            visibleItemIDs.insert(.missingBatteryWarning)
        } else {
            visibleItemIDs.remove(.missingBatteryWarning)
        }
        let showsSectionTitles = store.boolean(forKey: Self.sectionTitlesStorageKey)
            ?? (storedItemIDs == nil ? BatteryMenuVisibility.recommended.showsSectionTitles : true)
        visibility = BatteryMenuVisibility(
            visibleItemIDs: visibleItemIDs,
            showsSectionTitles: showsSectionTitles
        )
    }

    func isVisible(_ itemID: BatteryMenuItemID) -> Bool {
        visibility.contains(itemID)
    }

    func isAvailable(_ itemID: BatteryMenuItemID) -> Bool {
        availability.allows(itemID)
    }

    func updateAvailability(hasBattery: Bool, hardwareProfile: HardwareProfile?) {
        let desktopName = !hasBattery && hardwareProfile?.isDesktopMac == true
            ? hardwareProfile?.machineName
            : nil
        let availability = BatteryMenuAvailability(batteryFreeDesktopName: desktopName)
        guard self.availability != availability else { return }
        self.availability = availability
    }

    func setVisible(_ isVisible: Bool, for itemID: BatteryMenuItemID) {
        var visibleItemIDs = visibility.visibleItemIDs
        if isVisible {
            visibleItemIDs.insert(itemID)
        } else {
            visibleItemIDs.remove(itemID)
        }
        update(BatteryMenuVisibility(
            visibleItemIDs: visibleItemIDs,
            showsSectionTitles: visibility.showsSectionTitles
        ))
    }

    func setShowsSectionTitles(_ showsSectionTitles: Bool) {
        update(BatteryMenuVisibility(
            visibleItemIDs: visibility.visibleItemIDs,
            showsSectionTitles: showsSectionTitles
        ))
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
        store.setBoolean(
            visibility.showsSectionTitles,
            forKey: Self.sectionTitlesStorageKey
        )
        store.setBoolean(
            visibility.contains(.missingBatteryWarning),
            forKey: Self.missingBatteryWarningStorageKey
        )
        onChange?(visibility)
    }
}
