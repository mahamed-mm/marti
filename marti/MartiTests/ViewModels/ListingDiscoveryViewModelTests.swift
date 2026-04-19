import Foundation
import SwiftData
import Testing
@testable import Marti

@MainActor
struct ListingDiscoveryViewModelTests {

    // MARK: - Initial load

    @Test func initialLoad_fetchesDiscoveryFeedFromService() async {
        let service = MockListingService()
        let dto = MockListingServiceTests.makeDTO()
        let cat = Self.makeCategoryDTO(slug: "popular", title: "Popular", city: nil, displayOrder: 10)
        service.fetchFeedHandler = { _ in
            DiscoveryFeedDTO(categories: [cat], listings: [Self.tagging(dto, with: cat.id)])
        }

        let vm = makeViewModel(service: service)
        await vm.loadListings()

        #expect(service.fetchFeedCallCount == 1)
        #expect(vm.listings.count == 1)
        #expect(vm.listings.first?.id == dto.id)
        #expect(vm.rails.count == 1)
        #expect(vm.rails.first?.category.slug == "popular")
        #expect(vm.rails.first?.listings.count == 1)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test func emptyResults_keepsErrorNilAndRailsEmpty() async {
        let service = MockListingService()
        service.fetchFeedHandler = { _ in DiscoveryFeedDTO(categories: [], listings: []) }

        let vm = makeViewModel(service: service)
        await vm.loadListings()

        #expect(vm.rails.isEmpty)
        #expect(vm.listings.isEmpty)
        #expect(vm.error == nil)
    }

    // MARK: - Rails composition

    @Test func rails_happyPath_twoCategoriesShareListings() async {
        let service = MockListingService()
        let cat1 = Self.makeCategoryDTO(slug: "popular", title: "Popular", city: nil, displayOrder: 10)
        let cat2 = Self.makeCategoryDTO(slug: "verified", title: "Verified hosts", city: nil, displayOrder: 20)
        let a = Self.tagging(MockListingServiceTests.makeDTO(), with: [cat1.id, cat2.id])
        let b = Self.tagging(MockListingServiceTests.makeDTO(), with: [cat1.id, cat2.id])
        let c = Self.tagging(MockListingServiceTests.makeDTO(), with: [cat1.id, cat2.id])
        service.fetchFeedHandler = { _ in
            DiscoveryFeedDTO(categories: [cat1, cat2], listings: [a, b, c])
        }

        let vm = makeViewModel(service: service)
        await vm.loadListings()

        #expect(vm.rails.count == 2)
        #expect(vm.rails[0].category.slug == "popular")
        #expect(vm.rails[0].listings.count == 3)
        #expect(vm.rails[1].category.slug == "verified")
        #expect(vm.rails[1].listings.count == 3)
    }

    @Test func rails_empty_collapseOnCityFilterChange() async {
        let service = MockListingService()
        let global    = Self.makeCategoryDTO(slug: "beachfront",    title: "Beachfront",    city: nil,           displayOrder: 10)
        let hargeisa  = Self.makeCategoryDTO(slug: "new-hargeisa",  title: "New in Hargeisa", city: "Hargeisa",  displayOrder: 20)
        let mogListing = Self.tagging(
            MockListingServiceTests.makeDTO(city: "Mogadishu"),
            with: [global.id]
        )
        service.fetchFeedHandler = { _ in
            DiscoveryFeedDTO(categories: [global, hargeisa], listings: [mogListing])
        }

        let vm = makeViewModel(service: service)
        await vm.loadListings()

        // The Hargeisa-only category has no listings tagged to it, so it collapses
        // even without a city filter.
        #expect(vm.rails.count == 1)
        #expect(vm.rails.first?.category.slug == "beachfront")

        // Apply a Mogadishu filter — the Hargeisa category is filtered out even if
        // it had listings; the global category stays.
        vm.filter = ListingFilter(city: .mogadishu)
        #expect(vm.rails.count == 1)
        #expect(vm.rails.first?.category.slug == "beachfront")
    }

