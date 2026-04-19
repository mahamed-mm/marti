import SwiftUI

/// Rich bottom card surfaced when the traveler taps a price pin on the map.
///
/// Composed mutually exclusive with `FeeInclusionTag` and `MapEmptyStatePill`:
/// the caller anchors it above `FloatingTabView` when
/// `ListingDiscoveryViewModel.selectedListing != nil`.
///
/// Gestures:
///   - Tap on the card body (outside heart / close) → `onTapCard`
///   - Tap heart → `onToggleSave`
///   - Tap close → `onDismiss`
///   - Swipe down past 80pt or 600pt/s velocity → `onDismiss` (spring-back below)
///   - Horizontal swipe inside the hero → paging TabView (photo gallery)
///
/// Entrance animates with a spring unless `accessibilityReduceMotion` is on, in
/// which case it fades in.
struct SelectedListingCard: View {
    let listing: Listing
    let isSaved: Bool
    let onTapCard: () -> Void
    let onToggleSave: () -> Void
    let onDismiss: () -> Void

    @Environment(\.currencyService) private var currencyService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dragOffset: CGFloat = 0
    @State private var isVisible: Bool = false
    @State private var axis: DragAxis = .undetermined

    private enum DragAxis { case undetermined, vertical, horizontal }

    private let heroHeight: CGFloat = 200
    private let dismissDistance: CGFloat = 80
    private let dismissVelocity: CGFloat = 600

    var body: some View {
        cardContent
            .frame(maxWidth: 520)
            .background(Color.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
            .offset(y: dragOffset + (isVisible ? 0 : 40))
            .opacity(isVisible ? 1 : 0)
            .onAppear(perform: animateIn)
            .simultaneousGesture(dismissDrag)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityHint("Opens listing details.")
            .accessibilityAction { onTapCard() }
            .accessibilityAction(named: isSaved ? "Remove from saved" : "Save listing") {
                onToggleSave()
            }
            .accessibilityAction(named: "Close preview") {
                onDismiss()
            }
    }

    // MARK: - Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            hero
            info
                .contentShape(Rectangle())
                .onTapGesture { onTapCard() }
        }
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            photoGallery
                .frame(height: heroHeight)
                .frame(maxWidth: .infinity)
                .clipped()

