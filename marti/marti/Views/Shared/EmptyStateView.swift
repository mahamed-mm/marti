import SwiftUI

enum EmptyStateActionStyle {
    case ghost   // text-only ("Clear filters")
    case primary // cyan pill ("Browse Listings")
}

struct EmptyStateView: View {
    let systemImage: String
    var iconTint: Color = .coreAccent
    let title: String
    let subtitle: String
    var actionTitle: String?
    var actionStyle: EmptyStateActionStyle = .primary
    var action: (() -> Void)?

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            cardContent
                .padding(.horizontal, Spacing.base)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
    }

    private var cardContent: some View {
        VStack(spacing: Spacing.base) {
            ZStack {
                Circle()
                    .fill(iconTint.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(iconTint)
            }

            VStack(spacing: Spacing.md) {
                Text(title)
                    .font(.martiHeading5)
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.base)
            }

            if let actionTitle, let action {
                switch actionStyle {
                case .primary:
                    Button(actionTitle, action: action)
                        .buttonStyle(.primary)
                        .padding(.top, Spacing.sm)
                case .ghost:
                    Button(actionTitle, action: action)
                        .buttonStyle(.ghost)
                        .padding(.top, Spacing.sm)
                }
            }
        }
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.base)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.surfaceDefault)
        )
    }
}

#Preview("With CTA") {
    EmptyStateView(
        systemImage: "heart",
        iconTint: .statusDanger,
        title: "No saved listings yet",
        subtitle: "Tap the heart on any listing to save it here for later.",
        actionTitle: "Browse Listings",
        actionStyle: .primary,
        action: {}
    )
}

#Preview("Ghost CTA") {
    EmptyStateView(
        systemImage: "magnifyingglass",
        iconTint: .coreAccent,
        title: "No listings found",
        subtitle: "Try a different city or clear your filters.",
        actionTitle: "Clear filters",
        actionStyle: .ghost,
        action: {}
    )
}
