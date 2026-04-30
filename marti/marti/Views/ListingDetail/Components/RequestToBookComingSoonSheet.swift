import SwiftUI

/// Coming-soon sheet presented when the user taps "Request to Book". Mirrors
/// the construction style of `AuthSheetPlaceholderView` so the two stub
/// surfaces feel like a matched pair until the real Bookings flow ships.
struct RequestToBookComingSoonSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.base) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.coreAccent)
                    .padding(.top, Spacing.xl)

                Text("Booking is coming soon")
                    .font(.martiHeading4)
                    .foregroundStyle(Color.textPrimary)

                Text("Request-to-Book lands with the Bookings feature. Save this listing for now and we'll surface it when bookings open up.")
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

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
