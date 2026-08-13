import Bondry
import BondryApple
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
            ["battery.status", "battery.component-power"]
        )
        XCTAssertNotNil(payload["sampledAt"] as? String)
        XCTAssertTrue(capabilities.allSatisfy { $0["sampledAt"] == nil })
    }
}

@MainActor
final class BatteryAutomationSettingsTests: XCTestCase {
    func testDefaultsAreSafeWithoutPreparingAutomationStorage() {
        let preferences = MockAutomationPreferencesStore()
        let settings = BatteryAutomationSettings(
            preferences: preferences,
            namespace: "test.",
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
        XCTAssertTrue(preferences.values.isEmpty)
    }

    func testEnablingAuthenticatedAccessLoadsBondryTokenOnDemand() {
        let server = MockBatteryAutomationServer(accessToken: "secret")
        let settings = BatteryAutomationSettings(
            preferences: MockAutomationPreferencesStore(),
            namespace: "test.",
            networkInterfaces: []
        )
        settings.attach(server: server)

        settings.mcpEnabled = true

        XCTAssertEqual(settings.accessToken, "secret")
        XCTAssertEqual(server.accessTokenCallCount, 1)
        XCTAssertEqual(server.configurations.last?.mcpEnabled, true)
    }

    func testReadsStringOverridesWithoutPreparingTokenWhenAuthenticationIsDisabled() {
        let preferences = MockAutomationPreferencesStore(values: [
            "test.mcpEnabled": "YES",
            "test.authenticationRequired": "NO",
            "test.port": "20000",
            "test.requestsPerMinute": "45"
        ])
        let settings = BatteryAutomationSettings(
            preferences: preferences,
            namespace: "test.",
            networkInterfaces: []
        )

        XCTAssertTrue(settings.mcpEnabled)
        XCTAssertFalse(settings.authenticationRequired)
        XCTAssertEqual(settings.port, 20_000)
        XCTAssertEqual(settings.requestsPerMinute, 45)
        XCTAssertEqual(settings.accessToken, "")
    }

    func testPersistsServerAndExposureChoices() {
        let preferences = MockAutomationPreferencesStore()
        let settings = BatteryAutomationSettings(
            preferences: preferences,
            namespace: "test.",
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
        XCTAssertTrue(settings.restExampleCommand.contains("battery.snapshot"))
    }

    func testRegeneratingTokenRestartsWithTheNewCredential() {
        let server = MockBatteryAutomationServer(accessToken: "first", regeneratedToken: "second")
        let settings = BatteryAutomationSettings(
            preferences: MockAutomationPreferencesStore(),
            namespace: "test.",
            networkInterfaces: []
        )
        settings.attach(server: server)
        settings.restEnabled = true
        let startCount = server.configurations.count

        settings.regenerateAccessToken()

        XCTAssertEqual(settings.accessToken, "second")
        XCTAssertEqual(server.regenerateTokenCallCount, 1)
        XCTAssertEqual(server.configurations.count, startCount + 1)
    }

    func testDisablingAutomationStopsServerAndClearsPresentedToken() {
        let server = MockBatteryAutomationServer(accessToken: "secret")
        let settings = BatteryAutomationSettings(
            preferences: MockAutomationPreferencesStore(),
            namespace: "test.",
            networkInterfaces: []
        )
        settings.attach(server: server)
        settings.restEnabled = true
        let stopCount = server.stopCallCount

        settings.restEnabled = false

        XCTAssertEqual(settings.accessToken, "")
        XCTAssertEqual(server.stopCallCount, stopCount + 1)
        XCTAssertFalse(server.isRunning)
    }

    func testRapidRequestLimitChangesCoalesceServerReconfiguration() async {
        let server = MockBatteryAutomationServer(accessToken: "secret")
        let settings = BatteryAutomationSettings(
            preferences: MockAutomationPreferencesStore(),
            namespace: "test.",
            networkInterfaces: []
        )
        settings.attach(server: server)
        settings.restEnabled = true
        let startCount = server.configurations.count

        settings.requestsPerMinute = 31
        settings.requestsPerMinute = 60
        settings.requestsPerMinute = 100

        XCTAssertEqual(server.configurations.count, startCount)

        try? await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(server.configurations.count, startCount + 1)
        XCTAssertEqual(server.configurations.last?.requestsPerMinute, 100)
    }
}

final class BatteryAutomationServerTests: XCTestCase {
    func testRequiresBearerAuthenticationByDefault() async throws {
        let fixture = try AutomationServerFixture(
            state: populatedState(visibility: [.status])
        )
        let token = try fixture.server.accessToken()
        let port = try start(fixture.server, authenticationRequired: true)

        let rejected = try await request(port: port, path: "/api/v1", method: "GET")
        let accepted = try await request(
            port: port,
            path: "/api/v1",
            method: "GET",
            token: token
        )

        XCTAssertEqual(rejected.status, 401)
        XCTAssertEqual(accepted.status, 200)
    }

    func testAuthenticationCanBeDisabledExplicitly() async throws {
        let fixture = try AutomationServerFixture(
            state: populatedState(visibility: [.status])
        )
        let port = try start(fixture.server, authenticationRequired: false)

        let response = try await request(
            port: port,
            path: "/api/v1/capabilities/battery.snapshot",
            method: "POST"
        )
        let result = try XCTUnwrap(response.json["result"] as? [String: Any])

        XCTAssertEqual(response.status, 200)
        XCTAssertNotNil(result["capabilities"] as? [[String: Any]])
    }

    func testMCPListsOnlyCapabilitiesPermittedByBothLayers() async throws {
        let fixture = try AutomationServerFixture(
            state: populatedState(visibility: [.temperature])
        )
        let token = try fixture.server.accessToken()
        let port = try start(
            fixture.server,
            authenticationRequired: true,
            capabilities: [.status, .electrical]
        )

        let response = try await request(
            port: port,
            path: "/mcp",
            token: token,
            body: ["jsonrpc": "2.0", "id": 1, "method": "tools/list"]
        )
        let result = try XCTUnwrap(response.json["result"] as? [String: Any])
        let tools = try XCTUnwrap(result["tools"] as? [[String: Any]])

        XCTAssertEqual(
            Set(tools.compactMap { $0["name"] as? String }),
            ["battery.snapshot", "battery.electrical"]
        )
    }

    func testRESTReturnsStableFilteredReadingIdentifiers() async throws {
        let fixture = try AutomationServerFixture(
            state: populatedState(visibility: [.temperature, .voltage, .cycles])
        )
        let token = try fixture.server.accessToken()
        let port = try start(
            fixture.server,
            authenticationRequired: true,
            capabilities: [.electrical]
        )

        let response = try await request(
            port: port,
            path: "/api/v1/capabilities/battery.electrical",
            method: "POST",
            token: token
        )
        let result = try XCTUnwrap(response.json["result"] as? [String: Any])
        let readings = try XCTUnwrap(result["readings"] as? [[String: Any]])

        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(
            readings.compactMap { $0["id"] as? String },
            ["temperature", "voltage"]
        )

        let hidden = try await request(
            port: port,
            path: "/api/v1/capabilities/battery.capacity",
            method: "POST",
            token: token
        )
        XCTAssertEqual(hidden.status, 404)
    }

    func testReconfigurationAppliesLatestMenuVisibility() async throws {
        let state = try populatedState(visibility: [.status])
        let fixture = try AutomationServerFixture(state: state)
        let token = try fixture.server.accessToken()
        var port = try start(fixture.server, authenticationRequired: true)

        let initial = try await request(
            port: port,
            path: "/api/v1/capabilities",
            method: "GET",
            token: token
        )
        state.update(visibility: BatteryMenuVisibility(visibleItemIDs: [.temperature]))
        port = try start(fixture.server, authenticationRequired: true)
        let updated = try await request(
            port: port,
            path: "/api/v1/capabilities",
            method: "GET",
            token: token
        )

        XCTAssertEqual(capabilityIDs(in: initial), ["battery.snapshot", "battery.status"])
        XCTAssertEqual(capabilityIDs(in: updated), ["battery.electrical", "battery.snapshot"])
    }

    func testRateLimitsEachPrincipal() async throws {
        let fixture = try AutomationServerFixture(
            state: populatedState(visibility: [.status])
        )
        let port = try start(
            fixture.server,
            authenticationRequired: false,
            requestsPerMinute: 1
        )

        let allowed = try await request(port: port, path: "/api/v1", method: "GET")
        let blocked = try await request(port: port, path: "/api/v1", method: "GET")

        XCTAssertEqual(allowed.status, 200)
        XCTAssertEqual(blocked.status, 429)
    }

    func testRegeneratingPrimaryTokenRevokesThePreviousToken() async throws {
        let fixture = try AutomationServerFixture(
            state: populatedState(visibility: [.status])
        )
        let first = try fixture.server.accessToken()
        let port = try start(fixture.server, authenticationRequired: true)
        let second = try fixture.server.regenerateAccessToken()

        let rejected = try await request(
            port: port,
            path: "/api/v1",
            method: "GET",
            token: first
        )
        let accepted = try await request(
            port: port,
            path: "/api/v1",
            method: "GET",
            token: second
        )

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(rejected.status, 401)
        XCTAssertEqual(accepted.status, 200)
    }

    func testSuccessfulInvocationIsAudited() async throws {
        let fixture = try AutomationServerFixture(
            state: populatedState(visibility: [.status])
        )
        let token = try fixture.server.accessToken()
        let principal = try fixture.runtime.authenticate(token: token)
        let port = try start(fixture.server, authenticationRequired: true)

        let response = try await request(
            port: port,
            path: "/api/v1/capabilities/battery.status",
            method: "POST",
            token: token
        )
        let events = try fixture.runtime.auditEvents(for: principal.id, limit: 10)

        XCTAssertEqual(response.status, 200)
        let chronologicalEvents = events.sorted { $0.sequence < $1.sequence }
        XCTAssertEqual(
            chronologicalEvents.map(\.capabilityID),
            ["battery.status", "battery.status"]
        )
        XCTAssertEqual(chronologicalEvents.map(\.outcome), [.started, .succeeded])
        XCTAssertTrue(events.allSatisfy { $0.adapterID == "rest" })
    }

    func testStoppingReleasesTheCachedRuntime() throws {
        let fixture = try AutomationServerFixture(
            state: populatedState(visibility: [.status])
        )

        _ = try fixture.server.accessToken()
        XCTAssertEqual(fixture.runtimeLoader.loadCount, 1)

        fixture.server.stop()
        _ = try fixture.server.accessToken()

        XCTAssertEqual(fixture.runtimeLoader.loadCount, 2)
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

    private func capabilityIDs(in response: AutomationTestResponse) -> Set<String> {
        let capabilities = response.json["capabilities"] as? [[String: Any]] ?? []
        return Set(capabilities.compactMap { $0["id"] as? String })
    }

    private func start(
        _ server: BatteryAutomationServer,
        authenticationRequired: Bool,
        capabilities: Set<BatteryAutomationCapability> = Set(BatteryAutomationCapability.allCases),
        requestsPerMinute: Int = 1_000
    ) throws -> Int {
        try server.start(configuration: BatteryAutomationServer.Configuration(
            address: "127.0.0.1",
            port: 0,
            authenticationRequired: authenticationRequired,
            mcpEnabled: true,
            restEnabled: true,
            enabledCapabilities: capabilities,
            requestsPerMinute: requestsPerMinute
        ))
        return Int(try XCTUnwrap(server.activePort))
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
            request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
            request.setValue("2025-11-25", forHTTPHeaderField: "MCP-Protocol-Version")
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

private final class AutomationServerFixture {
    let directory: URL
    let runtime: BondryRuntime
    let runtimeLoader: MockAutomationRuntimeLoader
    let credentialStore = MockAutomationCredentialStore()
    let server: BatteryAutomationServer

    init(state: BatteryAutomationState) throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "BattakoreyAutomationTests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let key = try DatabaseKeyMaterial(rawRepresentation: Data(repeating: 0xA5, count: 32))
        let runtime = try BondryRuntime.open(
            at: directory.appendingPathComponent("automation.sqlite3"),
            key: key
        )
        self.runtime = runtime
        let runtimeLoader = MockAutomationRuntimeLoader(runtime: runtime)
        self.runtimeLoader = runtimeLoader
        server = BatteryAutomationServer(
            state: state,
            credentialStore: credentialStore,
            runtimeLoader: { try runtimeLoader.load() }
        )
    }

    deinit {
        server.stop()
        try? FileManager.default.removeItem(at: directory)
    }
}

private final class MockAutomationRuntimeLoader {
    let runtime: BondryRuntime
    private(set) var loadCount = 0

    init(runtime: BondryRuntime) {
        self.runtime = runtime
    }

    func load() throws -> BondryRuntime {
        loadCount += 1
        return runtime
    }
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

private final class MockAutomationCredentialStore: AutomationCredentialStoring {
    private(set) var credential: AutomationCredential?

    func loadCredential() throws -> AutomationCredential? {
        credential
    }

    func saveCredential(_ credential: AutomationCredential) throws {
        self.credential = credential
    }
}

private final class MockBatteryAutomationServer: BatteryAutomationServing {
    var activePort: UInt16? = 18_761
    var isRunning = true
    private var token: String
    private let regeneratedToken: String
    private(set) var accessTokenCallCount = 0
    private(set) var regenerateTokenCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var configurations: [BatteryAutomationServer.Configuration] = []

    init(accessToken: String, regeneratedToken: String? = nil) {
        token = accessToken
        self.regeneratedToken = regeneratedToken ?? accessToken
    }

    func accessToken() throws -> String {
        accessTokenCallCount += 1
        return token
    }

    func regenerateAccessToken() throws -> String {
        regenerateTokenCallCount += 1
        token = regeneratedToken
        return token
    }

    func start(configuration: BatteryAutomationServer.Configuration) throws {
        configurations.append(configuration)
        isRunning = true
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
    }
}
