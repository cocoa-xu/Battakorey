import Foundation
import IOKit

struct SMCPowerReading: Equatable {
    let batteryWatts: Double?
    let inputVolts: Double?
    let inputAmps: Double?
    let inputWatts: Double?
}

final class SMCPowerReader {
    private let client = AppleSMCClient()

    func read() -> SMCPowerReading? {
        let batteryWatts = value(for: .batteryPower)
        let inputVolts = value(for: .inputVoltage)
        let inputAmps = value(for: .inputCurrent)
        let inputWatts = value(for: .inputPower) ?? inputVolts.flatMap { volts in
            inputAmps.map { volts * $0 }
        }

        guard batteryWatts != nil || inputVolts != nil || inputAmps != nil || inputWatts != nil else {
            return nil
        }
        return SMCPowerReading(
            batteryWatts: batteryWatts,
            inputVolts: inputVolts,
            inputAmps: inputAmps,
            inputWatts: inputWatts
        )
    }

    static func decodeFloat(_ bytes: [UInt8]) -> Float? {
        AppleSMCClient.decodeFloat(bytes)
    }

    static func fourCC(_ key: String) -> UInt32? {
        AppleSMCKey(key)?.encoded
    }

    private func value(for rail: PowerRail) -> Double? {
        guard let reading = client.floatValue(for: rail.key).map(Double.init),
              rail.validRange.contains(reading) else {
            return nil
        }
        return reading
    }
}

private enum PowerRail {
    case batteryPower
    case inputVoltage
    case inputCurrent
    case inputPower

    var key: AppleSMCKey {
        switch self {
        case .batteryPower:
            return AppleSMCKey("PPBR")!
        case .inputVoltage:
            return AppleSMCKey("VD0R")!
        case .inputCurrent:
            return AppleSMCKey("ID0R")!
        case .inputPower:
            return AppleSMCKey("PDTR")!
        }
    }

    var validRange: Range<Double> {
        switch self {
        case .batteryPower:
            return 0..<200
        case .inputVoltage:
            return 0..<100
        case .inputCurrent:
            return 0..<50
        case .inputPower:
            return 0..<500
        }
    }
}

private struct AppleSMCKey {
    let encoded: UInt32

    init?(_ value: String) {
        let bytes = Array(value.utf8)
        guard bytes.count == 4 else { return nil }
        encoded = bytes.reduce(0) { ($0 << 8) | UInt32($1) }
    }
}

private final class AppleSMCClient {
    private var connection: io_connect_t = 0

    deinit {
        if connection != 0 {
            IOServiceClose(connection)
        }
    }

    func floatValue(for key: AppleSMCKey) -> Float? {
        guard connect(), let payload = payload(for: key) else { return nil }
        return Self.decodeFloat(payload)
    }

    static func decodeFloat(_ bytes: [UInt8]) -> Float? {
        guard bytes.count >= MemoryLayout<UInt32>.size else { return nil }
        var bits: UInt32 = 0
        withUnsafeMutableBytes(of: &bits) { destination in
            destination.copyBytes(from: bytes.prefix(MemoryLayout<UInt32>.size))
        }
        let value = Float(bitPattern: UInt32(littleEndian: bits))
        return value.isFinite ? value : nil
    }

    private func connect() -> Bool {
        guard MemoryLayout<AppleSMCMessage>.stride == 80 else { return false }
        if connection != 0 { return true }
        guard let matching = IOServiceMatching("AppleSMC") else { return false }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != IO_OBJECT_NULL else { return false }
        defer { IOObjectRelease(service) }

        var openedConnection: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, 0, &openedConnection) == KERN_SUCCESS else {
            return false
        }
        connection = openedConnection
        return true
    }

    private func payload(for key: AppleSMCKey) -> [UInt8]? {
        var metadataRequest = AppleSMCMessage()
        metadataRequest.key = key.encoded
        metadataRequest.operation = AppleSMCOperation.readMetadata.rawValue
        guard let metadataResponse = exchange(metadataRequest) else { return nil }

        let length = metadataResponse.metadata.length
        guard length > 0, length <= 32 else { return nil }

        var valueRequest = AppleSMCMessage()
        valueRequest.key = key.encoded
        valueRequest.metadata = metadataResponse.metadata
        valueRequest.operation = AppleSMCOperation.readValue.rawValue
        guard var valueResponse = exchange(valueRequest) else { return nil }

        return withUnsafeBytes(of: &valueResponse.payload) {
            Array($0.prefix(Int(length)))
        }
    }

    private func exchange(_ request: AppleSMCMessage) -> AppleSMCMessage? {
        var request = request
        var response = AppleSMCMessage()
        var responseSize = MemoryLayout<AppleSMCMessage>.stride
        let result = IOConnectCallStructMethod(
            connection,
            2,
            &request,
            MemoryLayout<AppleSMCMessage>.stride,
            &response,
            &responseSize
        )
        guard result == KERN_SUCCESS, response.result == 0 else { return nil }
        return response
    }
}

private enum AppleSMCOperation: UInt8 {
    case readValue = 5
    case readMetadata = 9
}

private struct AppleSMCVersion {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

private struct AppleSMCPowerLimits {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpu: UInt32 = 0
    var gpu: UInt32 = 0
    var memory: UInt32 = 0
}

private struct AppleSMCMetadata {
    var length: UInt32 = 0
    var type: UInt32 = 0
    var attributes: UInt8 = 0
}

private typealias AppleSMCPayload = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
)

private struct AppleSMCMessage {
    var key: UInt32 = 0
    var version = AppleSMCVersion()
    var limits = AppleSMCPowerLimits()
    var metadata = AppleSMCMetadata()
    var alignment: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var operation: UInt8 = 0
    var data: UInt32 = 0
    var payload: AppleSMCPayload = (
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
    )
}
