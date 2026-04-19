import Foundation
import Testing
@testable import Marti

@MainActor
@Suite struct ListingPricePinTests {
    @Test func accessibilityLabel_unsaved_saysListing() {
        let label = ListingPricePin.accessibilityLabel(dollars: 85, isSaved: false)
        #expect(label == "Listing for $85 per night")
    }

    @Test func accessibilityLabel_saved_prefixesSavedListing() {
        let label = ListingPricePin.accessibilityLabel(dollars: 120, isSaved: true)
        #expect(label == "Saved listing for $120 per night")
    }
}
