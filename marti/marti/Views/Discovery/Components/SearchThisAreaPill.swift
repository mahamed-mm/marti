import SwiftUI

/// Floating capsule that appears in map mode once the user has panned far
/// enough from the last anchored camera. Tapping invokes `action`, which the
/// caller wires to reset the anchor to the current camera and refresh the
/// visible-listing count.
///
/// Visually matches `FloatingMapIconButton`'s recipe (`.ultraThinMaterial`
/// fill, hairline stroke, soft drop shadow) so both controls read as a
/// coherent set of floating map utilities.
struct SearchThisAreaPill: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                Text("Search this area")
                    .font(.martiLabel2)
            }
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.sm)
            .frame(height: 40)
            .floatingIslandBackground(Capsule(style: .continuous))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search this area")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("On canvas") {
    SearchThisAreaPill(action: {})
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
}

#Preview("On bright map") {
    SearchThisAreaPill(action: {})
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.95, green: 0.92, blue: 0.78))
}
