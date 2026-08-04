import CoreFoundation
import Darwin
import Foundation

struct IOReportPowerReading: Equatable {
    let cpuWatts: Double?
    let gpuWatts: Double?
    let aneWatts: Double?
    let memoryWatts: Double?
    let gpuMemoryWatts: Double?
    let displayWatts: Double?
    let externalDisplayWatts: Double?
}

struct IOReportEnergySample {
    let channel: String
    let unit: String
    let energy: Int64
}

enum IOReportPowerDecoder {
    static func reading(
        from samples: [IOReportEnergySample],
        duration: TimeInterval
    ) -> IOReportPowerReading? {
        guard duration.isFinite, duration > 0 else { return nil }

        var cpuWatts: Double?
        var gpuWatts: Double?
        var aneWatts: Double?
        var memoryWatts: Double?
        var gpuMemoryWatts: Double?
        var displayWatts: Double?
        var externalDisplayWatts: Double?

        for sample in samples {
            guard let watts = watts(for: sample, duration: duration) else { continue }

            switch sample.channel {
            case let channel where channel.hasSuffix("CPU Energy"):
                add(watts, to: &cpuWatts)
            case "GPU Energy":
                add(watts, to: &gpuWatts)
            case let channel where channel.hasPrefix("ANE"):
                add(watts, to: &aneWatts)
            case let channel where channel.hasPrefix("DRAM"):
                add(watts, to: &memoryWatts)
            case let channel where channel.hasPrefix("GPU SRAM"):
                add(watts, to: &gpuMemoryWatts)
            case "DISP":
                add(watts, to: &displayWatts)
            case "DISPEXT":
                add(watts, to: &externalDisplayWatts)
            default:
                continue
            }
        }

        let values = [
            cpuWatts,
            gpuWatts,
            aneWatts,
            memoryWatts,
            gpuMemoryWatts,
            displayWatts,
            externalDisplayWatts
        ]
        guard values.contains(where: { $0 != nil }) else { return nil }

        return IOReportPowerReading(
            cpuWatts: cpuWatts,
            gpuWatts: gpuWatts,
            aneWatts: aneWatts,
            memoryWatts: memoryWatts,
            gpuMemoryWatts: gpuMemoryWatts,
            displayWatts: displayWatts,
            externalDisplayWatts: externalDisplayWatts
        )
    }

    private static func watts(
        for sample: IOReportEnergySample,
        duration: TimeInterval
    ) -> Double? {
        guard sample.energy >= 0 else { return nil }

        let joules: Double
        switch sample.unit.lowercased() {
        case "j":
            joules = Double(sample.energy)
        case "mj":
            joules = Double(sample.energy) / 1_000
        case "uj", "µj":
            joules = Double(sample.energy) / 1_000_000
        case "nj":
            joules = Double(sample.energy) / 1_000_000_000
        default:
            return nil
        }
        return joules / duration
    }

    private static func add(_ value: Double, to total: inout Double?) {
        total = (total ?? 0) + value
    }
}

final class IOReportPowerReader {
    private let api: IOReportAPI
    private let channels: CFMutableDictionary
    private let subscription: UnsafeMutableRawPointer
    private var previousSample: CFDictionary?
    private var previousTimestamp: TimeInterval?

    init?() {
        guard let api = IOReportAPI(),
              let channels = api.makePowerChannels() else {
            return nil
        }

        var subscribedChannels: CFMutableDictionary?
        guard let subscription = api.createSubscription(
            nil,
            channels,
            &subscribedChannels,
            0,
            nil
        ) else {
            return nil
        }

        self.api = api
        self.channels = channels
        self.subscription = subscription
    }

    func read() -> IOReportPowerReading? {
        guard let sample = api.createSamples(subscription, channels, nil)?.takeRetainedValue() else {
            previousSample = nil
            previousTimestamp = nil
            return nil
        }

        let timestamp = ProcessInfo.processInfo.systemUptime
        defer {
            previousSample = sample
            previousTimestamp = timestamp
        }

        guard let previousSample,
              let previousTimestamp,
              timestamp > previousTimestamp,
              let delta = api.createSamplesDelta(previousSample, sample, nil)?.takeRetainedValue()
        else {
            return nil
        }

        let samples = api.energySamples(in: delta)
        return IOReportPowerDecoder.reading(
            from: samples,
            duration: timestamp - previousTimestamp
        )
    }
}

private final class IOReportAPI {
    typealias CopyAllChannels = @convention(c) (UInt64, UInt64) -> Unmanaged<CFDictionary>?
    typealias CreateSubscription = @convention(c) (
        UnsafeRawPointer?,
        CFMutableDictionary,
        UnsafeMutablePointer<CFMutableDictionary?>?,
        UInt64,
        UnsafeRawPointer?
    ) -> UnsafeMutableRawPointer?
    typealias CreateSamples = @convention(c) (
        UnsafeMutableRawPointer,
        CFMutableDictionary,
        UnsafeRawPointer?
    ) -> Unmanaged<CFDictionary>?
    typealias CreateSamplesDelta = @convention(c) (
        CFDictionary,
        CFDictionary,
        UnsafeRawPointer?
    ) -> Unmanaged<CFDictionary>?
    typealias ChannelString = @convention(c) (CFDictionary) -> Unmanaged<CFString>?
    typealias IntegerValue = @convention(c) (CFDictionary, Int32) -> Int64

