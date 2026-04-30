import CoreLocation
import MapKit
import SwiftUI

/// Full Listing Detail surface. v3 visual pass — scroll-rhythm + section-stack
/// restructure on top of v2.
///
/// Section order inside the rounded-top `surfaceDefault` content card:
///   §B title block (centered) → §C highlights stat row →
///   §D host preview row → §E why-stay rows → §F about-this-place +
///   show-more → §G amenities preview + show-all → §I neighborhood map +
///   expand-disc + show-more → §J reviews summary (centered hero) →
///   §K expanded host card → §L things to know rows → (sticky §M footer).
///
/// §H "Where you'll sleep" is **deferred** until the schema grows per-room
/// photos — a one-line comment marks the slot below.
///
/// View is dumb: every interaction routes through the ViewModel. Save heart,
/// request-to-book, and the offline banner are all driven by VM state. The
/// `share` disc is decorative per the v2 locked decision — the closure is
/// empty and the accessibility hint telegraphs that to VoiceOver users.
/// Sheet state for §G "Show all amenities" lives on this view as
/// `@State private var isAmenitiesSheetPresented` per the v3 scope override
/// (the VM is not gaining a new property for this — UI-only nav state stays
/// on the view, mirroring how `isFeeTagDismissed` is handled).
struct ListingDetailView: View {
    @State private var viewModel: ListingDetailViewModel
    /// Tracks the most recent `.notFound` we've reacted to, so we only pop
    /// once per error transition rather than on every body re-evaluation.
    @State private var didHandleNotFound = false
    /// Local UI flag for the floating fee tag. Per the v2 spec we keep this
    /// dismissal in the View — it's a UI-only nag-suppression, not VM state.
    @State private var isFeeTagDismissed = false
    /// Local UI flag for the §F description "Show more" toggle. UI-only —
    /// does not need to live on the VM.
    @State private var isDescriptionExpanded = false
    /// Local UI flag for the §G "Show all amenities" sheet. v3 scope override
    /// keeps sheet state on the view rather than the VM (no new VM property).
    @State private var isAmenitiesSheetPresented = false
    /// Drives the haptic for the §D host-preview-row tap (the row scrolls
    /// the page to the §K expanded host card). Equatable-Bool flip on tap
    /// is the project pattern for `.sensoryFeedback`.
    @State private var hostPreviewHapticTrigger = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ListingDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        // `@Bindable` projection so we can hand SwiftUI bindings (`$vm.x`)
        // to subviews and `.sheet(isPresented:)` while the view itself
        // owns the VM via `@State`.
        @Bindable var vm = viewModel

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isOffline {
                    OfflineBannerView()
                }

