import Darwin
import Foundation

final class BatteryAutomationServer {
    struct Configuration: Equatable {
        let address: String
        let port: UInt16
        let token: String
        let authenticationRequired: Bool
        let mcpEnabled: Bool
        let restEnabled: Bool
        let enabledCapabilities: Set<BatteryAutomationCapability>
        let requestsPerMinute: Int

        init(
            address: String,
            port: UInt16,
            token: String,
            authenticationRequired: Bool,
            mcpEnabled: Bool,
            restEnabled: Bool,
            enabledCapabilities: Set<BatteryAutomationCapability>,
            requestsPerMinute: Int
        ) {
            self.address = address
            self.port = port
            self.token = token
            self.authenticationRequired = authenticationRequired
            self.mcpEnabled = mcpEnabled
            self.restEnabled = restEnabled
            self.enabledCapabilities = enabledCapabilities.intersection(
                Set(BatteryAutomationCapability.allCases)
            )
            self.requestsPerMinute = max(requestsPerMinute, 1)
        }
    }

    private struct HTTPRequest {
        let method: String
        let path: String
        let headers: [String: String]
        let body: Data
        let client: String
    }

    private struct HTTPResponse {
        let status: Int
        let headers: [String: String]
        let body: Data

        static func empty(status: Int) -> HTTPResponse {
            HTTPResponse(status: status, headers: [:], body: Data())
        }
    }

    private let state: BatteryAutomationState
    private let configurationLock = NSLock()
    private let connectionSlots = DispatchSemaphore(value: 8)
    private let rateLimiter = AutomationRateLimiter()
    private var listenFileDescriptor: Int32 = -1
    private var source: DispatchSourceRead?
    private var configuration: Configuration?

    init(state: BatteryAutomationState) {
        self.state = state
    }

    deinit {
        stop()
    }

    private(set) var activePort: UInt16?
    var isRunning: Bool { activePort != nil }