    @Test func errorWithCachedRails_keepsRailsAndFlipsOffline() async throws {
        // Seed both caches.
        let schema = Schema([Listing.self, DiscoveryCategory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let cat = Self.makeCategoryDTO(slug: "popular", title: "Popular", city: nil, displayOrder: 10)
        let dto = Self.tagging(MockListingServiceTests.makeDTO(), with: [cat.id])
        context.insert(DiscoveryCategory(dto: cat))
        context.insert(Listing(dto: dto))
        try context.save()

        let service = MockListingService()
        service.fetchFeedHandler = { _ in throw AppError.network("offline") }

        let vm = ListingDiscoveryViewModel(
            listingService: service,
            currencyService: StubCurrencyService(),
            authManager: AuthManager(isAuthenticated: false),
            modelContext: context,
            debounce: .milliseconds(5)
        )
        await vm.loadListings()

        #expect(vm.rails.count == 1)
        #expect(vm.rails.first?.listings.count == 1)
        #expect(vm.isOffline == true)
        #expect(vm.error == nil)
    }

    @Test func errorWithoutCache_surfacesError() async {
        let service = MockListingService()
        service.fetchFeedHandler = { _ in throw AppError.network("offline") }

        let vm = makeViewModel(service: service)
        await vm.loadListings()

        #expect(vm.error == .network("offline"))
        #expect(vm.rails.isEmpty)
        #expect(vm.isOffline == false)
    }

    // MARK: - Filters

    @Test func filterByCity_reloadsFeedWithCity() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))

        vm.applyFilter(ListingFilter(city: .mogadishu))
        await vm.awaitPendingDebounce()