                heroZone(currentIndex: $vm.currentPhotoIndex)
                contentCard
            }
        }
        .background(Color.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .hideFloatingTabBar(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footerStack
        }
        .sheet(isPresented: $vm.isAuthSheetPresented) {
            AuthSheetPlaceholderView()
        }
        .sheet(isPresented: $vm.isComingSoonSheetPresented) {
            RequestToBookComingSoonSheet()
        }
        .sheet(isPresented: $isAmenitiesSheetPresented) {
            ListingAmenitiesSheet(amenities: viewModel.listing.amenities)
        }
        .task {
            await viewModel.refresh()
        }
        .alert(
            "This listing is no longer available",
            isPresented: $vm.shouldShowNotFoundAlert
        ) {
            Button("OK") {
                guard !didHandleNotFound else { return }
                didHandleNotFound = true
                dismiss()
            }
        }
    }

    // MARK: - Hero

    /// Hero zone: the gallery itself plus the floating-trio button cluster
    /// (back / share / favorite) overlaid at `.top`.
    private func heroZone(currentIndex: Binding<Int>) -> some View {
        ZStack(alignment: .top) {
            ListingPhotoGalleryView(
                photoURLs: viewModel.listing.photoURLs,
                currentIndex: currentIndex
            )
            heroFloatingButtons
        }
    }

    private var heroFloatingButtons: some View {
        HStack(alignment: .top) {
            backButton
            Spacer()
            HStack(spacing: Spacing.md) {
                shareButton
                FavoriteHeartButton(
                    isSaved: viewModel.isSaved,
                    size: .large,
                    onToggle: { Task { await viewModel.toggleSave() } }
                )
            }
        }
        .padding(.horizontal, Spacing.base)
        .safeAreaPadding(.top)
    }

    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .glassDisc(diameter: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }

    /// Share is rendered for visual parity with the reference, but the action
    /// is intentionally empty — locked decision in
    /// `docs/specs/Listing Detail v2 visual pass.md`. The hint telegraphs
    /// the decorative state so VoiceOver users aren't surprised.
    private var shareButton: some View {
        Button(action: {}) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .glassDisc(diameter: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share")
        .accessibilityHint("Decorative — share is not available yet")
    }

    // MARK: - Content card (v3 section stack)

    /// Rounded-top card that holds the entire downstream section stack.
    /// Offset up by `Spacing.lg` so it overlaps the hero photo, matching the
    /// Airbnb reference's overlapping card treatment. Background is
    /// `surfaceDefault` rather than literal white per the locked decision —
    /// dark surface is the adapted recipe for Marti's dark-mode-only system.
    ///
    /// Section ordering follows v3 spec §B → §C → §D → §E → §F → §G → §I →
    /// §J → §K → §L. Every pair of sections is separated by a 0.5pt
    /// `dividerLine` hairline. Section spacing is `Spacing.lg` via the outer
    /// VStack.
    /// `ScrollViewReader` wraps the stack so the §D host preview row can
    /// scroll the page to the §K expanded host card on tap (per v3 spec §D
    /// "tap should scroll the page to the expanded host card"). The
    /// `expandedHostCardAnchor` constant is the single source of truth for
    /// the scroll anchor's `.id` — referenced once at the §K `.id(...)`
    /// call-site and once at the `proxy.scrollTo(...)` call-site.
    private static let expandedHostCardAnchor = "expanded-host-card"

    private var contentCard: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // §B + §C — title block and highlights stat row sit in the same
                // visual group (no hairline between them); the row trails into
                // a hairline that separates the title group from the host row.
                VStack(alignment: .leading, spacing: Spacing.md) {
                    titleBlock
                    ListingDetailHighlightsRow(
                        averageRating: viewModel.listing.averageRating,
                        reviewCount: viewModel.listing.reviewCount,
                        isVerified: viewModel.listing.isVerified
                    )
                }
                Divider().background(Color.dividerLine)

                // §D — small host preview row. Whole row is tappable; tap
                // scrolls the page to the §K expanded host card. Future
                // ship: this becomes a host-profile push.
                hostPreviewRow(scrollProxy: proxy)
                Divider().background(Color.dividerLine)

                // §E — why-stay rows (bare-glyph).
                ListingDetailWhyStaySection(
                    neighborhood: viewModel.listing.neighborhood,
                    city: viewModel.listing.city,
                    isVerified: viewModel.listing.isVerified
                )
                Divider().background(Color.dividerLine)

                // §F — about this place + show-more.
                descriptionSection
                Divider().background(Color.dividerLine)

                // §G — amenities preview + show-all.
                ListingAmenitiesSection(
                    amenities: viewModel.listing.amenities,
                    onShowAll: { isAmenitiesSheetPresented = true }
                )
                if !viewModel.listing.amenities.isEmpty {
                    Divider().background(Color.dividerLine)
                }

                // §H — Where you'll sleep — deferred until per-room photos schema lands.

                // §I — neighborhood map + expand-disc + show-more.
                neighborhoodSection
                Divider().background(Color.dividerLine)

                // §J — reviews summary (centered hero).
                ListingReviewsAggregateView(
                    averageRating: viewModel.listing.averageRating,
                    reviewCount: viewModel.listing.reviewCount
                )
                Divider().background(Color.dividerLine)

                // §K — expanded host card. `.id(...)` makes it the scroll
                // target for the §D row tap.
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Meet your host")
                        .font(.martiHeading4)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    ListingDetailExpandedHostCard(
                        hostName: viewModel.listing.hostName,
                        hostPhotoURL: viewModel.listing.hostPhotoURL,
                        hostCity: viewModel.listing.city,
                        isVerified: viewModel.listing.isVerified,
                        averageRating: viewModel.listing.averageRating,
                        reviewCount: viewModel.listing.reviewCount
                    )
                }
                .id(Self.expandedHostCardAnchor)
                Divider().background(Color.dividerLine)

                // §L — things to know (3 tappable rows + sheet routing).
                ListingDetailThingsToKnowSection(
                    cancellationPolicy: viewModel.listing.cancellationPolicy,
                    maxGuests: viewModel.listing.maxGuests
                )
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceDefault)
            .clipShape(
                .rect(
                    topLeadingRadius: Radius.lg,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: Radius.lg
                )
            )
            .offset(y: -Spacing.lg)
        }
    }

    // MARK: - §D Host preview row (tappable, scrolls to §K)

    /// §D host preview row, wired to scroll the page to the §K expanded host
    /// card on tap. Visual recipe is unchanged — `ListingHostCardView`
    /// renders the same 50pt avatar + "Hosted by …" + verified label as
    /// before. The tap binding + haptic + `.contentShape` are what was
    /// missing in Loop 1 (design-reviewer B1).
    ///
    /// Accessibility: re-combines the row into a single button-trait
    /// element so VoiceOver announces "Hosted by …, button" with a hint
    /// pointing at the destination, instead of three separate elements.
    private func hostPreviewRow(scrollProxy: ScrollViewProxy) -> some View {
        ListingHostCardView(
            hostName: viewModel.listing.hostName,
            hostPhotoURL: viewModel.listing.hostPhotoURL,
            isVerified: viewModel.listing.isVerified
        )
        .contentShape(Rectangle())
        .onTapGesture {
            hostPreviewHapticTrigger.toggle()
            withAnimation(.smooth(duration: 0.35)) {
                scrollProxy.scrollTo(Self.expandedHostCardAnchor, anchor: .top)
            }
        }
        .sensoryFeedback(.selection, trigger: hostPreviewHapticTrigger)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Scrolls to the host details below.")
    }

    // MARK: - §B Title block (centered)

    /// Centered title block per v3 §B. Title in `martiHeading3`, then
    /// neighborhood/city + capacity facts on `martiFootnote` secondary lines.
    /// We render only `maxGuests` until the schema grows bedrooms/beds/baths;
    /// the spec is explicit about not inventing those.
    private var titleBlock: some View {
        VStack(alignment: .center, spacing: Spacing.sm) {
            Text(viewModel.listing.title)
                .font(.martiHeading3)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(viewModel.listing.neighborhood), \(viewModel.listing.city)")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)

            Text(guestsLabel)
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    // MARK: - §F Description (about this place)

    /// "About this place" prose with a 6-line clamp + "Show more" toggle.
    /// Toggle is local `@State` per spec — no VM change.
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("About this place")
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(viewModel.listing.listingDescription)
                .font(.martiBody)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
                .lineLimit(isDescriptionExpanded ? nil : 6)
                .fixedSize(horizontal: false, vertical: true)
            if !isDescriptionExpanded {
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        isDescriptionExpanded = true
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text("Show more")
                            .font(.martiLabel2)
                            .foregroundStyle(Color.textPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show more")
                .accessibilityHint("Reveals the full listing description.")
            }
        }
    }

    // MARK: - §I Neighborhood

    /// Neighborhood section: header + subtitle + map embed (with overlay
    /// expand-disc) + "Show more" caption. Map view itself stays untouched —
    /// affordances are added at the call-site so `NeighborhoodMapView` stays
    /// a leaf primitive.
    ///
    /// Engineering call (§I expand-disc): tapping the disc opens the listing
    /// coordinate in Apple Maps via `MKMapItem.openInMaps(launchOptions:)`.
    /// Spec recommended this if it reads cleanly — it does, in one line — and
    /// it gives the affordance a real destination instead of leaving it
    /// decorative. Same coordinate that `NeighborhoodMapView` centers on,
    /// labeled with the listing title.
    private var neighborhoodSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Neighborhood")
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("\(viewModel.listing.neighborhood), \(viewModel.listing.city)")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
            mapWithExpandDisc
            showMoreNeighborhoodLink
        }
    }

    private var mapWithExpandDisc: some View {
        ZStack(alignment: .topTrailing) {
            NeighborhoodMapView(coordinate: coordinate)
            Button(action: openInAppleMaps) {
                // Spec §I: 20pt `.semibold` glyph on the 36pt disc. Loop 1
                // shipped 16pt — design-reviewer M3.
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .glassDisc(diameter: 36)
            }
            .buttonStyle(.plain)
            .padding(Spacing.md)
            .accessibilityLabel("Open in Maps")
            .accessibilityHint("Opens this listing's neighborhood in Apple Maps.")
        }
    }

    private var showMoreNeighborhoodLink: some View {
        Button(action: openInAppleMaps) {
            HStack(spacing: Spacing.xs) {
                Text("Show more")
                    .font(.martiLabel2)
                    .foregroundStyle(Color.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show more about this neighborhood")
        .accessibilityHint("Opens this listing's neighborhood in Apple Maps.")
    }

    /// Opens the coordinate in Apple Maps with the listing title as the place
    /// label. Uses `MKMapItem(location:address:)` (iOS 26) — `MKPlacemark`
    /// based init is deprecated. Side-effect-only; navigation stack does not
    /// change.
    private func openInAppleMaps() {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = viewModel.listing.title
        mapItem.openInMaps(launchOptions: nil)
    }

    // MARK: - Footer stack (fee tag + sticky footer)

    /// The bottom safe-area stack: the dismissible "Prices include all fees"
    /// tag floats above the sticky footer. Both render edge-to-edge inside
    /// the inset; horizontal padding is applied to the tag row only so the
    /// footer can fill the bar.
    private var footerStack: some View {
        VStack(spacing: Spacing.base) {
            if !isFeeTagDismissed {
                HStack {
                    Spacer()
                    FeeInclusionTag(onDismiss: dismissFeeTag)
                }
                .padding(.horizontal, Spacing.base)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            ListingDetailStickyFooterView(
                pricePerNightUSDCents: viewModel.listing.pricePerNight,
                fullSOSPriceLine: viewModel.fullSOSPriceLine,
                cancellationPolicy: viewModel.listing.cancellationPolicy,
                onRequestToBook: { viewModel.requestToBook() }
            )
        }
    }

    private func dismissFeeTag() {
        withAnimation(.smooth(duration: 0.18)) {
            isFeeTagDismissed = true
        }
    }

    // MARK: - Derived

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: viewModel.listing.latitude,
            longitude: viewModel.listing.longitude
        )
    }

    /// Capacity line. Singular at 1 guest, plural otherwise — small touch
    /// keeps copy from reading "1 guests".
    private var guestsLabel: String {
        let count = viewModel.listing.maxGuests
        return count == 1 ? "1 guest" : "\(count) guests"
    }
}
