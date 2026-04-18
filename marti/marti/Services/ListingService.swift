import Foundation

protocol ListingService: Sendable {
    /// Fetches one page of listings matching the filter. Pass `cursor = nil` for the first page.
    /// The returned array contains at most `limit` entries; an empty array means no more pages.
    func fetchListings(filter: ListingFilter, cursor: UUID?, limit: Int) async throws -> [ListingDTO]

    /// Persists or removes a "saved" relationship between the current user and a listing.
    /// Throws `AppError.unauthorized` when no user is signed in.
    func toggleSaved(listingID: UUID, saved: Bool) async throws
}

extension ListingService {
    func fetchListings(filter: ListingFilter, cursor: UUID? = nil, limit: Int = 20) async throws -> [ListingDTO] {
        try await fetchListings(filter: filter, cursor: cursor, limit: limit)
    }
}
