import SwiftUI

/// 3-column stat row for the Listing Detail title group (§C of v3 spec).
///
/// Sits directly under the centered title block — no top divider (it's part of
/// the same title group). Three equal-width columns separated by 1pt vertical
/// `dividerLine` hairlines:
///
/// - Column 1 — numeric rating (or "New" when `nil`) + a 5-star row.
/// - Column 2 — "Guest favorite" label when the gate `averageRating >= 4.8 &&
///   reviewCount >= 3` passes; falls back to "Verified" when the listing is
///   verified, otherwise an em-dash so the geometry never collapses.
/// - Column 3 — review count + "Reviews" footnote.
///
/// Engineering call (§C fallback): when the guest-favorite gate fails and the
/// listing is **not** `isVerified`, we render an em-dash rather than the spec's
/// "render `reviewCount` only" suggestion. Reason: column 3 already shows the
/// review count, so re-rendering it in column 2 reads as a duplicate. The
/// em-dash is a visual placeholder consistent with stat-row conventions
/// elsewhere in the app and keeps the three-column geometry rigid.
struct ListingDetailHighlightsRow: View {
    let averageRating: Double?
    let reviewCount: Int
    let isVerified: Bool

    var body: some View {
        HStack(spacing: 0) {
            ratingColumn
            verticalDivider
            middleColumn
            verticalDivider
            reviewsColumn
        }
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Columns

    private var ratingColumn: some View {
        VStack(spacing: Spacing.xs) {
            Text(ratingHeadline)
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
            starRow
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(ratingAccessibilityLabel)
    }

    private var middleColumn: some View {
        VStack(spacing: Spacing.xs) {
            if isGuestFavorite {
                guestFavoriteContent
            } else if isVerified {
                verifiedContent
            } else {
                Text("—")
                    .font(.martiHeading4)
                    .foregroundStyle(Color.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var reviewsColumn: some View {
        VStack(spacing: Spacing.xs) {
            Text("\(reviewCount)")
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
            Text("Reviews")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(reviewCount == 1 ? "1 review" : "\(reviewCount) reviews")
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(Color.dividerLine)
            .frame(width: 1, height: 40)
            .accessibilityHidden(true)
    }

    // MARK: - Subcontent

    /// Five-star row used in the rating column. Always five stars; filled stars
    /// represent the rounded average. When `averageRating == nil`, every star
    /// renders empty so the geometry still reads as a star row.
    private var starRow: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < filledStars ? "star.fill" : "star")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(index < filledStars ? Color.statusWarning : Color.starEmpty)
            }
        }
        .accessibilityHidden(true)
    }

    /// "Guest favorite" treatment: a leaf glyph on either side, label between.
    /// `leaf.fill` is the closest SF Symbol to the reference's laurel branches.
    /// Spec OK'd dropping the leaves if they read off — they do read OK at this
    /// scale on a dark surface.
    private var guestFavoriteContent: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .scaleEffect(x: -1, y: 1, anchor: .center)
            Text("Guest favorite")
                .font(.martiLabel2)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Image(systemName: "leaf.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Guest favorite")
    }

    /// "Verified" fallback for column 2 when the guest-favorite gate fails but
    /// the listing is verified. Same `VerifiedBadgeView(.label)` recipe used in
    /// the host preview row so the trust signal reads consistently.
    private var verifiedContent: some View {
        VerifiedBadgeView(variant: .label)
    }

    // MARK: - Derived

    /// Gate from §C of the v3 spec. Re-used by §J (reviews summary) so the two
    /// surfaces light up "Guest favorite" together.
    private var isGuestFavorite: Bool {
        guard let rating = averageRating else { return false }
        return rating >= 4.8 && reviewCount >= 3
    }

    private var ratingHeadline: String {
        guard let rating = averageRating else { return "New" }
        return String(format: "%.2f", rating)
    }

    /// Number of filled stars (rounded). 0 when `averageRating == nil` so the
    /// star row reads as empty rather than "all five filled".
    private var filledStars: Int {
        guard let rating = averageRating else { return 0 }
        return min(5, max(0, Int(rating.rounded())))
    }

    private var ratingAccessibilityLabel: String {
        guard let rating = averageRating else { return "New listing" }
        return "Rated \(String(format: "%.2f", rating)) out of 5"
    }
}

#if DEBUG

#Preview("Guest favorite") {
    ListingDetailHighlightsRow(averageRating: 4.92, reviewCount: 187, isVerified: true)
        .padding()
        .background(Color.surfaceDefault)
}

#Preview("Verified, not favorite") {
    ListingDetailHighlightsRow(averageRating: 4.3, reviewCount: 12, isVerified: true)
        .padding()
        .background(Color.surfaceDefault)
}

#Preview("New listing, no reviews") {
    ListingDetailHighlightsRow(averageRating: nil, reviewCount: 0, isVerified: false)
        .padding()
        .background(Color.surfaceDefault)
}

#endif
