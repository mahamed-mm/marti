import Foundation
import Testing
@testable import Marti

@MainActor
struct ListingDiscoveryViewModelTests {

    // MARK: - Initial load

    @Test func initialLoad_fetchesListingsFromService() async {
        let service = MockListingService()
        let dto = MockListingServiceTests.makeDTO()
        service.fetchHandler = { _, _, _ in [dto] }

        let vm = makeViewModel(service: service)
        await vm.loadListings()

        #expect(service.fetchCallCount == 1)
        #expect(vm.listings.count == 1)
        #expect(vm.listings.first?.id == dto.id)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test func emptyResults_clearsListingsAndKeepsErrorNil() async {
        let service = MockListingService()
        service.fetchHandler = { _, _, _ in [] }
        let vm = makeViewModel(service: service)
        await vm.loadListings()
        #expect(vm.listings.isEmpty)
        #expect(vm.error == nil)
    }

    // MARK: - Filters

    @Test func filterByCity_reloadsListings() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))

        vm.applyFilter(ListingFilter(city: .mogadishu))
        try? await Task.sleep(for: .milliseconds(40))

        #expect(service.fetchCallCount == 1)
        #expect(service.lastFilter?.city == .mogadishu)
    }

    @Test func filterByDates_reloadsListings() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))
        let checkIn = Date(timeIntervalSince1970: 2_000_000_000)
        let checkOut = checkIn.addingTimeInterval(86_400)

        vm.applyFilter(ListingFilter(checkIn: checkIn, checkOut: checkOut))
        try? await Task.sleep(for: .milliseconds(40))

        #expect(service.fetchCallCount == 1)
        #expect(service.lastFilter?.checkIn == checkIn)
        #expect(service.lastFilter?.checkOut == checkOut)
    }

    @Test func filterByGuests_reloadsListings() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))

        vm.applyFilter(ListingFilter(guestCount: 5))
        try? await Task.sleep(for: .milliseconds(40))

        #expect(service.lastFilter?.guestCount == 5)
    }

    @Test func filterByPriceRange_reloadsListings() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))

        vm.applyFilter(ListingFilter(priceMin: 5_000, priceMax: 20_000))
        try? await Task.sleep(for: .milliseconds(40))

        #expect(service.lastFilter?.priceMin == 5_000)
        #expect(service.lastFilter?.priceMax == 20_000)
    }

    @Test func clearFilters_resetsToDefaults() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(5))
        vm.filter = ListingFilter(city: .hargeisa, guestCount: 4, priceMin: 1000)

        vm.clearFilters()
        try? await Task.sleep(for: .milliseconds(40))

        #expect(vm.filter == .default)
        #expect(service.lastFilter == .default)
    }

    @Test func rapidFilterChanges_debouncedToSingleFetch() async {
        let service = MockListingService()
        let vm = makeViewModel(service: service, debounce: .milliseconds(20))

        vm.applyFilter(ListingFilter(city: .mogadishu))
        vm.applyFilter(ListingFilter(city: .hargeisa))
        vm.applyFilter(ListingFilter(city: .mogadishu, guestCount: 3))
        try? await Task.sleep(for: .milliseconds(80))

        #expect(service.fetchCallCount == 1)
        #expect(service.lastFilter?.city == .mogadishu)
        #expect(service.lastFilter?.guestCount == 3)
    }

    // MARK: - Pagination

    @Test func pagination_appendsNextPage() async {
        let service = MockListingService()
        let firstPage = (0..<3).map { _ in MockListingServiceTests.makeDTO() }
        let secondPage = (0..<3).map { _ in MockListingServiceTests.makeDTO() }
        var callIndex = 0
        service.fetchHandler = { _, cursor, _ in
            defer { callIndex += 1 }
            return callIndex == 0 ? firstPage : secondPage
        }

        let vm = makeViewModel(service: service, pageSize: 3)
        await vm.loadListings()
        #expect(vm.listings.count == 3)

        await vm.loadMore()
        #expect(vm.listings.count == 6)
        #expect(service.lastCursor == firstPage.last?.id)
    }

    @Test func pagination_stopsWhenLastPageReturnsLessThanLimit() async {
        let service = MockListingService()
        let firstPage = (0..<3).map { _ in MockListingServiceTests.makeDTO() }
        let secondPage = [MockListingServiceTests.makeDTO()]   // < pageSize
        var callIndex = 0
        service.fetchHandler = { _, _, _ in
            defer { callIndex += 1 }
            return callIndex == 0 ? firstPage : secondPage
        }

        let vm = makeViewModel(service: service, pageSize: 3)
        await vm.loadListings()
        await vm.loadMore()

        #expect(vm.hasMorePages == false)
        #expect(vm.listings.count == 4)
    }

    // MARK: - Refresh

    @Test func pullToRefresh_clearsListingsAndReloads() async {
        let service = MockListingService()
        let dto = MockListingServiceTests.makeDTO()
        service.fetchHandler = { _, _, _ in [dto] }

        let vm = makeViewModel(service: service)
        await vm.loadListings()
        #expect(vm.listings.count == 1)

        await vm.refresh()
        #expect(vm.listings.count == 1)
        #expect(service.fetchCallCount == 2)
        #expect(service.lastCursor == nil)
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

    // MARK: - Errors

    @Test func networkError_setsErrorState() async {
        let service = MockListingService()
        service.fetchHandler = { _, _, _ in throw AppError.network("offline") }
        let vm = makeViewModel(service: service)
        await vm.loadListings()
        #expect(vm.error == .network("offline"))
        #expect(vm.listings.isEmpty)
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

    // MARK: - Helpers

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
