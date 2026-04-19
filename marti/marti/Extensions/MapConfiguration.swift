import CoreLocation

/// Map camera configuration. Central seam for the default starting
/// camera when no city filter is active.
///
/// `defaultUserLocation` is a v1 static stand-in for real CoreLocation —
/// Mogadishu center at a legible city zoom. A future UserLocationService
/// will replace this value without touching callers.
enum MapConfiguration {
    static let defaultUserLocation: (coordinate: CLLocationCoordinate2D, zoom: Double) = (
        CLLocationCoordinate2D(latitude: 2.0469, longitude: 45.3182),
        12.5
    )
}
