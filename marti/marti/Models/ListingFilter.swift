import Foundation

nonisolated struct ListingFilter: Equatable, Sendable {
    var city: City?
    var checkIn: Date?
    var checkOut: Date?
    var guestCount: Int
    var priceMin: Int?
    var priceMax: Int?

    init(
        city: City? = nil,
        checkIn: Date? = nil,
        checkOut: Date? = nil,
        guestCount: Int = 1,
        priceMin: Int? = nil,
        priceMax: Int? = nil
    ) {
        self.city = city
        self.checkIn = checkIn
        self.checkOut = checkOut
        self.guestCount = guestCount
        self.priceMin = priceMin
        self.priceMax = priceMax
    }

    static let `default` = ListingFilter()
}
