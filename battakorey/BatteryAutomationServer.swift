import Bondry
import BondryApple
import BondryLocalServer
import Foundation

protocol BatteryAutomationServing: AnyObject {
    var activePort: UInt16? { get }
    var isRunning: Bool { get }

    func accessToken() throws -> String
    func regenerateAccessToken() throws -> String
    func start(configuration: BatteryAutomationServer.Configuration) throws
    func stop()
}

final class BatteryAutomationServer: BatteryAutomationServing {
    struct Configuration: Equatable {
        let address: String
        let port: UInt16
        let authenticationRequired: Bool
        let mcpEnabled: Bool
        let restEnabled: Bool
        let enabledCapabilities: Set<BatteryAutomationCapability>
        let requestsPerMinute: Int

        init(
            address: String,
            port: UInt16,
            authenticationRequired: Bool,
            mcpEnabled: Bool,
            restEnabled: Bool,
            enabledCapabilities: Set<BatteryAutomationCapability>,
            requestsPerMinute: Int
        ) {
            self.address = address
            self.port = port
            self.authenticationRequired = authenticationRequired
            self.mcpEnabled = mcpEnabled
            self.restEnabled = restEnabled
            self.enabledCapabilities = enabledCapabilities.intersection(
                Set(BatteryAutomationCapability.allCases)
            )
            self.requestsPerMinute = max(requestsPerMinute, 1)
        }
    }

    private static let snapshotCapabilityID = "battery.snapshot"
    private static let primaryClientName = "Battakorey Primary Client"
    private static let unauthenticatedPrincipalID = "battakorey.local-automation"

    private let state: BatteryAutomationState
    private let credentialStore: AutomationCredentialStoring
    private let runtimeLoader: () throws -> BondryRuntime
    private var runtime: BondryRuntime?
    private var server: BondryLocalServer?

    private(set) var activePort: UInt16?
    var isRunning: Bool { server?.isRunning == true }

    init(
        state: BatteryAutomationState,
        credentialStore: AutomationCredentialStoring = KeychainAutomationCredentialStore(),
        runtimeLoader: @escaping () throws -> BondryRuntime = BatteryAutomationServer.loadDefaultRuntime
    ) {
        self.state = state
        self.credentialStore = credentialStore
        self.runtimeLoader = runtimeLoader
    }

    deinit {
        stop()
    }

    func accessToken() throws -> String {
        try ensureCredential(in: loadRuntime()).secret
    }

    func regenerateAccessToken() throws -> String {
        let runtime = try loadRuntime()
        let client = try primaryClient(in: runtime)
        return try issueCredential(for: client, in: runtime).secret
    }

    func start(configuration: Configuration) throws {
        do {
            try stopServer()
        } catch {
            throw BatteryAutomationServerError.serverStop(error)
        }
        guard configuration.mcpEnabled || configuration.restEnabled else { return }

        let runtime = try loadRuntime()
        let capabilityIDs: Set<String>
        do {
            capabilityIDs = try registerCapabilities(
                in: runtime,
                allowedCapabilities: configuration.enabledCapabilities
            )
        } catch {
            throw BatteryAutomationServerError.capabilityRegistration(error)
        }
        let adapters = configuration.adapters
        let authentication: BondryLocalServerAuthentication
        let principalID: String
        if configuration.authenticationRequired {
            let credential = try ensureCredential(in: runtime)
            principalID = credential.clientID
            authentication = .bearerToken
        } else {
            principalID = Self.unauthenticatedPrincipalID
            authentication = .disabled(principalID: principalID)
        }
        do {
            try synchronizeGrants(
                in: runtime,
                principalID: principalID,
                adapters: adapters,
                capabilityIDs: capabilityIDs
            )
        } catch {
            throw BatteryAutomationServerError.authorizationPolicy(error)
        }

        let exposesToNetwork = configuration.address != "127.0.0.1"
        let started: BondryLocalServer
        do {
            started = try runtime.startLocalServer(configuration: BondryLocalServerConfiguration(
                adapters: adapters,
                mcpServer: configuration.mcpEnabled
                    ? try BondryMCPServerInformation(
                        name: "battakorey",
                        title: "Battakorey",
                        version: Bundle.main.object(
                            forInfoDictionaryKey: "CFBundleShortVersionString"
                        ) as? String ?? "development"
                    )
                    : nil,
                listeningAddress: configuration.address,
                port: configuration.port,
                authentication: authentication,
                limits: try BondryLocalServerLimits(
                    requestsPerMinute: UInt32(clamping: configuration.requestsPerMinute),
                    authenticationFailuresPerMinute: 30,
                    maxBodyBytes: BondryLocalServerLimits.standard.maxBodyBytes,
                    maxConnections: BondryLocalServerLimits.standard.maxConnections
                ),
                allowsCleartextNetworkAccess: exposesToNetwork,
                allowsUnauthenticatedNetworkAccess: exposesToNetwork
                    && !configuration.authenticationRequired
            ))
        } catch {
            throw BatteryAutomationServerError.serverStart(error)
        }
        server = started
        activePort = started.endpoint.port
    }

    func stop() {
        try? stopServer()
        runtime = nil
    }

    private func loadRuntime() throws -> BondryRuntime {
        if let runtime { return runtime }
        let loaded = try runtimeLoader()
        try loaded.checkHealth()
        runtime = loaded
        return loaded
    }

    private func stopServer() throws {
        defer {
            server = nil
            activePort = nil
        }
        try server?.stop()
    }

    private func ensureCredential(in runtime: BondryRuntime) throws -> AutomationCredential {
        if let credential = try credentialStore.loadCredential(),
           let principal = try? runtime.authenticate(token: credential.secret),
           principal.id == credential.clientID {
            return credential
        }
        return try issueCredential(for: primaryClient(in: runtime), in: runtime)
    }

