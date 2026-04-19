import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.base) {
            ZStack {
                Circle()
                    .fill(Color.statusDanger.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.statusDanger)
            }

            VStack(spacing: Spacing.md) {
                Text("Something went wrong")
                    .font(.martiHeading4)
                    .foregroundStyle(Color.textPrimary)

                Text(message)
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.lg)
            }

            Button("Try Again", action: retry)
                .buttonStyle(.primary)
                .padding(.top, Spacing.md)
        }
        .padding(.vertical, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Full-width "No connection" banner for the top of the screen (matches 1SX-1).
struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))
            Text("No connection")
                .font(.martiLabel2)
        }
        .foregroundStyle(Color.statusDanger)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.statusDanger.opacity(0.12))
    }
}

#Preview {
    VStack(spacing: 0) {
        OfflineBannerView()
        ErrorStateView(
            message: "We couldn't load listings right now. Check your connection and try again.",
            retry: {}
        )
    }
    .background(Color.canvas)
}