    let copyAllChannels: CopyAllChannels
    let createSubscription: CreateSubscription
    let createSamples: CreateSamples
    let createSamplesDelta: CreateSamplesDelta

    private let handle: UnsafeMutableRawPointer
    private let channelGroup: ChannelString
    private let channelName: ChannelString
    private let channelUnit: ChannelString
    private let integerValue: IntegerValue

    init?() {
        guard let handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_LAZY | RTLD_LOCAL) else {
            return nil
        }
        guard let copyAllChannels = Self.resolve("IOReportCopyAllChannels", from: handle, as: CopyAllChannels.self),
              let createSubscription = Self.resolve("IOReportCreateSubscription", from: handle, as: CreateSubscription.self),
              let createSamples = Self.resolve("IOReportCreateSamples", from: handle, as: CreateSamples.self),
              let createSamplesDelta = Self.resolve("IOReportCreateSamplesDelta", from: handle, as: CreateSamplesDelta.self),
              let channelGroup = Self.resolve("IOReportChannelGetGroup", from: handle, as: ChannelString.self),
              let channelName = Self.resolve("IOReportChannelGetChannelName", from: handle, as: ChannelString.self),
              let channelUnit = Self.resolve("IOReportChannelGetUnitLabel", from: handle, as: ChannelString.self),
              let integerValue = Self.resolve("IOReportSimpleGetIntegerValue", from: handle, as: IntegerValue.self)
        else {
            dlclose(handle)
            return nil
        }

        self.handle = handle
        self.copyAllChannels = copyAllChannels
        self.createSubscription = createSubscription
        self.createSamples = createSamples
        self.createSamplesDelta = createSamplesDelta
        self.channelGroup = channelGroup
        self.channelName = channelName
        self.channelUnit = channelUnit
        self.integerValue = integerValue
    }

    deinit {
        dlclose(handle)
    }

    func makePowerChannels() -> CFMutableDictionary? {
        guard let allChannels = copyAllChannels(0, 0)?.takeRetainedValue(),
              let source = channelArray(in: allChannels) else {
            return nil
        }

        var callbacks = kCFTypeArrayCallBacks
        guard let selected = CFArrayCreateMutable(kCFAllocatorDefault, 0, &callbacks) else {
            return nil
        }

        for index in 0..<CFArrayGetCount(source) {
            guard let pointer = CFArrayGetValueAtIndex(source, index) else { continue }
            let channel = unsafeBitCast(pointer, to: CFDictionary.self)
            if string(from: channelGroup(channel)) == "Energy Model",
               isPowerChannel(string(from: channelName(channel))) {
                CFArrayAppendValue(selected, pointer)
            }
        }

        guard CFArrayGetCount(selected) > 0,
              let channels = CFDictionaryCreateMutableCopy(
                kCFAllocatorDefault,
                CFDictionaryGetCount(allChannels),
                allChannels
              ) else {
            return nil
        }

        let key = "IOReportChannels" as CFString
        CFDictionarySetValue(
            channels,
            Unmanaged.passUnretained(key).toOpaque(),
            Unmanaged.passUnretained(selected).toOpaque()
        )
        return channels
    }

    func energySamples(in report: CFDictionary) -> [IOReportEnergySample] {
        guard let channels = channelArray(in: report) else { return [] }

        return (0..<CFArrayGetCount(channels)).compactMap { index in
            guard let pointer = CFArrayGetValueAtIndex(channels, index) else { return nil }
            let channel = unsafeBitCast(pointer, to: CFDictionary.self)
            return IOReportEnergySample(
                channel: string(from: channelName(channel)),
                unit: string(from: channelUnit(channel)),
                energy: integerValue(channel, 0)
            )
        }
    }

    private func channelArray(in report: CFDictionary) -> CFArray? {
        let key = "IOReportChannels" as CFString
        guard let pointer = CFDictionaryGetValue(
            report,
            Unmanaged.passUnretained(key).toOpaque()
        ) else {
            return nil
        }
        let value = unsafeBitCast(pointer, to: CFTypeRef.self)
        guard CFGetTypeID(value) == CFArrayGetTypeID() else { return nil }
        return unsafeBitCast(pointer, to: CFArray.self)
    }

    private func string(from value: Unmanaged<CFString>?) -> String {
        value.map { $0.takeUnretainedValue() as String } ?? ""
    }

    private func isPowerChannel(_ channel: String) -> Bool {
        channel.hasSuffix("CPU Energy")
            || channel == "GPU Energy"
            || channel.hasPrefix("ANE")
            || channel.hasPrefix("DRAM")
            || channel.hasPrefix("GPU SRAM")
            || channel == "DISP"
            || channel == "DISPEXT"
    }

    private static func resolve<T>(
        _ name: String,
        from handle: UnsafeMutableRawPointer,
        as type: T.Type
    ) -> T? {
        guard let symbol = dlsym(handle, name) else { return nil }
        return unsafeBitCast(symbol, to: type)
    }
}
