import SwiftUI

/// Horizontally-paged carousel of mini listing cards surfaced at the bottom of
/// the map screen when no pin is actively selected. Each card is
/// `ListingCardView(variant: .mapPreview)` wrapped in a fixed-width container
/// so `.scrollTargetBehavior(.viewAligned)` snaps one card at a time.
///
/// Two-way sync with the caller's selected pin id:
///   - Pin → carousel: changes to `selectedID` scroll the matching card to
///     center (spring animation).
///   - Carousel → pin: the currently centered card fires `onSelect` after a
///     200ms debounce so rapid swipes don't thrash the map's selection state.
///
/// Composed mutually exclusive with `SelectedListingCard` and
/// `MapEmptyStatePill`: the caller anchors exactly one of the three inside the
/// map's bottom chrome VStack based on `ListingDiscoveryViewModel` state.
struct MapListingsCarousel: View {
    let listings: [Listing]
    let savedListingIDs: Set<UUID>
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    let onToggleSave: (UUID) -> Void

    /// Pending selection task. Swiping cancels the in-flight debounce so the
    /// ViewModel only sees the id the user actually stopped on.
    @State private var visibilityTask: Task<Void, Never>?

    /// `onScrollTargetVisibilityChange` fires once on initial layout with the
    /// cards already visible on screen. Treating that synthetic event as a
    /// "user scrolled onto this card" would re-emit `onSelect(first)` the
    /// moment the carousel mounts after a card dismiss, snapping the user
    /// straight back into `SelectedListingCard`. Gate on this flag so only
    /// post-mount scroll events drive selection.
    @State private var hasSeenInitialVisibility: Bool = false

    /// Fixed-height floor for each card so the carousel's total bottom-chrome
    /// footprint stays around ~130pt including vertical padding (measured
    /// through `onGeometryChange` by the caller to drive Mapbox ornament
    /// insets).
    private let cardHeight: CGFloat = 110

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = max(0, proxy.size.width)
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Spacing.md) {
                        ForEach(listings) { listing in
                            cardContainer(for: listing, width: cardWidth)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: selectedID) { _, newValue in
                    guard let id = newValue else { return }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                        scrollProxy.scrollTo(id, anchor: .center)
                    }
                }
                .onScrollTargetVisibilityChange(idType: UUID.self) { visibleIDs in
                    guard hasSeenInitialVisibility else {
                        hasSeenInitialVisibility = true
                        return
                    }
                    handleVisibilityChange(visibleIDs)
                }
            }
        }
        .frame(height: cardHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Swipe to browse visible homes. \(listings.count) total.")
        .accessibilityScrollAction { edge in
            handleAccessibilityScroll(edge)
        }
    }

    /// Creates a fixed-size, tappable listing card configured for the map carousel.
    /// - Parameters:
    ///   - listing: The `Listing` to display in the card.
    ///   - width: The card's width in points.
    /// Creates the per-item card view used inside the carousel.
    /// - Parameters:
    ///   - listing: The `Listing` to display in the card.
    ///   - width: The width to apply to the card.
    /// - Returns: A view displaying the listing as a map-preview card sized to the provided width and the carousel's fixed card height; the card is tappable to select, reflects saved state and supports save toggling, and is identifiable for scroll-target alignment.

    private func cardContainer(for listing: Listing, width: CGFloat) -> some View {
        ListingCardView(
            listing: listing,
            variant: .mapPreview,
            isSaved: savedListingIDs.contains(listing.id),
            onToggleSave: { onToggleSave(listing.id) }
        )
        .frame(width: width, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .shadow(token: .island)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(listing.id) }
        .id(listing.id)
    }

    // MARK: - Visibility debounce

    /// Debounces `onSelect` so rapid swipes across several cards don't emit a
    /// selection for every intermediate card. With `.scrollTargetBehavior(
    /// Handles snap-aligned visibility changes by debouncing and invoking `onSelect` for the newly centered listing.
    /// Cancels any in-flight visibility task, waits 200 milliseconds to allow snapping to stabilize, and then calls `onSelect` with the first visible id unless the task was cancelled or the id is already selected.
    /// Debounces visibility-driven selection and emits `onSelect` for the first visible listing.
    /// 
    /// If `visibleIDs` is empty or its first element equals the current `selectedID`, the function returns immediately. Otherwise any pending visibility task is cancelled and a new task is scheduled that waits 200 milliseconds; if not cancelled, it calls `onSelect` with the first visible id.
    /// - Parameter visibleIDs: The ordered list of listing IDs reported as visible by the scroll-target visibility change; the first element is treated as the centered/aligned card.
    private func handleVisibilityChange(_ visibleIDs: [UUID]) {
        guard let first = visibleIDs.first else { return }
        if first == selectedID { return }
        visibilityTask?.cancel()
        visibilityTask = Task {
            try? await Task.sleep(for: .milliseconds(200))
            if Task.isCancelled { return }
            onSelect(first)
        }
    }

    // MARK: - Accessibility

    /// Moves selection one neighbor forward or backward in `listings` based on
    /// the VoiceOver scroll `Edge` (leading/top → previous, trailing/bottom →
    /// next). SwiftUI's `accessibilityScrollAction` surfaces directional intent
    /// Moves selection to the neighboring listing based on a VoiceOver scroll edge.
    ///
    — If there are no listings, does nothing.
    /// - Parameters:
    /// Moves the current selection one step in the direction indicated by a VoiceOver accessibility scroll.
    ///
    /// - Parameters:
    ///   - edge: The scroll direction provided by the accessibility action. `.leading` or `.top` moves selection to the previous listing; `.trailing` or `.bottom` moves selection to the next listing. No action is taken when the listings array is empty, when the computed next index equals the current index, or when already at the list bounds. Selection changes are emitted via `onSelect`.
    private func handleAccessibilityScroll(_ edge: Edge) {
        guard !listings.isEmpty else { return }
        let currentIndex = selectedID.flatMap { id in listings.firstIndex(where: { $0.id == id }) }
        let baseIndex = currentIndex ?? 0
        let nextIndex: Int
        switch edge {
        case .leading, .top:
            nextIndex = max(0, baseIndex - 1)
        case .trailing, .bottom:
            nextIndex = min(listings.count - 1, baseIndex + 1)
        }
        guard nextIndex != currentIndex else { return }
        onSelect(listings[nextIndex].id)
    }
}