    private func primaryClient(in runtime: BondryRuntime) throws -> BondryClient {
        if let credential = try credentialStore.loadCredential(),
           let client = try runtime.clients().first(where: { $0.id == credential.clientID }) {
            return client
        }
        if let client = try runtime.clients().first(where: { $0.name == Self.primaryClientName }) {
            return client
        }
        return try runtime.createClient(named: Self.primaryClientName)
    }

    private func issueCredential(
        for client: BondryClient,
        in runtime: BondryRuntime
    ) throws -> AutomationCredential {
        for token in try runtime.tokens(for: client.id) where token.revokedAt == nil {
            _ = try runtime.revokeToken(token.id)
        }
        let issued = try runtime.issueToken(for: client.id, label: "Primary")
        let credential = AutomationCredential(
            clientID: client.id,
            secret: issued.copySecret()
        )
        do {
            try credentialStore.saveCredential(credential)
        } catch {
            _ = try? runtime.revokeToken(issued.metadata.id)
            throw error
        }
        return credential
    }

    private func registerCapabilities(
        in runtime: BondryRuntime,
        allowedCapabilities: Set<BatteryAutomationCapability>
    ) throws -> Set<String> {
        for capability in try runtime.capabilities()
            where capability.id == Self.snapshotCapabilityID
                || capability.id.hasPrefix("battery.") {
            _ = try runtime.unregisterCapability(capability.id)
        }

        let exposed = state.exposedCapabilities(allowedCapabilities: allowedCapabilities)
        guard !exposed.isEmpty else { return [] }

        try runtime.registerCapability(BondryCapability(
            id: Self.snapshotCapabilityID,
            summary: "Read every currently exposed Battakorey reading.",
            effect: .readOnly
        )) { [state] _ in
            guard let payload = state.snapshotPayload(
                allowedCapabilities: allowedCapabilities
            ) else {
                throw BondryCapabilityHandlerError.failed(code: "snapshot_unavailable")
            }
            return try Self.encode(payload)
        }

        for capability in exposed {
            try runtime.registerCapability(BondryCapability(
                id: capability.bondryID,
                summary: capability.description,
                effect: .readOnly
            )) { [state] _ in
                guard let payload = state.payload(for: capability) else {
                    throw BondryCapabilityHandlerError.failed(code: "snapshot_unavailable")
                }
                return try Self.encode(payload)
            }
        }
        return Set([Self.snapshotCapabilityID] + exposed.map(\.bondryID))
    }

    private func synchronizeGrants(
        in runtime: BondryRuntime,
        principalID: String,
        adapters: Set<BondryLocalServerAdapter>,
        capabilityIDs: Set<String>
    ) throws {
        let desired = Set(adapters.flatMap { adapter in
            capabilityIDs.map { capabilityID in
                BondryCapabilityGrant(
                    principalID: principalID,
                    adapterID: adapter.rawValue,
                    capabilityID: capabilityID
                )
            }
        })
        let managedAdapters = Set(BondryLocalServerAdapter.allCases.map(\.rawValue))
        let existing = Set(try runtime.grants(for: principalID).filter {
            managedAdapters.contains($0.adapterID) && $0.capabilityID.hasPrefix("battery.")
        })

        for grant in existing.subtracting(desired) {
            _ = try runtime.removeGrant(
                principalID: grant.principalID,
                adapterID: grant.adapterID,
                capabilityID: grant.capabilityID
            )
        }
        for grant in desired.subtracting(existing) {
            _ = try runtime.addGrant(
                principalID: grant.principalID,
                adapterID: grant.adapterID,
                capabilityID: grant.capabilityID
            )
        }
    }

    private static func encode(_ object: [String: Any]) throws -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        } catch {
            throw BondryCapabilityHandlerError.failed(code: "encoding_failed")
        }
    }

    private static func loadDefaultRuntime() throws -> BondryRuntime {
        let fileManager = FileManager.default
        guard let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw BatteryAutomationServerError.applicationSupportUnavailable
        }
        let directory = applicationSupport
            .appendingPathComponent("Battakorey", isDirectory: true)
            .appendingPathComponent("Automation", isDirectory: true)
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try fileManager.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: directory.path
        )
        let keyConfiguration = try KeychainDatabaseKeyConfiguration(
            service: "moe.uwucocoa.battakorey.automation",
            account: "database-key"
        )
        let key = try KeychainDatabaseKeyProvider(
            configuration: keyConfiguration
        ).loadOrCreate()
        return try BondryRuntime.open(
            at: directory.appendingPathComponent("automation.sqlite3"),
            key: key
        )
    }
}

private extension BatteryAutomationServer.Configuration {
    var adapters: Set<BondryLocalServerAdapter> {
        var adapters: Set<BondryLocalServerAdapter> = []
        if mcpEnabled { adapters.insert(.mcp) }
        if restEnabled { adapters.insert(.rest) }
        return adapters
    }
}

enum BatteryAutomationServerError: LocalizedError {
    case applicationSupportUnavailable
    case capabilityRegistration(any Error)
    case authorizationPolicy(any Error)
    case serverStop(any Error)
    case serverStart(any Error)

    var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            "Could not locate the Application Support directory."
        case .capabilityRegistration(let error):
            "Could not register automation capabilities: \(error)"
        case .authorizationPolicy(let error):
            "Could not update the automation access policy: \(error)"
        case .serverStop(let error):
            "Could not stop the existing automation server: \(error)"
        case .serverStart(let error):
            "Could not start the automation server: \(error)"
        }
    }
}
