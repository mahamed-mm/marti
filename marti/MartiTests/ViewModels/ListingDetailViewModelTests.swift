import Foundation
import Testing
@testable import Marti

@MainActor
struct ListingDetailViewModelTests {

    // MARK: - Init

    /// First-frame contract: the seed populates everything the view renders so
    /// there's no spinner flash on push.
    @Test func init_withSeed_isFullyPopulatedForFirstFrame() {
        let seed = Self.makeListing(title: "Seaside hideaway")
        let vm = ListingDetailViewModel(
            listing: seed,
            listingService: MockListingService(),
            currencyService: StubCurrencyService(),
            authManager: AuthManager(isAuthenticated: false),
            isInitiallySaved: false
        )

        #expect(vm.listing.id == seed.id)
        #expect(vm.listing.title == "Seaside hideaway")
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(vm.isOffline == false)
        #expect(vm.isSaved == false)
        #expect(vm.currentPhotoIndex == 0)
        #expect(vm.isAuthSheetPresented == false)
        #expect(vm.isComingSoonSheetPresented == false)
        #expect(vm.shouldShowNotFoundAlert == false)
    }

    // MARK: - Refresh

    @Test func refresh_onSuccess_replacesListingWithFreshDTO() async {
        let seed = Self.makeListing(title: "Old title")
        let updated = Self.makeListingDTO(id: seed.id, title: "Fresh title")
        let service = MockListingService()
        service.fetchListingHandler = { _ in updated }

        let vm = Self.makeVM(seed: seed, service: service)
        await vm.refresh()

        #expect(service.fetchListingCallCount == 1)
        #expect(service.lastFetchListingID == seed.id)
        #expect(vm.listing.title == "Fresh title")
        #expect(vm.isOffline == false)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test func refresh_onNetworkFailure_keepsSeedAndFlipsIsOffline() async {
        let seed = Self.makeListing(title: "Seaside hideaway")
        let service = MockListingService()
        service.fetchListingHandler = { _ in throw AppError.network("offline") }

        let vm = Self.makeVM(seed: seed, service: service)
        await vm.refresh()

        // Seed must remain on screen; banner ask only.
        #expect(vm.listing.title == "Seaside hideaway")
        #expect(vm.isOffline == true)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test func refresh_onNotFound_setsErrorAndDoesNotMutateListing() async {
        let seed = Self.makeListing(title: "Seaside hideaway")
        let service = MockListingService()
        service.fetchListingHandler = { _ in throw AppError.notFound }

        let vm = Self.makeVM(seed: seed, service: service)
        await vm.refresh()

        #expect(vm.error == .notFound)
        #expect(vm.listing.title == "Seaside hideaway")
        #expect(vm.isOffline == false)
        // M1: alert flag must flip so the View can surface
        // "This listing is no longer available" before popping.
        #expect(vm.shouldShowNotFoundAlert == true)
    }

    /// Regression: when `refresh()` replaces the seed with a server snapshot
    /// that has fewer photos, `currentPhotoIndex` must be clamped to the new
    /// last valid index. Without the clamp, the gallery's TabView selection
    /// goes orphan and the counter pill renders nonsense like "6 / 3".
    @Test func refresh_whenServerSnapshotHasFewerPhotos_clampsCurrentPhotoIndex() async {
        let seed = Self.makeListing(
            photoURLs: (0..<6).map { "https://test.invalid/\($0).jpg" }
        )
        let shrunkDTO = Self.makeListingDTO(
            id: seed.id,
            photoURLs: (0..<3).map { "https://test.invalid/\($0).jpg" }
        )
        let service = MockListingService()
        service.fetchListingHandler = { _ in shrunkDTO }

        let vm = Self.makeVM(seed: seed, service: service)
        vm.currentPhotoIndex = 5

        await vm.refresh()

        #expect(vm.listing.photoURLs.count == 3)
        #expect(vm.currentPhotoIndex == 2)
    }

    // MARK: - Save

    @Test func toggleSave_whenUnauthenticated_presentsAuthSheetAndDoesNotCallService() async {
        let service = MockListingService()
        let vm = Self.makeVM(
            seed: Self.makeListing(),
            service: service,
            auth: AuthManager(isAuthenticated: false)
        )

        await vm.toggleSave()

        #expect(vm.isAuthSheetPresented == true)
        #expect(service.toggleCallCount == 0)
        #expect(vm.isSaved == false)
    }

    @Test func toggleSave_whenAuthenticated_optimisticallyTogglesAndCallsService() async {
        let service = MockListingService()
        var observed: [Bool] = []
        let vm = Self.makeVM(
            seed: Self.makeListing(),
            service: service,
            auth: AuthManager(isAuthenticated: true),
            isInitiallySaved: false,
            onSavedChanged: { observed.append($0) }
        )

        await vm.toggleSave()

        #expect(vm.isSaved == true)
        #expect(service.toggleCallCount == 1)
        #expect(service.lastToggleSaved == true)
        #expect(vm.isAuthSheetPresented == false)
        #expect(observed == [true])
    }

