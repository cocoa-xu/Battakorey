import Foundation
import XCTest
@testable import battakorey

final class BatteryAutomationStateTests: XCTestCase {
    func testCapabilitiesRequireBothMenuVisibilityAndAutomationPermission() throws {
        let state = BatteryAutomationState(visibility: BatteryMenuVisibility(
            visibleItemIDs: [.temperature, .voltage]
        ))
        state.update(
            snapshot: try XCTUnwrap(BatterySnapshot(rawData: MockBatteryData.discharging)),
            sampledAt: Date(timeIntervalSince1970: 1_000)
        )

        XCTAssertEqual(
            state.exposedCapabilities(allowedCapabilities: [.status, .electrical]),
            [.electrical]
        )

        let payload = try XCTUnwrap(state.payload(for: .electrical))
        let readings = try XCTUnwrap(payload["readings"] as? [[String: Any]])
        XCTAssertEqual(
            readings.compactMap { $0["id"] as? String },
            ["temperature", "voltage"]
        )
        XCTAssertEqual(readings.first?["formattedValue"] as? String, "31.2 °C")
        XCTAssertEqual(readings.first?["value"] as? Double, 31.25)
        XCTAssertEqual(readings.first?["unit"] as? String, "celsius")
        XCTAssertEqual(payload["sampledAt"] as? String, "1970-01-01T00:16:40Z")
    }

    func testSnapshotIncludesOnlyAllowedVisibleCapabilities() throws {
        let state = BatteryAutomationState(visibility: BatteryMenuVisibility(
            visibleItemIDs: [.status, .temperature, .cpuPower]
        ))
        state.update(snapshot: try XCTUnwrap(
            BatterySnapshot(rawData: MockBatteryData.discharging)
        ))

        let payload = try XCTUnwrap(state.snapshotPayload(
            allowedCapabilities: [.status, .capacity, .componentPower]
        ))
        let capabilities = try XCTUnwrap(payload["capabilities"] as? [[String: Any]])

        XCTAssertEqual(
            capabilities.compactMap { $0["capability"] as? String },
            ["status", "component-power"]
        )
    }
}

final class AutomationRateLimiterTests: XCTestCase {
    func testUsesAnIndependentSlidingWindowPerClient() {
        let limiter = AutomationRateLimiter()

        XCTAssertTrue(limiter.evaluate(client: "a", limit: 2, now: 100).isAllowed)
        XCTAssertTrue(limiter.evaluate(client: "a", limit: 2, now: 110).isAllowed)

        let blocked = limiter.evaluate(client: "a", limit: 2, now: 120)
        XCTAssertFalse(blocked.isAllowed)
        XCTAssertEqual(blocked.retryAfterSeconds, 40)
        XCTAssertTrue(limiter.evaluate(client: "b", limit: 2, now: 120).isAllowed)
        XCTAssertTrue(limiter.evaluate(client: "a", limit: 2, now: 161).isAllowed)
    }

    func testResetClearsHistory() {
        let limiter = AutomationRateLimiter()
        XCTAssertTrue(limiter.evaluate(client: "client", limit: 1, now: 100).isAllowed)
        XCTAssertFalse(limiter.evaluate(client: "client", limit: 1, now: 101).isAllowed)

        limiter.reset()

        XCTAssertTrue(limiter.evaluate(client: "client", limit: 1, now: 101).isAllowed)
    }

    func testTokenIsURLSafeAndRandom() throws {
        let first = try AutomationToken.generate()
        let second = try AutomationToken.generate()

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first.count, 43)
        XCTAssertTrue(first.allSatisfy {
            $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_"
        })
    }
}

@MainActor
final class BatteryAutomationSettingsTests: XCTestCase {
    func testDefaultsAreSafeAndDoNotReadKeychain() {
        let preferences = MockAutomationPreferencesStore()
        let tokenStore = MockAutomationTokenStore(token: "secret")
        let settings = BatteryAutomationSettings(
            preferences: preferences,
            namespace: "test.",
            tokenStore: tokenStore,
            networkInterfaces: []
        )

        XCTAssertFalse(settings.mcpEnabled)
        XCTAssertFalse(settings.restEnabled)
        XCTAssertTrue(settings.authenticationRequired)
        XCTAssertEqual(settings.bindAddress, "127.0.0.1")
        XCTAssertEqual(settings.port, 18_761)
        XCTAssertEqual(settings.requestsPerMinute, 30)
        XCTAssertEqual(settings.enabledCapabilities, Set(BatteryAutomationCapability.allCases))
        XCTAssertEqual(settings.accessToken, "")
        XCTAssertEqual(tokenStore.loadCount, 0)
        XCTAssertTrue(preferences.values.isEmpty)
    }

