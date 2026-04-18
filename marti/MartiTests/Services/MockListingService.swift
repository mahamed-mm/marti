import Foundation
@testable import Marti

/// Test double for `ListingService`. Configure `fetchHandler` and `toggleHandler`
/// per test. Records the most recent inputs for assertion.
final class MockListingService: ListingService, @unchecked Sendable {
    var fetchHandler: (@Sendable (ListingFilter, UUID?, Int) async throws -> [ListingDTO])?
    var toggleHandler: (@Sendable (UUID, Bool) async throws -> Void)?

    private(set) var fetchCallCount = 0
    private(set) var lastFilter: ListingFilter?
    private(set) var lastCursor: UUID?
    private(set) var lastLimit: Int?

    private(set) var toggleCallCount = 0
    private(set) var lastToggleListingID: UUID?
    private(set) var lastToggleSaved: Bool?

    func fetchListings(filter: ListingFilter, cursor: UUID?, limit: Int) async throws -> [ListingDTO] {
        fetchCallCount += 1
        lastFilter = filter
        lastCursor = cursor
        lastLimit = limit
        guard let handler = fetchHandler else { return [] }
        return try await handler(filter, cursor, limit)
    }

    func toggleSaved(listingID: UUID, saved: Bool) async throws {
        toggleCallCount += 1
        lastToggleListingID = listingID
        lastToggleSaved = saved
        try await toggleHandler?(listingID, saved)
    }
}
