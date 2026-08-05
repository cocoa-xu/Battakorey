import XCTest
@testable import battakorey

final class PowerObservationTests: XCTestCase {
    func testFreshnessRejectsExpiredAndFutureObservations() {
        let sampledAt = Date(timeIntervalSince1970: 1_000)
        let observation = ElectricalObservation(
            value: 45,
            unit: .watts,
            kind: .measured,
            domain: .input,
            direction: .input,
            source: .smc,
            sampledAt: sampledAt,
            measurementWindow: nil,
            freshnessLimit: 5,
            stability: .privateABI,
            accessTier: .enhanced,
            confidence: .medium
        )

        XCTAssertTrue(observation.isFresh(at: sampledAt.addingTimeInterval(5)))
        XCTAssertFalse(observation.isFresh(at: sampledAt.addingTimeInterval(6)))
        XCTAssertFalse(observation.isFresh(at: sampledAt.addingTimeInterval(-1)))
    }

    func testPowerContractUsesTheSameFreshnessRule() {
        let sampledAt = Date(timeIntervalSince1970: 1_000)
        let contract = PowerContract(
            portNumber: 2,
            voltageVolts: 20,
            currentAmps: 5,
            maximumPowerWatts: 100,
            kind: .contracted,
            direction: .input,
            source: .portRegistry,
            sampledAt: sampledAt,
            freshnessLimit: 5,
            stability: .undocumentedSchema,
            accessTier: .enhanced,
            confidence: .medium
        )

        XCTAssertTrue(contract.isFresh(at: sampledAt.addingTimeInterval(5)))
        XCTAssertFalse(contract.isFresh(at: sampledAt.addingTimeInterval(6)))
        XCTAssertFalse(contract.isFresh(at: sampledAt.addingTimeInterval(-1)))
    }
}
