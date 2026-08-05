import Foundation
import IOKit

struct SMCPowerReading: Equatable {
    let batteryWatts: Double?
    let inputVolts: Double?
    let inputAmps: Double?
    let inputWatts: Double?
    let batteryTemperatureCelsius: Double?
    let sampledAt: Date

    init(
        batteryWatts: Double?,
        inputVolts: Double?,
        inputAmps: Double?,
        inputWatts: Double?,
        batteryTemperatureCelsius: Double? = nil,
        sampledAt: Date = Date()
    ) {
        self.batteryWatts = batteryWatts
        self.inputVolts = inputVolts
        self.inputAmps = inputAmps
        self.inputWatts = inputWatts
        self.batteryTemperatureCelsius = batteryTemperatureCelsius
        self.sampledAt = sampledAt
    }
}

final class SMCPowerReader {
    private let client = AppleSMCClient()

    func read(at date: Date = Date()) -> SMCPowerReading? {
        let batteryWatts = value(for: .batteryPower)
        let inputVolts = value(for: .inputVoltage)
        let inputAmps = value(for: .inputCurrent)
        let inputWatts = value(for: .inputPower) ?? product(inputVolts, inputAmps)
        let temperatures = [PowerRail.batteryTemperature1, .batteryTemperature2]
            .compactMap(value)
        let batteryTemperature = temperatures.isEmpty
            ? nil
            : temperatures.reduce(0, +) / Double(temperatures.count)

        guard batteryWatts != nil
            || inputVolts != nil
            || inputAmps != nil
            || inputWatts != nil
            || batteryTemperature != nil else {
            return nil
        }
        return SMCPowerReading(
            batteryWatts: batteryWatts,
            inputVolts: inputVolts,
            inputAmps: inputAmps,
            inputWatts: inputWatts,
            batteryTemperatureCelsius: batteryTemperature,
            sampledAt: date
        )
    }

    static func decodeFloat(_ bytes: [UInt8]) -> Float? {
        SMCValueDecoder.decodeFloat(bytes)
    }

    static func decode(_ bytes: [UInt8], type: String) -> Double? {
        guard let encodedType = AppleSMCKey(type)?.encoded else { return nil }
        return SMCValueDecoder.decode(bytes, type: encodedType)
    }

    static func fourCC(_ key: String) -> UInt32? {
        AppleSMCKey(key)?.encoded
    }

    private func value(for rail: PowerRail) -> Double? {
        guard let key = AppleSMCKey(rail.rawValue),
              let reading = client.numericValue(for: key),
              rail.validRange.contains(reading) else {
            return nil
        }
        return reading
    }

    private func product(_ left: Double?, _ right: Double?) -> Double? {
        guard let left, let right else { return nil }
        return left * right
    }
}

private enum PowerRail: String {
    case batteryPower = "PPBR"
    case inputVoltage = "VD0R"
    case inputCurrent = "ID0R"
    case inputPower = "PDTR"
    case batteryTemperature1 = "TB1T"
    case batteryTemperature2 = "TB2T"

    var validRange: ClosedRange<Double> {
        switch self {
        case .batteryPower:
            return SMCValueLimits.batteryPowerWatts
        case .inputVoltage:
            return SMCValueLimits.inputVoltageVolts
        case .inputCurrent:
            return SMCValueLimits.inputCurrentAmps
        case .inputPower:
            return SMCValueLimits.inputPowerWatts
        case .batteryTemperature1, .batteryTemperature2:
            return SMCValueLimits.batteryTemperatureCelsius
        }
    }
}

private struct AppleSMCKey {
    let encoded: UInt32

