import Foundation

/// Composite pagination cursor. A single `UUID` is not monotonic for randomly
/// generated IDs, so we page by `(createdAt, id)` in descending order.
nonisolated struct ListingCursor: Sendable, Equatable {
    let createdAt: Date
    let id: UUID
}

/// Grouped response for the Discovery screen: one call returns every category
/// visible for the requested city and every listing needed to populate those
/// rails. The client composes `DiscoveryRail`s in the ViewModel.
nonisolated struct DiscoveryFeedDTO: Sendable, Equatable {
    let categories: [DiscoveryCategoryDTO]
    let listings:   [ListingDTO]
}

protocol ListingService: Sendable {
    /// Fetches one page of listings matching the filter. Pass `cursor = nil` for the first page.
    /// The returned array contains at most `limit` entries; an empty array means no more pages.
    func fetchListings(filter: ListingFilter, cursor: ListingCursor?, limit: Int) async throws -> [ListingDTO]

    /// Fetches the grouped Discovery feed for the requested city. Passing `nil`
    /// returns the nation-wide feed (city-specific and global categories combined).
    func fetchDiscoveryFeed(city: City?) async throws -> DiscoveryFeedDTO

    /// Persists or removes a "saved" relationship between the current user and a listing.
    /// Throws `AppError.unauthorized` when no user is signed in.
    func toggleSaved(listingID: UUID, saved: Bool) async throws
}

extension ListingService {
    /// Fetches a page of listings matching the provided filter and pagination cursor.
    /// 
    /// - Parameters:
    ///   - filter: Criteria used to select and sort listings for the request.
    ///   - cursor: Composite pagination cursor containing `createdAt` and `id`; pass `nil` to request the first page.
    ///   - limit: Maximum number of listings to return for this page.
    /// - Returns: An array of `ListingDTO` objects up to `limit` in length; an empty array indicates there are no more pages.
    func fetchListings(filter: ListingFilter, cursor: ListingCursor? = nil, limit: Int = 20) async throws -> [ListingDTO] {
        try await fetchListings(filter: filter, cursor: cursor, limit: limit)
    }
}
