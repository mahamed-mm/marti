import SwiftUI

/// Trust indicator for Verified hosts. Two variants:
///
/// - `.icon` (default) — a small cyan-glyph disc for listing cards, so the
///   signal doesn't compete with the photo. The disc reuses the material /
///   stroke / shadow recipe from `FavoriteHeartButton` so the two top-corner
///   overlays on a card read as a matched pair.
/// - `.label` — the full "Verified" text in a translucent capsule, reserved
///   for the Listing Detail screen where the badge sits next to host identity
///   and the extra width buys real information rather than decoration.
struct VerifiedBadgeView: View {
    enum Variant { case icon, label }

    var variant: Variant = .icon

    var body: some View {
        Group {
            switch variant {
            case .icon:  iconBadge
            case .label: labelBadge
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verified host")
    }

    private var iconBadge: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.coreAccent)
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
    }

    private var labelBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.coreAccent)
            Text("Verified")
                .font(.martiLabel2)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 1)
        .background(
            Capsule()
                .fill(Color.surfaceDefault.opacity(0.65))
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.03), lineWidth: 1)
                )
        )
    }
}

#Preview("Icon · dark backdrop") {
    ZStack {
        Color.black
        VerifiedBadgeView()
    }
    .frame(height: 120)
}

#Preview("Icon · light backdrop") {
    ZStack {
        Color.gray
        VerifiedBadgeView()
    }
    .frame(height: 120)
}

#Preview("Label · detail") {
    ZStack {
        Color(white: 0.15)
        VerifiedBadgeView(variant: .label)
    }
    .frame(height: 120)
}
