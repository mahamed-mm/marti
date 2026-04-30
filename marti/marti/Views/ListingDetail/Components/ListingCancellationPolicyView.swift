import SwiftUI

/// Cancellation policy section. Renders the policy name (capitalized) plus
/// a friendly one-line subtitle for the three known PRD policies. Unknown
/// strings render the raw value with no subtitle so we never lie about a
/// refund window we can't speak to.
struct ListingCancellationPolicyView: View {
    let policy: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Cancellation policy")
                .font(.martiHeading4)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(displayName)
                    .font(.martiLabel1)
                    .foregroundStyle(Color.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.martiFootnote)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var key: String {
        policy.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var displayName: String {
        switch key {
        case "flexible":  return "Flexible"
        case "moderate":  return "Moderate"
        case "strict":    return "Strict"
        default:          return policy
        }
    }

    private var subtitle: String? {
        switch key {
        case "flexible":
            return "Free cancellation up to 24 hours before check-in."
        case "moderate":
            return "Free cancellation up to 5 days before check-in."
        case "strict":
            return "Free cancellation up to 14 days before check-in."
        default:
            return nil
        }
    }
}