    func start(configuration: Configuration) throws {
        stop()
        guard configuration.mcpEnabled || configuration.restEnabled else { return }
        rateLimiter.reset()

        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw BatteryAutomationServerError.socket(String(cString: strerror(errno)))
        }
        listenFileDescriptor = descriptor
        var reuse: Int32 = 1
        setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_REUSEADDR,
            &reuse,
            socklen_t(MemoryLayout.size(ofValue: reuse))
        )
        var noSignal: Int32 = 1
        setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_NOSIGPIPE,
            &noSignal,
            socklen_t(MemoryLayout.size(ofValue: noSignal))
        )

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = configuration.port.bigEndian
        guard inet_pton(AF_INET, configuration.address, &address.sin_addr) == 1 else {
            close(descriptor)
            listenFileDescriptor = -1
            throw BatteryAutomationServerError.invalidAddress(configuration.address)
        }
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0, listen(descriptor, 16) == 0 else {
            let message = String(cString: strerror(errno))
            close(descriptor)
            listenFileDescriptor = -1
            throw BatteryAutomationServerError.bind(
                address: configuration.address,
                port: configuration.port,
                message: message
            )
        }

        configurationLock.withLock { self.configuration = configuration }
        let readSource = DispatchSource.makeReadSource(fileDescriptor: descriptor)
        readSource.setEventHandler { [weak self] in
            self?.acceptConnection(from: descriptor)
        }
        readSource.setCancelHandler { close(descriptor) }
        source = readSource
        readSource.resume()
        activePort = configuration.port
    }

    func stop() {
        configurationLock.withLock { configuration = nil }
        rateLimiter.reset()
        activePort = nil
        guard let source else {
            listenFileDescriptor = -1
            return
        }
        let closed = DispatchSemaphore(value: 0)
        let descriptor = listenFileDescriptor
        source.setCancelHandler {
            close(descriptor)
            closed.signal()
        }
        source.cancel()
        _ = closed.wait(timeout: .now() + 1)
        self.source = nil
        listenFileDescriptor = -1
    }

    func updateAccessPolicy(
        enabledCapabilities: Set<BatteryAutomationCapability>,
        requestsPerMinute: Int
    ) {
        configurationLock.withLock {
            guard let current = configuration else { return }
            configuration = Configuration(
                address: current.address,
                port: current.port,
                token: current.token,
                authenticationRequired: current.authenticationRequired,
                mcpEnabled: current.mcpEnabled,
                restEnabled: current.restEnabled,
                enabledCapabilities: enabledCapabilities,
                requestsPerMinute: requestsPerMinute
            )
        }
        rateLimiter.reset()
    }

    static func tools(capabilities: [BatteryAutomationCapability]) -> [[String: Any]] {
        guard !capabilities.isEmpty else { return [] }
        let annotations: [String: Any] = [
            "readOnlyHint": true,
            "destructiveHint": false,
            "idempotentHint": true,
            "openWorldHint": false
        ]
        let schema: [String: Any] = [
            "type": "object",
            "properties": [:],
            "additionalProperties": false
        ]
        let snapshot: [String: Any] = [
            "name": "battery_get_snapshot",
            "description": "Get every currently exposed Battakorey reading.",
            "inputSchema": schema,
            "annotations": annotations
        ]
        return [snapshot] + capabilities.map { capability in
            [
                "name": capability.toolName,
                "description": capability.description,
                "inputSchema": schema,
                "annotations": annotations
            ]
        }
    }

    private func acceptConnection(from listener: Int32) {
        var address = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let client = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                accept(listener, $0, &length)
            }
        }
        guard client >= 0 else { return }
        let clientIdentifier = clientIdentifier(for: address)
        guard connectionSlots.wait(timeout: .now()) == .success else {
            close(client)
            return
        }
        var noSignal: Int32 = 1
        setsockopt(
            client,
            SOL_SOCKET,
            SO_NOSIGPIPE,
            &noSignal,
            socklen_t(MemoryLayout.size(ofValue: noSignal))
        )
        var timeout = timeval(tv_sec: 5, tv_usec: 0)
        setsockopt(
            client,
            SOL_SOCKET,
            SO_RCVTIMEO,
            &timeout,
            socklen_t(MemoryLayout.size(ofValue: timeout))
        )
        setsockopt(
            client,
            SOL_SOCKET,
            SO_SNDTIMEO,
            &timeout,
            socklen_t(MemoryLayout.size(ofValue: timeout))
        )
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else {
                close(client)
                return
            }
            defer { self.connectionSlots.signal() }
            self.handle(client, client: clientIdentifier)
        }
    }

    private func handle(_ descriptor: Int32, client: String) {
        defer { close(descriptor) }
        guard let request = readRequest(from: descriptor, client: client) else {
            send(.empty(status: 400), to: descriptor)
            return
        }
        send(route(request), to: descriptor)
    }

    private func route(_ request: HTTPRequest) -> HTTPResponse {
        guard let configuration = configurationLock.withLock({ configuration }) else {
            return .empty(status: 503)
        }
        let rateLimit = rateLimiter.evaluate(
            client: request.client,
            limit: configuration.requestsPerMinute
        )
        guard rateLimit.isAllowed else {
            return HTTPResponse(
                status: 429,
                headers: [
                    "Content-Type": "application/json; charset=utf-8",
                    "Retry-After": String(rateLimit.retryAfterSeconds)
                ],
                body: jsonData(["error": "Rate limit exceeded"])
            )
        }
        guard authorized(request, configuration: configuration) else {
            return HTTPResponse(
                status: 401,
                headers: [
                    "Content-Type": "application/json; charset=utf-8",
                    "WWW-Authenticate": "Bearer"
                ],
                body: jsonData(["error": "Unauthorized"])
            )
        }
        if request.path == "/mcp" {
            guard configuration.mcpEnabled else {
                return jsonResponse(["error": "Not found"], status: 404)
            }
            guard request.method == "POST" else {
                return HTTPResponse(status: 405, headers: ["Allow": "POST"], body: Data())
            }
            return handleMCP(request.body, configuration: configuration)
        }
        if request.path == "/api/v1" || request.path.hasPrefix("/api/v1/") {
            guard configuration.restEnabled else {
                return jsonResponse(["error": "Not found"], status: 404)
            }
            return handleREST(request, configuration: configuration)
        }
        return jsonResponse(["error": "Not found"], status: 404)
    }

    private func handleMCP(_ data: Data, configuration: Configuration) -> HTTPResponse {
        guard let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let method = message["method"] as? String else {
            return jsonResponse([
                "jsonrpc": "2.0",
                "id": NSNull(),
                "error": ["code": -32700, "message": "Parse error"]
            ], status: 400)
        }
        let id = message["id"]
        let params = message["params"] as? [String: Any] ?? [:]
        let capabilities = state.exposedCapabilities(
            allowedCapabilities: configuration.enabledCapabilities
        )
        let result: Any
        switch method {
        case "initialize":
            let requestedVersion = params["protocolVersion"] as? String
            let protocolVersion = Self.supportedProtocolVersions.contains(requestedVersion ?? "")
                ? requestedVersion!
                : Self.supportedProtocolVersions[0]
            result = [
                "protocolVersion": protocolVersion,
                "capabilities": ["tools": [:]],
                "serverInfo": ["name": "Battakorey", "version": appVersion],
                "instructions": "Query current battery and power telemetry. "
                    + "Returned readings are limited by the user's menu visibility "
                    + "and Automation exposure settings."
            ]
        case "ping":
            result = [:] as [String: Any]
        case "notifications/initialized":
            return .empty(status: 202)
        case "tools/list":
            result = ["tools": Self.tools(capabilities: capabilities)]
        case "tools/call":
            guard let name = params["name"] as? String else {
                if id == nil { return .empty(status: 202) }
                return mcpError(id: id, code: -32602, message: "Invalid params")
            }
            let output: [String: Any]
            if name == "battery_get_snapshot", !capabilities.isEmpty {
                output = state.snapshotPayload(
                    allowedCapabilities: Set(capabilities)
                ) ?? ["error": "No battery snapshot is available yet."]
            } else if let capability = BatteryAutomationCapability.matching(toolName: name),
                      capabilities.contains(capability) {
                output = state.payload(for: capability)
                    ?? ["error": "No battery snapshot is available yet."]
            } else {
                if id == nil { return .empty(status: 202) }
                return mcpError(id: id, code: -32601, message: "Tool is disabled")
            }
            let text = String(data: jsonData(output), encoding: .utf8) ?? "{}"
            result = [
                "content": [["type": "text", "text": text]],
                "structuredContent": output,
                "isError": output["error"] != nil
            ]
        default:
            if id == nil { return .empty(status: 202) }
            return mcpError(id: id, code: -32601, message: "Method not found")
        }
        guard let id else { return .empty(status: 202) }
        return jsonResponse(["jsonrpc": "2.0", "id": id, "result": result])
    }

    private func handleREST(
        _ request: HTTPRequest,
        configuration: Configuration
    ) -> HTTPResponse {
        let capabilities = state.exposedCapabilities(
            allowedCapabilities: configuration.enabledCapabilities
        )
        if request.method == "GET", request.path == "/api/v1" {
            return jsonResponse([
                "version": "v1",
                "capabilities": capabilities.map(\.rawValue),
                "resources": [
                    "snapshot": "/api/v1/snapshot",
                    "capabilities": "/api/v1/capabilities",
                    "readings": "/api/v1/readings/{capability}"
                ]
            ])
        }
        if request.method == "GET", request.path == "/api/v1/capabilities" {
            return jsonResponse([
                "capabilities": capabilities.map {
                    [
                        "id": $0.rawValue,
                        "title": $0.title,
                        "description": $0.description
                    ]
                }
            ])
        }
        if request.method == "GET", request.path == "/api/v1/snapshot" {
            guard !capabilities.isEmpty else {
                return jsonResponse(["error": "Not found"], status: 404)
            }
            guard let payload = state.snapshotPayload(
                allowedCapabilities: Set(capabilities)
            ) else {
                return jsonResponse(
                    ["error": "No battery snapshot is available yet."],
                    status: 503
                )
            }
            return jsonResponse(payload)
        }
        let prefix = "/api/v1/readings/"
        if request.method == "GET", request.path.hasPrefix(prefix) {
            let name = String(request.path.dropFirst(prefix.count))
            guard let capability = BatteryAutomationCapability(rawValue: name),
                  capabilities.contains(capability) else {
                return jsonResponse(["error": "Not found"], status: 404)
            }
            guard let payload = state.payload(for: capability) else {
                return jsonResponse(
                    ["error": "No battery snapshot is available yet."],
                    status: 503
                )
            }
            return jsonResponse(payload)
        }
        return jsonResponse(["error": "Not found"], status: 404)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "development"
    }

    private static let supportedProtocolVersions = [
        "2025-11-25",
        "2025-06-18",
        "2024-11-05"
    ]

    private func authorized(
        _ request: HTTPRequest,
        configuration: Configuration
    ) -> Bool {
        guard configuration.authenticationRequired else { return true }
        guard let value = request.headers["authorization"],
              value.hasPrefix("Bearer ") else {
            return false
        }
        return constantTimeEqual(
            String(value.dropFirst("Bearer ".count)),
            configuration.token
        )
    }

    private func constantTimeEqual(_ lhs: String, _ rhs: String) -> Bool {
        let left = Array(lhs.utf8)
        let right = Array(rhs.utf8)
        var difference = left.count ^ right.count
        for index in 0..<max(left.count, right.count) {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            difference |= Int(a ^ b)
        }
        return difference == 0
    }

    private func mcpError(id: Any?, code: Int, message: String) -> HTTPResponse {
        jsonResponse([
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "error": ["code": code, "message": message]
        ])
    }

    private func jsonResponse(_ value: Any, status: Int = 200) -> HTTPResponse {
        HTTPResponse(
            status: status,
            headers: ["Content-Type": "application/json; charset=utf-8"],
            body: jsonData(value)
        )
    }

    private func jsonData(_ value: Any) -> Data {
        (try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]))
            ?? Data("{}".utf8)
    }

    private func readRequest(from descriptor: Int32, client: String) -> HTTPRequest? {
        let headerLimit = 64 * 1024
        let bodyLimit = 1024 * 1024
        var data = Data()
        var headerEnd: Data.Index?
        let delimiter = Data("\r\n\r\n".utf8)

        while headerEnd == nil, data.count <= headerLimit {
            guard receive(into: &data, from: descriptor) else { return nil }
            headerEnd = data.range(of: delimiter)?.upperBound
        }
        guard let headerEnd,
              let headerText = String(data: data[..<headerEnd], encoding: .utf8) else {
            return nil
        }
        let lines = headerText.components(separatedBy: "\r\n")
        guard let first = lines.first else { return nil }
        let parts = first.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return nil }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() where !line.isEmpty {
            guard let separator = line.firstIndex(of: ":") else { return nil }
            let name = line[..<separator].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: separator)...]
                .trimmingCharacters(in: .whitespaces)
            headers[name] = value
        }
        let contentLength = headers["content-length"].flatMap(Int.init) ?? 0
        guard contentLength >= 0, contentLength <= bodyLimit else { return nil }
        while data.count - headerEnd < contentLength {
            guard receive(into: &data, from: descriptor),
                  data.count <= headerEnd + bodyLimit else {
                return nil
            }
        }
        let path = String(parts[1]).split(separator: "?", maxSplits: 1)
            .first.map(String.init) ?? "/"
        return HTTPRequest(
            method: String(parts[0]).uppercased(),
            path: path,
            headers: headers,
            body: data.subdata(in: headerEnd..<(headerEnd + contentLength)),
            client: client
        )
    }

    private func clientIdentifier(for address: sockaddr_in) -> String {
        var address = address.sin_addr
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        guard inet_ntop(AF_INET, &address, &buffer, socklen_t(buffer.count)) != nil else {
            return "unknown"
        }
        return String(cString: buffer)
    }

    private func receive(into data: inout Data, from descriptor: Int32) -> Bool {
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        let count = recv(descriptor, &buffer, buffer.count, 0)
        guard count > 0 else { return false }
        data.append(buffer, count: count)
        return true
    }

    private func send(_ response: HTTPResponse, to descriptor: Int32) {
        let reason: String = switch response.status {
        case 200: "OK"
        case 202: "Accepted"
        case 400: "Bad Request"
        case 401: "Unauthorized"
        case 404: "Not Found"
        case 405: "Method Not Allowed"
        case 429: "Too Many Requests"
        case 503: "Service Unavailable"
        default: "Error"
        }
        var headers = response.headers
        headers["Content-Length"] = String(response.body.count)
        headers["Connection"] = "close"
        headers["Cache-Control"] = "no-store"
        headers["X-Content-Type-Options"] = "nosniff"
        var message = Data("HTTP/1.1 \(response.status) \(reason)\r\n".utf8)
        for (name, value) in headers.sorted(by: { $0.key < $1.key }) {
            message.append(Data("\(name): \(value)\r\n".utf8))
        }
        message.append(Data("\r\n".utf8))
        message.append(response.body)
        message.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            var sent = 0
            while sent < message.count {
                let count = Darwin.send(
                    descriptor,
                    baseAddress.advanced(by: sent),
                    message.count - sent,
                    0
                )
                guard count > 0 else { return }
                sent += count
            }
        }
    }
}

enum BatteryAutomationServerError: LocalizedError {
    case socket(String)
    case invalidAddress(String)
    case bind(address: String, port: UInt16, message: String)

    var errorDescription: String? {
        switch self {
        case let .socket(message):
            "Could not create the automation server socket: \(message)"
        case let .invalidAddress(address):
            "The automation bind address is invalid: \(address)"
        case let .bind(address, port, message):
            "Could not listen on \(address):\(port): \(message)"
        }
    }
}
