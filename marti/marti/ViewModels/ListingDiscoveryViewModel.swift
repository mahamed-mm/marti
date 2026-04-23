import CoreLocation
import Foundation
import MapboxMaps
import Observation
import SwiftData

enum ViewMode: Sendable, Equatable {
    case list
    case map
}

@Observable
@MainActor
final class ListingDiscoveryViewModel {
    // MARK: - State

    private(set) var listings: [Listing] = []
    private(set) var categories: [DiscoveryCategory] = []
    // Starts `true` so the first render of `DiscoveryView` picks the
    // skeleton branch instead of flashing the empty state before `.task`
    // fires `loadListings()`. `loadListings()` sets this to `false` at the
    // end of every call.
    private(set) var isLoading: Bool = true
    private(set) var isLoadingMore: Bool = false
    private(set) var error: AppError?
    private(set) var hasMorePages: Bool = true
    private(set) var savedListingIDs: Set<UUID> = []
    private(set) var isOffline: Bool = false
    private(set) var visibleListingCount: Int = 0

    var filter: ListingFilter = .default
    var viewMode: ViewMode = .list
    var selectedPinID: UUID?
    var isSearchSheetPresented: Bool = false
    var isSearchScreenPresented: Bool = false
    var isAuthSheetPresented: Bool = false
    var feeTagDismissed: Bool = false

    // MARK: - Derived

    var selectedListing: Listing? {
        guard let id = selectedPinID else { return nil }
        return listings.first(where: { $0.id == id })
    }

    var headerTitle: String {
        if let city = filter.city {
            return "Homes in \(city.rawValue)"
        }
        return "Homes across Somalia"
    }

    /// Derived horizontally-scrolling rails for the Discovery list.
    ///
    /// Rules:
    /// - Only categories matching the current city filter (or global) are kept.
    /// - Each rail's listings are those whose `categoryIDs` include the category's id.
    /// - Empty rails collapse (never render an empty shell).
    /// - Order is `displayOrder` ascending, ties broken by `slug` for stability.
    var rails: [DiscoveryRail] {
        let cityFilter = filter.city?.rawValue
        return categories
            .filter { category in
                guard let cityFilter else { return true }
                return category.city == nil || category.city == cityFilter
            }
            .sorted {
                if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
                return $0.slug < $1.slug
            }
            .compactMap { category in
                let categoryListings = listings.filter { $0.categoryIDs.contains(category.id) }
                guard !categoryListings.isEmpty else { return nil }
                return DiscoveryRail(
                    category: DiscoveryCategoryDTO(model: category),
                    listings: categoryListings
                )
            }
    }

    var headerSubtitle: String {
        let dateLabel: String
        if let start = filter.checkIn, let end = filter.checkOut {
            dateLabel = Self.dateRangeFormatter.string(from: start)
                + " – "
                + Self.dateRangeFormatter.string(from: end)
        } else {
            dateLabel = "Any dates"
        }
        let guestLabel = filter.guestCount == 1 ? "1 guest" : "\(filter.guestCount) guests"
        return "\(dateLabel) · \(guestLabel)"
    }

    /// Map-mode header copy, driven by the live viewport count rather than
    /// static filter summary. List mode continues to use `headerTitle` /
    /// `headerSubtitle`; those stay untouched.
    var headerLiveSummary: String {
        let n = visibleListingCount
        let noun = n == 1 ? "home" : "homes"
        if let city = filter.city {
            return "\(n) \(noun) in \(Self.cityName(city))"
        }
        return "\(n) \(noun) in view"
    }

    /// Returns the human-readable display name for a given city.
    /// - Parameter city: The `City` enum value to convert to a display name.
    /// Maps a `City` value to its human-readable display name.
    /// - Parameter city: The city enum value to map.
    /// - Returns: The display name for the given city (e.g., "Mogadishu", "Hargeisa").
    private static func cityName(_ city: City) -> String {
        city.rawValue
    }

    /// Camera the map view should frame when it opens. Driven purely by
    /// `filter.city`: a city filter centers on that city at its default
    /// zoom; otherwise we fall back to `MapConfiguration.defaultUserLocation`
    /// (v1 static stand-in for real user location).
    var targetCamera: (coordinate: CLLocationCoordinate2D, zoom: Double) {
        if let city = filter.city {
            return (city.centerCoordinate, city.defaultZoom)
        }
        return MapConfiguration.defaultUserLocation
    }

