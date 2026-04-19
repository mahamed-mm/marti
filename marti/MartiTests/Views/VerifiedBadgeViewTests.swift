import Foundation
import Testing
@testable import Marti

@MainActor
@Suite struct VerifiedBadgeViewTests {
    /// The default variant must stay `.icon`. Any new call site that forgets
    /// to specify one should fall back to the card-safe disc, not the loud
    /// text pill that originally dominated 170pt rail cards.
    @Test func defaultVariantIsIcon() {
        #expect(VerifiedBadgeView().variant == .icon)
    }

    @Test func labelVariantIsAddressable() {
        #expect(VerifiedBadgeView(variant: .label).variant == .label)
    }
}
