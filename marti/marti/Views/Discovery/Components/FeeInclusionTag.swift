import SwiftUI

/// Dismissible chip floated above the map or the selected-listing card that
/// informs travelers displayed prices include all fees.
///
/// Stateless by design — dismissal lives on
/// `ListingDiscoveryViewModel.feeTagDismissed`, backed by `UserDefaults` so
/// the tag stays gone across app launches (trust messaging is one-time, not a
/// per-session nag). The caller hides this view when that flag is true.
struct FeeInclusionTag: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("Prices include all fees")
                .font(.martiFootnote)
                .foregroundStyle(Color.textPrimary)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.leading, Spacing.base)
        .background(Capsule().fill(Color.surfaceElevated))
    }
}

#Preview("Default") {
    VStack {
        FeeInclusionTag(onDismiss: {})
        Spacer()
    }
    .padding(Spacing.base)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#Preview("In context (above a stub card)") {
    VStack(spacing: Spacing.sm) {
        Spacer()
        FeeInclusionTag(onDismiss: {})
        RoundedRectangle(cornerRadius: Radius.lg)
            .fill(Color.surfaceDefault)
            .frame(height: 140)
            .overlay(
                Text("Stub selected-listing card")
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textTertiary)
            )
    }
    .padding(Spacing.base)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}
