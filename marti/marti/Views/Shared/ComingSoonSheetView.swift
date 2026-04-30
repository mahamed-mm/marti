import SwiftUI

/// Generic "this feature ships later" sheet. Mirrors the construction of
/// `RequestToBookComingSoonSheet` and `AuthSheetPlaceholderView` so the three
/// stub surfaces feel like a matched set, but takes title + body copy via
/// init so callers can re-use it across multiple deferred features.
///
/// Today's call sites:
/// - Listing Detail v3 §L "House rules" row → "Full house rules ship with host onboarding."
/// - Listing Detail v3 §L "Safety & property" row → "Detailed safety info ships with the Trust & Safety surface."
///
/// Closes the 2026-04-28 carry-over follow-up `n3` ("ComingSoon sheet
/// duplication") in `current.md`. The two existing dedicated sheets
/// (`RequestToBookComingSoonSheet`, `AuthSheetPlaceholderView`) stay as-is —
/// they each carry feature-specific copy and (for Auth) a side effect on
/// `AuthManager`. `ComingSoonSheetView` is the generic destination for new
/// "ships with feature X" rows that have nothing to do but tell the user.
struct ComingSoonSheetView: View {
    let title: String
    let message: String
    /// SF Symbol name for the hero glyph. Defaults to a clock+badge to read as
    /// "scheduled for later" rather than "error".
    var systemImage: String = "clock.badge"

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.base) {
                Image(systemName: systemImage)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.coreAccent)
                    .padding(.top, Spacing.xl)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.martiHeading4)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("Got it") { dismiss() }
                    .buttonStyle(.primaryFullWidth)
                    .padding(.horizontal, Spacing.base)
                    .padding(.bottom, Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.surfaceDefault)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.surfaceDefault)
    }
}

#if DEBUG

#Preview("House rules") {
    ComingSoonSheetView(
        title: "House rules",
        message: "Full house rules ship with host onboarding.",
        systemImage: "key.fill"
    )
}

#Preview("Safety & property") {
    ComingSoonSheetView(
        title: "Safety & property",
        message: "Detailed safety info ships with the Trust & Safety surface.",
        systemImage: "shield.lefthalf.filled"
    )
}

#endif
