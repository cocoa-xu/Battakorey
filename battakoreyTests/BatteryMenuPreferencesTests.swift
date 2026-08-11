import XCTest
@testable import battakorey

final class BatteryMenuPreferencesTests: XCTestCase {
    func testUsesRecommendedItemsWhenNoPreferenceIsStored() {
        let store = MockBatteryPreferencesStore()
        let model = BatteryPreferencesModel(store: store)

        XCTAssertEqual(model.visibility, .recommended)
        XCTAssertEqual(model.visibility.visibleItemIDs, [
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
        ])
        XCTAssertFalse(model.visibility.showsSectionTitles)
        XCTAssertTrue(store.values.isEmpty)
        XCTAssertTrue(store.booleans.isEmpty)
    }

    func testPersistsChangesAndNotifiesTheMenu() {
        let store = MockBatteryPreferencesStore()
        let model = BatteryPreferencesModel(store: store)
        var receivedVisibility: BatteryMenuVisibility?
        model.onChange = { receivedVisibility = $0 }

        model.setVisible(true, for: .cellVoltages)

        XCTAssertTrue(model.isVisible(.cellVoltages))
        XCTAssertEqual(receivedVisibility, model.visibility)
        XCTAssertEqual(
            Set(store.values[BatteryPreferencesModel.storageKey] ?? []),
            Set(model.visibility.visibleItemIDs.map(\.rawValue))
        )
        XCTAssertEqual(store.booleans[BatteryPreferencesModel.sectionTitlesStorageKey], false)
        XCTAssertEqual(
            store.booleans[BatteryPreferencesModel.missingBatteryWarningStorageKey],
            true
        )
    }

    func testRestoresAnEmptySelectionAndIgnoresUnknownItems() {
        let key = BatteryPreferencesModel.storageKey
        let emptyModel = BatteryPreferencesModel(
            store: MockBatteryPreferencesStore(values: [key: []])
        )
        let restoredModel = BatteryPreferencesModel(
            store: MockBatteryPreferencesStore(values: [key: ["temperature", "futureMetric"]])
        )
        let hiddenTitlesModel = BatteryPreferencesModel(store: MockBatteryPreferencesStore(
            values: [key: ["temperature"]],
            booleans: [BatteryPreferencesModel.sectionTitlesStorageKey: false]
        ))

        XCTAssertEqual(emptyModel.visibility.visibleItemIDs, [.missingBatteryWarning])
        XCTAssertTrue(emptyModel.visibility.showsSectionTitles)
        XCTAssertEqual(
            restoredModel.visibility.visibleItemIDs,
            [.missingBatteryWarning, .temperature]
        )
        XCTAssertTrue(restoredModel.visibility.showsSectionTitles)
        XCTAssertFalse(hiddenTitlesModel.visibility.showsSectionTitles)
    }

    func testPersistsAndRestoresDisabledMissingBatteryWarning() {
        let store = MockBatteryPreferencesStore()
        let model = BatteryPreferencesModel(store: store)

        model.setVisible(false, for: .missingBatteryWarning)

        XCTAssertFalse(model.isVisible(.missingBatteryWarning))
        XCTAssertEqual(
            store.booleans[BatteryPreferencesModel.missingBatteryWarningStorageKey],
            false
        )

        let restoredModel = BatteryPreferencesModel(store: store)

        XCTAssertFalse(restoredModel.isVisible(.missingBatteryWarning))
        XCTAssertTrue(restoredModel.isVisible(.status))
    }

    func testPersistsSectionTitlePreference() {
        let store = MockBatteryPreferencesStore()
        let model = BatteryPreferencesModel(store: store)

        model.setShowsSectionTitles(true)

        XCTAssertTrue(model.visibility.showsSectionTitles)
        XCTAssertEqual(store.booleans[BatteryPreferencesModel.sectionTitlesStorageKey], true)
    }

    func testPresetsReplaceTheCurrentSelection() {
        let store = MockBatteryPreferencesStore(values: [
            BatteryPreferencesModel.storageKey: [BatteryMenuItemID.voltage.rawValue]
        ])
        let model = BatteryPreferencesModel(store: store)

        model.showAllItems()
        XCTAssertEqual(model.visibility, .all)
        XCTAssertTrue(model.visibility.showsSectionTitles)

        model.useRecommendedItems()
        XCTAssertEqual(model.visibility, .recommended)
        XCTAssertFalse(model.visibility.showsSectionTitles)
    }

