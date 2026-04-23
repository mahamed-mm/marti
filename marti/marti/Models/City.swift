import CoreLocation
import Foundation

nonisolated enum City: String, CaseIterable, Codable, Sendable {
    case mogadishu = "Mogadishu"
    case hargeisa = "Hargeisa"
    case kismayo = "Kismayo"
    case garowe = "Garowe"
    case berbera = "Berbera"

    var centerCoordinate: CLLocationCoordinate2D {
        switch self {
        case .mogadishu: CLLocationCoordinate2D(latitude: 2.0469, longitude: 45.3182)
        case .hargeisa:  CLLocationCoordinate2D(latitude: 9.5600, longitude: 44.0650)
        case .kismayo:   CLLocationCoordinate2D(latitude: -0.3582, longitude: 42.5453)
        case .garowe:    CLLocationCoordinate2D(latitude: 8.4064, longitude: 48.4814)
        case .berbera:   CLLocationCoordinate2D(latitude: 10.4356, longitude: 45.0143)
        }
    }

    var defaultZoom: Double { 12.5 }
}
