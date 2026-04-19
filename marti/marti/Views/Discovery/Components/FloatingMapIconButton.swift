import SwiftUI

/// Circular icon island used at the leading and trailing edges of
/// `DiscoveryView.mapLayout`'s top chrome. Sized at 44pt for HIG compliance,
/// with a material + stroke + drop-shadow finish that reads as floating above
/// raw Mapbox content (sand, water, satellite imagery, etc.).
struct FloatingMapIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    init(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 44, height: 44)
                .floatingIslandBackground(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("On canvas") {
    FloatingMapIconButton(
        systemImage: "list.bullet",
        accessibilityLabel: "Show list view"
    ) {}
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
}

#Preview("On bright map") {
    FloatingMapIconButton(
        systemImage: "slider.horizontal.3",
        accessibilityLabel: "Filters"
    ) {}
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.95, green: 0.92, blue: 0.78))
}
