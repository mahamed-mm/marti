import SwiftUI

/// Floating "Map" toggle that lives at the bottom of Discovery list mode.
/// Inverts the `.ultraThinMaterial` style of `FloatingMapIconButton` — solid
/// high-contrast fill so the FAB reads as a primary action above scrolling
/// listing photos, not chrome.
struct MapToggleFAB: View {
    let action: () -> Void

    @State private var tapCounter: Int = 0

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button {
            tapCounter &+= 1
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "map.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.canvas)
                Text("Map")
                    .font(.martiLabel2)
                    .foregroundStyle(Color.canvas)
            }
            .padding(.horizontal, Spacing.base + Spacing.sm)
            .padding(.vertical, Spacing.sm + 2)
            .background(Capsule().fill(Color.textPrimary))
            .shadow(token: .floatingCard)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCounter)
        .accessibilityLabel("Switch to map view")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("On canvas") {
    MapToggleFAB(action: {})
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
}

#Preview("On bright photo") {
    MapToggleFAB(action: {})
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.95, green: 0.88, blue: 0.72))
}
