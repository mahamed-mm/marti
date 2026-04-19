import CoreLocation
import Foundation

nonisolated enum City: String, CaseIterable, Codable, Sendable {
    case mogadishu = "Mogadishu"
    case hargeisa = "Hargeisa"

    var centerCoordinate: CLLocationCoordinate2D {
        switch self {
        case .mogadishu: CLLocationCoordinate2D(latitude: 2.0469, longitude: 45.3182)
        case .hargeisa:  CLLocationCoordinate2D(latitude: 9.5600, longitude: 44.0650)
        }
    }

    var defaultZoom: Double { 12.5 }
}
