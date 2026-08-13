import XCTest
@testable import battakorey

@MainActor
final class BattakoreyMenuTests: XCTestCase {
    func testMenuDefersBatteryRowsUntilItOpens() throws {
        let menu = BattakoreyMenu()
        let battery = try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.discharging))
        menu.prepare()
        let placeholderItemCount = menu.items.count

        menu.update(with: battery, visibility: .recommended)

        XCTAssertEqual(menu.items.count, placeholderItemCount)

        menu.menuWillOpen(menu)

        XCTAssertGreaterThan(menu.items.count, placeholderItemCount)
    }

    func testClosedMenuDefersSubsequentLayoutChanges() throws {
        let menu = BattakoreyMenu()
        let battery = try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.discharging))
        menu.prepare()
        menu.update(with: battery, visibility: .recommended)
        menu.menuWillOpen(menu)
        let visibleItemCount = menu.items.count
        menu.menuDidClose(menu)

        menu.update(with: battery, visibility: .all)

        XCTAssertEqual(menu.items.count, visibleItemCount)

        menu.menuWillOpen(menu)

        XCTAssertGreaterThan(menu.items.count, visibleItemCount)
    }
}
