import SwiftUI

// MARK: - Colors (dark mode only — see DESIGN.md §Color System)

extension Color {
    static let canvas             = Color(red: 0x01/255, green: 0x09/255, blue: 0x13/255)
    static let surfaceDefault     = Color(red: 0x13/255, green: 0x1D/255, blue: 0x2B/255)
    static let surfaceElevated    = Color(red: 0x1F/255, green: 0x2D/255, blue: 0x42/255)
    static let surfaceHighlight   = Color(red: 0x1A/255, green: 0x2A/255, blue: 0x3D/255)

    /// 1pt top-edge highlight used on the hero search capsule and on `full`
    /// listing cards — gives a single glassy sheen so elevated surfaces read as
    /// physical planes in dark mode rather than flat rectangles.
    static let surfaceGlass       = Color.white.opacity(0.06)

    /// 1pt hairline used at the corner boundary between a photo and canvas
    /// (rail-card image overlay). Prevents dark images from merging into the
    /// canvas at the corner radius.
    static let surfaceStroke      = Color.white.opacity(0.08)

    static let textPrimary        = Color.white
    static let textSecondary      = Color(red: 0xBD/255, green: 0xC4/255, blue: 0xCB/255)
    static let textTertiary       = Color(red: 0x95/255, green: 0xA0/255, blue: 0xAE/255)

    static let coreAccent         = Color(red: 0x84/255, green: 0xE9/255, blue: 0xFF/255)
    static let corePrimary        = Color(red: 0x05/255, green: 0x41/255, blue: 0x84/255)

    static let statusSuccess      = Color(red: 0x62/255, green: 0xF1/255, blue: 0xC6/255)
    static let statusDanger       = Color(red: 0xFF/255, green: 0x64/255, blue: 0x9C/255)
    static let statusWarning      = Color(red: 0xFE/255, green: 0xEB/255, blue: 0x87/255)

    static let dividerLine        = Color.white.opacity(0.08)

    static let starEmpty          = Color(red: 0x44/255, green: 0x50/255, blue: 0x5F/255)
}

// MARK: - Spacing

enum Spacing {
    static let xs:   CGFloat = 2
    static let sm:   CGFloat = 4
    static let md:   CGFloat = 8
    static let base: CGFloat = 16
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let xxl:  CGFloat = 40

    /// Horizontal inset between a screen edge and primary column content
    /// (search pill, chips, section headers, rail content). Single source
    /// of truth — prefer over raw `Spacing.base` when the intent is
    /// "screen edge", so a future tweak only touches one line.
    static let screenMargin: CGFloat = base

    /// Horizontal gap between cards inside a horizontal rail (Discovery,
    /// similar-listings, saved). Intentionally tighter than `Spacing.base`
    /// so a peek of the next card is visible without swapping in a wider
    /// screen margin.
    static let cardGap: CGFloat = 12

    /// Visible width of the trailing peek card in a horizontal rail. Sized
    /// so the peek clearly telegraphs "more here" without looking like a
    /// clipped full card (40–48pt is the range across travel/commerce apps).
    static let peekWidth: CGFloat = 44

    /// Fixed card width used by horizontal rails across the app (Discovery
    /// category rails, similar-listings, saved). Tuned so that on a compact
    /// iPhone (≈402pt wide) the rail shows two full cards + a visible peek
    /// of a third after leading/trailing `screenMargin` and one `cardGap`:
    ///   402 − (2·16) − 12 − (2·170) = 18pt peek.
    /// 170pt gives the rail card enough room for a square image plus title
    /// plus meta row without the text feeling cramped; using a constant keeps
    /// card width identical across every rail in the app rather than drifting
    /// with screen size.
    static let railCardWidth: CGFloat = 170

    /// Inset inside a listing card's content box (horizontal, top, bottom).
    /// Intentionally tighter than `base` (16) so the content reads snugly fit
    /// inside the card rather than sitting at screen-edge distance from the
    /// photo above it. Shared by `ListingCardView` (.full variant) and
    /// `SkeletonListingCard` so the skeleton stays pixel-accurate with the
    /// real card.
    static let cardPadding: CGFloat = 14
}

// MARK: - Corner radius

enum Radius {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 40
    static let full: CGFloat = 100
}

// MARK: - Typography helpers

// Sizes anchor to the nearest semantic TextStyle so Dynamic Type (up to AX5)
// scales these tokens. Designed sizes stay close to the DESIGN.md scale at the
// default Dynamic Type setting (small offsets: 24→22, 16→17, 14→13, 12→12).
extension Font {
    /// Editorial display face used for the Discovery hero title and any
    /// destination-led screen. Rounded + black gives a tactile identity read
    /// without adding a custom font file. Anchors to `.largeTitle` so Dynamic
    /// Type scales up to AX5.
    static let martiDisplay    = Font.system(.largeTitle, design: .rounded, weight: .black)

