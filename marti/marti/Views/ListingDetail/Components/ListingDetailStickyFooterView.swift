import SwiftUI

/// Sticky bottom CTA bar for Listing Detail. v3 visual pass: two stacked rows.
///
/// Top row (only when `cancellationPolicy != "strict"`):
/// `checkmark` + "Free cancellation". Flat icon+text — no background; reads
/// cleaner against the existing `.thinMaterial`.
///
/// Bottom row: USD primary in `.martiHeading3` (bumped from `.martiLabel1` to
/// match the reference visual weight). Secondary line is dropped when SOS
/// is unavailable per v3 §M ("only render sub-line when SOS rate present"),
/// rather than rendering a bare "Monthly" label that adds no information.
/// Trailing pill-shaped Reserve CTA on `Color.statusDanger`. The Reserve pill
/// is intentionally *not* `PrimaryButtonStyle` — this red CTA is
/// detail-screen-specific and we don't want to mutate the global primary
/// style for a one-off color. If a second red CTA shows up later, extract
/// a `DangerCapsuleButtonStyle`.
///
/// Money formatting: USD comes from `pricePerNightUSDCents` as a plain `$NN`
/// string (cents are stored as `Int USD cents` per project gotcha). SOS is
/// the full-form string from the VM (`LiveCurrencyService` under the hood)
/// and is hidden when the rate is unavailable rather than rendering an empty
/// slot.
struct ListingDetailStickyFooterView: View {
    let pricePerNightUSDCents: Int
    let fullSOSPriceLine: String?
    let cancellationPolicy: String
    let onRequestToBook: () -> Void

    /// Drives the light-impact haptic on Reserve taps. Equatable `Bool` flips
    /// on every tap so `.sensoryFeedback` actually fires.
    @State private var hapticTrigger = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if showFreeCancellation {
                freeCancellationRow
            }
            footerRow
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.dividerLine)
                .frame(height: 0.5)
        }
    }

    // MARK: - Subviews

    private var freeCancellationRow: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .accessibilityHidden(true)
            Text("Free cancellation")
                .font(.martiFootnote)
        }
        .foregroundStyle(Color.textSecondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Free cancellation")
    }

    private var footerRow: some View {
        HStack(alignment: .center, spacing: Spacing.base) {
            VStack(alignment: .leading, spacing: 2) {
                Text(usdString)
                    .font(.martiHeading3)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityLabel("\(usdString) per month")
                if let secondary = secondaryLine {
                    Text(secondary)
                        .font(.martiFootnote)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Spacing.md)

            reserveButton
        }
    }

    private var reserveButton: some View {
        Button("Reserve") {
            hapticTrigger.toggle()
            onRequestToBook()
        }
        .font(.martiLabel1)
        .foregroundStyle(Color.canvas)
        .frame(minHeight: 48)
        .padding(.horizontal, Spacing.lg)
        .background(Color.statusDanger)
        .clipShape(Capsule())
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .accessibilityLabel("Reserve this listing")
    }

    // MARK: - Derived

    /// Hide the row when the policy is the strict variant — the spec keys off
    /// the literal `"strict"` string per the locked decision (the model
    /// stores raw policy strings and we don't have an enum yet).
    private var showFreeCancellation: Bool {
        cancellationPolicy
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() != "strict"
    }

    /// USD price string from cents. `8500` → `$85`. No fractional cents on
    /// the bar — the detail surface follows the card convention.
    private var usdString: String {
        let dollars = Double(pricePerNightUSDCents) / 100.0
        if dollars.rounded() == dollars {
            return "$\(Int(dollars))"
        }
        return String(format: "$%.2f", dollars)
    }

    /// Secondary line under the price. v3 §M: only render when SOS is
    /// available — otherwise drop the line entirely rather than showing a
    /// bare "Monthly" label that adds nothing.
    private var secondaryLine: String? {
        guard let sos = fullSOSPriceLine else { return nil }
        return "Monthly · \(sos)"
    }
}
