import Foundation
import SwiftData

@Model
final class Listing {
    @Attribute(.unique) var id: UUID
    var title: String
    var city: String
    var neighborhood: String
    var listingDescription: String
    var pricePerNight: Int
    var latitude: Double
    var longitude: Double
    var photoURLs: [String]
    var amenities: [String]
    var maxGuests: Int
    var hostID: UUID
    var hostName: String
    var hostPhotoURL: String?
    var isVerified: Bool
    var averageRating: Double?
    var reviewCount: Int
    var cancellationPolicy: String
    var createdAt: Date
    var updatedAt: Date
    /// Category memberships mirrored from `listing_categories`. Default `[]` keeps
    /// pre-migration cached rows decodable when SwiftData opens an older store.
    var categoryIDs: [UUID] = []

    init(
        id: UUID,
        title: String,
        city: String,
        neighborhood: String,
        listingDescription: String,
        pricePerNight: Int,
        latitude: Double,
        longitude: Double,
        photoURLs: [String],
        amenities: [String],
        maxGuests: Int,
        hostID: UUID,
        hostName: String,
        hostPhotoURL: String?,
        isVerified: Bool,
        averageRating: Double?,
        reviewCount: Int,
        cancellationPolicy: String,
        createdAt: Date,
        updatedAt: Date,
        categoryIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.city = city
        self.neighborhood = neighborhood
        self.listingDescription = listingDescription
        self.pricePerNight = pricePerNight
        self.latitude = latitude
        self.longitude = longitude
        self.photoURLs = photoURLs
        self.amenities = amenities
        self.maxGuests = maxGuests
        self.hostID = hostID
        self.hostName = hostName
        self.hostPhotoURL = hostPhotoURL
        self.isVerified = isVerified
        self.averageRating = averageRating
        self.reviewCount = reviewCount
        self.cancellationPolicy = cancellationPolicy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.categoryIDs = categoryIDs
    }
}

/// Codable DTO for decoding Supabase rows. Mirrors the `listings` table column names
/// (snake_case) and maps into the SwiftData `Listing` model.
nonisolated struct ListingDTO: Codable, Sendable, Equatable {
    let id: UUID
    let title: String
    let city: String
    let neighborhood: String
    let description: String
    let pricePerNight: Int
    let latitude: Double
    let longitude: Double
    let photoURLs: [String]
    let amenities: [String]
    let maxGuests: Int
    let hostID: UUID
    let hostName: String
    let hostPhotoURL: String?
    let isVerified: Bool
    let averageRating: Double?
    let reviewCount: Int
    let cancellationPolicy: String
    let createdAt: Date
    let updatedAt: Date
    let categoryIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case city
        case neighborhood
        case description
        case pricePerNight = "price_per_night"
        case latitude
        case longitude
        case photoURLs = "photo_urls"
        case amenities
        case maxGuests = "max_guests"
        case hostID = "host_id"
        case hostName = "host_name"
        case hostPhotoURL = "host_photo_url"
        case isVerified = "is_verified"
        case averageRating = "average_rating"
        case reviewCount = "review_count"
        case cancellationPolicy = "cancellation_policy"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case categoryIDs = "category_ids"
    }

    init(
        id: UUID,
        title: String,
        city: String,
        neighborhood: String,
        description: String,
        pricePerNight: Int,
        latitude: Double,
        longitude: Double,
        photoURLs: [String],
        amenities: [String],
        maxGuests: Int,
        hostID: UUID,
        hostName: String,
        hostPhotoURL: String?,
        isVerified: Bool,
        averageRating: Double?,
        reviewCount: Int,
        cancellationPolicy: String,
        createdAt: Date,
        updatedAt: Date,
        categoryIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.city = city
        self.neighborhood = neighborhood
        self.description = description
        self.pricePerNight = pricePerNight
        self.latitude = latitude
        self.longitude = longitude
        self.photoURLs = photoURLs
        self.amenities = amenities
        self.maxGuests = maxGuests
        self.hostID = hostID
        self.hostName = hostName
        self.hostPhotoURL = hostPhotoURL
        self.isVerified = isVerified
        self.averageRating = averageRating
        self.reviewCount = reviewCount
        self.cancellationPolicy = cancellationPolicy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.categoryIDs = categoryIDs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id                  = try c.decode(UUID.self,    forKey: .id)
        self.title               = try c.decode(String.self,  forKey: .title)
        self.city                = try c.decode(String.self,  forKey: .city)
        self.neighborhood        = try c.decode(String.self,  forKey: .neighborhood)
        self.description         = try c.decode(String.self,  forKey: .description)
        self.pricePerNight       = try c.decode(Int.self,     forKey: .pricePerNight)
        self.latitude            = try c.decode(Double.self,  forKey: .latitude)
        self.longitude           = try c.decode(Double.self,  forKey: .longitude)
        self.photoURLs           = try c.decode([String].self, forKey: .photoURLs)
        self.amenities           = try c.decode([String].self, forKey: .amenities)
        self.maxGuests           = try c.decode(Int.self,     forKey: .maxGuests)
        self.hostID              = try c.decode(UUID.self,    forKey: .hostID)
        self.hostName            = try c.decode(String.self,  forKey: .hostName)
        self.hostPhotoURL        = try c.decodeIfPresent(String.self, forKey: .hostPhotoURL)
        self.isVerified          = try c.decode(Bool.self,    forKey: .isVerified)
        self.averageRating       = try c.decodeIfPresent(Double.self, forKey: .averageRating)
        self.reviewCount         = try c.decode(Int.self,     forKey: .reviewCount)
        self.cancellationPolicy  = try c.decode(String.self,  forKey: .cancellationPolicy)
        self.createdAt           = try c.decode(Date.self,    forKey: .createdAt)
        self.updatedAt           = try c.decode(Date.self,    forKey: .updatedAt)
        // Supabase's plain `listings` table doesn't expose `category_ids`;
        // only the `listings_with_categories` view does. Default to []
        // so decoding works for both.
        self.categoryIDs         = try c.decodeIfPresent([UUID].self, forKey: .categoryIDs) ?? []
    }
}

extension Listing {
    convenience init(dto: ListingDTO) {
        self.init(
            id: dto.id,
            title: dto.title,
            city: dto.city,
            neighborhood: dto.neighborhood,
            listingDescription: dto.description,
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
            categoryIDs: dto.categoryIDs
        )
    }
}

extension ListingDTO {
    init(model: Listing) {
        self.init(
            id: model.id,
            title: model.title,
            city: model.city,
            neighborhood: model.neighborhood,
            description: model.listingDescription,
            pricePerNight: model.pricePerNight,
            latitude: model.latitude,
            longitude: model.longitude,
            photoURLs: model.photoURLs,
            amenities: model.amenities,
            maxGuests: model.maxGuests,
            hostID: model.hostID,
            hostName: model.hostName,
            hostPhotoURL: model.hostPhotoURL,
            isVerified: model.isVerified,
            averageRating: model.averageRating,
            reviewCount: model.reviewCount,
            cancellationPolicy: model.cancellationPolicy,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            categoryIDs: model.categoryIDs
        )
    }
}
