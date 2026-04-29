import SwiftUI

/// Reviews aggregate row for the Listing Detail screen.
///
/// CHECKPOINT 1 locked this surface to aggregate data only — no individual
/// review text. Renders star + numeric rating + count, plus a footnote
/// pointing at the Reviews feature. When `averageRating == nil`, "New" is
/// shown in place of the numeric rating and the count is omitted.
struct ListingReviewsAggregateView: View {
    let averageRating: Double?
    let reviewCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Reviews")
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            ratingRow

            Text("Individual reviews ship with the Reviews feature.")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var ratingRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.statusWarning)
            if let rating = averageRating {
                Text(String(format: "%.1f", rating))
                    .font(.martiLabel1)
                    .foregroundStyle(Color.textPrimary)
                Text("(\(reviewCount) \(reviewCount == 1 ? "review" : "reviews"))")
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text("New")
                    .font(.martiLabel1)
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }

    private var accessibilityLabel: String {
        guard let rating = averageRating else { return "New listing, no reviews yet." }
        let countWord = reviewCount == 1 ? "review" : "reviews"
        return "Rated \(String(format: "%.1f", rating)) out of 5, \(reviewCount) \(countWord)."
    }
}
