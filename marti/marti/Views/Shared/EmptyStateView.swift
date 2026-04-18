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
                actionButton(actionTitle: actionTitle, action: action)
                    .padding(.top, Spacing.sm)
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

    @ViewBuilder
    private func actionButton(actionTitle: String, action: @escaping () -> Void) -> some View {
        switch actionStyle {
        case .ghost:
            Button(actionTitle, action: action)
                .font(.martiLabel1)
                .foregroundStyle(Color.coreAccent)
                .frame(minHeight: 44)
        case .primary:
            Button(action: action) {
                Text(actionTitle)
                    .font(.martiLabel1)
                    .foregroundStyle(Color.canvas)
                    .padding(.horizontal, Spacing.xl)
                    .frame(minHeight: 48)
                    .background(Color.coreAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
            .buttonStyle(.plain)
        }
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
