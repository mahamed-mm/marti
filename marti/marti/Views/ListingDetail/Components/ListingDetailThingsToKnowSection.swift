import SwiftUI

/// "Things to know" section (§L of v3 spec). Three tappable rows, each
/// presenting its own sheet on tap:
///
/// 1. **Cancellation policy** → presents `ListingCancellationPolicyView` in a
///    sheet (re-uses the v2 component as the sheet body — its standalone
///    placement is removed from the detail screen).
/// 2. **House rules** → presents a `ComingSoonSheetView` (full house rules
///    ship with host onboarding).
/// 3. **Safety & property** → presents a `ComingSoonSheetView` (detailed
///    safety info ships with the Trust & Safety surface).
///
/// Owns its own `enum DetailSheet { case cancellation, houseRules, safety }`
/// + `@State` and `.sheet(item:)` routing. The enum stays on this view, not
/// the ViewModel — pure UI navigation state with no business meaning,
/// consistent with how `isFeeTagDismissed` is handled.
struct ListingDetailThingsToKnowSection: View {
    let cancellationPolicy: String
    let maxGuests: Int

    /// Sheet identifier. Each case presents a different sheet body. `Identifiable`
    /// conformance is what enables `.sheet(item:)` to drive presentation.
    enum DetailSheet: String, Identifiable {
        case cancellation
        case houseRules
        case safety

        var id: String { rawValue }
    }

    @State private var presentedSheet: DetailSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Things to know")
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: Spacing.lg) {
                row(
                    glyph: "calendar.badge.exclamationmark",
                    title: "Cancellation policy",
                    subtitle: cancellationSubtitle,
                    sheet: .cancellation,
                    accessibilityHint: "Tap to view full policy."
                )
                row(
                    glyph: "key.fill",
                    title: "House rules",
                    subtitle: houseRulesSubtitle,
                    sheet: .houseRules,
                    accessibilityHint: "Tap to view full house rules."
                )
                row(
                    glyph: "shield.lefthalf.filled",
                    title: "Safety & property",
                    subtitle: "Host has agreed to Marti's safety standards.",
                    sheet: .safety,
                    accessibilityHint: "Tap to view safety information."
                )
            }
            .padding(.top, Spacing.xs)
        }
        // Section-level haptic — fires once per `presentedSheet` change.
        // Loop 1 attached `.sensoryFeedback` per row, which made all three
        // rows watch the same trigger and emit a triple-buzz on every tap.
        // Lifting the modifier to the outer VStack collapses that to one
        // haptic per state change.
        .sensoryFeedback(.selection, trigger: presentedSheet?.id ?? "")
        .sheet(item: $presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    // MARK: - Row

    private func row(
        glyph: String,
        title: String,
        subtitle: String,
        sheet: DetailSheet,
        accessibilityHint: String
    ) -> some View {
        Button {
            presentedSheet = sheet
        } label: {
            HStack(alignment: .top, spacing: Spacing.base) {
                Image(systemName: glyph)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 24, alignment: .center)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.martiLabel1)
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitle)
                        .font(.martiFootnote)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: Spacing.md)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Sheet content

    @ViewBuilder
    private func sheetContent(for sheet: DetailSheet) -> some View {
        switch sheet {
        case .cancellation:
            cancellationSheet
        case .houseRules:
            ComingSoonSheetView(
                title: "House rules",
                message: "Full house rules ship with host onboarding.",
                systemImage: "key.fill"
            )
        case .safety:
            ComingSoonSheetView(
                title: "Safety & property",
                message: "Detailed safety info ships with the Trust & Safety surface.",
                systemImage: "shield.lefthalf.filled"
            )
        }
    }

    private var cancellationSheet: some View {
        NavigationStack {
            ScrollView {
                ListingCancellationPolicyView(policy: cancellationPolicy)
                    .padding(.horizontal, Spacing.screenMargin)
                    .padding(.vertical, Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.surfaceDefault)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.surfaceDefault)
    }

    // MARK: - Derived copy

    /// Subtitle for the cancellation row. Mirrors the human copy
    /// `ListingCancellationPolicyView` already uses for the three known
    /// policies; falls back to the raw value for unknown strings so we never
    /// invent a refund window.
    private var cancellationSubtitle: String {
        switch cancellationPolicy.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "flexible":
            return "Free cancellation up to 24 hours before check-in."
        case "moderate":
            return "Free cancellation up to 5 days before check-in."
        case "strict":
            return "Free cancellation up to 14 days before check-in."
        default:
            return cancellationPolicy
        }
    }

    /// Singular "1 guest" vs plural "N guests". Tiny copy touch keeps the row
    /// from reading "Max 1 guests".
    private var houseRulesSubtitle: String {
        let guestPhrase = maxGuests == 1 ? "1 guest" : "\(maxGuests) guests"
        return "Check-in after 2pm. Check-out before noon. Max \(guestPhrase)."
    }
}

/// Tiny dismiss-button helper to keep the cancellation sheet's toolbar tidy.
private struct DismissButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button("Close") { dismiss() }
            .foregroundStyle(Color.textSecondary)
    }
}

#if DEBUG

#Preview("Strict policy, 4 guests") {
    ListingDetailThingsToKnowSection(cancellationPolicy: "strict", maxGuests: 4)
        .padding()
        .background(Color.surfaceDefault)
}

#Preview("Flexible policy, 1 guest") {
    ListingDetailThingsToKnowSection(cancellationPolicy: "flexible", maxGuests: 1)
        .padding()
        .background(Color.surfaceDefault)
}

#endif
