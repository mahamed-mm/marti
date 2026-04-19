import SwiftUI

/// Centered two-line context pill flanked by circular back and tune (filter) buttons.
///
/// Used in map mode of the Discovery screen to surface the current city + filter
/// summary (e.g. "Homes in Mogadishu" / "Dec 17 – Dec 24 · 2 guests") without
/// requiring the user to reopen the filter sheet. Title and subtitle are
/// presentation-only in v1; future versions may make them tappable for inline
/// city/date editing.
struct DiscoveryHeaderPill: View {
    let title: String
    let subtitle: String
    var backLabel: String = "Close map view"
    var tuneLabel: String = "Filters"
    let onBack: () -> Void
    let onTune: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            circularIconButton(systemImage: "chevron.left", label: backLabel, action: onBack)
            pill
            circularIconButton(systemImage: "slider.horizontal.3", label: tuneLabel, action: onTune)
        }
        .frame(maxWidth: 520)
    }

    private var pill: some View {
        VStack(spacing: Spacing.sm) {
            Text(title)
                .font(.martiLabel1)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .allowsTightening(true)
                .minimumScaleFactor(0.9)
            Text(subtitle)
                .font(.martiFootnote)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .allowsTightening(true)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(Capsule().fill(Color.surfaceElevated))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title). \(subtitle)"))
        .accessibilityAddTraits(.isHeader)
    }

    private func circularIconButton(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.surfaceElevated))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview("Default · Any dates · 1 guest") {
    VStack {
        DiscoveryHeaderPill(
            title: "Homes across Somalia",
            subtitle: "Any dates · 1 guest",
            onBack: {},
            onTune: {}
        )
        Spacer()
    }
    .padding(.horizontal, Spacing.base)
    .padding(.top, Spacing.md)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#Preview("Filtered · date range") {
    VStack {
        DiscoveryHeaderPill(
            title: "Homes in Mogadishu",
            subtitle: "Dec 17 – Dec 24 · 2 guests",
            onBack: {},
            onTune: {}
        )
        Spacer()
    }
    .padding(.horizontal, Spacing.base)
    .padding(.top, Spacing.md)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#Preview("Long truncating title") {
    VStack {
        DiscoveryHeaderPill(
            title: "Homes in a ridiculously long place name that will not fit",
            subtitle: "Dec 17 – Dec 24 · 10 guests",
            onBack: {},
            onTune: {}
        )
        Spacer()
    }
    .padding(.horizontal, Spacing.base)
    .padding(.top, Spacing.md)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}