#if DEBUG

/// Creates a sample `Listing` populated with the provided title, price, rating, and review count for use in previews and debugging.
/// - Parameters:
///   - title: The listing title.
///   - price: The price per night.
///   - rating: The average rating to assign (`nil` for no rating). Defaults to `4.8`.
///   - reviewCount: The number of reviews. Defaults to `24`.
/// Creates a sample `Listing` populated with placeholder data for use in SwiftUI previews.
/// - Returns: A `Listing` populated with the provided `title`, `price`, optional `rating`, and `reviewCount`, with other fields set to fixed placeholder values suitable for UI previews.
private func carouselPreviewListing(
    title: String,
    price: Int,
    rating: Double? = 4.8,
    reviewCount: Int = 24
) -> Listing {
    Listing(
        id: UUID(),
        title: title,
        city: "Mogadishu",
        neighborhood: "Hodan",
        listingDescription: "",
        pricePerNight: price,
        latitude: 2.0469,
        longitude: 45.3182,
        photoURLs: ["https://example.com/placeholder.jpg"],
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

#Preview("Default · three listings") {
    let listings: [Listing] = [
        carouselPreviewListing(title: "Seafront villa", price: 8500),
        carouselPreviewListing(title: "City-center studio", price: 4200, rating: 4.6, reviewCount: 12),
        carouselPreviewListing(title: "Hillside retreat", price: 12000, rating: 4.9, reviewCount: 87)
    ]
    return VStack {
        Spacer()
        MapListingsCarousel(
            listings: listings,
            savedListingIDs: [listings[0].id],
            selectedID: nil,
            onSelect: { _ in },
            onToggleSave: { _ in }
        )
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.bottom, Spacing.base)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#endif
