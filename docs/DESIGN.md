# Design System: Marti

Tokens, components, and visual rules. Audits live in `docs/audits/`.

For SwiftUI rules (SF Symbols only, AX5, accessibility labels) see @.claude/rules/swiftui.md. This doc covers the design language.

## Visual identity

Dark-only. Every screen renders on `Color.canvas` (#010913). Card elevation comes from progressively lighter surface colors (`surfaceDefault` → `surfaceElevated` → `surfaceHighlight`), not shadows. Cyan (`coreAccent` #84E9FF) is the single primary accent — CTAs, active chips, active tab icons, the verified-badge glyph, the selected price pin fill. Gold (`statusWarning` #FEEB87) is the rating-star color.

Discovery's list mode leads with an editorial display title over a demoted search capsule and icon buttons; map mode strips chrome to a header pill, a floating card, and the tab bar.

`.preferredColorScheme(.dark)` is set once on `MainTabView`. The app cannot render light mode — every token is a dark value.

## Color tokens

All colors flow through `Extensions/DesignTokens.swift`. **No `Color(red:…)` / `Color("…")` / hex literals in view code.**

| Token              | Hex          | Use for                                                                                            |
| ------------------ | ------------ | -------------------------------------------------------------------------------------------------- |
| `canvas`           | #010913      | Screen background. Also primary-button text color, selected-pin text.                              |
| `surfaceDefault`   | —            | Cards, header pill, price pin idle, hero search capsule.                                           |
| `surfaceElevated`  | —            | Search-pill iconography, chips, 48pt icon buttons, filter rows, date pills, stepper.               |
| `surfaceHighlight` | —            | Skeleton bars, loading-state pins.                                                                 |
| `surfaceGlass`     | white @ 0.06 | Top-edge highlight on glass capsules.                                                              |
| `surfaceStroke`    | white @ 0.08 | 1pt hairline on dark photos at corner radii.                                                       |
| `textPrimary`      | —            | Default foreground.                                                                                |
| `textSecondary`    | —            | Secondary metadata, inactive tab label.                                                            |
| `textTertiary`     | —            | Placeholders, captions, SOS price line, inactive tab icon.                                         |
| `coreAccent`       | #84E9FF      | CTAs, active chip, active tab, verified glyph, selected price pin, range slider, date-picker tint. |
| `statusDanger`     | —            | Saved-heart fill (via `FavoriteHeartButton`), error icon + ring, offline banner.                   |
| `statusWarning`    | #FEEB87      | Rating stars (`star.fill`).                                                                        |
| `dividerLine`      | —            | Filter-sheet dividers, price-pin stroke, map-skeleton stroke.                                      |

`AccentColor.colorset` is intentionally empty — the only `.tint(…)` call passes `Color.coreAccent` explicitly.

## Typography

All type uses `Font.system(…)` — no custom fonts, no asset-catalog fonts. Each token anchors to a semantic `TextStyle` so Dynamic Type scales to AX5 without per-callsite work.

| Token           | Anchor                              | Use for                                                        |
| --------------- | ----------------------------------- | -------------------------------------------------------------- |
| `martiDisplay`  | `.title`, `.rounded`, `.black` | Editorial hero titles ("Feel at home.").                       |
| `martiHeading3` | `.title3`, `.bold`                  | Placeholder/section heroes.                                    |
| `martiHeading4` | `.title3`, `.semibold`              | Section headers, sheet titles, error/empty titles.             |
| `martiHeading5` | `.headline`                         | Card titles, prices, map-fallback title.                       |
| `martiBody`     | `.body`                             | Search-capsule text, key inputs.                               |
| `martiFootnote` | `.footnote`                         | Most secondary copy.                                           |
| `martiCaption`  | `.caption`                          | Captions, fine print, uppercase labels.                        |
| `martiLabel1`   | `.headline`                         | Primary-button label, header pill, stepper center.             |
| `martiLabel2`   | `.subheadline`                      | Chip labels, meta rows, price/date pills, ghost-compact label. |

Inline `Font.system(size:weight:)` is permitted **only for SF Symbol icons** (sizing the glyph itself, not text). For text, always use a token.

## Spacing

| Token           | pt  | Use for                                                              |
| --------------- | --- | -------------------------------------------------------------------- |
| `xs`            | 2   | —                                                                    |
| `sm`            | 4   | Tight gaps inside chips/badges.                                      |
| `md`            | 8   | Default `HStack`/`VStack` gap.                                       |
| `base`          | 16  | Default block separation.                                            |
| `lg`            | 24  | Section separation.                                                  |
| `xl`            | 32  | Hero/section breathing room.                                         |
| `xxl`           | 40  | Top-level vertical rhythm.                                           |
| `screenMargin`  | 16  | Screen-edge horizontal padding (always).                             |
| `cardGap`       | 12  | Gap between cards in a rail.                                         |
| `peekWidth`     | 44  | Peek of next card visible at rail edge.                              |
| `railCardWidth` | 170 | Rail card width — sized so two cards + peek fit on a compact iPhone. |

If a value isn't in the scale, add it to the scale — don't reach for raw literals.

## Radius

| Token  | pt  | Use for                                                      |
| ------ | --- | ------------------------------------------------------------ |
| `xs`   | 4   | Tiny chips, hairlines.                                       |
| `sm`   | 8   | Inputs, small surfaces.                                      |
| `md`   | 12  | Cards, sheets, hero search card, filter chips.               |
| `lg`   | 24  | Hero cards, full-width sheets.                               |
| `xl`   | 40  | Floating containers.                                         |
| `full` | 100 | Capsules — tab bar, header pill, price pins, banners.        |

## Iconography

- **SF Symbols only.** No raster icons (exception: brand assets in `Assets.xcassets`).
- Tab-bar weight switches `.regular` (inactive) → `.semibold` (active) — a proxy for stroke weight since SF Symbols don't ship a 1.5pt option.
- The Discovery search capsule swaps `magnifyingglass` ↔ `slider.horizontal.3` based on whether any filter is active.
- Same glyph for the same concept across screens.

## Components

Reusable views in `Views/Shared/` and `Views/Discovery/Components/`. Reuse before reinventing.

| Component                                                                                                                          | Use for                                                                                           |
| ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `PrimaryButtonStyle` / `.primary` / `.primaryFullWidth`                                                                            | All primary CTAs.                                                                                 |
| `GhostButtonStyle` / `.ghost` / `.ghostCompact`                                                                                    | Secondary text-style actions.                                                                     |
| `FavoriteHeartButton`                                                                                                              | Every save heart. Outlined glyph; saved state = `.semibold` weight + `statusDanger` tint.         |
| `VerifiedBadgeView` (`.icon` / `.label`)                                                                                           | Verified-host indicator. `.icon` on cards (24pt glass disc + cyan checkmark), `.label` on detail. |
| `ListingCardView(variant:)`                                                                                                        | All listing cards. Variants: `.full`, `.rail`, `.compact`, `.mapPreview`.                         |
| `CityChipView`                                                                                                                     | City filter chips.                                                                                |
| `EmptyStateView` / `ErrorStateView` / `OfflineBannerView`                                                                          | Empty / error / offline UI.                                                                       |
| `SkeletonListingCard` / `SkeletonHeader`                                                                                           | Loading states. **Static — no shimmer.**                                                          |
| `FloatingTabView`                                                                                                                  | App tab bar (canvas-masked, custom).                                                              |
| `CategoryRailView`                                                                                                                 | Horizontal rail layout.                                                                           |
| `DiscoveryHeroHeaderView` / `DiscoveryHeaderPill`                                                                                  | Discovery chrome (list mode / map mode).                                                          |
| `MapEmptyStatePill` / `SearchThisAreaPill` / `SelectedListingCard` / `MapListingsCarousel` / `ListingPricePin` / `PricePinCluster` | Map-mode chrome. Owned by Discovery.                                                              |
| `FeeInclusionTag`                                                                                                                  | One-shot onboarding toast.                                                                        |
| `PriceRangeSlider`                                                                                                                 | Range slider with `.accessibilityAdjustableAction`.                                               |

If a recipe gets repeated across files (glass disc, 48pt circle icon button, capsule pill), extract a component or `ViewModifier` instead of redrawing it inline.

## Motion

All animations should respect `@Environment(\.accessibilityReduceMotion)`. Wrap with `reduceMotion ? nil : <curve>`.

Standard curves — use these, don't add new ones:

| Use                    | Curve                                          |
| ---------------------- | ---------------------------------------------- |
| Default UI transitions | `.spring(response: 0.3, dampingFraction: 0.7)` |
| Quick state changes    | `.easeOut(duration: 0.2)`                      |
| Tab bar / chrome hide  | `.easeInOut(duration: 0.25)`                   |

Haptics: `.sensoryFeedback(.impact(weight: .light), trigger: …)` on save, tab change, search-this-area.

## Shadows

Cards do **not** carry shadows — elevation comes from surface color stepping (`surfaceDefault` → `surfaceElevated` → `surfaceHighlight`). Shadows only on floating chrome:

| Use                                             | Recipe                         |
| ----------------------------------------------- | ------------------------------ |
| Glass disc (heart, verified-icon, close button) | `black @ 0.25, radius 4, y 1`  |
| Floating card                                   | `black @ 0.35, radius 16, y 6` |
| Tab bar                                         | `black @ 0.3, radius 8, y 2`   |

## Accessibility

- **`.accessibilityLabel`** on every interactive element without visible text. Heart, X, tab bar, map pins, icon buttons, pills.
- **`.accessibilityHint`** for non-obvious affordances ("Dismisses the listing preview").
- **Decorative icons:** `.accessibilityHidden(true)` so VoiceOver doesn't read SF Symbol names.
- **`.accessibilityElement(children: .combine)`** on grouped chrome (verified badge, listing card overlays).
- **Test layouts at AX5.** Use `@Environment(\.dynamicTypeSize)` to hide non-essentials at large sizes. Use `ViewThatFits` to reflow when single-line layouts break.
- **Reduce Motion:** wrap every animation.

## Localization

- **V1:** English-only. UI strings hardcoded inline today.
- **V1.1:** Full Somali. Migrate to `Localizable.xcstrings` before V1.1 work begins. Discovery is the largest surface (~90+ strings) and should be migrated first.
- **V2:** Arabic. RTL layout review required.
- New strings should ideally use `LocalizedStringKey` even in V1 to ease the migration.

## Hard don'ts

- Don't write `Color(red:…)` / `Color("name")` / `Color(hex:…)` in view code. Use a token.
- Don't write a literal corner radius (`cornerRadius: 8`). Use `Radius.*`.
- Don't write a literal padding outside the `Spacing` scale.
- Don't add a new animation curve. Pick one of the three standard curves.
- Don't add raster icons unless they're brand assets.
- Don't ship a screen without `.accessibilityLabel` on every unlabeled interactive element.
- Don't ship a placeholder string ("Lorem ipsum…"). Ask for real copy.
- Don't reach for `.preferredColorScheme(.light)` — the app is dark only.

## See also

- SwiftUI rules → @.claude/rules/swiftui.md
- Architecture → @docs/ARCHITECTURE.md
- Product requirements → @docs/PRD.md
- Audit history → `docs/audits/`
- Design tokens (source of truth) → `marti/Marti/Extensions/DesignTokens.swift`
