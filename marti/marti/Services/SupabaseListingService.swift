import Foundation
import Supabase

/// Talks to the `listings` and `saved_listings` Postgres tables via Supabase PostgREST.
/// Schema: see `docs/specs/listing-discovery.md` and the SQL migration to create the tables.
nonisolated final class SupabaseListingService: ListingService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    /// Fetches listings that match the provided filter and returns a single page of results using keyset pagination.
    /// 
    /// Applies optional filtering by city, minimum guest capacity, and price range. When a `cursor` is provided, results are paged relative to the cursor tuple using keyset pagination over `(created_at DESC, id DESC)`. Results are ordered by `created_at` descending then `id` descending and limited to `limit`.
    /// - Parameters:
    ///   - filter: Criteria used to filter listings (city, guest count, optional min/max price).
    ///   - cursor: Optional keyset cursor; pagination returns rows strictly after the cursor tuple using `createdAt` and `id`.
    ///   - limit: Maximum number of listings to return.
    /// - Returns: An array of `ListingDTO` objects matching the filters, ordered by `created_at` descending then `id` descending.
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

    /// Fetches the discovery feed by concurrently loading categories and listings, optionally scoped to a city.
    /// - Parameters:
    ///   - city: Optional city used to filter categories and listings; pass `nil` to include global content.
    /// - Returns: A `DiscoveryFeedDTO` containing the fetched categories and listings.
    /// - Throws: `AppError` if either categories or listings retrieval fails.
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

    /// Fetches discovery categories, optionally scoped to a city while also including global categories.
    /// - Parameters:
    ///   - city: If provided, returns categories specific to this city and categories where `city` is `NULL` (global).
    /// - Returns: An array of `DiscoveryCategoryDTO` ordered by `display_order` ascending.
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

    /// Fetches listings together with their associated categories, optionally limited to a specific city.
    /// - Parameters:
    ///   - city: If provided, only listings for this city are returned; if `nil`, listings for all cities are returned.
    /// - Returns: An array of `ListingDTO` objects from the `listings_with_categories` view, ordered by `created_at` descending.
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

    /// Fetches a single listing row by its primary key.
    ///
    /// Uses PostgREST's `.single()` modifier so a missing row returns the
    /// `PGRST116` error which we surface as `AppError.notFound`. Other
    /// transport / decode failures funnel through the standard `map(_:)`
    /// helper and become `.network` or `.unknown`.
    ///
    /// - Parameter id: The listing UUID to fetch.
    /// - Returns: The decoded `ListingDTO` for the row.
    /// - Throws: `AppError.notFound` when no row matches `id`,
    ///   `AppError.network` on transport failure, otherwise
    ///   `AppError.unknown`.
    func fetchListing(id: UUID) async throws -> ListingDTO {
        do {
            let dto: ListingDTO = try await client.from("listings")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            return dto
        } catch {
            throw map(error)
        }
    }

    /// Add or remove the current user's saved listing.
    ///
    /// Inserts a saved listing row for the authenticated user when `saved` is `true`; removes the saved row when `saved` is `false`.
    /// - Parameters:
    ///   - listingID: The UUID of the listing to save or unsave.
    ///   - saved: `true` to save the listing, `false` to remove it.
    /// - Throws: `AppError.unauthorized` if there is no authenticated user; other persistence or network errors mapped to `AppError`.
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
        // `.single()` raises `PGRST116` when zero rows match — surface that as
        // `.notFound` so the Listing Detail screen can pop on a missing row.
        if let postgrest = error as? PostgrestError, postgrest.code == "PGRST116" {
            return .notFound
        }
        return .unknown(error.localizedDescription)
    }
}
