import SwiftUI

/// Compact empty-state pill shown in map mode when the current filters match
/// no listings. Tapping anywhere on the pill invokes `onAdjust` — the caller
/// wires this to open the filter sheet.
///
/// Composed mutually exclusive with `SelectedListingCard` and `FeeInclusionTag`:
/// the caller anchors exactly one of the three above `FloatingTabView` based
/// on `ListingDiscoveryViewModel` state.
struct MapEmptyStatePill: View {
    let onAdjust: () -> Void

    var body: some View {
        Button(action: onAdjust) {
            HStack(spacing: Spacing.sm) {
                Text("No stays match your filters")
                    .foregroundStyle(Color.textPrimary)
                Text("·")
                    .foregroundStyle(Color.textTertiary)
                Text("Adjust filters")
                    .foregroundStyle(Color.coreAccent)
            }
            .font(.martiFootnote)
            .lineLimit(1)
            .truncationMode(.tail)
            .allowsTightening(true)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, Spacing.base)
            .frame(minHeight: 44)
            .background(Capsule().fill(Color.surfaceElevated))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 520)
        .accessibilityLabel("No stays match your filters. Adjust filters.")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Default") {
    VStack {
        MapEmptyStatePill(onAdjust: {})
        Spacer()
    }
    .padding(Spacing.base)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}

#Preview("Anchored above stub tab bar") {
    VStack {
        Spacer()
        MapEmptyStatePill(onAdjust: {})
        RoundedRectangle(cornerRadius: Radius.full)
            .fill(Color.surfaceDefault)
            .frame(height: 56)
            .padding(.top, Spacing.base)
            .overlay(
                Text("Stub FloatingTabView")
                    .font(.martiCaption)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.top, Spacing.base)
            )
    }
    .padding(Spacing.base)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.canvas)
}
