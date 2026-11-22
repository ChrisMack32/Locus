import Darwin
import Foundation
import UIKit

enum LocalDevVPN {
    static let appStoreURL = URL(string: "https://apps.apple.com/us/app/localdevvpn/id6755608044")!
    static let detectURL = URL(string: "localdevvpn://")!

    /// Starts the tunnel, then returns to Locus via `locus://`.
    static let enableURL = URL(string: "localdevvpn://enable?scheme=locus")!

    static var isInstalled: Bool {
        UIApplication.shared.canOpenURL(detectURL)
    }

    /// True when traffic to the tunnel peer (usually `10.7.0.1`) leaves through a VPN interface.
    ///
    /// Current LocalDevVPN puts `10.7.1.1/32` on the utun and only *routes* `10.7.0.1`.
    /// Looking for `10.7.0.x` on an interface misses that, so the status chip stayed on
    /// “Connect” while teleport still worked.
    static var isConnected: Bool {
        let target = TunnelConfig.targetIP
        if let source = udpRouteSourceAddress(for: target),
           let name = interfaceName(owning: source),
           isTunnelInterface(name) {
            return true
        }
        // Older builds assigned `10.7.0.0/24` directly to the utun.
        return tunnelInterfaceAddresses().contains { address in
            address == target || sharesPrivatePrefix(address, target)
        }
    }

    static func openInstalled() {
        UIApplication.shared.open(enableURL)
    }

    static func openAppStore() {
        UIApplication.shared.open(appStoreURL)
    }

    /// Open LocalDevVPN to connect if installed; otherwise App Store.
    static func openOrInstall() {
        if isInstalled {
            openInstalled()
        } else {
            openAppStore()
        }
    }

    /// UDP `connect` sends nothing. The kernel only picks the source address for the route.
    private static func udpRouteSourceAddress(for host: String) -> String? {
        let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard fd >= 0 else { return nil }
        defer { close(fd) }

        var remote = sockaddr_in()
        remote.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        remote.sin_family = sa_family_t(AF_INET)
        remote.sin_port = in_port_t(9).bigEndian
        guard inet_pton(AF_INET, host, &remote.sin_addr) == 1 else { return nil }

        let connected = withUnsafePointer(to: &remote) { pointer -> Int32 in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { address in
                connect(fd, address, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard connected == 0 else { return nil }

        var local = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let named = withUnsafeMutablePointer(to: &local) { pointer -> Int32 in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { address in
                getsockname(fd, address, &length)
            }
        }
        guard named == 0 else { return nil }

        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        guard inet_ntop(AF_INET, &local.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else { return nil }
        let address = String(cString: buffer)
        return address == "0.0.0.0" ? nil : address
    }

    private static func interfaceName(owning address: String) -> String? {
        enumerateIPv4 { name, host in
            host == address ? name : nil
        }
    }

    private static func tunnelInterfaceAddresses() -> [String] {
        var found: [String] = []
        enumerateIPv4 { name, host in
            if isTunnelInterface(name) { found.append(host) }
            return nil as String?
        }
        return found
    }

    private static func isTunnelInterface(_ name: String) -> Bool {
        name.hasPrefix("utun") || name.hasPrefix("ipsec") || name.hasPrefix("ppp")
    }

    private static func sharesPrivatePrefix(_ address: String, _ target: String) -> Bool {
        let addressParts = address.split(separator: ".")
        let targetParts = target.split(separator: ".")
        guard addressParts.count == 4, targetParts.count == 4 else { return false }
        return addressParts[0] == targetParts[0]
            && addressParts[1] == targetParts[1]
            && addressParts[2] == targetParts[2]
    }

    @discardableResult
    private static func enumerateIPv4<T>(_ body: (String, String) -> T?) -> T? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            let interface = current.pointee
            if let address = interface.ifa_addr,
               address.pointee.sa_family == UInt8(AF_INET),
               let namePtr = interface.ifa_name {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(
                    address,
                    socklen_t(MemoryLayout<sockaddr_in>.size),
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                ) == 0 {
                    if let match = body(String(cString: namePtr), String(cString: host)) {
                        return match
                    }
                }
            }
            pointer = interface.ifa_next
        }
        return nil
    }
}
