import Foundation
import Supabase

/// Talks to the `listings` and `saved_listings` Postgres tables via Supabase PostgREST.
/// Schema: see `docs/specs/listing-discovery.md` and the SQL migration to create the tables.
nonisolated final class SupabaseListingService: ListingService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchListings(filter: ListingFilter, cursor: UUID?, limit: Int) async throws -> [ListingDTO] {
        var query = client.from("listings").select()

        if let city = filter.city {
            query = query.eq("city", value: city.rawValue)
        }
        query = query.gte("max_guests", value: filter.guestCount)
        if let priceMin = filter.priceMin {
            query = query.gte("price_per_night", value: priceMin)
        }
        if let priceMax = filter.priceMax {
            query = query.lte("price_per_night", value: priceMax)
        }
        if let cursor {
            query = query.gt("id", value: cursor.uuidString)
        }
        // Date availability filtering will land with the Bookings feature — see Step 5 notes.

        do {
            let response: [ListingDTO] = try await query
                .order("id")
                .limit(limit)
                .execute()
                .value
            return response
        } catch {
            throw map(error)
        }
    }

    func toggleSaved(listingID: UUID, saved: Bool) async throws {
        guard let userID = try? await client.auth.user().id else {
            throw AppError.unauthorized
        }

        do {
            if saved {
                struct SavedRow: Encodable {
                    let user_id: UUID
                    let listing_id: UUID
                }
                try await client.from("saved_listings")
                    .insert(SavedRow(user_id: userID, listing_id: listingID))
                    .execute()
            } else {
                try await client.from("saved_listings")
                    .delete()
                    .eq("user_id", value: userID.uuidString)
                    .eq("listing_id", value: listingID.uuidString)
                    .execute()
            }
        } catch {
            throw map(error)
        }
    }

    // MARK: - Error mapping

    private func map(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = error as? URLError {
            return .network(urlError.localizedDescription)
        }
        return .unknown(error.localizedDescription)
    }
}