    private static let dateRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    // MARK: - Dependencies

    private let listingService: ListingService
    private let currencyService: CurrencyService
    private let authManager: AuthManager
    private let modelContext: ModelContext?
    private let userDefaults: UserDefaults
    private let pageSize: Int
    private let debounce: Duration

    // MARK: - Persistence keys

    static let feeTagDismissedKey = "discovery.feeTagDismissed"

    // MARK: - Task references

    private var loadTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?

    // MARK: - Init

    init(
        listingService: ListingService,
        currencyService: CurrencyService,
        authManager: AuthManager,
        modelContext: ModelContext? = nil,
        userDefaults: UserDefaults = .standard,
        pageSize: Int = 20,
        debounce: Duration = .milliseconds(300)
    ) {
        self.listingService = listingService
        self.currencyService = currencyService
        self.authManager = authManager
        self.modelContext = modelContext
        self.userDefaults = userDefaults
        self.pageSize = pageSize
        self.debounce = debounce
        self.feeTagDismissed = userDefaults.bool(forKey: Self.feeTagDismissedKey)
    }

    /// Loads the discovery feed and updates the view model's listings and categories.
    /// 
    /// Performs a cache-first refresh: surfaces cached listing and category snapshots immediately, then fetches fresh data from the network. On success, replaces `listings` and `categories`, persists snapshots to the local cache, sets `hasMorePages = false`, and clears any error/offline state. On failure, preserves cached rails (if present) and marks the view model offline; if no cache exists, records the mapped error. Handles task cancellation and clears a stale map selection after completion.

    func loadListings() async {
        loadTask?.cancel()
        let task = Task { @MainActor in
            // Cache-first: surface cached listings AND categories immediately so the
            // UI renders rails before the network roundtrip lands. Cache is read as
            // detached DTO snapshots — SwiftData @Model instances must NEVER be
            // surfaced to Views, otherwise writeCache's stale-purge can detach a
            // @Model while a View still holds it, crashing on the next property fault.
            let cachedListings   = readCache()
            let cachedCategories = readCategoryCache()

            if listings.isEmpty, !cachedListings.isEmpty {
                listings = cachedListings.map { Listing(dto: $0) }
            }
            if categories.isEmpty, !cachedCategories.isEmpty {
                categories = cachedCategories.map { DiscoveryCategory(dto: $0) }
            }

            isLoading = rails.isEmpty
            error = nil
            do {
                let feed = try await listingService.fetchDiscoveryFeed(city: filter.city)
                if Task.isCancelled { return }
                listings   = feed.listings.map   { Listing(dto: $0) }
                categories = feed.categories.map { DiscoveryCategory(dto: $0) }
                // Rails view doesn't paginate; flat pagination is a future SeeAll concern.
                hasMorePages = false
                writeCache(replacingWith: feed.listings)
                writeCategoryCache(replacingWith: feed.categories)
                isOffline = false
            } catch {
                if Task.isCancelled { return }
                if !cachedListings.isEmpty || !cachedCategories.isEmpty {
                    // Keep cached rails on screen, just flag offline.
                    isOffline = true
                } else {
                    self.error = mapError(error)
                }
            }
            isLoading = false
            clearSelectionIfStale()
        }
        loadTask = task
        await task.value
    }

