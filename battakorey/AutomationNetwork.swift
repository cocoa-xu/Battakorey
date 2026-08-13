import Darwin
import Foundation

enum AutomationNetworkScope: String, CaseIterable, Identifiable {
    case thisMac
    case allInterfaces
    case selectedInterface

    var id: String { rawValue }

    var label: String {
        switch self {
        case .thisMac: "This Mac Only"
        case .allInterfaces: "All Interfaces"
        case .selectedInterface: "One Interface"
        }
    }

    var exposesToNetwork: Bool { self != .thisMac }
}

struct AutomationNetworkInterface: Identifiable, Equatable {
    let name: String
    let address: String

    var id: String { "\(name):\(address)" }
    var label: String { "\(name) · \(address)" }

    static var current: [AutomationNetworkInterface] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let head else { return [] }
        defer { freeifaddrs(head) }

        var result: [AutomationNetworkInterface] = []
        var cursor: UnsafeMutablePointer<ifaddrs>? = head
        while let entry = cursor?.pointee {
            defer { cursor = entry.ifa_next }
            guard let address = entry.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_INET),
                  entry.ifa_flags & UInt32(IFF_UP) != 0,
                  entry.ifa_flags & UInt32(IFF_LOOPBACK) == 0 else {
                continue
            }
            var value = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                $0.pointee.sin_addr
            }
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            guard inet_ntop(AF_INET, &value, &buffer, socklen_t(buffer.count)) != nil else {
                continue
            }
            result.append(AutomationNetworkInterface(
                name: String(cString: entry.ifa_name),
                address: String(cString: buffer)
            ))
        }
        return Array(Set(result.map(\.id))).compactMap { id in
            result.first { $0.id == id }
        }.sorted {
            $0.name == $1.name ? $0.address < $1.address : $0.name < $1.name
        }
    }
}
