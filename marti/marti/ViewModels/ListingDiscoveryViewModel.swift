import Foundation
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
    private(set) var isLoading: Bool = false
    private(set) var isLoadingMore: Bool = false
    private(set) var error: AppError?
    private(set) var hasMorePages: Bool = true
    private(set) var savedListingIDs: Set<UUID> = []
    private(set) var isOffline: Bool = false

    var filter: ListingFilter = .default
    var viewMode: ViewMode = .list
    var selectedPinID: UUID?
    var isFilterSheetPresented: Bool = false
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
    private let pageSize: Int
    private let debounce: Duration

    // MARK: - Task references

    private var loadTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?

    // MARK: - Init

    init(
        listingService: ListingService,
        currencyService: CurrencyService,
        authManager: AuthManager,
        modelContext: ModelContext? = nil,
        pageSize: Int = 20,
        debounce: Duration = .milliseconds(300)
    ) {
        self.listingService = listingService
        self.currencyService = currencyService
        self.authManager = authManager
        self.modelContext = modelContext
        self.pageSize = pageSize
        self.debounce = debounce
    }

    // MARK: - Loading

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

    func refresh() async {
        listings = []
        categories = []
        hasMorePages = false
        await loadListings()
    }

    // MARK: - Filters

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
    /// + refresh + fetch). Exists so tests don't need wall-clock `Task.sleep`s.
    func awaitPendingDebounce() async {
        await debounceTask?.value
    }

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

    func selectPin(_ id: UUID?) {
        selectedPinID = id
    }

    func dismissFeeTag() {
        feeTagDismissed = true
    }

    private func clearSelectionIfStale() {
        guard let id = selectedPinID else { return }
        if !listings.contains(where: { $0.id == id }) {
            selectedPinID = nil
        }
    }

    // MARK: - Helpers

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
    /// `writeCache` later deletes stale rows.
    private func readCache() -> [ListingDTO] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Listing>(sortBy: [SortDescriptor(\.id)])
        let managed = (try? modelContext.fetch(descriptor)) ?? []
        return managed.map { ListingDTO(model: $0) }
    }

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

    private func readCategoryCache() -> [DiscoveryCategoryDTO] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<DiscoveryCategory>(sortBy: [SortDescriptor(\.displayOrder)])
        let managed = (try? modelContext.fetch(descriptor)) ?? []
        return managed.map { DiscoveryCategoryDTO(model: $0) }
    }

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