    /// Section headers (e.g. rail titles) — rounded design with bold weight so
    /// they read as titles, not labels. Body/meta stays on default SF.
    static let martiHeading3   = Font.system(.title2,    design: .rounded, weight: .bold)
    static let martiHeading4   = Font.system(.title3,    design: .rounded, weight: .bold)

    static let martiHeading5   = Font.system(.headline,  weight: .bold)
    static let martiBody       = Font.system(.body,      weight: .regular)
    static let martiFootnote   = Font.system(.footnote,  weight: .regular)
    static let martiCaption    = Font.system(.caption,   weight: .regular)
    static let martiLabel1     = Font.system(.body,      weight: .bold)
    static let martiLabel2     = Font.system(.footnote,  weight: .bold)
}

// MARK: - Shadows

/// Canonical elevation tokens. Five recipes cover every floating chrome in the
/// app — small glass overlays, price pins, floating material islands, the tab
/// bar, and the elevated listing card. Callers apply via `.shadow(_ token:)`.
///
/// Dark backgrounds blunt most shadows — these values land close to the spec
/// in `docs/DESIGN.md §Shadows` and are intentionally few: drift starts with
/// one-off `(color:radius:y:)` calls.
enum Shadow {
    case glassDisc      // heart + verified-icon-disc overlays on card photos
    case pin            // price pins and clusters on the map
    case island         // floating material islands (header pill, icon button, search-this-area pill, carousel card, hero card)
    case tabBar         // FloatingTabView capsule
    case floatingCard   // elevated SelectedListingCard, MapToggleFAB

    fileprivate var opacity: Double {
        switch self {
        case .glassDisc:    0.25
        case .pin:          0.25
        case .island:       0.18
        case .tabBar:       0.30
        case .floatingCard: 0.35
        }
    }
    fileprivate var radius: CGFloat {
        switch self {
        case .glassDisc:    4
        case .pin:          4
        case .island:       8
        case .tabBar:       8
        case .floatingCard: 16
        }
    }
    fileprivate var yOffset: CGFloat {
        switch self {
        case .glassDisc:    1
        case .pin:          2
        case .island:       2
        case .tabBar:       2
        case .floatingCard: 6
        }
    }
}

extension View {
    /// Applies a canonical `Shadow` token. Labeled as `token:` to avoid
    /// colliding with SwiftUI's own `.shadow(_ style:radius:…)` overload.
    /// Use in place of inline `.shadow(color:radius:x:y:)` calls so
    /// Applies a canonical, tokenized shadow to the view.
    /// - Parameters:
    ///   - token: The `Shadow` token that selects a predefined shadow style (opacity, radius, and vertical offset).
    /// - Returns: The view with the shadow specified by the token applied.
    func shadow(token: Shadow) -> some View {
        shadow(color: Color.black.opacity(token.opacity), radius: token.radius, x: 0, y: token.yOffset)
    }
}

// MARK: - Chrome recipes

extension View {
    /// Circular `.ultraThinMaterial` disc with a white hairline and the
    /// `.glassDisc` shadow. Used for small floating overlays on card photos —
    /// save heart, verified badge, close-button pair on the selected-listing
    /// card. Caller places a glyph (e.g. `Image(systemName:)`) inside and
    /// supplies the visible disc diameter; outer hit-target framing stays at
    /// Renders the view as a circular glassy disc of the specified diameter.
    /// - Parameters:
    ///   - diameter: The diameter of the circular disc in points.
    /// - Returns: A view sized to `diameter`, presented as a circular, material-filled disc with a subtle white outline and the `glassDisc` shadow applied.
    func glassDisc(diameter: CGFloat) -> some View {
        self
            .frame(width: diameter, height: diameter)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
            .shadow(token: .glassDisc)
    }

    /// `.ultraThinMaterial` fill with a soft `dividerLine` hairline and the
    /// `.island` shadow, clipped to the provided shape. Used by floating map
    /// chrome — header pill, circular icon button, "Search this area" pill,
    /// Applies a material-filled background, a faint hairline stroke, and the "island" shadow using the provided shape.
    /// - Parameters:
    ///   - shape: An insettable shape used to draw the background fill and hairline stroke.
    /// - Returns: A view with the provided shape filled with ultra-thin material, overlaid with a subtle divider stroke, and rendered with the island shadow.
    func floatingIslandBackground<S: InsettableShape>(_ shape: S) -> some View {
        self
            .background(shape.fill(.ultraThinMaterial))
            .overlay(shape.stroke(Color.dividerLine.opacity(0.25), lineWidth: 0.5))
            .shadow(token: .island)
    }
}