    init?(_ value: String) {
        let bytes = Array(value.utf8)
        guard bytes.count == FourCharacterCode.byteCount else { return nil }
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

    func numericValue(for key: AppleSMCKey) -> Double? {
        guard connect(), let reading = reading(for: key) else { return nil }
        return SMCValueDecoder.decode(reading.payload, type: reading.type)
    }

    private func connect() -> Bool {
        guard MemoryLayout<AppleSMCMessage>.stride == AppleSMCConnection.messageStride else {
            return false
        }
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

    private func reading(for key: AppleSMCKey) -> (payload: [UInt8], type: UInt32)? {
        var metadataRequest = AppleSMCMessage()
        metadataRequest.key = key.encoded
        metadataRequest.operation = AppleSMCOperation.readMetadata.rawValue
        guard let metadataResponse = exchange(metadataRequest) else { return nil }

        let length = metadataResponse.metadata.length
        guard length > 0, length <= AppleSMCConnection.maximumPayloadLength else { return nil }

        var valueRequest = AppleSMCMessage()
        valueRequest.key = key.encoded
        valueRequest.metadata = metadataResponse.metadata
        valueRequest.operation = AppleSMCOperation.readValue.rawValue
        guard var valueResponse = exchange(valueRequest) else { return nil }

        let payload = withUnsafeBytes(of: &valueResponse.payload) {
            Array($0.prefix(Int(length)))
        }
        return (payload, metadataResponse.metadata.type)
    }

    private func exchange(_ request: AppleSMCMessage) -> AppleSMCMessage? {
        var request = request
        var response = AppleSMCMessage()
        var responseSize = MemoryLayout<AppleSMCMessage>.stride
        let result = IOConnectCallStructMethod(
            connection,
            AppleSMCConnection.userClientMethod,
            &request,
            MemoryLayout<AppleSMCMessage>.stride,
            &response,
            &responseSize
        )
        guard result == KERN_SUCCESS, response.result == 0 else { return nil }
        return response
    }
}

private enum SMCValueDecoder {
    static func decode(_ bytes: [UInt8], type: UInt32) -> Double? {
        switch dataTypeName(type) {
        case SMCDataType.float:
            return decodeFloat(bytes).map(Double.init)
        case SMCDataType.unsignedByte:
            return bytes.first.map(Double.init)
        case SMCDataType.unsignedWord:
            return unsignedInteger(bytes, count: SMCDataSize.word).map { Double($0) }
        case SMCDataType.unsignedDoubleWord:
            return unsignedInteger(bytes, count: SMCDataSize.doubleWord).map { Double($0) }
        case SMCDataType.signedByte:
            return bytes.first.map { Double(Int8(bitPattern: $0)) }
        case SMCDataType.signedWord:
            return signedInteger(bytes, count: SMCDataSize.word).map { Double($0) }
        case SMCDataType.signedDoubleWord:
            return signedInteger(bytes, count: SMCDataSize.doubleWord).map { Double($0) }
        default:
            return fixedPoint(bytes, type: type)
        }
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

    private static func fixedPoint(_ bytes: [UInt8], type: UInt32) -> Double? {
        let characters = dataTypeBytes(type)
        guard characters[SMCFixedPointFormat.radixMarkerIndex] == SMCFixedPointFormat.radixMarker,
              let fractionalBits = hexadecimalDigit(
                characters[SMCFixedPointFormat.fractionalBitsIndex]
              ),
              fractionalBits < SMCFixedPointFormat.maximumFractionalBits else {
            return nil
        }
        let divisor = Double(1 << fractionalBits)
        if characters[SMCFixedPointFormat.signednessIndex] == SMCFixedPointFormat.signedMarker {
            return signedInteger(bytes, count: SMCDataSize.word).map { Double($0) / divisor }
        }
        if characters[SMCFixedPointFormat.signednessIndex] == SMCFixedPointFormat.unsignedMarker {
            return unsignedInteger(bytes, count: SMCDataSize.word).map { Double($0) / divisor }
        }
        return nil
    }

    private static func unsignedInteger(_ bytes: [UInt8], count: Int) -> UInt64? {
        guard bytes.count >= count,
              (SMCDataSize.byte...MemoryLayout<UInt64>.size).contains(count) else {
            return nil
        }
        return bytes.prefix(count).reduce(0) { ($0 << 8) | UInt64($1) }
    }

    private static func signedInteger(_ bytes: [UInt8], count: Int) -> Int64? {
        guard let unsigned = unsignedInteger(bytes, count: count) else { return nil }
        let shift = UInt64.bitWidth - count * UInt8.bitWidth
        return Int64(bitPattern: unsigned << shift) >> shift
    }

    private static func hexadecimalDigit(_ value: UInt8) -> Int? {
        Int(String(UnicodeScalar(value)), radix: SMCFixedPointFormat.hexadecimalRadix)
    }

    private static func dataTypeName(_ type: UInt32) -> String {
        String(decoding: dataTypeBytes(type), as: UTF8.self)
    }

    private static func dataTypeBytes(_ type: UInt32) -> [UInt8] {
        withUnsafeBytes(of: type.bigEndian) { Array($0) }
    }
}

private enum FourCharacterCode {
    static let byteCount = 4
}

private enum SMCDataSize {
    static let byte = 1
    static let word = 2
    static let doubleWord = 4
}

private enum SMCFixedPointFormat {
    static let signednessIndex = 0
    static let radixMarkerIndex = 1
    static let fractionalBitsIndex = 3
    static let signedMarker = UInt8(ascii: "s")
    static let unsignedMarker = UInt8(ascii: "f")
    static let radixMarker = UInt8(ascii: "p")
    static let maximumFractionalBits = UInt16.bitWidth
    static let hexadecimalRadix = 16
}

private enum SMCDataType {
    static let float = "flt "
    static let unsignedByte = "ui8 "
    static let unsignedWord = "ui16"
    static let unsignedDoubleWord = "ui32"
    static let signedByte = "si8 "
    static let signedWord = "si16"
    static let signedDoubleWord = "si32"
}

private enum SMCValueLimits {
    static let batteryPowerWatts = -200.0...200.0
    static let inputVoltageVolts = 0.0...100.0
    static let inputCurrentAmps = -50.0...50.0
    static let inputPowerWatts = -500.0...500.0
    static let batteryTemperatureCelsius = -20.0...120.0
}

private enum AppleSMCConnection {
    static let userClientMethod: UInt32 = 2
    static let messageStride = 80
    static let maximumPayloadLength: UInt32 = 32
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
