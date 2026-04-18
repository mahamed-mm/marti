import SwiftUI

enum ListingCardVariant {
    case full
    case compact
    case mapPreview
}

struct ListingCardView: View {
    let listing: Listing
    let variant: ListingCardVariant
    let isSaved: Bool
    let onToggleSave: () -> Void

    @Environment(\.currencyService) private var currencyService

    var body: some View {
        switch variant {
        case .full:       fullCard
        case .compact:    compactCard
        case .mapPreview: mapPreviewCard
        }
    }

    // MARK: - Full

    private var fullCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                photo(height: 200)

                if listing.isVerified {
                    verifiedBadge
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                heartButton
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
            heartButton
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

            heartButton
        }
        .padding(Spacing.md)
        .background(Color.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Pieces

    private func photo(height: CGFloat) -> some View {
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
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.surfaceHighlight
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var verifiedBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10))
            Text("Verified")
                .font(.martiCaption.bold())
        }
        .foregroundStyle(Color.statusSuccess)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule().fill(Color.statusSuccess.opacity(0.15))
        )
        .accessibilityLabel("Verified host")
    }

    private var heartButton: some View {
        Button(action: onToggleSave) {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(isSaved ? Color.statusDanger : Color.white)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isSaved)
        .accessibilityLabel(isSaved ? "Remove from saved" : "Save listing")
    }

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