    func testBatteryFreeDesktopHidesOnlyBatterySpecificOptionsByDefault() {
        let model = BatteryPreferencesModel(store: MockBatteryPreferencesStore())

        model.updateAvailability(
            hasBattery: false,
            hardwareProfile: HardwareProfile(machineName: "Mac mini")
        )

        XCTAssertEqual(model.availability.batteryFreeDesktopName, "Mac mini")
        XCTAssertFalse(model.showsPreference(.missingBatteryWarning))
        XCTAssertFalse(model.showsPreference(.batteryLevel))
        XCTAssertFalse(model.showsPreference(.cycles))
        XCTAssertFalse(model.showsPreference(.cellVoltages))
        XCTAssertTrue(model.showsPreference(.status))
        XCTAssertTrue(model.showsPreference(.systemDraw))
        XCTAssertTrue(model.showsPreference(.adapterRating))
        XCTAssertTrue(model.showsPreference(.liveInput))
        XCTAssertTrue(model.showsPreference(.cpuPower))

        model.setShowsBatteryOnlyPreferences(true)

        XCTAssertTrue(model.showsPreference(.missingBatteryWarning))
        XCTAssertTrue(model.showsPreference(.batteryLevel))
        XCTAssertTrue(model.showsPreference(.cycles))
        XCTAssertTrue(model.showsPreference(.cellVoltages))

        model.updateAvailability(
            hasBattery: false,
            hardwareProfile: HardwareProfile(machineName: "Mac mini")
        )

        XCTAssertTrue(model.showsBatteryOnlyPreferences)
        XCTAssertTrue(model.showsPreference(.batteryLevel))
    }

    func testBatteryOrUnrecognizedHardwareKeepsPreferencesAvailable() {
        let model = BatteryPreferencesModel(store: MockBatteryPreferencesStore())

        model.updateAvailability(
            hasBattery: false,
            hardwareProfile: HardwareProfile(machineName: "Future Mac")
        )
        XCTAssertNil(model.availability.batteryFreeDesktopName)
        XCTAssertTrue(model.showsPreference(.batteryLevel))

        model.updateAvailability(
            hasBattery: false,
            hardwareProfile: HardwareProfile(machineName: "MacBook Pro")
        )
        XCTAssertNil(model.availability.batteryFreeDesktopName)
        XCTAssertTrue(model.showsPreference(.missingBatteryWarning))
        XCTAssertTrue(model.showsPreference(.batteryLevel))

        model.updateAvailability(
            hasBattery: true,
            hardwareProfile: HardwareProfile(machineName: "Mac mini")
        )
        XCTAssertNil(model.availability.batteryFreeDesktopName)
        XCTAssertTrue(model.showsPreference(.batteryLevel))
    }

    func testNewDesktopDetectionRestoresTheHiddenDefault() {
        let model = BatteryPreferencesModel(store: MockBatteryPreferencesStore())
        model.setShowsBatteryOnlyPreferences(true)

        model.updateAvailability(
            hasBattery: false,
            hardwareProfile: HardwareProfile(machineName: "Mac Studio")
        )

        XCTAssertFalse(model.showsBatteryOnlyPreferences)
        XCTAssertFalse(model.showsPreference(.batteryLevel))
    }
}

private final class MockBatteryPreferencesStore: BatteryPreferencesStoring {
    var values: [String: [String]]
    var booleans: [String: Bool]

    init(
        values: [String: [String]] = [:],
        booleans: [String: Bool] = [:]
    ) {
        self.values = values
        self.booleans = booleans
    }

    func stringArray(forKey key: String) -> [String]? {
        values[key]
    }

    func setStringArray(_ value: [String], forKey key: String) {
        values[key] = value
    }

    func boolean(forKey key: String) -> Bool? {
        booleans[key]
    }

    func setBoolean(_ value: Bool, forKey key: String) {
        booleans[key] = value
    }
}
