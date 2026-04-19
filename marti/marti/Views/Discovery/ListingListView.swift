import SwiftUI

struct ListingListView: View {
    @Bindable var viewModel: ListingDiscoveryViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isOffline {
                OfflineBannerView()
            }
            states
        }
    }

    @ViewBuilder
    private var states: some View {
        if viewModel.isLoading && viewModel.rails.isEmpty {
            loadingState
        } else if let error = viewModel.error, viewModel.rails.isEmpty {
            ErrorStateView(message: error.userMessage) {
                Task { await viewModel.loadListings() }
            }
        } else if viewModel.rails.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                iconTint: Color.coreAccent,
                title: "No listings found",
                subtitle: "Try a different city or clear your filters.",
                actionTitle: "Clear filters",
                actionStyle: .ghost,
                action: { viewModel.clearFilters() }
            )
        } else {
            content
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.base) {
                SkeletonHeader()
                ForEach(0..<2, id: \.self) { _ in
                    SkeletonListingCard()
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.top, Spacing.base)
        }
        .background(Color.canvas)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                ForEach(viewModel.rails, id: \.category.id) { rail in
                    CategoryRailView(
                        rail: rail,
                        savedIDs: viewModel.savedListingIDs,
                        onToggleSave: { id in
                            Task { await viewModel.toggleSave(listingID: id) }
                        },
                        // TODO: navigation-ready — wire to SeeAllView when that screen ships.
                        onSeeAll: { }
                    )
                }
            }
            .padding(.top, Spacing.base)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.canvas)
        .refreshable {
            await viewModel.refresh()
        }
    }
}

private extension AppError {
    var userMessage: String {
        switch self {
        case .network(let message):
            return "Couldn't reach Marti. \(message)"
        case .notFound:
            return "We couldn't find what you were looking for."
        case .unauthorized:
            return "Please sign in and try again."
        case .unknown(let message):
            return message
        }
    }
}
