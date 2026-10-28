import Testing

@testable import PulseCore

@Suite("Which connections count")
struct InterfaceFilterTests {
    @Test("Wi-Fi, Ethernet and cellular tethering count", arguments: ["en0", "en1", "en7", "pdp_ip0"])
    func physicalCounts(name: String) {
        #expect(InterfaceFilter.counts(name: name, isLoopback: false))
    }

    @Test(
        "Loopback, VPN tunnels and Apple-internal links do not count",
        arguments: ["lo0", "utun0", "utun4", "awdl0", "llw0", "bridge0", "gif0", "stf0", "anpi0", "ap1"])
    func virtualIgnored(name: String) {
        #expect(!InterfaceFilter.counts(name: name, isLoopback: false))
    }

    @Test("Anything flagged as loopback never counts")
    func loopbackFlag() {
        #expect(!InterfaceFilter.counts(name: "en0", isLoopback: true))
    }
}