        #expect(service.fetchFeedCallCount == 1)
        #expect(service.lastFeedCity == .mogadishu)
    }

    @Test func filterByDates_triggersRefresh() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))
        let checkIn = Date(timeIntervalSince1970: 2_000_000_000)
        let checkOut = checkIn.addingTimeInterval(86_400)

        vm.applyFilter(ListingFilter(checkIn: checkIn, checkOut: checkOut))
        await vm.awaitPendingDebounce()

        #expect(service.fetchFeedCallCount == 1)
        #expect(vm.filter.checkIn == checkIn)
        #expect(vm.filter.checkOut == checkOut)
    }

    @Test func filterByGuests_triggersRefresh() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))

        vm.applyFilter(ListingFilter(guestCount: 5))
        await vm.awaitPendingDebounce()

        #expect(vm.filter.guestCount == 5)
        #expect(service.fetchFeedCallCount == 1)
    }

    @Test func filterByPriceRange_triggersRefresh() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))

        vm.applyFilter(ListingFilter(priceMin: 5_000, priceMax: 20_000))
        await vm.awaitPendingDebounce()

        #expect(vm.filter.priceMin == 5_000)
        #expect(vm.filter.priceMax == 20_000)
        #expect(service.fetchFeedCallCount == 1)
    }

    @Test func clearFilters_resetsToDefaults() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))
        vm.filter = ListingFilter(city: .hargeisa, guestCount: 4, priceMin: 1000)

        vm.clearFilters()
        await vm.awaitPendingDebounce()

        #expect(vm.filter == .default)
        #expect(service.lastFeedCity == nil)
    }

    @Test func rapidFilterChanges_debouncedToSingleFetch() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(20))

        vm.applyFilter(ListingFilter(city: .mogadishu))
        vm.applyFilter(ListingFilter(city: .hargeisa))
        vm.applyFilter(ListingFilter(city: .mogadishu, guestCount: 3))
        await vm.awaitPendingDebounce()

        #expect(service.fetchFeedCallCount == 1)
        #expect(service.lastFeedCity == .mogadishu)
        #expect(vm.filter.guestCount == 3)
    }

    // MARK: - Refresh

    @Test func pullToRefresh_reloadsFeed() async {
        let service = MockListingService()
        let cat = Self.makeCategoryDTO(slug: "popular", title: "Popular", city: nil, displayOrder: 10)
        let dto = Self.tagging(MockListingServiceTests.makeDTO(), with: [cat.id])
        service.fetchFeedHandler = { _ in
            DiscoveryFeedDTO(categories: [cat], listings: [dto])
        }

        let vm = makeViewModel(service: service)
        await vm.loadListings()
        #expect(vm.rails.count == 1)

        await vm.refresh()
        #expect(vm.rails.count == 1)
        #expect(service.fetchFeedCallCount == 2)
    }

    // MARK: - Save

    @Test func toggleSave_whenAuthenticated_callsService() async {
        let service = MockListingService()
        let auth = AuthManager(isAuthenticated: true)
        let vm = makeViewModel(service: service, auth: auth)
        let id = UUID()

        await vm.toggleSave(listingID: id)

        #expect(service.toggleCallCount == 1)
        #expect(service.lastToggleListingID == id)
        #expect(service.lastToggleSaved == true)
        #expect(vm.savedListingIDs.contains(id))
        #expect(vm.isAuthSheetPresented == false)
    }

    @Test func toggleSave_whenUnauthenticated_presentsAuthSheet() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, auth: AuthManager(isAuthenticated: false))

        await vm.toggleSave(listingID: UUID())

        #expect(service.toggleCallCount == 0)
        #expect(vm.isAuthSheetPresented == true)
        #expect(vm.savedListingIDs.isEmpty)
    }

    @Test func toggleSave_onFailure_revertsOptimisticState() async {
        let service = MockListingService()
        service.toggleHandler = { _, _ in throw AppError.network("boom") }
        let auth = AuthManager(isAuthenticated: true)
        let vm = makeViewModel(service: service, auth: auth)
        let id = UUID()

        await vm.toggleSave(listingID: id)

        #expect(vm.savedListingIDs.contains(id) == false)
        #expect(vm.error == .network("boom"))
    }

    // MARK: - View mode

    @Test func setViewMode_preservesFilter() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service)
        vm.filter = ListingFilter(city: .hargeisa, guestCount: 2)

        vm.setViewMode(.map)

        #expect(vm.viewMode == .map)
        #expect(vm.filter == ListingFilter(city: .hargeisa, guestCount: 2))
    }

    // MARK: - Header pill

    @Test func headerTitle_whenCityNil_returnsAcrossSomalia() {
        let vm = makeViewModel()
        #expect(vm.headerTitle == "Homes across Somalia")
    }

    @Test func headerTitle_whenCitySet_returnsHomesInCity() {
        let vm = makeViewModel()
        vm.filter = ListingFilter(city: .mogadishu)
        #expect(vm.headerTitle == "Homes in Mogadishu")
        vm.filter = ListingFilter(city: .hargeisa)
        #expect(vm.headerTitle == "Homes in Hargeisa")
    }

    @Test func headerSubtitle_withoutDates_returnsAnyDates() {
        let vm = makeViewModel()
        #expect(vm.headerSubtitle == "Any dates · 1 guest")
    }

    @Test func headerSubtitle_withOnlyOneDate_returnsAnyDates() {
        let vm = makeViewModel()
        let checkIn = Date(timeIntervalSince1970: 2_000_000_000)
        vm.filter = ListingFilter(checkIn: checkIn, checkOut: nil, guestCount: 2)
        #expect(vm.headerSubtitle == "Any dates · 2 guests")
    }

    @Test func headerSubtitle_withDates_formatsDateRange() {
        let vm = makeViewModel()
        let (checkIn, checkOut) = Self.utcDates(
            start: DateComponents(year: 2026, month: 12, day: 17),
            end: DateComponents(year: 2026, month: 12, day: 24)
        )
        vm.filter = ListingFilter(checkIn: checkIn, checkOut: checkOut, guestCount: 2)

        #expect(vm.headerSubtitle.contains("Dec 17"))
        #expect(vm.headerSubtitle.contains("Dec 24"))
        #expect(vm.headerSubtitle.contains("·"))
        #expect(vm.headerSubtitle.hasSuffix("2 guests"))
    }

    @Test func headerSubtitle_formatsGuestCount_singleAndPlural() {
        let vm = makeViewModel()
        vm.filter = ListingFilter(guestCount: 1)
        #expect(vm.headerSubtitle == "Any dates · 1 guest")
        vm.filter = ListingFilter(guestCount: 3)
        #expect(vm.headerSubtitle == "Any dates · 3 guests")
    }

    // MARK: - Selected listing

    @Test func selectedListing_resolvesFromSelectedPinID() async {
        let service = MockListingService()
        let idA = UUID()
        let idB = UUID()
        service.fetchFeedHandler = { _ in
            DiscoveryFeedDTO(
                categories: [],
                listings: [
                    MockListingServiceTests.makeDTO(id: idA),
                    MockListingServiceTests.makeDTO(id: idB)
                ]
            )
        }

        let vm = makeViewModel(service: service)
        await vm.loadListings()
        vm.selectPin(idB)

        #expect(vm.selectedListing?.id == idB)
    }

    @Test func selectedListing_nilWhenPinIDMissingFromListings() async {
        let service = MockListingService()
        service.fetchFeedHandler = { _ in
            DiscoveryFeedDTO(categories: [], listings: [MockListingServiceTests.makeDTO()])
        }

        let vm = makeViewModel(service: service)
        await vm.loadListings()
        vm.selectedPinID = UUID()

        #expect(vm.selectedListing == nil)
    }

    @Test func selectPin_clearsWhenListingNotInCurrentResults() async {
        let service = MockListingService()
        let idA = UUID()
        let idC = UUID()
        let counter = Locked(0)
        service.fetchFeedHandler = { _ in
            let index = counter.increment()
            let id: UUID = (index == 0) ? idA : idC
            return DiscoveryFeedDTO(categories: [], listings: [MockListingServiceTests.makeDTO(id: id)])
        }

        let vm = makeViewModel(service: service)
        await vm.loadListings()
        vm.selectPin(idA)
        #expect(vm.selectedPinID == idA)

        await vm.refresh()

        #expect(vm.selectedPinID == nil)
    }

    @Test func selectionSurvives_refreshThatStillContainsListing() async {
        let service = MockListingService()
        let idA = UUID()
        service.fetchFeedHandler = { _ in
            DiscoveryFeedDTO(categories: [], listings: [MockListingServiceTests.makeDTO(id: idA)])
        }

        let vm = makeViewModel(service: service)
        await vm.loadListings()
        vm.selectPin(idA)

        await vm.refresh()

        #expect(vm.selectedPinID == idA)
        #expect(vm.selectedListing?.id == idA)
    }

    // MARK: - SwiftData cache safety

    /// Regression: a View holding a `Listing` from `vm.listings` must never crash
    /// when SwiftData deletes the corresponding row from the model context.
    @Test func cacheHit_surfacesListingsDetachedFromModelContext() async throws {
        let schema = Schema([Listing.self, DiscoveryCategory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let cachedDTO = MockListingServiceTests.makeDTO()
        context.insert(Listing(dto: cachedDTO))
        try context.save()

        let service = MockListingService()
        service.fetchFeedHandler = { _ in throw AppError.network("offline") }

        let vm = ListingDiscoveryViewModel(
            listingService: service,
            currencyService: StubCurrencyService(),
            authManager: AuthManager(isAuthenticated: false),
            modelContext: context,
            debounce: .milliseconds(5)
        )
        await vm.loadListings()

        #expect(vm.listings.count == 1)
        #expect(vm.isOffline == true)

        let managed = try context.fetch(FetchDescriptor<Listing>())
        for row in managed { context.delete(row) }
        try context.save()

        let photos = vm.listings.first?.photoURLs
        #expect(photos == cachedDTO.photoURLs)
    }

    // MARK: - Fee-inclusion tag

    @Test func dismissFeeTag_flipsFeeTagDismissed() {
        let vm = makeViewModel()
        #expect(vm.feeTagDismissed == false)

        vm.dismissFeeTag()

        #expect(vm.feeTagDismissed == true)
    }

    @Test func feeTagDismissed_doesNotPersistAcrossInstances() {
        let first = makeViewModel()
        first.dismissFeeTag()
        #expect(first.feeTagDismissed == true)

        let second = makeViewModel()
        #expect(second.feeTagDismissed == false)
    }

    // MARK: - Helpers

    private static func utcDates(start: DateComponents, end: DateComponents) -> (Date, Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return (calendar.date(from: start)!, calendar.date(from: end)!)
    }

    nonisolated static func makeCategoryDTO(
        id: UUID = UUID(),
        slug: String,
        title: String,
        subtitle: String? = nil,
        city: String? = nil,
        displayOrder: Int,
        createdAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> DiscoveryCategoryDTO {
        DiscoveryCategoryDTO(
            id: id,
            slug: slug,
            title: title,
            subtitle: subtitle,
            city: city,
            displayOrder: displayOrder,
            createdAt: createdAt
        )
    }

    /// Returns a copy of the supplied listing DTO with its `categoryIDs` overridden.
    nonisolated static func tagging(_ dto: ListingDTO, with categoryIDs: [UUID]) -> ListingDTO {
        ListingDTO(
            id: dto.id,
            title: dto.title,
            city: dto.city,
            neighborhood: dto.neighborhood,
            description: dto.description,
            pricePerNight: dto.pricePerNight,
            latitude: dto.latitude,
            longitude: dto.longitude,
            photoURLs: dto.photoURLs,
            amenities: dto.amenities,
            maxGuests: dto.maxGuests,
            hostID: dto.hostID,
            hostName: dto.hostName,
            hostPhotoURL: dto.hostPhotoURL,
            isVerified: dto.isVerified,
            averageRating: dto.averageRating,
            reviewCount: dto.reviewCount,
            cancellationPolicy: dto.cancellationPolicy,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            categoryIDs: categoryIDs
        )
    }

    nonisolated static func tagging(_ dto: ListingDTO, with categoryID: UUID) -> ListingDTO {
        tagging(dto, with: [categoryID])
    }

    private func makeViewModel(
        service: MockListingService = MockListingService(),
        currency: CurrencyService = StubCurrencyService(),
        auth: AuthManager? = nil,
        pageSize: Int = 20,
        debounce: Duration = .milliseconds(5)
    ) -> ListingDiscoveryViewModel {
        ListingDiscoveryViewModel(
            listingService: service,
            currencyService: currency,
            authManager: auth ?? AuthManager(isAuthenticated: false),
            pageSize: pageSize,
            debounce: debounce
        )
    }
}

private final class StubCurrencyService: CurrencyService, @unchecked Sendable {
    func usdToSOS(_ usdCents: Int, display: CurrencyDisplay) -> String? { nil }
    func refreshRate() async throws {}
}

/// Minimal thread-safe counter. Avoids pulling `Synchronization.Mutex` into
/// individual test closures; `@Sendable` constraints on handler closures need
/// simple captured state.
final class Locked<T>: @unchecked Sendable {
    private var value: T
    private let lock = NSLock()
    init(_ value: T) { self.value = value }
    func withLock<R>(_ body: (inout T) -> R) -> R {
        lock.lock(); defer { lock.unlock() }
        return body(&value)
    }
}

extension Locked where T == Int {
    func increment() -> Int {
        withLock { current in
            defer { current += 1 }
            return current
        }
    }
}
