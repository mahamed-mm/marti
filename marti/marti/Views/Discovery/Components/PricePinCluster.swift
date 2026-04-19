import SwiftUI

/// Stable, deterministic group of listings whose price pins would collide in
/// screen space at the current camera. Rendered by `PricePinCluster`.
///
/// `id` is a hash of the sorted member listing ids so grouping doesn't jitter
/// across renders while pan/zoom is quiet. `centroid` is the arithmetic mean
/// of member coordinates — good enough for a cluster pin anchor; the cluster
/// does not need geodesic precision.
struct PricePinClusterGroup: Identifiable, Equatable {
    let id: Int
    let memberIDs: [UUID]
    let centroid: (latitude: Double, longitude: Double)
    let minDollars: Int

    /// Determines whether two `PricePinClusterGroup` instances represent the same cluster for rendering purposes.
    /// Compares `id`, `memberIDs`, `centroid.latitude`, `centroid.longitude`, and `minDollars`.
    /// - Returns: `true` if all compared properties are equal, `false` otherwise.
    static func == (lhs: PricePinClusterGroup, rhs: PricePinClusterGroup) -> Bool {
        lhs.id == rhs.id
            && lhs.memberIDs == rhs.memberIDs
            && lhs.centroid.latitude  == rhs.centroid.latitude
            && lhs.centroid.longitude == rhs.centroid.longitude
            && lhs.minDollars == rhs.minDollars
    }
}

/// Map annotation showing multiple colliding listings as a single capsule
/// pill: "N homes from $MIN". Tap zooms the camera in on the cluster's
/// centroid so the individual pins split apart.
///
/// Visual parity with `ListingPricePin`: same capsule, stroke, shadow, and
/// hit target (≥44×44). Typography stays on `martiLabel2` so both pin
/// variants read as the same family. No selected/saved/focused state — a
/// cluster is always "pre-selection"; the user must zoom first.
struct PricePinCluster: View {
    let count: Int
    let minDollars: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "square.stack.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text("\(count) · from $\(minDollars)")
                .font(.martiLabel2)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule().fill(Color.surfaceDefault)
        )
        .overlay(
            Capsule().stroke(Color.dividerLine, lineWidth: 0.5)
        )
        .shadow(token: .pin)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: count)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(Self.accessibilityLabel(count: count, minDollars: minDollars))
    }

    /// Pure function so unit tests can assert the VoiceOver copy without
    /// spinning up a view hierarchy. Parallel to
    /// Produces an accessibility label describing a cluster's item count and starting price.
    /// - Parameters:
    ///   - count: The number of listings in the cluster.
    ///   - minDollars: The minimum displayed price for the cluster.
    /// - Returns: A string for VoiceOver like "Cluster of {count} home(s) starting at ${minDollars}. Double-tap to zoom in."
    nonisolated static func accessibilityLabel(count: Int, minDollars: Int) -> String {
        let noun = count == 1 ? "home" : "homes"
        return "Cluster of \(count) \(noun) starting at $\(minDollars). Double-tap to zoom in."
    }
}
