import SwiftUI

enum ListingCardVariant {
    case full
    /// Variant used inside horizontal category rails. The card sizes itself
    /// to the width its container gives it (see `CategoryRailView`'s
    /// `.containerRelativeFrame`) and uses a 1:1 square photo so its height
    /// follows from that width.
    case rail
    case compact
    case mapPreview
}

struct ListingCardView: View {
    let listing: Listing
    let variant: ListingCardVariant
    let isSaved: Bool
    let onToggleSave: () -> Void

    @Environment(\.currencyService) private var currencyService
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        switch variant {
        case .full:        fullCard
        case .rail:        railCard
        case .compact:     compactCard
        case .mapPreview:  mapPreviewCard
        }
    }

    // MARK: - Full

    private var fullCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                photo(height: 200)

                if listing.isVerified {
                    VerifiedBadgeView(variant: .icon)
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                FavoriteHeartButton(isSaved: isSaved, size: .small, onToggle: onToggleSave)
                    .padding(Spacing.md)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(listing.title)
                    .font(.martiHeading5)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .padding(.top, 14)

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                    Text("\(listing.neighborhood), \(listing.city)")
                        .font(.martiFootnote)
                        .lineLimit(1)
                }
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 10)

                Group {
                    if let rating = listing.averageRating {
                        ratingRow(rating: rating, count: listing.reviewCount)
                    } else {
                        Text("New")
                            .font(.martiFootnote)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .padding(.top, 6)

                priceLine()
                    .padding(.top, 12)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Color.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Rail (compact, Airbnb-style)

    /// Compact rail card: square image with all-four-sides rounding, title
    /// directly below (no panel), and a single meta row "$price · ★ rating".
    /// Location and review count live on the detail screen, not the card.
    ///
    /// Width is imposed by the parent (`CategoryRailView`) via a fixed
    /// `.frame(width: Spacing.railCardWidth)`. The photo is pinned to an
    /// explicit square `.frame(width: _, height: _)` rather than driven by
    /// `.aspectRatio(1, .fit)` — on iOS 26 the aspect-ratio form causes card 1
    /// to shift back to `x = 0` once AsyncImage resolves, clipping the title.
    /// Badge and heart use `.overlay(alignment:)` on the clipped photo so
    /// their anchors are structural, not a byproduct of ZStack arithmetic.
    private var railCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            photo()
                .frame(width: Spacing.railCardWidth, height: Spacing.railCardWidth)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .overlay(alignment: .top) { photoOverlay }

            Text(listing.title)
                .font(.martiLabel2)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .truncationMode(.tail)
                .padding(.top, Spacing.md)

            railMetaRow
                .padding(.top, Spacing.xs)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(railAccessibilityLabel)
    }

    /// Single top-anchored overlay containing both the Verified chip (leading)
    /// and the heart button (trailing). Combining them into one HStack avoids
    /// the two-overlay pattern where a second `.overlay(alignment: .topTrailing)`
    /// sometimes failed to render on top of a `.clipShape`'d photo.
    private var photoOverlay: some View {
        HStack(alignment: .center, spacing: 0) {
            if listing.isVerified {
                VerifiedBadgeView()
            }
            Spacer(minLength: 0)
            FavoriteHeartButton(isSaved: isSaved, size: .small, onToggle: onToggleSave)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    @ViewBuilder
    private var railMetaRow: some View {
        if let rating = listing.averageRating {
            HStack(spacing: Spacing.sm) {
                Text(usdString())
                Text("·")
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.coreAccent)
                Text(String(format: "%.1f", rating))
            }
            .font(.martiCaption)
            .foregroundStyle(Color.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
        } else {
            Text(usdString())
                .font(.martiCaption)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
    }

    private var railAccessibilityLabel: String {
        let verified = listing.isVerified ? ", Verified" : ""
        if let rating = listing.averageRating {
            let ratingText = String(format: "%.1f", rating)
            return "\(listing.title), \(usdString()) per night, rated \(ratingText) stars\(verified)"
        } else {
            return "\(listing.title), \(usdString()) per night, new listing\(verified)"
        }
    }

    // MARK: - Compact

    private var compactCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            photo(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(listing.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(listing.city)
                    .font(.martiCaption)
                    .foregroundStyle(Color.textTertiary)
                Text(usdString())
                    .font(.martiLabel2)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .overlay(alignment: .topTrailing) {
            FavoriteHeartButton(isSaved: isSaved, size: .small, onToggle: onToggleSave)
                .padding(Spacing.md)
        }
    }

    // MARK: - Map preview

    private var mapPreviewCard: some View {
        HStack(spacing: Spacing.base) {
            photo(height: 80)
                .frame(width: 100, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(listing.title)
                    .font(.martiLabel2)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "mappin")
                        .font(.system(size: 10))
                    Text("\(listing.neighborhood), \(listing.city)")
                        .font(.martiCaption)
                }
                .foregroundStyle(Color.textSecondary)

                HStack(spacing: Spacing.sm) {
                    if let rating = listing.averageRating {
                        ratingRow(rating: rating, count: listing.reviewCount, compact: true)
                        Text("·")
                            .font(.martiCaption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    Text("\(usdString())/night")
                        .font(.martiLabel2)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                }
            }

            FavoriteHeartButton(isSaved: isSaved, size: .small, onToggle: onToggleSave)
        }
        .padding(Spacing.md)
        .background(Color.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    /// Returns a view that displays the listing photo stretched to fill the available width, constrained to the specified height, and clipped to its bounds.
    /// - Parameter height: The fixed height (in points) to apply to the photo view.
    /// - Returns: A view showing the listing photo sized to the provided height and expanded to the available width, with any overflowing content clipped.

    private func photo(height: CGFloat) -> some View {
        photo()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
    }

    /// Aspect-ratio-driven variant. The caller applies `.aspectRatio(_:)`
    /// (or wraps in a fixed-width container) to determine the photo's height.
    /// Used by `.rail` so the square image sizes from the card's resolved
    /// width rather than a GeometryReader-computed height parameter.
    ///
    /// No internal width modifier: earlier versions had `.frame(maxWidth:
    /// .infinity)` here, which caused the rail variant's card contents to
    /// claim more than the outer `.frame(width: Spacing.railCardWidth)`
    /// offered — content laid out oversized, got centre-clipped, and visually
    /// chopped chip/heart/title on both edges. The aspect-ratio wrapper and
    /// Renders the listing's primary photo or a placeholder when no valid photo URL exists.
    /// - Returns: A view that displays the first photo URL if it can be parsed and loaded; while the image is loading it shows `Color.surfaceHighlight`, and if loading fails it shows the photo placeholder.
    private func photo() -> some View {
        Group {
            if let urlString = listing.photoURLs.first, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.surfaceHighlight
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        photoPlaceholder
                    @unknown default:
                        Color.surfaceHighlight
                    }
                }
            } else {
                photoPlaceholder
            }
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.surfaceHighlight
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundStyle(Color.textTertiary)
        }
    }

    /// Creates a horizontal rating display with a star icon, a numeric rating, and an optional review count.
    /// - Parameters:
    ///   - rating: The average rating to display; formatted to one decimal place.
    ///   - count: The number of reviews to show in parentheses when `compact` is `false`.
    ///   - compact: When `true`, uses smaller typography and hides the review count.
    /// - Returns: A view containing a star icon, the formatted rating, and optionally the review count.
    private func ratingRow(rating: Double, count: Int, compact: Bool = false) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: compact ? 10 : 12))
                .foregroundStyle(Color.statusWarning)
            Text(String(format: "%.1f", rating))
                .font(compact ? .martiCaption.bold() : .martiFootnote.bold())
                .foregroundStyle(Color.textPrimary)
            if !compact {
                Text("(\(count))")
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    /// Single horizontal price line as in OV-1: "$85 /night ~1.5M SOS", left-aligned.
    private func priceLine() -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(usdString())
                .font(.martiHeading5)
                .foregroundStyle(Color.textPrimary)
            Text("/night")
                .font(.martiFootnote)
                .foregroundStyle(Color.textTertiary)
            if let sos = currencyService.usdToSOS(listing.pricePerNight, display: .abbreviated) {
                Text(sos)
                    .font(.martiCaption)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.leading, Spacing.xs)
            }
            Spacer()
        }
    }

    private func usdString() -> String {
        let dollars = listing.pricePerNight / 100
        return "$\(dollars)"
    }
}
