import Foundation
import Testing
@testable import Marti

struct ListingTests {
    private static let sampleJSON = """
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "title": "Peaceful Villa in Hodan",
      "city": "Mogadishu",
      "neighborhood": "Hodan",
      "description": "A quiet two-bedroom villa with a garden.",
      "price_per_night": 8500,
      "latitude": 2.0469,
      "longitude": 45.3182,
      "photo_urls": ["https://example.com/a.jpg", "https://example.com/b.jpg"],
      "amenities": ["WiFi", "AC", "Parking"],
      "max_guests": 4,
      "host_id": "22222222-2222-2222-2222-222222222222",
      "host_name": "Aisha M.",
      "host_photo_url": "https://example.com/host.jpg",
      "is_verified": true,
      "average_rating": 4.7,
      "review_count": 23,
      "cancellation_policy": "moderate",
      "created_at": "2026-03-01T12:00:00Z",
      "updated_at": "2026-04-10T09:30:00Z"
    }
    """.data(using: .utf8)!

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    @Test func decodesSupabaseRowIntoDTO() throws {
        let dto = try Self.makeDecoder().decode(ListingDTO.self, from: Self.sampleJSON)
        #expect(dto.id == UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        #expect(dto.title == "Peaceful Villa in Hodan")
        #expect(dto.city == "Mogadishu")
        #expect(dto.neighborhood == "Hodan")
        #expect(dto.pricePerNight == 8500)
        #expect(dto.photoURLs.count == 2)
        #expect(dto.amenities == ["WiFi", "AC", "Parking"])
        #expect(dto.maxGuests == 4)
        #expect(dto.hostName == "Aisha M.")
        #expect(dto.isVerified)
        #expect(dto.averageRating == 4.7)
        #expect(dto.reviewCount == 23)
    }

    @Test func dtoRoundTripsThroughJSON() throws {
        let original = try Self.makeDecoder().decode(ListingDTO.self, from: Self.sampleJSON)
        let encoded = try Self.makeEncoder().encode(original)
        let roundTripped = try Self.makeDecoder().decode(ListingDTO.self, from: encoded)
        #expect(original == roundTripped)
    }

    @Test func nullableFieldsDecodeAsNil() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "title": "T", "city": "Hargeisa", "neighborhood": "N", "description": "D",
          "price_per_night": 1000, "latitude": 9.55, "longitude": 44.07,
          "photo_urls": [], "amenities": [], "max_guests": 1,
          "host_id": "22222222-2222-2222-2222-222222222222", "host_name": "H",
          "host_photo_url": null, "is_verified": false,
          "average_rating": null, "review_count": 0,
          "cancellation_policy": "flexible",
          "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let dto = try Self.makeDecoder().decode(ListingDTO.self, from: json)
        #expect(dto.hostPhotoURL == nil)
        #expect(dto.averageRating == nil)
    }

    @Test func dtoMapsIntoSwiftDataModel() throws {
        let dto = try Self.makeDecoder().decode(ListingDTO.self, from: Self.sampleJSON)
        let model = Listing(dto: dto)
        #expect(model.id == dto.id)
        #expect(model.title == dto.title)
        #expect(model.listingDescription == dto.description)
        #expect(model.pricePerNight == dto.pricePerNight)
        #expect(model.photoURLs == dto.photoURLs)
        #expect(model.hostID == dto.hostID)
    }

    @Test func modelRoundTripsBackToDTO() throws {
        let dto = try Self.makeDecoder().decode(ListingDTO.self, from: Self.sampleJSON)
        let model = Listing(dto: dto)
        let restored = ListingDTO(model: model)
        #expect(dto == restored)
    }
}