    @Test func toggleSave_onServiceFailure_rollsBackOptimisticState() async {
        let service = MockListingService()
        service.toggleHandler = { _, _ in throw AppError.network("boom") }
        var observed: [Bool] = []
        let vm = Self.makeVM(
            seed: Self.makeListing(),
            service: service,
            auth: AuthManager(isAuthenticated: true),
            isInitiallySaved: false,
            onSavedChanged: { observed.append($0) }
        )

        await vm.toggleSave()

        #expect(vm.isSaved == false)
        #expect(vm.error == .network("boom"))
        // Parent must NOT see a phantom commit on rollback.
        #expect(observed.isEmpty)
    }

    @Test func toggleSave_concurrentTaps_areGuarded() async {
        // Use a continuation to gate the first tap so we can fire a second
        // tap *while* the first is in flight and verify the guard rejects
        // the second invocation.
        let service = MockListingService()
        let release = AsyncContinuationHolder()
        service.toggleHandler = { _, _ in
            await release.wait()
        }
        let vm = Self.makeVM(
            seed: Self.makeListing(),
            service: service,
            auth: AuthManager(isAuthenticated: true)
        )

        let first = Task { await vm.toggleSave() }
        // Yield enough times for the first tap to capture `isSavingInFlight`.
        for _ in 0..<5 { await Task.yield() }

        await vm.toggleSave() // second tap — should no-op.
        release.resume()
        await first.value

        // Only the first tap reaches the service, and the optimistic state
        // settles on the first tap's value.
        #expect(service.toggleCallCount == 1)
        #expect(vm.isSaved == true)
    }

    // MARK: - Request to book

    @Test func requestToBook_setsComingSoonSheetPresented() {
        let vm = Self.makeVM(seed: Self.makeListing(), service: MockListingService())
        #expect(vm.isComingSoonSheetPresented == false)

        vm.requestToBook()

        #expect(vm.isComingSoonSheetPresented == true)
    }

    // MARK: - Photo index

    @Test func currentPhotoIndex_isObservableForPageDotIndicator() {
        let vm = Self.makeVM(seed: Self.makeListing(), service: MockListingService())
        #expect(vm.currentPhotoIndex == 0)

        vm.currentPhotoIndex = 2
        #expect(vm.currentPhotoIndex == 2)

        vm.currentPhotoIndex = 0
        #expect(vm.currentPhotoIndex == 0)
    }

    // MARK: - Helpers

    private static func makeVM(
        seed: Listing,
        service: MockListingService,
        currency: CurrencyService = StubCurrencyService(),
        auth: AuthManager? = nil,
        isInitiallySaved: Bool = false,
        onSavedChanged: ((Bool) -> Void)? = nil
    ) -> ListingDetailViewModel {
        ListingDetailViewModel(
            listing: seed,
            listingService: service,
            currencyService: currency,
            authManager: auth ?? AuthManager(isAuthenticated: false),
            isInitiallySaved: isInitiallySaved,
            onSavedChanged: onSavedChanged
        )
    }

    static func makeListing(
        id: UUID = UUID(),
        title: String = "Test",
        photoURLs: [String] = ["https://test.invalid/a.jpg", "https://test.invalid/b.jpg"]
    ) -> Listing {
        Listing(
            id: id,
            title: title,
            city: "Mogadishu",
            neighborhood: "Hodan",
            listingDescription: "desc",
            pricePerNight: 8500,
            latitude: 2.0469,
            longitude: 45.3182,
            photoURLs: photoURLs,
            amenities: ["WiFi", "AC"],
            maxGuests: 2,
            hostID: UUID(),
            hostName: "Host",
            hostPhotoURL: nil,
            isVerified: true,
            averageRating: 4.6,
            reviewCount: 12,
            cancellationPolicy: "flexible",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
    }

    nonisolated static func makeListingDTO(
        id: UUID = UUID(),
        title: String = "Test",
        photoURLs: [String] = ["https://test.invalid/a.jpg"]
    ) -> ListingDTO {
        ListingDTO(
            id: id,
            title: title,
            city: "Mogadishu",
            neighborhood: "Hodan",
            description: "desc",
            pricePerNight: 8500,
            latitude: 2.0469,
            longitude: 45.3182,
            photoURLs: photoURLs,
            amenities: ["WiFi"],
            maxGuests: 2,
            hostID: UUID(),
            hostName: "Host",
            hostPhotoURL: nil,
            isVerified: true,
            averageRating: 4.6,
            reviewCount: 12,
            cancellationPolicy: "flexible",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000),
            categoryIDs: []
        )
    }
}

private final class StubCurrencyService: CurrencyService, @unchecked Sendable {
    func usdToSOS(_ usdCents: Int, display: CurrencyDisplay) -> String? { nil }
    func refreshRate() async throws {}
}

/// Tiny one-shot continuation holder. Lets a test gate a service stub on a
/// signal from the test code so we can deterministically interleave
/// concurrent tasks without sleeping.
private final class AsyncContinuationHolder: @unchecked Sendable {
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}
