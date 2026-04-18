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
            // Cache-first: surface cached listings immediately so the UI has something to render.
            let cached = readCache()
            if !cached.isEmpty, listings.isEmpty {
                listings = cached
            }

            isLoading = listings.isEmpty
            error = nil
            do {
                let dtos = try await listingService.fetchListings(filter: filter, cursor: nil, limit: pageSize)
                if Task.isCancelled { return }
                listings = dtos.map { Listing(dto: $0) }
                hasMorePages = dtos.count == pageSize
                writeCache(replacingWith: dtos)
                isOffline = false
            } catch {
                if Task.isCancelled { return }
                if !cached.isEmpty {
                    // Keep cached listings on screen, just flag offline.
                    isOffline = true
                } else {
                    self.error = mapError(error)
                }
            }
            isLoading = false
        }
        loadTask = task
        await task.value
    }

    func loadMore() async {
        guard hasMorePages, !isLoading, !isLoadingMore, let last = listings.last else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let dtos = try await listingService.fetchListings(filter: filter, cursor: last.id, limit: pageSize)
            listings.append(contentsOf: dtos.map { Listing(dto: $0) })
            hasMorePages = dtos.count == pageSize
        } catch {
            self.error = mapError(error)
        }
    }

    func refresh() async {
        listings = []
        hasMorePages = true
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

    // MARK: - Helpers

    private func mapError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }

    // MARK: - Cache

    private func readCache() -> [Listing] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Listing>(sortBy: [SortDescriptor(\.id)])
        return (try? modelContext.fetch(descriptor)) ?? []
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
            if existingByID[dto.id] == nil {
                modelContext.insert(Listing(dto: dto))
            }
        }
        try? modelContext.save()
    }
}
