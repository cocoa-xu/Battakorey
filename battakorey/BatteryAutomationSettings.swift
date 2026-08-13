import Foundation

protocol AutomationPreferencesStoring {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: AutomationPreferencesStoring {}

@MainActor
final class BatteryAutomationSettings: ObservableObject {
    enum Default {
        static let mcpEnabled = false
        static let restEnabled = false
        static let authenticationRequired = true
        static let port = 18_761
        static let networkScope = AutomationNetworkScope.thisMac
        static let requestsPerMinute = 30
        static let enabledCapabilities = Set(BatteryAutomationCapability.allCases)
    }

    static let portRange = 1_024 ... Int(UInt16.max)
    static let randomPortRange = 49_152 ... Int(UInt16.max)
    static let requestsPerMinuteRange = 1 ... 120

    @Published var mcpEnabled: Bool {
        didSet {
            store(mcpEnabled, for: "mcpEnabled")
            applyServerConfiguration()
        }
    }
    @Published var restEnabled: Bool {
        didSet {
            store(restEnabled, for: "restEnabled")
            applyServerConfiguration()
        }
    }
    @Published var authenticationRequired: Bool {
        didSet {
            store(authenticationRequired, for: "authenticationRequired")
            applyServerConfiguration()
        }
    }
    @Published var port: Int {
        didSet {
            let clamped = min(max(port, Self.portRange.lowerBound), Self.portRange.upperBound)
            guard clamped == port else {
                port = clamped
                return
            }
            store(port, for: "port")
            applyServerConfiguration()
        }
    }
    @Published var networkScope: AutomationNetworkScope {
        didSet {
            store(networkScope.rawValue, for: "networkScope")
            applyServerConfiguration()
        }
    }
    @Published var interfaceAddress: String {
        didSet {
            store(interfaceAddress, for: "interfaceAddress")
            applyServerConfiguration()
        }
    }
    @Published var requestsPerMinute: Int {
        didSet {
            let range = Self.requestsPerMinuteRange
            let clamped = min(max(requestsPerMinute, range.lowerBound), range.upperBound)
            guard clamped == requestsPerMinute else {
                requestsPerMinute = clamped
                return
            }
            store(requestsPerMinute, for: "requestsPerMinute")
            scheduleServerConfiguration()
        }
    }
    @Published var enabledCapabilities: Set<BatteryAutomationCapability> {
        didSet {
            store(enabledCapabilities.map(\.rawValue).sorted(), for: "enabledCapabilities")
            applyServerConfiguration()
        }
    }
    @Published private(set) var networkInterfaces: [AutomationNetworkInterface]
    @Published private(set) var accessToken: String
    @Published private(set) var securityProblem: String?
    @Published private(set) var serverProblem: String?
    @Published private(set) var isServerRunning = false

    private let preferences: AutomationPreferencesStoring
    private let namespace: String
    private weak var server: (any BatteryAutomationServing)?
    private var pendingServerConfiguration: Task<Void, Never>?

    init(
        preferences: AutomationPreferencesStoring = UserDefaults.standard,
        namespace: String = "BattakoreyAutomation.",
        networkInterfaces: [AutomationNetworkInterface] = AutomationNetworkInterface.current
    ) {
        self.preferences = preferences
        self.namespace = namespace
        self.networkInterfaces = networkInterfaces
        let storedScope = Self.string(
            in: preferences,
            key: namespace + "networkScope"
        )
        networkScope = storedScope.flatMap(AutomationNetworkScope.init(rawValue:))
            ?? Default.networkScope
        interfaceAddress = Self.string(
            in: preferences,
            key: namespace + "interfaceAddress"
        ) ?? networkInterfaces.first?.address ?? ""
        mcpEnabled = Self.boolean(
            in: preferences,
            key: namespace + "mcpEnabled"
        ) ?? Default.mcpEnabled
        restEnabled = Self.boolean(
            in: preferences,
            key: namespace + "restEnabled"
        ) ?? Default.restEnabled
        authenticationRequired = Self.boolean(
            in: preferences,
            key: namespace + "authenticationRequired"
        ) ?? Default.authenticationRequired
        port = min(max(
            Self.integer(in: preferences, key: namespace + "port") ?? Default.port,
            Self.portRange.lowerBound
        ), Self.portRange.upperBound)
        requestsPerMinute = min(max(
            Self.integer(
                in: preferences,
                key: namespace + "requestsPerMinute"
            ) ?? Default.requestsPerMinute,
            Self.requestsPerMinuteRange.lowerBound
        ), Self.requestsPerMinuteRange.upperBound)
        let storedCapabilities = Self.stringArray(
            in: preferences,
            key: namespace + "enabledCapabilities"
        )
        enabledCapabilities = Set(
            storedCapabilities?.compactMap(BatteryAutomationCapability.init(rawValue:))
                ?? Array(Default.enabledCapabilities)
        )

        accessToken = ""
        securityProblem = nil
    }

