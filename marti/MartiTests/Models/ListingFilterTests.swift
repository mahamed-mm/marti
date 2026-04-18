import Foundation
import Testing
@testable import Marti

struct ListingFilterTests {
    @Test func defaultFilterHasAllOpenCriteria() {
        let filter = ListingFilter()
        #expect(filter.city == nil)
        #expect(filter.checkIn == nil)
        #expect(filter.checkOut == nil)
        #expect(filter.guestCount == 1)
        #expect(filter.priceMin == nil)
        #expect(filter.priceMax == nil)
    }

    @Test func defaultStaticPropertyMatchesEmptyInit() {
        #expect(ListingFilter.default == ListingFilter())
    }

    @Test func customInitOverridesDefaults() {
        let checkIn = Date(timeIntervalSince1970: 1_800_000_000)
        let checkOut = checkIn.addingTimeInterval(86_400 * 3)
        let filter = ListingFilter(
            city: .mogadishu,
            checkIn: checkIn,
            checkOut: checkOut,
            guestCount: 4,
            priceMin: 5_000,
            priceMax: 20_000
        )
        #expect(filter.city == .mogadishu)
        #expect(filter.checkIn == checkIn)
        #expect(filter.checkOut == checkOut)
        #expect(filter.guestCount == 4)
        #expect(filter.priceMin == 5_000)
        #expect(filter.priceMax == 20_000)
    }
}
