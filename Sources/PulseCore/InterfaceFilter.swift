/// Decides which network interfaces represent real internet traffic.
///
/// Only physical links count: Wi-Fi and Ethernet (`en*`) and cellular
/// tethering (`pdp_ip*`). VPN tunnels are skipped because their traffic is
/// already counted on the physical link underneath; loopback and Apple's
/// internal links (AirDrop, Sidecar, bridges) are not internet at all.
public enum InterfaceFilter {
    private static let countedPrefixes = ["en", "pdp_ip"]

    public static func counts(name: String, isLoopback: Bool) -> Bool {
        guard !isLoopback else { return false }
        return countedPrefixes.contains { name.hasPrefix($0) }
    }
}
