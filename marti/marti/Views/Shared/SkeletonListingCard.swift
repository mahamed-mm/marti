import SwiftUI

struct SkeletonListingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.surfaceHighlight)
                .frame(height: 200)

            VStack(alignment: .leading, spacing: Spacing.md) {
                bar(width: 220, height: 18) // title
                bar(width: 140, height: 14) // location
                bar(width: 80,  height: 14) // rating
                bar(width: 160, height: 16) // price
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 14)
        }
        .background(Color.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .accessibilityHidden(true)
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Radius.xs)
            .fill(Color.surfaceHighlight)
            .frame(width: width, height: height)
    }
}

/// Skeleton primitives that mirror the real header chrome (search pill + city chips).
struct SkeletonHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            Capsule()
                .fill(Color.surfaceHighlight)
                .frame(height: 48)

            HStack(spacing: Spacing.md) {
                chip(width: 60)
                chip(width: 110)
                chip(width: 90)
            }
        }
        .accessibilityHidden(true)
    }

    private func chip(width: CGFloat) -> some View {
        Capsule()
            .fill(Color.surfaceHighlight)
            .frame(width: width, height: 36)
    }
}

#Preview {
    VStack(spacing: Spacing.base) {
        SkeletonHeader()
        SkeletonListingCard()
        SkeletonListingCard()
    }
    .padding(Spacing.base)
    .background(Color.canvas)
}