    var bindAddress: String {
        switch networkScope {
        case .thisMac: "127.0.0.1"
        case .allInterfaces: "0.0.0.0"
        case .selectedInterface:
            networkInterfaces.contains { $0.address == interfaceAddress }
                ? interfaceAddress
                : "127.0.0.1"
        }
    }

    var connectionHost: String {
        networkScope == .selectedInterface ? bindAddress : "127.0.0.1"
    }

    var mcpEndpoint: String {
        "http://\(connectionHost):\(port)/mcp"
    }

    var restEndpoint: String {
        "http://\(connectionHost):\(port)/api/v1"
    }

    var claudeInstallCommand: String {
        let authorization = authenticationRequired
            ? " --header \"Authorization: Bearer \(accessToken)\""
            : ""
        return "claude mcp add --transport http\(authorization) battakorey \(mcpEndpoint)"
    }

    var restExampleCommand: String {
        let authorization = authenticationRequired
            ? " -H \"Authorization: Bearer \(accessToken)\""
            : ""
        return "curl -X POST\(authorization) \(restEndpoint)/capabilities/battery.snapshot"
    }

    func attach(server: any BatteryAutomationServing) {
        self.server = server
        applyServerConfiguration()
    }

    func stop() {
        pendingServerConfiguration?.cancel()
        pendingServerConfiguration = nil
        server?.stop()
        isServerRunning = false
        accessToken = ""
    }

    func randomizePort() {
        var newPort = Int.random(in: Self.randomPortRange)
        if newPort == port {
            newPort = newPort == Self.randomPortRange.upperBound
                ? Self.randomPortRange.lowerBound
                : newPort + 1
        }
        port = newPort
    }

    func regenerateAccessToken() {
        guard let server else { return }
        do {
            accessToken = try server.regenerateAccessToken()
            securityProblem = nil
            applyServerConfiguration()
        } catch {
            securityProblem = error.localizedDescription
        }
    }

    func refreshNetworkInterfaces() {
        networkInterfaces = AutomationNetworkInterface.current
        if networkScope == .selectedInterface,
           !networkInterfaces.contains(where: { $0.address == interfaceAddress }) {
            interfaceAddress = networkInterfaces.first?.address ?? ""
        }
    }

    func toggleCapability(_ capability: BatteryAutomationCapability) {
        if enabledCapabilities.contains(capability) {
            enabledCapabilities.remove(capability)
        } else {
            enabledCapabilities.insert(capability)
        }
    }

    func refreshExposure() {
        applyServerConfiguration()
    }

    private func applyServerConfiguration() {
        pendingServerConfiguration?.cancel()
        pendingServerConfiguration = nil
        isServerRunning = false
        serverProblem = nil
        guard let server else { return }
        guard mcpEnabled || restEnabled else {
            server.stop()
            accessToken = ""
            return
        }
        do {
            try server.start(configuration: BatteryAutomationServer.Configuration(
                address: bindAddress,
                port: UInt16(clamping: port),
                authenticationRequired: authenticationRequired,
                mcpEnabled: mcpEnabled,
                restEnabled: restEnabled,
                enabledCapabilities: enabledCapabilities,
                requestsPerMinute: requestsPerMinute
            ))
            if authenticationRequired {
                accessToken = try server.accessToken()
                securityProblem = nil
            } else {
                accessToken = ""
                securityProblem = nil
            }
            isServerRunning = server.isRunning
        } catch {
            server.stop()
            accessToken = ""
            serverProblem = error.localizedDescription
        }
    }

    private func scheduleServerConfiguration() {
        pendingServerConfiguration?.cancel()
        pendingServerConfiguration = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(250))
            } catch {
                return
            }
            self?.applyServerConfiguration()
        }
    }

    private func store(_ value: Any, for key: String) {
        preferences.set(value, forKey: namespace + key)
    }

    private static func boolean(
        in store: AutomationPreferencesStoring,
        key: String
    ) -> Bool? {
        let value = store.object(forKey: key)
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        guard let value = value as? String else { return nil }
        switch value.lowercased() {
        case "1", "true", "yes": return true
        case "0", "false", "no": return false
        default: return nil
        }
    }

    private static func integer(
        in store: AutomationPreferencesStoring,
        key: String
    ) -> Int? {
        let value = store.object(forKey: key)
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return (value as? String).flatMap(Int.init)
    }

    private static func string(
        in store: AutomationPreferencesStoring,
        key: String
    ) -> String? {
        store.object(forKey: key) as? String
    }

    private static func stringArray(
        in store: AutomationPreferencesStoring,
        key: String
    ) -> [String]? {
        store.object(forKey: key) as? [String]
    }
}
