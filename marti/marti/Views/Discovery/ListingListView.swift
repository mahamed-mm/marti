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
        if viewModel.isLoading && viewModel.listings.isEmpty {
            loadingState
        } else if let error = viewModel.error, viewModel.listings.isEmpty {
            ErrorStateView(message: error.userMessage) {
                Task { await viewModel.loadListings() }
            }
        } else if viewModel.listings.isEmpty {
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
            .padding(.horizontal, Spacing.base)
            .padding(.top, Spacing.base)
        }
        .background(Color.canvas)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.base) {
                ForEach(Array(viewModel.listings.enumerated()), id: \.element.id) { index, listing in
                    NavigationLink {
                        ListingDetailPlaceholderView(listing: listing)
                    } label: {
                        ListingCardView(
                            listing: listing,
                            variant: .full,
                            isSaved: viewModel.savedListingIDs.contains(listing.id),
                            onToggleSave: {
                                Task { await viewModel.toggleSave(listingID: listing.id) }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        let triggerIndex = max(0, viewModel.listings.count - 3)
                        if index == triggerIndex {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(Color.coreAccent)
                        .padding(.vertical, Spacing.base)
                }
            }
            .padding(.horizontal, Spacing.base)
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
