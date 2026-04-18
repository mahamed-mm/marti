import Foundation
import Testing
@testable import Marti

struct LiveCurrencyServiceTests {

    // MARK: - Formatting

    @Test func formatsSmallAmountAsAbbreviatedSOS() {
        let result = LiveCurrencyService.format(sos: 850, display: .abbreviated)
        #expect(result == "~850 SOS")
    }

    @Test func formatsThousandsAsAbbreviated() {
        let result = LiveCurrencyService.format(sos: 48_550, display: .abbreviated)
        #expect(result == "~48.6K SOS")
    }

    @Test func formatsMillionsAsAbbreviatedWithOneDecimal() {
        let result = LiveCurrencyService.format(sos: 1_530_000, display: .abbreviated)
        #expect(result == "~1.5M SOS")
    }

    @Test func formatsExactMillionsWithoutDecimal() {
        let result = LiveCurrencyService.format(sos: 2_000_000, display: .abbreviated)
        #expect(result == "~2M SOS")
    }

    @Test func formatsFullValueWithGroupingSeparators() {
        let result = LiveCurrencyService.format(sos: 1_530_000, display: .full)
        #expect(result == "~1,530,000 SOS")
    }

    // MARK: - Cache lookup

    @Test func returnsNilWhenCacheEmpty() {
        let defaults = makeDefaults()
        let service = LiveCurrencyService(userDefaults: defaults, now: { Date() })
        #expect(service.usdToSOS(8500, display: .abbreviated) == nil)
        #expect(service.usdToSOS(8500, display: .full) == nil)
    }

    @Test func usesCachedRateWhenFresh() {
        let defaults = makeDefaults()
        let fixedNow = Date(timeIntervalSince1970: 2_000_000_000)
        defaults.set(570.0, forKey: LiveCurrencyService.rateKey)
        defaults.set(fixedNow.addingTimeInterval(-3_600), forKey: LiveCurrencyService.timestampKey)

        let service = LiveCurrencyService(userDefaults: defaults, now: { fixedNow })
        let result = service.usdToSOS(8500, display: .abbreviated)
        // 8500 cents = $85; 85 * 570 = 48,450 SOS ≈ "~48.5K SOS"
        #expect(result == "~48.5K SOS")
    }

    @Test func returnsNilWhenCacheOlderThanSevenDays() {
        let defaults = makeDefaults()
        let fixedNow = Date(timeIntervalSince1970: 2_000_000_000)
        let eightDaysAgo = fixedNow.addingTimeInterval(-8 * 24 * 60 * 60)
        defaults.set(570.0, forKey: LiveCurrencyService.rateKey)
        defaults.set(eightDaysAgo, forKey: LiveCurrencyService.timestampKey)

        let service = LiveCurrencyService(userDefaults: defaults, now: { fixedNow })
        #expect(service.usdToSOS(8500, display: .abbreviated) == nil)
    }

    @Test func defaultDisplayIsAbbreviated() {
        let defaults = makeDefaults()
        let fixedNow = Date(timeIntervalSince1970: 2_000_000_000)
        defaults.set(570.0, forKey: LiveCurrencyService.rateKey)
        defaults.set(fixedNow, forKey: LiveCurrencyService.timestampKey)

        let service = LiveCurrencyService(userDefaults: defaults, now: { fixedNow })
        #expect(service.usdToSOS(8500) == "~48.5K SOS")
    }

    // MARK: - Helpers

    private func makeDefaults() -> UserDefaults {
        let suite = "test.LiveCurrencyService.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
