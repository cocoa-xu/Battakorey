import Foundation
import IOKit

struct SMCPowerReading: Equatable {
    let batteryWatts: Double?
    let inputVolts: Double?
    let inputAmps: Double?
    let inputWatts: Double?
}

final class SMCPowerReader {
    private var connection: io_connect_t = 0

    deinit {
        if connection != 0 {
            IOServiceClose(connection)
        }
    }

    func read() -> SMCPowerReading? {
        guard open() else { return nil }

        let batteryWatts = plausible(readFloat(key: "PPBR"), range: 0..<200)
        let inputVolts = plausible(readFloat(key: "VD0R"), range: 0..<100)
        let inputAmps = plausible(readFloat(key: "ID0R"), range: 0..<50)
        let reportedInputWatts = plausible(readFloat(key: "PDTR"), range: 0..<500)
        let calculatedInputWatts = inputVolts.flatMap { volts in inputAmps.map { volts * $0 } }
        let inputWatts = reportedInputWatts ?? calculatedInputWatts

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

    private func open() -> Bool {
        guard MemoryLayout<SMCParamStruct>.stride == 80 else { return false }
        if connection != 0 { return true }
        guard let matching = IOServiceMatching("AppleSMC") else { return false }
        let service = IOServiceGetMatchingService(mach_port_t(MACH_PORT_NULL), matching)
        guard service != IO_OBJECT_NULL else { return false }
        defer { IOObjectRelease(service) }

        var newConnection: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, 0, &newConnection) == KERN_SUCCESS else {
            return false
        }
        connection = newConnection
        return true
    }

    private func readFloat(key: String) -> Double? {
        guard let bytes = readKey(key) else { return nil }
        return Self.decodeFloat(bytes).map(Double.init)
    }

    private func plausible(_ value: Double?, range: Range<Double>) -> Double? {
        guard let value, range.contains(value) else { return nil }
        return value
    }

    private func readKey(_ key: String) -> [UInt8]? {
        guard let encodedKey = Self.fourCC(key) else { return nil }

        var info = SMCParamStruct()
        info.key = encodedKey
        info.data8 = Self.getKeyInfoCommand
        guard let keyInfo = callDriver(input: &info), keyInfo.keyInfo.dataSize > 0 else {
            return nil
        }

        var read = SMCParamStruct()
        read.key = encodedKey
        read.keyInfo.dataSize = keyInfo.keyInfo.dataSize
        read.keyInfo.dataType = keyInfo.keyInfo.dataType
        read.data8 = Self.readKeyCommand
        guard let output = callDriver(input: &read) else { return nil }

        var bytes = output.bytes
        return withUnsafeBytes(of: &bytes) {
            Array($0.prefix(Int(min(keyInfo.keyInfo.dataSize, 32))))
        }
    }

    private func callDriver(input: inout SMCParamStruct) -> SMCParamStruct? {
        guard connection != 0 else { return nil }
        var output = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.stride
        let result = IOConnectCallStructMethod(
            connection,
            Self.kernelIndex,
            &input,
            MemoryLayout<SMCParamStruct>.stride,
            &output,
            &outputSize
        )
        guard result == KERN_SUCCESS, output.result == 0 else { return nil }
        return output
    }

    static func decodeFloat(_ bytes: [UInt8]) -> Float? {
        guard bytes.count >= 4 else { return nil }
        let bits = UInt32(bytes[0])
            | UInt32(bytes[1]) << 8
            | UInt32(bytes[2]) << 16
            | UInt32(bytes[3]) << 24
        let value = Float(bitPattern: bits)
        return value.isFinite ? value : nil
    }

    static func fourCC(_ key: String) -> UInt32? {
        let scalars = Array(key.unicodeScalars)
        guard scalars.count == 4 else { return nil }
        var result: UInt32 = 0
        for scalar in scalars {
            guard scalar.value <= 0xFF else { return nil }
            result = (result << 8) | UInt32(scalar.value)
        }
        return result
    }

    private static let kernelIndex: UInt32 = 2
    private static let readKeyCommand: UInt8 = 5
    private static let getKeyInfoCommand: UInt8 = 9
}

private struct SMCVersion {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

private struct SMCPLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memoryPLimit: UInt32 = 0
}

private struct SMCKeyInfoData {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

private typealias SMCBytes = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
)

private struct SMCParamStruct {
    var key: UInt32 = 0
    var version = SMCVersion()
    var powerLimit = SMCPLimitData()
    var keyInfo = SMCKeyInfoData()
    var padding: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: SMCBytes = (
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
    )
}
