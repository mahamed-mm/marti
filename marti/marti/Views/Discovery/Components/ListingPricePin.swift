import SwiftUI

/// Map annotation showing a listing's nightly price as a capsule pill.
///
/// Purely presentational: the caller owns selection and saved state. The
/// selected state swaps the fill to `coreAccent` and the label to `canvas`;
/// the transition animates over 0.2s ease-out unless Reduce Motion is on, in
/// which case the swap is instantaneous (spec Edge Case 13).
///
/// When `isSaved` is true, a small `heart.fill` glyph sits before the price
/// in `coreAccent` (or `canvas` when the pin is also selected, so the heart
/// stays legible against the cyan fill). This is the map-level signal that
/// the traveler has shortlisted this listing — competitors omit it, which
/// means the dense unselected pin reads as "Marti" rather than generic.
///
/// `isFocused` is an additional, subtle state applied to the pin whose
/// coordinate is closest to the current camera center. It renders an inner
/// 1pt highlight stroke so the soon-to-be-selected pin reads as "up next"
/// without stealing attention from `isSelected`. Selected always wins: when
/// the pin is selected the focus highlight is suppressed.
struct ListingPricePin: View {
    let listing: Listing
    let isSelected: Bool
    let isSaved: Bool
    var isFocused: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let dollars = listing.pricePerNight / 100
        HStack(spacing: Spacing.xs) {
            if isSaved {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isSelected ? Color.canvas : Color.coreAccent)
            }
            Text("$\(dollars)")
                .font(.martiLabel2)
                .foregroundStyle(isSelected ? Color.canvas : Color.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule().fill(isSelected ? Color.coreAccent : Color.surfaceDefault)
        )
        .overlay(
            Capsule().stroke(Color.dividerLine, lineWidth: 0.5)
        )
        .overlay(
            // Selected wins over focused — never stack the inner highlight on
            // top of the cyan fill where it would muddy contrast.
            Capsule()
                .strokeBorder(Color.textPrimary.opacity(0.08), lineWidth: 1)
                .opacity(isFocused && !isSelected ? 1 : 0)
        )
        .shadow(token: .pin)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isSelected)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isSaved)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isFocused)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .sensoryFeedback(.impact(weight: .light), trigger: isSelected)
        .accessibilityLabel(Self.accessibilityLabel(dollars: dollars, isSaved: isSaved))
    }

    /// Pure function so unit tests can assert the VoiceOver copy without
    /// Constructs the accessibility label for a listing's nightly price, including saved state.
    /// - Parameters:
    ///   - dollars: The nightly price in whole dollars.
    ///   - isSaved: `true` if the listing is saved by the user; otherwise `false`.
    /// Builds the VoiceOver label describing a listing's nightly price and saved state.
    /// - Parameters:
    ///   - dollars: The nightly price in whole dollars.
    ///   - isSaved: `true` if the listing is saved, `false` otherwise.
    /// - Returns: A string like "Listing for $123 per night" or "Saved listing for $123 per night".
    nonisolated static func accessibilityLabel(dollars: Int, isSaved: Bool) -> String {
        let prefix = isSaved ? "Saved listing" : "Listing"
        return "\(prefix) for $\(dollars) per night"
    }
}
