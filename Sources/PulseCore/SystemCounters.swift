import Darwin
import Foundation

public enum SystemCountersError: Error {
    case sysctlFailed(errno: Int32)
}

/// Reads lifetime byte counters for every counted interface from the kernel.
///
/// Uses the routing sysctl with `NET_RT_IFLIST2`, which carries 64-bit
/// counters (the classic `getifaddrs` ones wrap at 4 GB).
public enum SystemCounters {
    public static func read(now: Date = Date()) throws -> TrafficSnapshot {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &length, nil, 0) == 0 else {
            throw SystemCountersError.sysctlFailed(errno: errno)
        }
        // Interfaces can appear between the two calls; leave some headroom.
        length += length / 4
        var buffer = [UInt8](repeating: 0, count: length)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &length, nil, 0) == 0 else {
            throw SystemCountersError.sysctlFailed(errno: errno)
        }

        var counters: [String: InterfaceCounters] = [:]
        buffer.withUnsafeBytes { raw in
            var offset = 0
            while offset + MemoryLayout<if_msghdr>.size <= length {
                let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
                guard header.ifm_msglen > 0 else { break }
                defer { offset += Int(header.ifm_msglen) }

                guard Int32(header.ifm_type) == RTM_IFINFO2,
                    offset + MemoryLayout<if_msghdr2>.size <= length
                else { continue }
                let message = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
                let end = offset + Int(header.ifm_msglen)
                guard let name = interfaceName(in: raw, at: offset + MemoryLayout<if_msghdr2>.size, end: end)
                else { continue }

                let isLoopback = (message.ifm_flags & IFF_LOOPBACK) != 0
                guard InterfaceFilter.counts(name: name, isLoopback: isLoopback) else { continue }
                counters[name] = InterfaceCounters(
                    received: message.ifm_data.ifi_ibytes,
                    sent: message.ifm_data.ifi_obytes)
            }
        }
        return TrafficSnapshot(counters: counters, takenAt: now)
    }

    /// The link-level address that follows each interface message carries its name,
    /// which saves a separate system call per interface.
    private static func interfaceName(in raw: UnsafeRawBufferPointer, at offset: Int, end: Int) -> String? {
        guard offset + MemoryLayout<sockaddr_dl>.size <= end else { return nil }
        let address = raw.loadUnaligned(fromByteOffset: offset, as: sockaddr_dl.self)
        guard Int32(address.sdl_family) == AF_LINK, address.sdl_nlen > 0 else { return nil }
        let nameStart = offset + MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data)!
        let nameEnd = nameStart + Int(address.sdl_nlen)
        guard nameEnd <= end else { return nil }
        return String(decoding: raw[nameStart..<nameEnd], as: UTF8.self)
    }
}
