import SwiftUI

/// Reviews aggregate row for the Listing Detail screen.
///
/// CHECKPOINT 1 locked this surface to aggregate data only — no individual
/// review text. v3 visual pass: when `averageRating != nil` we render the
/// centered hero rating block from IMG_0611 — large `martiDisplay` rating,
/// optional "Guest favorite" label gated on the same `>= 4.8 && reviewCount
/// >= 3` rule used in §C, and a "Based on N ratings and reviews." footnote.
///
/// When `averageRating == nil`, the existing "New" treatment renders — the
/// listing simply has no reviews yet, no hero block.
struct ListingReviewsAggregateView: View {
    let averageRating: Double?
    let reviewCount: Int

    var body: some View {
        // Outer VStack does NOT use `.accessibilityElement(children: .combine)`.
        // Combining at the top would flatten the "Reviews" header into one
        // merged label and erase its `.isHeader` trait — design-reviewer M1.
        // Instead the combine + summary label live on the rating block
        // alone, so VoiceOver focus reads:
        //   "Reviews, heading" → "[combined rating block]" → footnote.
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Reviews")
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if averageRating != nil {
                centeredHero
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(ratingBlockAccessibilityLabel)
            } else {
                newRow
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(ratingBlockAccessibilityLabel)
            }

            Text("Individual reviews ship with the Reviews feature.")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - v3 centered hero block

    @ViewBuilder
    private var centeredHero: some View {
        if let rating = averageRating {
            VStack(spacing: Spacing.xs) {
                Text(String(format: "%.2f", rating))
                    .font(.martiDisplay)
                    .foregroundStyle(Color.textPrimary)
                if isGuestFavorite {
                    Text("Guest favorite")
                        .font(.martiLabel2)
                        .foregroundStyle(Color.textPrimary)
                }
                Text(footnoteCopy)
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Spacing.md)
        }
    }

    /// Pre-v3 "New" branch — kept verbatim so the no-reviews case continues
    /// to read the same way.
    @ViewBuilder
    private var newRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.statusWarning)
            Text("New")
                .font(.martiLabel1)
                .foregroundStyle(Color.textPrimary)
        }
    }

    // MARK: - Derived

    /// Same gate as §C's highlights row. Lights up "Guest favorite" on both
    /// surfaces in lockstep so the two never disagree.
    private var isGuestFavorite: Bool {
        guard let rating = averageRating else { return false }
        return rating >= 4.8 && reviewCount >= 3
    }

    private var footnoteCopy: String {
        let label = reviewCount == 1 ? "rating and review" : "ratings and reviews"
        return "Based on \(reviewCount) \(label)."
    }

    /// Combined label for the rating block (the centered hero or the "New"
    /// row). Stays scoped to the rating block — the section header has its
    /// own `.isHeader`-trait element above and the footnote stays its own
    /// element below.
    private var ratingBlockAccessibilityLabel: String {
        guard let rating = averageRating else { return "New listing, no reviews yet." }
        let countWord = reviewCount == 1 ? "review" : "reviews"
        let favoriteSuffix = isGuestFavorite ? ", guest favorite" : ""
        return "Rated \(String(format: "%.2f", rating)) out of 5\(favoriteSuffix), \(reviewCount) \(countWord)."
    }
}