    func testEnablingAuthenticatedAccessLoadsTokenOnDemand() {
        let tokenStore = MockAutomationTokenStore(token: "secret")
        let settings = BatteryAutomationSettings(
            preferences: MockAutomationPreferencesStore(),
            namespace: "test.",
            tokenStore: tokenStore,
            networkInterfaces: []
        )

        settings.mcpEnabled = true

        XCTAssertEqual(settings.accessToken, "secret")
        XCTAssertEqual(tokenStore.loadCount, 1)
    }

    func testReadsStringOverridesWithoutTouchingKeychainWhenAuthenticationIsDisabled() {
        let preferences = MockAutomationPreferencesStore(values: [
            "test.mcpEnabled": "YES",
            "test.authenticationRequired": "NO",
            "test.port": "20000",
            "test.requestsPerMinute": "45"
        ])
        let tokenStore = MockAutomationTokenStore(token: "secret")
        let settings = BatteryAutomationSettings(
            preferences: preferences,
            namespace: "test.",
            tokenStore: tokenStore,
            networkInterfaces: []
        )

        XCTAssertTrue(settings.mcpEnabled)
        XCTAssertFalse(settings.authenticationRequired)
        XCTAssertEqual(settings.port, 20_000)
        XCTAssertEqual(settings.requestsPerMinute, 45)
        XCTAssertEqual(tokenStore.loadCount, 0)
    }

    func testPersistsServerAndExposureChoices() {
        let preferences = MockAutomationPreferencesStore()
        let settings = BatteryAutomationSettings(
            preferences: preferences,
            namespace: "test.",
            tokenStore: MockAutomationTokenStore(token: "secret"),
            networkInterfaces: []
        )

        settings.mcpEnabled = true
        settings.authenticationRequired = false
        settings.port = 20_000
        settings.requestsPerMinute = 45
        settings.toggleCapability(.diagnostics)

        XCTAssertEqual(preferences.values["test.mcpEnabled"] as? Bool, true)
        XCTAssertEqual(preferences.values["test.authenticationRequired"] as? Bool, false)
        XCTAssertEqual(preferences.values["test.port"] as? Int, 20_000)
        XCTAssertEqual(preferences.values["test.requestsPerMinute"] as? Int, 45)
        let storedCapabilities = Set(
            preferences.values["test.enabledCapabilities"] as? [String] ?? []
        )
        XCTAssertFalse(storedCapabilities.contains("diagnostics"))
        XCTAssertFalse(settings.claudeInstallCommand.contains("Authorization"))
        XCTAssertFalse(settings.restExampleCommand.contains("Authorization"))
    }
}

final class BatteryAutomationServerTests: XCTestCase {
    func testRequiresBearerAuthenticationByDefault() async throws {
        let state = try populatedState(visibility: [.status])
        let server = BatteryAutomationServer(state: state)
        let port = try start(server, authenticationRequired: true)
        defer { server.stop() }

        let response = try await request(
            port: port,
            path: "/api/v1",
            method: "GET"
        )

        XCTAssertEqual(response.status, 401)
        XCTAssertEqual(response.json["error"] as? String, "Unauthorized")
    }

    func testAuthenticationCanBeDisabledExplicitly() async throws {
        let state = try populatedState(visibility: [.status])
        let server = BatteryAutomationServer(state: state)
        let port = try start(server, authenticationRequired: false)
        defer { server.stop() }

        let response = try await request(
            port: port,
            path: "/api/v1/snapshot",
            method: "GET"
        )

        XCTAssertEqual(response.status, 200)
        XCTAssertNotNil(response.json["capabilities"] as? [[String: Any]])
    }