            HStack(spacing: Spacing.sm) {
                FavoriteHeartButton(isSaved: isSaved, size: .large, onToggle: onToggleSave)
                    .accessibilityHidden(true)
                closeButton
            }
            .padding(Spacing.md)
        }
    }

    @ViewBuilder
    private var photoGallery: some View {
        if listing.photoURLs.isEmpty {
            photoPlaceholder
        } else {
            TabView {
                ForEach(listing.photoURLs, id: \.self) { urlString in
                    photoSlide(urlString: urlString)
                        .tag(urlString)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: listing.photoURLs.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private func photoSlide(urlString: String) -> some View {
        Group {
            if let url = URL(string: urlString) {
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
        .clipped()
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.surfaceHighlight
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(listing.title)
                .font(.martiHeading5)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)

            Text("\(listing.neighborhood), \(listing.city)")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)

            if let rating = listing.averageRating {
                ratingRow(rating: rating, count: listing.reviewCount)
                    .padding(.top, Spacing.xs)
            }

            priceLine
                .padding(.top, Spacing.sm)
        }
        .padding(Spacing.base)
    }

    private func ratingRow(rating: Double, count: Int) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.statusWarning)
            Text(String(format: "%.1f", rating))
                .font(.martiFootnote.bold())
                .foregroundStyle(Color.textPrimary)
            Text("(\(count))")
                .font(.martiFootnote)
                .foregroundStyle(Color.textTertiary)
        }
    }

    /// Price row. `ViewThatFits` prefers the single-line layout but falls back
    /// to stacking the SOS underneath when AX5 Dynamic Type + a long price
    /// would otherwise force truncation.
    private var priceLine: some View {
        let sos = currencyService.usdToSOS(listing.pricePerNight, display: .abbreviated)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                priceUSD
                if let sos {
                    Text(sos)
                        .font(.martiCaption)
                        .foregroundStyle(Color.textTertiary)
                        .padding(.leading, Spacing.xs)
                }
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                priceUSD
                if let sos {
                    Text(sos)
                        .font(.martiCaption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }

    private var priceUSD: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(usdString)
                .font(.martiHeading5)
                .foregroundStyle(Color.textPrimary)
            Text("/night")
                .font(.martiFootnote)
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var usdString: String {
        let dollars = listing.pricePerNight / 100
        return "$\(dollars)"
    }

    // MARK: - Overlay buttons

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 44, height: 44)
                .background(glassBackground)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)   // Exposed via parent's custom action.
    }

    /// Dark scrim under `.ultraThinMaterial` so the overlay buttons stay
    /// legible on bright photos where material alone isn't enough contrast.
    private var glassBackground: some View {
        Circle()
            .fill(Color.black.opacity(0.35))
            .overlay(Circle().fill(.ultraThinMaterial))
    }

    // MARK: - Entrance + dismiss drag

    private func animateIn() {
        guard !isVisible else { return }
        if reduceMotion {
            isVisible = true
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                isVisible = true
            }
        }
    }

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // Latch the axis on first decisive movement so diagonal drags
                // don't flicker between card-drag and TabView paging.
                if axis == .undetermined {
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    if max(dx, dy) < 10 { return }
                    axis = dy > dx ? .vertical : .horizontal
                }
                guard axis == .vertical, value.translation.height > 0 else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                defer { axis = .undetermined }
                guard axis == .vertical else { return }
                let translation = value.translation.height
                let velocity = value.predictedEndTranslation.height - translation
                if translation > dismissDistance || velocity > dismissVelocity {
                    onDismiss()
                } else if reduceMotion {
                    dragOffset = 0
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Accessibility summary

    private var accessibilityDescription: String {
        var parts: [String] = [
            listing.title,
            "\(listing.neighborhood), \(listing.city)"
        ]
        if let rating = listing.averageRating {
            parts.append("\(String(format: "%.1f", rating)) stars, \(listing.reviewCount) reviews")
        }
        let dollars = listing.pricePerNight / 100
        if let sos = currencyService.usdToSOS(listing.pricePerNight, display: .abbreviated) {
            parts.append("\(dollars) dollars per night, about \(sos)")
        } else {
            parts.append("\(dollars) dollars per night")
        }
        if listing.photoURLs.count > 1 {
            parts.append("\(listing.photoURLs.count) photos")
        }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Previews

#if DEBUG

private extension Listing {
    static func previewSample(
        id: UUID = UUID(),
        title: String = "Seafront villa with pool",
        city: String = "Mogadishu",
        neighborhood: String = "Hodan",
        price: Int = 8500,
        rating: Double? = 4.8,
        reviewCount: Int = 24,
        photoURLs: [String] = ["https://example.com/placeholder.jpg"]
    ) -> Listing {
        Listing(
            id: id,
            title: title,
            city: city,
            neighborhood: neighborhood,
            listingDescription: "",
            pricePerNight: price,
            latitude: 2.0469,
            longitude: 45.3182,
            photoURLs: photoURLs,
            amenities: [],
            maxGuests: 2,
            hostID: UUID(),
            hostName: "Host",
            hostPhotoURL: nil,
            isVerified: true,
            averageRating: rating,
            reviewCount: reviewCount,
            cancellationPolicy: "flexible",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

#Preview("Default · rated · saved") {
    VStack {
        Spacer()
        SelectedListingCard(
            listing: .previewSample(),
            isSaved: true,
            onTapCard: {},
            onToggleSave: {},
            onDismiss: {}
        )
        .padding(.horizontal, Spacing.base)
        .padding(.bottom, Spacing.lg)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#Preview("No photos · no rating") {
    VStack {
        Spacer()
        SelectedListingCard(
            listing: .previewSample(
                rating: nil,
                reviewCount: 0,
                photoURLs: []
            ),
            isSaved: false,
            onTapCard: {},
            onToggleSave: {},
            onDismiss: {}
        )
        .padding(.horizontal, Spacing.base)
        .padding(.bottom, Spacing.lg)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#Preview("Long title · dense content") {
    VStack {
        Spacer()
        SelectedListingCard(
            listing: .previewSample(
                title: "Spectacular beachfront villa with private plunge pool and panoramic Indian Ocean views",
                neighborhood: "Liido",
                price: 42000,
                rating: 4.95,
                reviewCount: 312
            ),
            isSaved: false,
            onTapCard: {},
            onToggleSave: {},
            onDismiss: {}
        )
        .padding(.horizontal, Spacing.base)
        .padding(.bottom, Spacing.lg)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#endif
