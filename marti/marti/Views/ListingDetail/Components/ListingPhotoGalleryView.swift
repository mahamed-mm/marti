import SwiftUI

/// Paged horizontal photo gallery for the Listing Detail header.
///
/// Each photo fills a 4:3 aspect frame; the page indicator is the small
/// `"\(current) / \(count)"` pill in the bottom-trailing corner — the native
/// page-dot indicator is suppressed via `.tabViewStyle(.page(indexDisplayMode:
/// .never))`. The pill is hidden when `photoURLs.isEmpty` so the placeholder
/// pane reads cleanly.
///
/// The save heart used to live as an overlay on this component; in the v2
/// visual pass it moved up to the floating-trio cluster owned by
/// `ListingDetailView` so all three hero affordances (back, share, favorite)
/// share one elevation layer. As a result this view no longer takes a
/// `isSaved` flag or a `onToggleSave` callback.
///
/// Edge case: empty `photoURLs` collapses to a single `surfaceHighlight` pane
/// with no counter pill. The tab-view branch is skipped entirely so no
/// indicator chrome shows over an empty rail.
struct ListingPhotoGalleryView: View {
    let photoURLs: [String]
    @Binding var currentIndex: Int

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
            if !photoURLs.isEmpty {
                counterPill
                    .padding(Spacing.base)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if photoURLs.isEmpty {
            placeholderPane
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, urlString in
                    page(for: urlString)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Photo \(index + 1) of \(photoURLs.count)")
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
        }
    }

    /// Bottom-trailing photo counter pill ("1 / 18"). Sits on a 50% black
    /// capsule for legibility against any photo. Marked
    /// `accessibilityHidden(true)` because the per-page swipe announcement
    /// already names "Photo N of M" via the page label.
    private var counterPill: some View {
        Text("\(currentIndex + 1) / \(photoURLs.count)")
            .font(.martiLabel2)
            .foregroundStyle(Color.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Capsule().fill(Color.black.opacity(0.5)))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func page(for urlString: String) -> some View {
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Color.surfaceHighlight
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderPane
                @unknown default:
                    Color.surfaceHighlight
                }
            }
            .clipped()
        } else {
            placeholderPane
        }
    }

    private var placeholderPane: some View {
        ZStack {
            Color.surfaceHighlight
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(Color.textTertiary)
        }
    }
}
