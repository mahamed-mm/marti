import CoreLocation
import SwiftUI

/// Full Listing Detail surface. Replaces the prior placeholder.
///
/// v2 visual pass: hero photo gallery is overlaid by a three-button cluster
/// (back · share · favorite) on `.glassDisc(diameter: 44)` discs. The whole
/// section stack downstream of the hero lives on a rounded-top
/// `Color.surfaceDefault` overlay card that rises into the photo by
/// `Spacing.lg`. The fee-inclusion tag floats above the sticky footer via
/// `safeAreaInset(.bottom)`; dismissal is local UI state on this view (no
/// VM change).
///
/// View is dumb: every interaction routes through the ViewModel. Save heart,
/// request-to-book, and the offline banner are all driven by VM state. The
/// `share` disc is decorative per the spec's locked decision — the closure
/// is empty and the accessibility hint telegraphs that to VoiceOver users.
/// `.task { await vm.refresh() }` fires the background refresh once on first
/// appearance — the seed already populates the surface, so there is no
/// spinner branch in the body.
struct ListingDetailView: View {
    @State private var viewModel: ListingDetailViewModel
    /// Tracks the most recent `.notFound` we've reacted to, so we only pop
    /// once per error transition rather than on every body re-evaluation.
    @State private var didHandleNotFound = false
    /// Local UI flag for the floating fee tag. Per the v2 spec we keep this
    /// dismissal in the View — it's a UI-only nag-suppression, not VM state.
    @State private var isFeeTagDismissed = false
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

    // MARK: - Content card

    /// Rounded-top card that holds the entire downstream section stack.
    /// Offset up by `Spacing.lg` so it overlaps the hero photo, matching the
    /// Airbnb reference's overlapping card treatment. Background is
    /// `surfaceDefault` rather than literal white per the locked decision —
    /// dark surface is the adapted recipe for Marti's dark-mode-only system.
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            titleBlock
            Divider().background(Color.dividerLine)
            ListingHostCardView(
                hostName: viewModel.listing.hostName,
                hostPhotoURL: viewModel.listing.hostPhotoURL,
                isVerified: viewModel.listing.isVerified
            )
            Divider().background(Color.dividerLine)
            ListingAmenitiesSection(amenities: viewModel.listing.amenities)
            if !viewModel.listing.amenities.isEmpty {
                Divider().background(Color.dividerLine)
            }
            descriptionSection
            Divider().background(Color.dividerLine)
            NeighborhoodMapView(coordinate: coordinate)
            Divider().background(Color.dividerLine)
            ListingCancellationPolicyView(policy: viewModel.listing.cancellationPolicy)
            Divider().background(Color.dividerLine)
            ListingReviewsAggregateView(
                averageRating: viewModel.listing.averageRating,
                reviewCount: viewModel.listing.reviewCount
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

    // MARK: - Title block

    /// Top of the content card: title, neighborhood line, capacity line,
    /// centered rating row. The mappin glyph from v1 is dropped — the
    /// reference renders no glyph here.
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(viewModel.listing.title)
                .font(.martiHeading3)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(viewModel.listing.neighborhood), \(viewModel.listing.city)")
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)

            Text(guestsLabel)
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)

            ratingRow
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private var ratingRow: some View {
        HStack(spacing: Spacing.sm) {
            if let rating = viewModel.listing.averageRating {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.statusWarning)
                Text(String(format: "%.1f", rating))
                    .font(.martiLabel2)
                    .foregroundStyle(Color.textPrimary)
                Text("(\(viewModel.listing.reviewCount))")
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text("New")
                    .font(.martiLabel2)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

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
                .fixedSize(horizontal: false, vertical: true)
        }
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
