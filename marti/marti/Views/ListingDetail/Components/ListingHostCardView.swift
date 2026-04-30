import SwiftUI

/// Host card for the Listing Detail screen. Avatar (50pt) + name + verified
/// badge label. Host response rate is intentionally not rendered this ship
/// (deferred per CHECKPOINT 1).
struct ListingHostCardView: View {
    let hostName: String
    let hostPhotoURL: String?
    let isVerified: Bool

    private let avatarDiameter: CGFloat = 50

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.base) {
            avatar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Hosted by \(hostName)")
                    .font(.martiHeading5)
                    .foregroundStyle(Color.textPrimary)
                if isVerified {
                    VerifiedBadgeView(variant: .label)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var avatar: some View {
        if let urlString = hostPhotoURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    initialFallback
                }
            }
            .frame(width: avatarDiameter, height: avatarDiameter)
            .clipShape(Circle())
        } else {
            initialFallback
        }
    }

    private var initialFallback: some View {
        ZStack {
            Circle().fill(Color.surfaceElevated)
            Text(initial)
                .font(.martiHeading5)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(width: avatarDiameter, height: avatarDiameter)
    }

    private var initial: String {
        hostName.first.map { String($0).uppercased() } ?? "?"
    }

    private var accessibilityLabel: String {
        isVerified
            ? "Hosted by \(hostName), verified host."
            : "Hosted by \(hostName)."
    }
}
