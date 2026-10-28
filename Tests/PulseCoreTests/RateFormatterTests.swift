import Testing

@testable import PulseCore

@Suite("Rate formatting")
struct RateFormatterTests {
    @Test("Idle traffic reads as zero kilobytes")
    func zero() {
        #expect(RateFormatter.format(bytesPerSecond: 0) == "0 KB/s")
    }

    @Test("Tiny background traffic rounds into kilobytes")
    func belowOneKilobyte() {
        #expect(RateFormatter.format(bytesPerSecond: 40) == "0 KB/s")
        #expect(RateFormatter.format(bytesPerSecond: 512) == "0.5 KB/s")
    }

    @Test("Small values keep one decimal place")
    func smallValuesHaveDecimal() {
        #expect(RateFormatter.format(bytesPerSecond: 4_200) == "4.2 KB/s")
        #expect(RateFormatter.format(bytesPerSecond: 4_800_000) == "4.8 MB/s")
        #expect(RateFormatter.format(bytesPerSecond: 1_000_000) == "1.0 MB/s")
    }

    @Test("Values of ten and above drop the decimal")
    func largeValuesAreWhole() {
        #expect(RateFormatter.format(bytesPerSecond: 120_000) == "120 KB/s")
        #expect(RateFormatter.format(bytesPerSecond: 54_400_000) == "54 MB/s")
    }

    @Test("Rounding up to a thousand moves to the next unit")
    func roundingCrossesUnit() {
        #expect(RateFormatter.format(bytesPerSecond: 999_600) == "1.0 MB/s")
        #expect(RateFormatter.format(bytesPerSecond: 9_960) == "10 KB/s")
    }

    @Test("Gigabytes are the top unit")
    func gigabytes() {
        #expect(RateFormatter.format(bytesPerSecond: 2_500_000_000) == "2.5 GB/s")
        #expect(RateFormatter.format(bytesPerSecond: 5_000_000_000_000) == "5000 GB/s")
    }

    @Test("Negative or invalid input never shows nonsense")
    func invalidInput() {
        #expect(RateFormatter.format(bytesPerSecond: -10) == "0 KB/s")
        #expect(RateFormatter.format(bytesPerSecond: .nan) == "0 KB/s")
        #expect(RateFormatter.format(bytesPerSecond: .infinity) == "0 KB/s")
    }
}
