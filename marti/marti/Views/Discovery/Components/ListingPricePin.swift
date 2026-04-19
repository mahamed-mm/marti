import SwiftUI

/// Map annotation showing a listing's nightly price as a capsule pill.
///
/// Purely presentational: the caller owns selection state and the tap gesture.
/// The selected state swaps the fill to `coreAccent` and the label to `canvas`;
/// the transition animates over 0.2s ease-out unless Reduce Motion is on, in
/// which case the swap is instantaneous (spec Edge Case 13).
struct ListingPricePin: View {
    let listing: Listing
    let isSelected: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let dollars = listing.pricePerNight / 100
        Text("$\(dollars)")
            .font(.martiLabel2)
            .foregroundStyle(isSelected ? Color.canvas : Color.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule().fill(isSelected ? Color.coreAccent : Color.surfaceDefault)
            )
            .overlay(
                Capsule().stroke(Color.dividerLine, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isSelected)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel("Listing for $\(dollars) per night")
    }
}
