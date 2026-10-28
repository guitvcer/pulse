import Foundation

/// Turns a byte rate into a short menu bar label such as "4.8 MB/s".
///
/// Uses decimal units (1 KB = 1000 bytes), like Finder. Values under ten keep
/// one decimal place, larger ones are whole, so a label never exceeds
/// four significant characters before the unit (except absurd GB values).
public enum RateFormatter {
    private static let units = ["KB/s", "MB/s", "GB/s"]

    public static func format(bytesPerSecond: Double) -> String {
        guard bytesPerSecond.isFinite, bytesPerSecond > 0 else { return "0 KB/s" }

        var value = bytesPerSecond / 1000
        var unitIndex = 0
        while unitIndex < units.count - 1, rounded(value) >= 1000 {
            value /= 1000
            unitIndex += 1
        }

        let shown = rounded(value)
        let unit = units[unitIndex]
        if shown == 0 { return "0 \(unit)" }
        if shown < 10 { return String(format: "%.1f %@", shown, unit) }
        return String(format: "%.0f %@", shown, unit)
    }

    /// Rounds the way the label will display it: one decimal under ten, whole above.
    private static func rounded(_ value: Double) -> Double {
        let tenths = (value * 10).rounded() / 10
        return tenths < 10 ? tenths : value.rounded()
    }
}
