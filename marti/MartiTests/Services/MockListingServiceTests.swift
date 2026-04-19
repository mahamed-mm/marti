import Foundation
import Testing
@testable import Marti

struct MockListingServiceTests {

    @Test func recordsFetchInputs() async throws {
        let service = MockListingService()
        let cursor = ListingCursor(createdAt: Date(timeIntervalSince1970: 1_800_000_000), id: UUID())
        let filter = ListingFilter(city: .mogadishu, guestCount: 3)
        _ = try await service.fetchListings(filter: filter, cursor: cursor, limit: 20)

        #expect(service.fetchCallCount == 1)
        #expect(service.lastFilter == filter)
        #expect(service.lastCursor == cursor)
        #expect(service.lastLimit == 20)
    }

    @Test func returnsHandlerResultsWhenSet() async throws {
        let service = MockListingService()
        let dto = Self.makeDTO()
        service.fetchHandler = { _, _, _ in [dto] }
        let result = try await service.fetchListings(filter: .default, cursor: nil, limit: 20)
        #expect(result == [dto])
    }

    @Test func returnsEmptyArrayWhenNoHandler() async throws {
        let service = MockListingService()
        let result = try await service.fetchListings(filter: .default, cursor: nil, limit: 20)
        #expect(result.isEmpty)
    }

    @Test func toggleRecordsParameters() async throws {
        let service = MockListingService()
        let id = UUID()
        try await service.toggleSaved(listingID: id, saved: true)
        #expect(service.toggleCallCount == 1)
        #expect(service.lastToggleListingID == id)
        #expect(service.lastToggleSaved == true)
    }

    @Test func toggleHandlerCanThrow() async {
        let service = MockListingService()
        service.toggleHandler = { _, _ in throw AppError.unauthorized }
        await #expect(throws: AppError.unauthorized) {
            try await service.toggleSaved(listingID: UUID(), saved: true)
        }
    }

    @Test func fetchDiscoveryFeed_recordsCityAndReturnsHandlerOutput() async throws {
        let service = MockListingService()
        let feed = DiscoveryFeedDTO(
            categories: [
                DiscoveryCategoryDTO(
                    id: UUID(),
                    slug: "popular",
                    title: "Popular",
                    subtitle: nil,
                    city: "Mogadishu",
                    displayOrder: 10,
                    createdAt: Date(timeIntervalSince1970: 1_800_000_000)
                )
            ],
            listings: [Self.makeDTO()]
        )
        service.fetchFeedHandler = { _ in feed }

        let result = try await service.fetchDiscoveryFeed(city: .mogadishu)

        #expect(service.fetchFeedCallCount == 1)
        #expect(service.lastFeedCity == .mogadishu)
        #expect(result == feed)
    }

    @Test func fetchDiscoveryFeed_returnsEmptyWhenNoHandler() async throws {
        let service = MockListingService()
        let result = try await service.fetchDiscoveryFeed(city: nil)
        #expect(result.categories.isEmpty)
        #expect(result.listings.isEmpty)
    }

    nonisolated static func makeDTO(
        id: UUID = UUID(),
        city: String = "Mogadishu",
        categoryIDs: [UUID] = []
    ) -> ListingDTO {
        ListingDTO(
            id: id,
            title: "Test",
            city: city,
            neighborhood: "Hodan",
            description: "desc",
            pricePerNight: 8500,
            latitude: 2.0469,
            longitude: 45.3182,
            photoURLs: [],
            amenities: [],
            maxGuests: 2,
            hostID: UUID(),
            hostName: "Host",
            hostPhotoURL: nil,
            isVerified: true,
            averageRating: nil,
            reviewCount: 0,
            cancellationPolicy: "flexible",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000),
            categoryIDs: categoryIDs
        )
    }
}
