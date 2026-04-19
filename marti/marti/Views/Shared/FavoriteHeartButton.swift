import SwiftUI

/// Canonical save-heart affordance. Used by every "save this listing" control
/// in the app — rail / full / compact / mapPreview cards in `ListingCardView`
/// and the map-mode bottom card in `SelectedListingCard`.
///
/// Visual recipe is fixed: icon (`heart` / `heart.fill`, 16pt semibold) tinted
/// `statusDanger` when saved and `textPrimary` when unsaved, sitting on a
/// `.ultraThinMaterial` disc with a white hairline stroke and a subtle drop
/// shadow. The shadow carries the component on bright photos where the
/// material background goes nearly transparent — do not remove it.
///
/// The interaction uses `.onTapGesture`, not a `Button`, on purpose. iOS 26
/// suppresses the visual rendering of a `Button` nested inside a
/// `NavigationLink`'s label in some cases — the disc never shows. Using a tap
/// gesture on a plain `Image` keeps the visual intact and lets the heart's
/// tap fire independently of the `NavigationLink`'s tap so saving doesn't
/// push the detail screen.
///
/// Padding around the disc is the caller's concern — this view draws no
/// margin of its own so it drops cleanly into any container.
struct FavoriteHeartButton: View {
    let isSaved: Bool
    var size: Size = .small
    let onToggle: () -> Void

    /// Two call-site sizes. The visible disc diameter differs, but the hit
    /// target is always 44pt to satisfy HIG's minimum touch target.
    enum Size {
        /// 32pt visible disc, 44pt hit target. Floats over card images as a
        /// secondary affordance alongside larger primary content.
        case small
        /// 44pt visible disc, 44pt hit target. Used when the heart sits next
        /// to other 44pt controls (e.g. the close button on
        /// `SelectedListingCard`) so the two read at the same weight.
        case large

        var visibleDiameter: CGFloat {
            switch self {
            case .small: 32
            case .large: 44
            }
        }

        var hitDiameter: CGFloat { 44 }
    }

    var body: some View {
        Image(systemName: isSaved ? "heart.fill" : "heart")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(isSaved ? Color.statusDanger : Color.textPrimary)
            .frame(width: size.visibleDiameter, height: size.visibleDiameter)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
            .frame(width: size.hitDiameter, height: size.hitDiameter)
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }
            .sensoryFeedback(.impact(weight: .light), trigger: isSaved)
            .accessibilityLabel(isSaved ? "Remove from saved" : "Save listing")
            .accessibilityAddTraits(.isButton)
    }
}

#if DEBUG

#Preview("Unsaved · small") {
    FavoriteHeartButton(isSaved: false, size: .small, onToggle: {})
        .padding()
        .background(Color.surfaceHighlight)
}

#Preview("Saved · small") {
    FavoriteHeartButton(isSaved: true, size: .small, onToggle: {})
        .padding()
        .background(Color.surfaceHighlight)
}

#Preview("Saved · large") {
    FavoriteHeartButton(isSaved: true, size: .large, onToggle: {})
        .padding()
        .background(Color.surfaceHighlight)
}

#endif
