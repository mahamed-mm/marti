import Foundation
import Supabase

/// Talks to the `listings` and `saved_listings` Postgres tables via Supabase PostgREST.
/// Schema: see `docs/specs/listing-discovery.md` and the SQL migration to create the tables.
nonisolated final class SupabaseListingService: ListingService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchListings(filter: ListingFilter, cursor: ListingCursor?, limit: Int) async throws -> [ListingDTO] {
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
            // Keyset pagination: page through `created_at DESC, id DESC` by selecting rows
            // strictly "after" the cursor tuple: created_at < ts OR (created_at = ts AND id < lastID).
            let ts = cursor.createdAt.formatted(.iso8601)
            query = query.or("created_at.lt.\(ts),and(created_at.eq.\(ts),id.lt.\(cursor.id.uuidString))")
        }
        // Date availability filtering will land with the Bookings feature — see Step 5 notes.

        do {
            let response: [ListingDTO] = try await query
                .order("created_at", ascending: false)
                .order("id", ascending: false)
                .limit(limit)
                .execute()
                .value
            return response
        } catch {
            throw map(error)
        }
    }

    func fetchDiscoveryFeed(city: City?) async throws -> DiscoveryFeedDTO {
        // Two independent queries — run them concurrently.
        async let categoriesTask: [DiscoveryCategoryDTO] = fetchCategories(city: city)
        async let listingsTask:   [ListingDTO]           = fetchListingsWithCategories(city: city)

        do {
            let (categories, listings) = try await (categoriesTask, listingsTask)
            return DiscoveryFeedDTO(categories: categories, listings: listings)
        } catch {
            throw map(error)
        }
    }

    private func fetchCategories(city: City?) async throws -> [DiscoveryCategoryDTO] {
        var query = client.from("categories").select()
        if let city {
            // Return both city-specific categories AND global (city IS NULL) ones.
            query = query.or("city.eq.\(city.rawValue),city.is.null")
        }
        return try await query
            .order("display_order", ascending: true)
            .execute()
            .value
    }

    private func fetchListingsWithCategories(city: City?) async throws -> [ListingDTO] {
        var query = client.from("listings_with_categories").select()
        if let city {
            query = query.eq("city", value: city.rawValue)
        }
        return try await query
            .order("created_at", ascending: false)
            .execute()
            .value
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
