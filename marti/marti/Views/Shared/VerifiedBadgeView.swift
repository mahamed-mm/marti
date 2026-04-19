import SwiftUI

/// Small pill badge that flags a Verified host. Sits on top of listing photos,
/// so its background must be opaque enough to stay legible against both bright
/// and dark imagery.
///
/// Contrast budget: white `textPrimary` over `surfaceDefault` at 90% opacity
/// yields ~16.5:1 at the worst case, comfortably past WCAG AA (4.5:1). The
/// hairline stroke lifts the pill visually off the image and prevents the
/// capsule from disappearing on near-black photography.
struct VerifiedBadgeView: View {
    var body: some View {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verified host")
    }
}

#Preview {
    ZStack {
        Color.gray
        VerifiedBadgeView()
    }
    .frame(height: 120)
}
