import Foundation
import Observation

/// Draft-state holder for the full-screen search surface.
///
/// Seeds from the currently applied `ListingFilter` so WHERE / WHEN / WHO rows
/// hydrate correctly when the screen opens mid-session. Price bounds are held
/// verbatim from the initial filter and re-emitted on commit — the search
/// screen doesn't edit price (that stays in the filters sheet).
@Observable
@MainActor
final class SearchScreenViewModel {
    var destinationText: String
    var selectedCity: City?
    /// Check-in drives the valid range for check-out; if a check-in moves past
    /// the current check-out we clear check-out so the user can reselect
    /// rather than silently holding an inverted range.
    var draftCheckIn: Date? {
        didSet {
            if let checkIn = draftCheckIn, let checkOut = draftCheckOut, checkOut < checkIn {
                draftCheckOut = nil
            }
        }
    }
    var draftCheckOut: Date?
    var draftGuests: Int
    var isWhenSheetPresented: Bool = false
    var isWhoSheetPresented: Bool = false
    /// Monotonically increments every `commitSearch()` call. Observed by the
    /// view via `.sensoryFeedback(trigger:)` so each commit fires one haptic.
    private(set) var committedSearchCount: Int = 0

    private let initialFilter: ListingFilter
    private let onSearch: (ListingFilter) -> Void

    init(initialFilter: ListingFilter, onSearch: @escaping (ListingFilter) -> Void) {
        self.initialFilter = initialFilter
        self.onSearch = onSearch
        self.destinationText = initialFilter.city?.rawValue ?? ""
        self.selectedCity = initialFilter.city
        self.draftCheckIn = initialFilter.checkIn
        self.draftCheckOut = initialFilter.checkOut
        self.draftGuests = initialFilter.guestCount
    }

    func selectCity(_ city: City) {
        selectedCity = city
        destinationText = city.rawValue
    }

    func clearDestination() {
        destinationText = ""
        selectedCity = nil
    }

    func clearAll() {
        destinationText = ""
        selectedCity = nil
        draftCheckIn = nil
        draftCheckOut = nil
        draftGuests = 1
    }

    func commitSearch() {
        // Price bounds are not editable on this screen — carry them through so
        // an existing price filter isn't wiped when the user commits a new
        // destination/date/guest selection.
        let newFilter = ListingFilter(
            city: selectedCity,
            checkIn: draftCheckIn,
            checkOut: draftCheckOut,
            guestCount: draftGuests,
            priceMin: initialFilter.priceMin,
            priceMax: initialFilter.priceMax
        )
        committedSearchCount &+= 1
        onSearch(newFilter)
    }
}
