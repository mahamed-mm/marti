import Foundation
import Observation

/// View model for `ListingDetailView`. Seeded with a `Listing` from the
/// navigation hand-off so the first frame renders fully populated. Refreshes
/// the snapshot from the service in the background and mirrors the offline
/// pattern used by Discovery: with a seeded listing in hand, network failure
/// flips `isOffline = true` instead of surfacing an error.
///
/// Save handling is deliberately copied from
/// `ListingDiscoveryViewModel.toggleSave` (lines 285–309). Two callsites is
/// below the abstraction threshold per `CLAUDE.md`; extracting a shared helper
/// would couple two different parents (Discovery's `Set<UUID>` vs. Detail's
/// single `Bool`) without buying enough.
@Observable
@MainActor
final class ListingDetailViewModel {
    // MARK: - State

    /// Snapshot rendered by the view. Seeded at init from the navigation
    /// hand-off; replaced on a successful background refresh.
    private(set) var listing: Listing
    /// `true` while a background refresh is in flight. `false` initially —
    /// the seed gives us a fully populated first frame, no spinner needed.
    private(set) var isLoading: Bool = false
    /// Surfaced only when refresh fails AND we have no fallback to show.
    /// Today the seed is mandatory, so this realistically only flips on
    /// `.notFound` (listing was deleted between push and refresh).
    private(set) var error: AppError?
    /// Mirror of Discovery's offline pattern: refresh failed, but the seeded
    /// snapshot is still on screen. Banner ask, not a destructive empty state.
    private(set) var isOffline: Bool = false
    /// Optimistic save state. Starts from the parent's `savedListingIDs` set
    /// so a re-push reflects the latest server-confirmed value.
    private(set) var isSaved: Bool

    /// Bound to the gallery's `TabView` selection so the page-dot indicator
    /// reflects the current photo. Settable so the SwiftUI binding can write
    /// back into the view model.
    var currentPhotoIndex: Int = 0
    /// Sheet gates. Plain `Bool` because SwiftUI's `.sheet(isPresented:)`
    /// expects a `Binding<Bool>` — the SDK doesn't care these are mutable.
    var isAuthSheetPresented: Bool = false
    var isComingSoonSheetPresented: Bool = false
    /// Drives the "This listing is no longer available" alert in the View.
    /// Flips to `true` when refresh resolves to `.notFound`; the View binds it
    /// to `.alert(isPresented:)` and pops the stack from the OK action. The
    /// View also keeps a `didHandleNotFound` guard so a re-push of the same
    /// id still works after the user has acknowledged the alert.
    var shouldShowNotFoundAlert: Bool = false

    /// Concurrent-tap guard for `toggleSave`. Private so neither view nor
    /// tests can drive it directly — the guard is a property of the action,
    /// not external state.
    private var isSavingInFlight: Bool = false

    // MARK: - Dependencies

    private let listingService: ListingService
    private let currencyService: CurrencyService
    private let authManager: AuthManager
    /// Optional callback to keep a parent (Discovery) in sync with the
    /// authoritative save state once the server confirms / fails.
    private let onSavedChanged: ((Bool) -> Void)?

    // MARK: - Init

    init(
        listing: Listing,
        listingService: ListingService,
        currencyService: CurrencyService,
        authManager: AuthManager,
        isInitiallySaved: Bool = false,
        onSavedChanged: ((Bool) -> Void)? = nil
    ) {
        self.listing = listing
        self.listingService = listingService
        self.currencyService = currencyService
        self.authManager = authManager
        self.isSaved = isInitiallySaved
        self.onSavedChanged = onSavedChanged
    }

    // MARK: - Actions

    /// Background-refreshes the seeded `listing` against the source of truth.
    ///
    /// Mirrors the Discovery cache-vs-error policy: with the seed already on
    /// screen, a network failure flips `isOffline = true` instead of dropping
    /// the user into an error state. A `.notFound` is the one error we *do*
    /// surface even with a seed — the listing has been deleted server-side
    /// and the view should pop, so the value remains for the view to react
    /// to (either via an alert or `.task` re-render).
    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let dto = try await listingService.fetchListing(id: listing.id)
            // Replace the @Model snapshot with a freshly hydrated value
            // built from the wire DTO. We don't write to the SwiftData
            // cache here — Discovery owns the cache write path.
            listing = Listing(dto: dto)
            // Clamp the gallery's selection to the new photo count so a
            // shrunk server snapshot doesn't leave the TabView pointing at
            // an orphaned tag (counter would render "6 / 3").
            currentPhotoIndex = min(currentPhotoIndex, max(0, listing.photoURLs.count - 1))
            isOffline = false
            error = nil
        } catch let appError as AppError {
            switch appError {
            case .notFound:
                // Surface the deletion explicitly; the View shows an alert
                // and pops on the OK action.
                error = .notFound
                shouldShowNotFoundAlert = true
            default:
                // Network / unknown / unauthorized — keep seed, flip offline.
                isOffline = true
            }
        } catch {
            isOffline = true
        }
    }

    /// Toggles the save state for the seeded listing. Pattern is intentionally
    /// copied from `ListingDiscoveryViewModel.toggleSave` (lines 285–309) per
    /// the spec's "two callsites is below the abstraction threshold" rule.
    ///
    /// Behavior:
    /// - Unauthenticated → present `AuthSheetPlaceholderView`, no service call.
    /// - Authenticated → flip `isSaved`, call the service, roll back on error.
    /// - Concurrent taps while one is in flight → no-op.
    /// - On commit (success), invoke `onSavedChanged` so the parent (Discovery)
    ///   can mirror its `savedListingIDs` set.
    func toggleSave() async {
        guard authManager.isAuthenticated else {
            isAuthSheetPresented = true
            return
        }
        guard !isSavingInFlight else { return }
        isSavingInFlight = true
        defer { isSavingInFlight = false }

        let wasSaved = isSaved
        let newSaved = !wasSaved
        isSaved = newSaved

        do {
            try await listingService.toggleSaved(listingID: listing.id, saved: newSaved)
            onSavedChanged?(newSaved)
        } catch {
            // Roll back optimistic flip and surface the error.
            isSaved = wasSaved
            self.error = mapError(error)
        }
    }

    /// Triggers the "Request to Book" coming-soon sheet. No service call;
    /// Bookings infra ships separately.
    func requestToBook() {
        isComingSoonSheetPresented = true
    }

    // MARK: - Display helpers

    /// Full-form SOS price line for the sticky CTA bar (e.g. "~1,530,000 SOS").
    /// Returns `nil` when no rate is cached, in which case the SOS line should
    /// simply hide rather than render an empty placeholder.
    var fullSOSPriceLine: String? {
        currencyService.usdToSOS(listing.pricePerNight, display: .full)
    }

    // MARK: - Error mapping

    /// Mirrors Discovery's mapping policy: preserve `AppError` if already one,
    /// otherwise wrap as `.unknown`.
    private func mapError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}
