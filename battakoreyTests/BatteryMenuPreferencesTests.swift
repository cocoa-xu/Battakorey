import XCTest
@testable import battakorey

final class BatteryMenuPreferencesTests: XCTestCase {
    func testUsesRecommendedItemsWhenNoPreferenceIsStored() {
        let store = MockBatteryPreferencesStore()
        let model = BatteryPreferencesModel(store: store)

        XCTAssertEqual(model.visibility, .recommended)
        XCTAssertTrue(model.isVisible(.batteryLevel))
        XCTAssertFalse(model.isVisible(.cellVoltages))
        XCTAssertTrue(store.values.isEmpty)
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
    }

    func testRestoresAnEmptySelectionAndIgnoresUnknownItems() {
        let key = BatteryPreferencesModel.storageKey
        let emptyModel = BatteryPreferencesModel(
            store: MockBatteryPreferencesStore(values: [key: []])
        )
        let restoredModel = BatteryPreferencesModel(
            store: MockBatteryPreferencesStore(values: [key: ["temperature", "futureMetric"]])
        )

        XCTAssertTrue(emptyModel.visibility.visibleItemIDs.isEmpty)
        XCTAssertEqual(restoredModel.visibility.visibleItemIDs, [.temperature])
    }

    func testPresetsReplaceTheCurrentSelection() {
        let store = MockBatteryPreferencesStore(values: [
            BatteryPreferencesModel.storageKey: [BatteryMenuItemID.voltage.rawValue]
        ])
        let model = BatteryPreferencesModel(store: store)

        model.showAllItems()
        XCTAssertEqual(model.visibility, .all)

        model.useRecommendedItems()
        XCTAssertEqual(model.visibility, .recommended)
    }
}

private final class MockBatteryPreferencesStore: BatteryPreferencesStoring {
    var values: [String: [String]]

    init(values: [String: [String]] = [:]) {
        self.values = values
    }

    func stringArray(forKey key: String) -> [String]? {
        values[key]
    }

    func setStringArray(_ value: [String], forKey key: String) {
        values[key] = value
    }
}
