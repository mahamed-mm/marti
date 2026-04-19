import Foundation
@testable import Marti

/// Test double for `ListingService`. Configure `fetchHandler`, `fetchFeedHandler`,
/// and `toggleHandler` per test. Records the most recent inputs for assertion.
final class MockListingService: ListingService, @unchecked Sendable {
    var fetchHandler: (@Sendable (ListingFilter, ListingCursor?, Int) async throws -> [ListingDTO])?
    var fetchFeedHandler: (@Sendable (City?) async throws -> DiscoveryFeedDTO)?
    var toggleHandler: (@Sendable (UUID, Bool) async throws -> Void)?

    private(set) var fetchCallCount = 0
    private(set) var lastFilter: ListingFilter?
    private(set) var lastCursor: ListingCursor?
    private(set) var lastLimit: Int?

    private(set) var fetchFeedCallCount = 0
    private(set) var lastFeedCity: City?

    private(set) var toggleCallCount = 0
    private(set) var lastToggleListingID: UUID?
    private(set) var lastToggleSaved: Bool?

    func fetchListings(filter: ListingFilter, cursor: ListingCursor?, limit: Int) async throws -> [ListingDTO] {
        fetchCallCount += 1
        lastFilter = filter
        lastCursor = cursor
        lastLimit = limit
        guard let handler = fetchHandler else { return [] }
        return try await handler(filter, cursor, limit)
    }

    func fetchDiscoveryFeed(city: City?) async throws -> DiscoveryFeedDTO {
        fetchFeedCallCount += 1
        lastFeedCity = city
        guard let handler = fetchFeedHandler else {
            return DiscoveryFeedDTO(categories: [], listings: [])
        }
        return try await handler(city)
    }

    func toggleSaved(listingID: UUID, saved: Bool) async throws {
        toggleCallCount += 1
        lastToggleListingID = listingID
        lastToggleSaved = saved
        try await toggleHandler?(listingID, saved)
    }
}
