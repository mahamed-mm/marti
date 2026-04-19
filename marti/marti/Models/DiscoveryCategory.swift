import Foundation
import SwiftData

@Model
final class DiscoveryCategory {
    @Attribute(.unique) var id: UUID
    var slug: String
    var title: String
    var subtitle: String?
    /// Matches the `listings.city` text column. `nil` = global (shown for all cities).
    var city: String?
    var displayOrder: Int
    var createdAt: Date

    init(
        id: UUID,
        slug: String,
        title: String,
        subtitle: String?,
        city: String?,
        displayOrder: Int,
        createdAt: Date
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.subtitle = subtitle
        self.city = city
        self.displayOrder = displayOrder
        self.createdAt = createdAt
    }
}

/// Codable DTO for decoding Supabase `categories` rows. Mirrors the table column
/// names (snake_case) and maps into the SwiftData `DiscoveryCategory` model.
nonisolated struct DiscoveryCategoryDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let slug: String
    let title: String
    let subtitle: String?
    let city: String?
    let displayOrder: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case title
        case subtitle
        case city
        case displayOrder = "display_order"
        case createdAt    = "created_at"
    }
}

extension DiscoveryCategory {
    convenience init(dto: DiscoveryCategoryDTO) {
        self.init(
            id: dto.id,
            slug: dto.slug,
            title: dto.title,
            subtitle: dto.subtitle,
            city: dto.city,
            displayOrder: dto.displayOrder,
            createdAt: dto.createdAt
        )
    }
}

extension DiscoveryCategoryDTO {
    init(model: DiscoveryCategory) {
        self.init(
            id: model.id,
            slug: model.slug,
            title: model.title,
            subtitle: model.subtitle,
            city: model.city,
            displayOrder: model.displayOrder,
            createdAt: model.createdAt
        )
    }
}
