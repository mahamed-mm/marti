import Foundation
@testable import Marti

/// Test double for `ListingService`. Configure `fetchHandler`, `fetchFeedHandler`,
/// and `toggleHandler` per test. Records the most recent inputs for assertion.
final class MockListingService: ListingService, @unchecked Sendable {
    var fetchHandler: (@Sendable (ListingFilter, ListingCursor?, Int) async throws -> [ListingDTO])?
    var fetchFeedHandler: (@Sendable (City?) async throws -> DiscoveryFeedDTO)?
    var toggleHandler: (@Sendable (UUID, Bool) async throws -> Void)?
    var fetchListingHandler: (@Sendable (UUID) async throws -> ListingDTO)?

    private(set) var fetchCallCount = 0
    private(set) var lastFilter: ListingFilter?
    private(set) var lastCursor: ListingCursor?
    private(set) var lastLimit: Int?

    private(set) var fetchFeedCallCount = 0
    private(set) var lastFeedCity: City?

    private(set) var toggleCallCount = 0
    private(set) var lastToggleListingID: UUID?
    private(set) var lastToggleSaved: Bool?

    private(set) var fetchListingCallCount = 0
    private(set) var lastFetchListingID: UUID?

    /// Fetches listings matching the provided filter and pagination cursor, up to the specified limit.
    /// - Parameters:
    ///   - filter: Criteria used to select listings.
    ///   - cursor: Optional pagination cursor indicating where to continue fetching results.
    ///   - limit: Maximum number of listings to return.
    /// - Returns: An array of `ListingDTO` objects; returns an empty array when no fetch handler is configured.
    func fetchListings(filter: ListingFilter, cursor: ListingCursor?, limit: Int) async throws -> [ListingDTO] {
        fetchCallCount += 1
        lastFilter = filter
        lastCursor = cursor
        lastLimit = limit
        guard let handler = fetchHandler else { return [] }
        return try await handler(filter, cursor, limit)
    }

    /// Fetches the discovery feed optionally scoped to a specific city.
    /// - Parameters:
    ///   - city: The city to scope the feed to, or `nil` to request an unscoped feed.
    /// - Returns: A `DiscoveryFeedDTO` containing categories and listings for the requested city; returns an empty feed (`categories: [], listings: []`) when no handler is configured.
    func fetchDiscoveryFeed(city: City?) async throws -> DiscoveryFeedDTO {
        fetchFeedCallCount += 1
        lastFeedCity = city
        guard let handler = fetchFeedHandler else {
            return DiscoveryFeedDTO(categories: [], listings: [])
        }
        return try await handler(city)
    }

    /// Records a toggle-saved invocation and, if configured, forwards it to the test handler to perform the update.
    /// Increments the mock's call counter and stores the provided listing ID and saved state for assertions.
    /// - Parameters:
    ///   - listingID: The identifier of the listing whose saved state is being toggled.
    ///   - saved: The new saved state to apply (`true` to save, `false` to unsave).
    /// - Throws: Any error thrown by the configured `toggleHandler`.
    func toggleSaved(listingID: UUID, saved: Bool) async throws {
        toggleCallCount += 1
        lastToggleListingID = listingID
        lastToggleSaved = saved
        try await toggleHandler?(listingID, saved)
    }

    /// Returns a single listing by ID via the configured `fetchListingHandler`.
    /// Records the call count and the most recent ID for assertion.
    /// - Parameter id: The listing identifier to fetch.
    /// - Returns: The DTO produced by the handler.
    /// - Throws: `AppError.notFound` if no handler is configured (matches the
    ///   real service's contract for a missing row).
    func fetchListing(id: UUID) async throws -> ListingDTO {
        fetchListingCallCount += 1
        lastFetchListingID = id
        guard let handler = fetchListingHandler else { throw AppError.notFound }
        return try await handler(id)
    }
}
