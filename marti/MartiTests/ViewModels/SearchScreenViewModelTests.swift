import Foundation
import Testing
@testable import Marti

@MainActor
struct SearchScreenViewModelTests {

    // MARK: - Seeding

    @Test func seedsFromInitialFilter_populatesAllDraftFields() {
        let d1 = Date(timeIntervalSince1970: 2_000_000_000)
        let d2 = Date(timeIntervalSince1970: 2_000_000_000 + 86_400)
        let filter = ListingFilter(
            city: .hargeisa,
            checkIn: d1,
            checkOut: d2,
            guestCount: 3,
            priceMin: 5_000,
            priceMax: 20_000
        )

        let vm = SearchScreenViewModel(initialFilter: filter) { _ in }

        #expect(vm.destinationText == "Hargeisa")
        #expect(vm.selectedCity == .hargeisa)
        #expect(vm.draftCheckIn == d1)
        #expect(vm.draftCheckOut == d2)
        #expect(vm.draftGuests == 3)
    }

    @Test func seedsFromDefaultFilter_hasEmptyDestinationAndNoDatesAndOneGuest() {
        let vm = SearchScreenViewModel(initialFilter: ListingFilter()) { _ in }

        #expect(vm.destinationText == "")
        #expect(vm.selectedCity == nil)
        #expect(vm.draftCheckIn == nil)
        #expect(vm.draftCheckOut == nil)
        #expect(vm.draftGuests == 1)
    }

    // MARK: - selectCity

    @Test func selectCity_fillsDestinationTextWithCityName() {
        let vm = SearchScreenViewModel(initialFilter: ListingFilter()) { _ in }

        vm.selectCity(.kismayo)

        #expect(vm.destinationText == "Kismayo")
        #expect(vm.selectedCity == .kismayo)
    }

    // MARK: - clearDestination

    @Test func clearDestination_wipesDestinationButPreservesDatesAndGuests() {
        let vm = SearchScreenViewModel(initialFilter: ListingFilter()) { _ in }
        let d1 = Date(timeIntervalSince1970: 2_000_000_000)
        let d2 = Date(timeIntervalSince1970: 2_000_000_000 + 86_400)
        vm.selectCity(.mogadishu)
        vm.draftCheckIn = d1
        vm.draftCheckOut = d2
        vm.draftGuests = 4

        vm.clearDestination()

        #expect(vm.destinationText == "")
        #expect(vm.selectedCity == nil)
        // Preserved
        #expect(vm.draftCheckIn == d1)
        #expect(vm.draftCheckOut == d2)
        #expect(vm.draftGuests == 4)
    }

    // MARK: - clearAll

    @Test func clearAll_resetsAllDraftFieldsToDefaults() {
        let vm = SearchScreenViewModel(initialFilter: ListingFilter()) { _ in }
        vm.selectCity(.mogadishu)
        vm.draftCheckIn = Date(timeIntervalSince1970: 2_000_000_000)
        vm.draftCheckOut = Date(timeIntervalSince1970: 2_000_000_000 + 86_400)
        vm.draftGuests = 6

        vm.clearAll()

        #expect(vm.destinationText == "")
        #expect(vm.selectedCity == nil)
        #expect(vm.draftCheckIn == nil)
        #expect(vm.draftCheckOut == nil)
        #expect(vm.draftGuests == 1)
    }

    // MARK: - commitSearch

    @Test func commitSearch_emitsFilterMatchingDraftCityDatesAndGuests() {
        let captured = CapturedFilter()
        let vm = SearchScreenViewModel(initialFilter: ListingFilter()) { filter in
            captured.record(filter)
        }
        let d1 = Date(timeIntervalSince1970: 2_000_000_000)
        let d2 = Date(timeIntervalSince1970: 2_000_000_000 + 86_400 * 3)
        vm.selectCity(.berbera)
        vm.draftCheckIn = d1
        vm.draftCheckOut = d2
        vm.draftGuests = 2

        vm.commitSearch()

        #expect(captured.count == 1)
        let emitted = try! #require(captured.last)
        #expect(emitted.city == .berbera)
        #expect(emitted.checkIn == d1)
        #expect(emitted.checkOut == d2)
        #expect(emitted.guestCount == 2)
    }

    @Test func commitSearch_preservesPriceBoundsFromInitialFilter() {
        let captured = CapturedFilter()
        let initial = ListingFilter(priceMin: 7_500, priceMax: 30_000)
        let vm = SearchScreenViewModel(initialFilter: initial) { filter in
            captured.record(filter)
        }
        vm.selectCity(.mogadishu)
        vm.draftGuests = 5

        vm.commitSearch()

        #expect(captured.count == 1)
        let emitted = try! #require(captured.last)
        #expect(emitted.priceMin == 7_500)
        #expect(emitted.priceMax == 30_000)
        // Sanity: draft fields still propagated through.
        #expect(emitted.city == .mogadishu)
        #expect(emitted.guestCount == 5)
    }

    @Test func commitSearch_withNoCity_emitsNilCityButKeepsDatesAndGuests() {
        let captured = CapturedFilter()
        let vm = SearchScreenViewModel(initialFilter: ListingFilter()) { filter in
            captured.record(filter)
        }
        let d1 = Date(timeIntervalSince1970: 2_100_000_000)
        let d2 = Date(timeIntervalSince1970: 2_100_000_000 + 86_400 * 2)
        vm.draftCheckIn = d1
        vm.draftCheckOut = d2
        vm.draftGuests = 3

        vm.commitSearch()

        #expect(captured.count == 1)
        let emitted = try! #require(captured.last)
        #expect(emitted.city == nil)
        #expect(emitted.checkIn == d1)
        #expect(emitted.checkOut == d2)
        #expect(emitted.guestCount == 3)
    }
}

// MARK: - Capture helper

/// `@MainActor`-isolated collector for filters emitted by `onSearch`. The VM is
/// `@MainActor`, so the closure runs on the main actor too — this matches
/// isolation and avoids the need for a lock.
@MainActor
private final class CapturedFilter {
    private var filters: [ListingFilter] = []

    func record(_ filter: ListingFilter) {
        filters.append(filter)
    }

    var count: Int { filters.count }
    var last: ListingFilter? { filters.last }
}
