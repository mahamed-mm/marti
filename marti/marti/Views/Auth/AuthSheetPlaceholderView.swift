import SwiftUI

/// Placeholder until the Auth feature ships. Toggles `AuthManager.isAuthenticated`
/// so save / save-revert flows can be exercised in v1.
struct AuthSheetPlaceholderView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.base) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.coreAccent)
                    .padding(.top, Spacing.xl)

                Text("Sign in to save")
                    .font(.martiHeading4)
                    .foregroundStyle(Color.textPrimary)

                Text("Real sign-in lands with the Auth feature. Tap below to simulate it.")
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                Spacer()

                Button("Continue") {
                    auth.isAuthenticated = true
                    dismiss()
                }
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
