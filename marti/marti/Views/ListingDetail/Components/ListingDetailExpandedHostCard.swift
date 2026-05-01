import SwiftUI

/// "Meet your host" expanded card (§K of v3 spec). The second host surface on
/// the detail screen — `ListingHostCardView` is the small preview at the top
/// (§D), this is the larger card lower in the stack modeled on IMG_0612.
///
/// Container: `surfaceElevated` fill, `Radius.lg`, `Spacing.lg` padding.
/// Two-column layout:
///
/// - **Leading column (60%)**: 80pt circular avatar, optional verified-icon
///   overlay at the bottom-trailing, host name centered beneath, optional
///   `VerifiedBadgeView(.label)` underneath that.
/// - **Trailing column (40%)**: stacked stat rows, separated by `dividerLine`
///   hairlines. Always shows review count; rating only when `averageRating`
///   is non-nil. Years-hosting is **not** rendered — Marti has no tenure
///   column, and the v2 locked decision says we don't invent it.
///
/// Below the card: a row of factlets, each prefixed by a 16pt SF Symbol.
/// Today the only stable factlet is "Lives in {city}" — the language line
/// ("Speaks English & Somali") is hard-coded for v1 and documented as a
/// placeholder for the future `host_languages` column.
///
/// No "Send message to host" button — Feature 4 territory. Per the v3 spec,
/// a vacancy reads better than a dead button.
struct ListingDetailExpandedHostCard: View {
    let hostName: String
    let hostPhotoURL: String?
    let hostCity: String
    let isVerified: Bool
    let averageRating: Double?
    let reviewCount: Int

    private let avatarDiameter: CGFloat = 80

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            card
            factletRow
            if isVerified {
                verifiedParagraph
            }
        }
    }

    // MARK: - Card

    private var card: some View {
        HStack(alignment: .center, spacing: Spacing.base) {
            leadingColumn
                .frame(maxWidth: .infinity)
            trailingColumn
                .frame(maxWidth: .infinity)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.surfaceElevated)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cardAccessibilityLabel)
    }

    private var leadingColumn: some View {
        VStack(spacing: Spacing.md) {
            avatar
            Text(hostName)
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if isVerified {
                VerifiedBadgeView(variant: .label)
            }
        }
    }

    private var trailingColumn: some View {
        VStack(spacing: Spacing.md) {
            statRow(value: "\(reviewCount)", label: "Reviews")
            if let rating = averageRating {
                Rectangle()
                    .fill(Color.dividerLine)
                    .frame(height: 0.5)
                statRow(value: String(format: "%.2f", rating), label: "Rating", trailingGlyph: "star.fill")
            }
        }
    }

    private func statRow(value: String, label: String, trailingGlyph: String? = nil) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: 2) {
                Text(value)
                    .font(.martiHeading4)
                    .foregroundStyle(Color.textPrimary)
                if let trailingGlyph {
                    Image(systemName: trailingGlyph)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityHidden(true)
                }
            }
            Text(label)
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatar: some View {
        Group {
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
        .overlay(alignment: .bottomTrailing) {
            if isVerified {
                VerifiedBadgeView(variant: .icon)
                    .offset(x: 4, y: 4)
            }
        }
    }

    private var initialFallback: some View {
        ZStack {
            Circle().fill(Color.surfaceDefault)
            Text(initial)
                .font(.martiHeading3)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(width: avatarDiameter, height: avatarDiameter)
    }

    private var initial: String {
        hostName.first.map { String($0).uppercased() } ?? "?"
    }

    // MARK: - Factlets and verified paragraph

    /// "Lives in {city}" + "Speaks English & Somali" — small factlets below
    /// the card. The language line is **hard-coded for v1** because every
    /// Marti host launches with these two languages. When a future listing
    /// surfaces a different language profile, we add a `host_languages:
    /// [String]` column and replace this. Documented as a deliberate
    /// placeholder.
    private var factletRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            factlet(glyph: "globe", text: "Speaks English & Somali")
            factlet(glyph: "house.fill", text: "Lives in \(hostCity)")
        }
    }

    private func factlet(glyph: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: glyph)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 20, alignment: .center)
                .accessibilityHidden(true)
            Text(text)
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var verifiedParagraph: some View {
        Text("Verified hosts have been ID-checked by Marti and have a track record of great stays.")
            .font(.martiBody)
            .foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var cardAccessibilityLabel: String {
        let verifiedSuffix = isVerified ? ", verified host" : ""
        if let rating = averageRating {
            return "\(hostName)\(verifiedSuffix). \(String(format: "%.2f", rating)) rating, \(reviewCount) reviews."
        }
        return "\(hostName)\(verifiedSuffix). \(reviewCount) reviews."
    }
}

#if DEBUG

#Preview("Verified host with rating") {
    ListingDetailExpandedHostCard(
        hostName: "Erik",
        hostPhotoURL: nil,
        hostCity: "Mogadishu",
        isVerified: true,
        averageRating: 4.92,
        reviewCount: 187
    )
    .padding()
    .background(Color.surfaceDefault)
}

#Preview("Unverified host, new") {
    ListingDetailExpandedHostCard(
        hostName: "Amina",
        hostPhotoURL: nil,
        hostCity: "Mogadishu",
        isVerified: false,
        averageRating: nil,
        reviewCount: 0
    )
    .padding()
    .background(Color.surfaceDefault)
}

#endif
