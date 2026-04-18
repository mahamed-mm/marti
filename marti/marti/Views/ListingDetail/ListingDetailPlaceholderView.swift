import SwiftUI

/// Temporary placeholder until the Listing Detail feature ships.
struct ListingDetailPlaceholderView: View {
    let listing: Listing

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.base) {
                Text(listing.title)
                    .font(.martiHeading3)
                    .foregroundStyle(Color.textPrimary)
                Text("\(listing.neighborhood), \(listing.city)")
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                Text("Listing detail coming soon")
                    .font(.martiBody)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.top, Spacing.lg)
            }
            .padding(Spacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.canvas)
        .navigationTitle(listing.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
