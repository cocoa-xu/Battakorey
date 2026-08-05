import XCTest
@testable import battakorey

final class BatteryMonitorTests: XCTestCase {
    func testSamplesOffMainThreadAndPublishesOnMainThread() {
        let provider = MonitorBatteryProvider()
        let monitor = BatteryMonitor(provider: provider)
        let published = expectation(description: "Publishes a battery snapshot")

        monitor.onSnapshot = { _ in
            XCTAssertTrue(Thread.isMainThread)
            published.fulfill()
        }
        monitor.start()

        wait(for: [published], timeout: 2)
        monitor.stop()
        XCTAssertFalse(provider.sampledOnMainThread)
    }
}

private final class MonitorBatteryProvider: BatteryInfoProviding {
    private(set) var sampledOnMainThread = true

    func snapshot() -> BatterySnapshot? {
        sampledOnMainThread = Thread.isMainThread
        return BatterySnapshot(rawData: MockBatteryData.discharging)
    }

    func powerSourceDidChange() {}
}