    func testMCPListsOnlyCapabilitiesPermittedByBothLayers() async throws {
        let state = try populatedState(visibility: [.temperature])
        let server = BatteryAutomationServer(state: state)
        let port = try start(
            server,
            authenticationRequired: true,
            capabilities: [.status, .electrical]
        )
        defer { server.stop() }

        let response = try await request(
            port: port,
            path: "/mcp",
            token: "test-token",
            body: ["jsonrpc": "2.0", "id": 1, "method": "tools/list"]
        )
        let result = try XCTUnwrap(response.json["result"] as? [String: Any])
        let tools = try XCTUnwrap(result["tools"] as? [[String: Any]])

        XCTAssertEqual(
            tools.compactMap { $0["name"] as? String },
            ["battery_get_snapshot", "battery_get_electrical"]
        )
    }

    func testRESTReturnsStableFilteredReadingIdentifiers() async throws {
        let state = try populatedState(visibility: [.temperature, .voltage, .cycles])
        let server = BatteryAutomationServer(state: state)
        let port = try start(
            server,
            authenticationRequired: true,
            capabilities: [.electrical]
        )
        defer { server.stop() }

        let response = try await request(
            port: port,
            path: "/api/v1/readings/electrical",
            method: "GET",
            token: "test-token"
        )
        let readings = try XCTUnwrap(response.json["readings"] as? [[String: Any]])

        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(
            readings.compactMap { $0["id"] as? String },
            ["temperature", "voltage"]
        )

        let hidden = try await request(
            port: port,
            path: "/api/v1/readings/capacity",
            method: "GET",
            token: "test-token"
        )
        XCTAssertEqual(hidden.status, 404)
    }

    func testRateLimitsEachClient() async throws {
        let state = try populatedState(visibility: [.status])
        let server = BatteryAutomationServer(state: state)
        let port = try start(
            server,
            authenticationRequired: false,
            requestsPerMinute: 1
        )
        defer { server.stop() }

        let allowed = try await request(port: port, path: "/api/v1", method: "GET")
        let blocked = try await request(port: port, path: "/api/v1", method: "GET")

        XCTAssertEqual(allowed.status, 200)
        XCTAssertEqual(blocked.status, 429)
        XCTAssertEqual(blocked.json["error"] as? String, "Rate limit exceeded")
    }

    private func populatedState(
        visibility: Set<BatteryMenuItemID>
    ) throws -> BatteryAutomationState {
        let state = BatteryAutomationState(visibility: BatteryMenuVisibility(
            visibleItemIDs: visibility
        ))
        state.update(snapshot: try XCTUnwrap(
            BatterySnapshot(rawData: MockBatteryData.discharging)
        ))
        return state
    }

    private func start(
        _ server: BatteryAutomationServer,
        authenticationRequired: Bool,
        capabilities: Set<BatteryAutomationCapability> = Set(BatteryAutomationCapability.allCases),
        requestsPerMinute: Int = 1_000
    ) throws -> Int {
        for port in 19_800 ... 19_860 {
            do {
                try server.start(configuration: BatteryAutomationServer.Configuration(
                    address: "127.0.0.1",
                    port: UInt16(port),
                    token: "test-token",
                    authenticationRequired: authenticationRequired,
                    mcpEnabled: true,
                    restEnabled: true,
                    enabledCapabilities: capabilities,
                    requestsPerMinute: requestsPerMinute
                ))
                if server.isRunning { return port }
            } catch {
                continue
            }
        }
        throw XCTSkip("No free automation test port")
    }

    private func request(
        port: Int,
        path: String,
        method: String = "POST",
        token: String? = nil,
        body: [String: Any]? = nil
    ) async throws -> AutomationTestResponse {
        var request = URLRequest(url: try XCTUnwrap(
            URL(string: "http://127.0.0.1:\(port)\(path)")
        ))
        request.httpMethod = method
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        let (data, response) = try await URLSession(configuration: configuration).data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        let json = data.isEmpty
            ? [:]
            : try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return AutomationTestResponse(status: http.statusCode, json: json)
    }
}

private struct AutomationTestResponse {
    let status: Int
    let json: [String: Any]
}

private final class MockAutomationPreferencesStore: AutomationPreferencesStoring {
    var values: [String: Any]

    init(values: [String: Any] = [:]) {
        self.values = values
    }

    func object(forKey defaultName: String) -> Any? {
        values[defaultName]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        values[defaultName] = value
    }
}

private final class MockAutomationTokenStore: AutomationTokenStoring {
    private var token: String?
    private(set) var loadCount = 0

    init(token: String?) {
        self.token = token
    }

    func loadToken() throws -> String? {
        loadCount += 1
        return token
    }

    func saveToken(_ token: String) throws {
        self.token = token
    }
}