    /// Loads the next page of listings and appends them to the current feed.
    /// 
    /// If loading is not possible (no more pages, already loading, or there are no listings), the method returns immediately.
    /// On success, the fetched listings are appended to `listings` and `hasMorePages` is updated to reflect whether another page may exist.
    /// On failure, `error` is set with a mapped `AppError`.
    /// Side effects: toggles `isLoadingMore` for the duration of the operation and mutates `listings`, `hasMorePages`, and `error`.
    func loadMore() async {
        guard hasMorePages, !isLoading, !isLoadingMore, let last = listings.last else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let dtos = try await listingService.fetchListings(
                filter: filter,
                cursor: ListingCursor(createdAt: last.createdAt, id: last.id),
                limit: pageSize
            )
            listings.append(contentsOf: dtos.map { Listing(dto: $0) })
            hasMorePages = dtos.count == pageSize
        } catch {
            self.error = mapError(error)
        }
    }

    /// Clears the current feed and pagination state, then reloads listings and categories.
    /// 
    /// This resets `listings`, `categories`, and `hasMorePages` before invoking `loadListings()`.
    func refresh() async {
        listings = []
        categories = []
        hasMorePages = false
        await loadListings()
    }

    /// Applies the given listing filter and schedules a debounced refresh of the feed.
    /// Cancels any in-flight debounce task and starts a new one that will call `refresh()` after the view model's debounce interval.
    /// - Parameter newFilter: The filter to apply to the discovery feed; becomes the view model's active `filter`.

    func applyFilter(_ newFilter: ListingFilter) {
        filter = newFilter
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: debounce)
            if Task.isCancelled { return }
            await refresh()
        }
    }

    /// Test hook: deterministically await the in-flight debounce task (debounce
    /// Waits for the currently scheduled debounce task to complete, if one exists.
    /// 
    /// Intended as a test hook to ensure any pending debounce work finishes before making assertions.
    func awaitPendingDebounce() async {
        await debounceTask?.value
    }

    /// Resets the current listing filter to the default preset.
    func clearFilters() {
        applyFilter(.default)
    }

    // MARK: - Save

    func toggleSave(listingID: UUID) async {
        guard authManager.isAuthenticated else {
            isAuthSheetPresented = true
            return
        }
        let wasSaved = savedListingIDs.contains(listingID)
        let newSaved = !wasSaved

        if newSaved {
            savedListingIDs.insert(listingID)
        } else {
            savedListingIDs.remove(listingID)
        }

        do {
            try await listingService.toggleSaved(listingID: listingID, saved: newSaved)
        } catch {
            if newSaved {
                savedListingIDs.remove(listingID)
            } else {
                savedListingIDs.insert(listingID)
            }
            self.error = mapError(error)
        }
    }

    // MARK: - Map / View mode

    func setViewMode(_ mode: ViewMode) {
        viewMode = mode
    }

    /// Selects the map pin corresponding to the given listing identifier.
    /// - Parameters:
    /// Selects the map pin corresponding to the given listing ID or clears the selection.
    /// Selects the map pin corresponding to the given listing identifier.
    /// - Parameter id: The listing `UUID` to select, or `nil` to clear the current selection.
    func selectPin(_ id: UUID?) {
        selectedPinID = id
    }

    /// Updates the count of listings whose coordinates fall within the given
    /// map-camera bounds. Called from `ListingMapView` on camera-idle so the
    /// Updates the live map-visible listing count by counting listings whose coordinates fall inside the provided map bounds.
    /// - Parameter bounds: The map coordinate bounds used to determine which listings are considered in view.
    /// Recalculates and updates the number of listings whose coordinates fall within the provided map bounds.
    /// - Parameters:
    ///   - bounds: The map bounds used to determine which listings are currently visible. The view model's `visibleListingCount` is updated only if the computed count differs from the current value.
    func updateVisibleListings(bounds: CoordinateBounds) {
        let count = listings.reduce(into: 0) { acc, listing in
            let coord = CLLocationCoordinate2D(latitude: listing.latitude,
                                               longitude: listing.longitude)
            if bounds.contains(forPoint: coord, wrappedCoordinates: true) {
                acc += 1
            }
        }
        if count != visibleListingCount { visibleListingCount = count }
    }

    /// Marks the fee tag as dismissed so the UI will stop presenting it.
    /// Persists across app launches via `UserDefaults` — trust messaging is
    /// Marks the discovery fee tag as dismissed and persists that state to UserDefaults.
    /// 
    /// Marks the discovery fee tag as dismissed and persists that state to `UserDefaults`.
    /// 
    /// The dismissed flag is stored under `Self.feeTagDismissedKey`.
    func dismissFeeTag() {
        feeTagDismissed = true
        userDefaults.set(true, forKey: Self.feeTagDismissedKey)
    }

    /// Clears the current map pin selection if the selected pin's listing no longer exists in `listings`.
    /// 
    /// Does nothing if `selectedPinID` is already `nil`.
    private func clearSelectionIfStale() {
        guard let id = selectedPinID else { return }
        if !listings.contains(where: { $0.id == id }) {
            selectedPinID = nil
        }
    }

    /// Normalize an `Error` into an `AppError`.
    /// - Parameter error: The error to convert.
    /// - Returns: The same `AppError` if `error` is already one, otherwise `.unknown` constructed with the error's localized description.

    private func mapError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }

    // MARK: - Cache

    /// Snapshots cached listings into detached DTOs while the managed models are still
    /// attached to the context. Returning DTOs (not `Listing` instances) keeps the
    /// ViewModel and any View binding immune to SwiftData fault errors when
    /// Reads cached listing records from the SwiftData model context and returns them as detached `ListingDTO` snapshots.
    /// - Returns: An array of `ListingDTO` representing cached listings; returns an empty array if there is no `modelContext` or if the fetch fails.
    private func readCache() -> [ListingDTO] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Listing>(sortBy: [SortDescriptor(\.id)])
        let managed = (try? modelContext.fetch(descriptor)) ?? []
        return managed.map { ListingDTO(model: $0) }
    }

    /// Replaces the persisted Listing cache with the given DTO snapshots by deleting stale rows and upserting incoming records.
    /// 
    /// If `modelContext` is `nil` this is a no-op. For present contexts, any cached `Listing` whose `id` is not in `dtos` is deleted; for each DTO, an existing row is updated (its `categoryIDs` are synchronized) or a new `Listing` is inserted. Attempts to save the context at the end.
    /// - Parameter dtos: The fresh `ListingDTO` snapshots to write to the cache.
    private func writeCache(replacingWith dtos: [ListingDTO]) {
        guard let modelContext else { return }
        // Remove anything not in the fresh result, then upsert.
        let freshIDs = Set(dtos.map(\.id))
        let existing = (try? modelContext.fetch(FetchDescriptor<Listing>())) ?? []
        for stale in existing where !freshIDs.contains(stale.id) {
            modelContext.delete(stale)
        }
        let existingByID = Dictionary(uniqueKeysWithValues: existing.compactMap { freshIDs.contains($0.id) ? ($0.id, $0) : nil })
        for dto in dtos {
            if let existing = existingByID[dto.id] {
                // categoryIDs may have changed even when id/title haven't — keep the
                // cached row's membership in sync so rails stay accurate.
                existing.categoryIDs = dto.categoryIDs
            } else {
                modelContext.insert(Listing(dto: dto))
            }
        }
        try? modelContext.save()
    }

    /// Reads cached discovery categories from the SwiftData model context and returns them as DTO snapshots.
    /// - Returns: An array of `DiscoveryCategoryDTO` representing cached categories sorted by `displayOrder`; returns an empty array if `modelContext` is nil or the fetch fails.
    private func readCategoryCache() -> [DiscoveryCategoryDTO] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<DiscoveryCategory>(sortBy: [SortDescriptor(\.displayOrder)])
        let managed = (try? modelContext.fetch(descriptor)) ?? []
        return managed.map { DiscoveryCategoryDTO(model: $0) }
    }

    /// Upserts the given category DTOs into the SwiftData model context and removes any cached categories not present in `dtos`.
    /// - Description: For each DTO, updates an existing `DiscoveryCategory` with matching `id` (overwriting `slug`, `title`, `subtitle`, `city`, and `displayOrder`) or inserts a new `DiscoveryCategory` if none exists. Any persisted categories whose `id` is not present in `dtos` are deleted. Attempts to save the context at the end; failures are ignored.
    /// - Parameters:
    ///   - dtos: Snapshot representations of discovery categories to persist. If `modelContext` is `nil`, the call is a no-op.
    private func writeCategoryCache(replacingWith dtos: [DiscoveryCategoryDTO]) {
        guard let modelContext else { return }
        let freshIDs = Set(dtos.map(\.id))
        let existing = (try? modelContext.fetch(FetchDescriptor<DiscoveryCategory>())) ?? []
        for stale in existing where !freshIDs.contains(stale.id) {
            modelContext.delete(stale)
        }
        let existingByID = Dictionary(uniqueKeysWithValues: existing.compactMap { freshIDs.contains($0.id) ? ($0.id, $0) : nil })
        for dto in dtos {
            if let existing = existingByID[dto.id] {
                existing.slug         = dto.slug
                existing.title        = dto.title
                existing.subtitle     = dto.subtitle
                existing.city         = dto.city
                existing.displayOrder = dto.displayOrder
            } else {
                modelContext.insert(DiscoveryCategory(dto: dto))
            }
        }
        try? modelContext.save()
    }
}
