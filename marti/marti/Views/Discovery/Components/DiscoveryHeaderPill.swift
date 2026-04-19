import SwiftUI

/// Pure display capsule used as the centre island of the Discovery map chrome.
///
/// Renders a 56pt-tall ultra-thin-material capsule with a single-line title
/// (and optional stacked subtitle). The leading list-toggle and trailing
/// filter controls live as separate `FloatingMapIconButton` islands composed
/// alongside this pill in `DiscoveryView.mapLayout`.
///
/// Used in list mode (with subtitle) and map mode (subtitle `nil`, sitting
/// between the two icon islands).
struct DiscoveryHeaderPill: View {
    let title: String
    let subtitle: String?

    var body: some View {
        centerLabel
            .frame(height: 56)
            .padding(.horizontal, Spacing.base)
            .floatingIslandBackground(Capsule())
            .frame(maxWidth: 520)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(combinedA11yLabel))
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var centerLabel: some View {
        if let subtitle, !subtitle.isEmpty {
            VStack(spacing: 2) {
                Text(title)
                    .font(.martiLabel1)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
                Text(subtitle)
                    .font(.martiFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
            }
        } else {
            Text(title)
                .font(.martiLabel1)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.85)
        }
    }

    private var combinedA11yLabel: String {
        if let subtitle, !subtitle.isEmpty { return "\(title). \(subtitle)" }
        return title
    }
}

#Preview("Default · Any dates · 1 guest") {
    VStack {
        DiscoveryHeaderPill(
            title: "Homes across Somalia",
            subtitle: "Any dates · 1 guest"
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
            subtitle: "Dec 17 – Dec 24 · 2 guests"
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
            subtitle: "Dec 17 – Dec 24 · 10 guests"
        )
        Spacer()
    }
    .padding(.horizontal, Spacing.base)
    .padding(.top, Spacing.md)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#Preview("Map mode · live count") {
    VStack {
        DiscoveryHeaderPill(
            title: "42 homes in view",
            subtitle: nil
        )
        Spacer()
    }
    .padding(.horizontal, Spacing.base)
    .padding(.top, Spacing.md)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}
