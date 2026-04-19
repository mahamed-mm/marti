# Design System: Marti — Observed

## Snapshot

- **Audit run:** 2026-04-19 (refresh, late — after the discovery-header + outlined-heart + icon-verified-badge commits landed)
- **Head commit:** `ae05b0e feat: added discovery header component` (5 commits beyond the prior audit)
- **Views surveyed:** 24 Swift files under `marti/marti/Views/` + `Extensions/DesignTokens.swift` + `marti/marti/Views/Shared/Buttons.swift` (`ButtonStyle` definitions)
- **Only shipped screen:** Discovery (list + map + filters). Auth, Listing Detail, Saved, Bookings, Messages, Profile are all placeholder `ComingSoonView` / placeholder sheets (`MainTabView.swift:67–86`, `ListingDetailPlaceholderView.swift`, `AuthSheetPlaceholderView.swift`).
- **Source of truth for intent:** `docs/DESIGN.previous.md` (the original spec) is left untouched — the prior audit flagged it as intent-doc-preserved, and this audit does the same rather than duplicating the preservation.

## Visual identity

Dark-only. Every surveyed screen renders on `Color.canvas` (#010913) with card elevation carried by progressively lighter surface colors (`surfaceDefault` → `surfaceElevated` → `surfaceHighlight`) rather than shadows. Cyan (`coreAccent` #84E9FF) is the single primary accent, used for CTAs, active chips, active tab icons, the verified-badge glyph, and the selected price pin fill. Gold/yellow (`statusWarning` #FEEB87) is the rating-star color across every card. Chrome is reduced to pill headers, a floating tab capsule, and a single cyan CTA. The shipped flow (Discovery) now leads list mode with an editorial display title ("Feel at home.") over a demoted search capsule and map/filter icon buttons — a visual hierarchy change landed in `ae05b0e`. Map mode still strips everything but a header pill, a floating card, and the tab bar. `.preferredColorScheme(.dark)` is set once on `MainTabView` (`MainTabView.swift:63`); nothing else checks `colorScheme`, and every token in `DesignTokens.swift` points at a dark value, so the app cannot render a light mode even if `preferredColorScheme` were dropped.

## Color system

All colors flow through `Extensions/DesignTokens.swift:5–35`. That file is the sole source of hex values — grep confirms **zero `Color(red:…)` / `Color("…")` / `Color(hex:…)` / `Color(UIColor:…)` literals anywhere under `Views/`**. Unchanged from the previous audit.

Two new tokens landed since the previous audit:

- `surfaceGlass = Color.white.opacity(0.06)` — 1pt top-edge highlight on the hero search capsule (`DiscoveryHeroHeaderView.swift:75`) and, by intent, on `full` listing cards.
- `surfaceStroke = Color.white.opacity(0.08)` — 1pt hairline keeping dark photos from bleeding into canvas at the corner radius of a rail-card image. Used at `ListingCardView.swift:110`.

Tokens actually used across views:

| Token              | Used in                                                                            | Notes                                                                                              |
| ------------------ | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `canvas`           | 6+ call sites (screen bg, `PrimaryButtonStyle` text color, selected price pin text) | matches intent                                                                                     |
| `surfaceDefault`   | 9+ call sites (cards, header pill bg, price pin idle, hero search capsule)         | matches intent                                                                                     |
| `surfaceElevated`  | 8+ call sites (search pill iconography, chips, 48pt icon buttons, filter rows, date/stepper) | matches intent                                                                             |
| `surfaceHighlight` | 3 call sites (`SkeletonListingCard` bars, `SkeletonHeader`, map-skeleton pins)     | matches intent                                                                                     |
| `surfaceGlass`     | 1 call site (hero-capsule stroke) — new token                                      | defined for "hero search capsule + full listing cards"; only the first is wired today              |
| `surfaceStroke`    | 1 call site (rail-card photo hairline) — new token                                 | dedicated to the rail photo's corner stroke                                                        |
| `textPrimary`      | ~45 call sites                                                                     | most-used foreground                                                                               |
| `textSecondary`    | ~18 call sites                                                                     | secondary metadata, inactive tab label                                                             |
| `textTertiary`     | ~25 call sites                                                                     | placeholders, captions, SOS price, inactive tab icon                                               |
| `coreAccent`       | ~18 call sites                                                                     | CTAs (`PrimaryButtonStyle`, `GhostButtonStyle`), active chip, active tab, verified glyph, selected price pin, range slider, date-picker `.tint` |
| `corePrimary`      | 0 call sites under `Views/`                                                        | **unused token** (unchanged since last audit)                                                      |
| `statusSuccess`    | 0 call sites under `Views/`                                                        | **unused token** — design intended it for Verified badge; shipping code uses `coreAccent` instead  |
| `statusDanger`     | 4 call sites (error icon + ring, offline banner bg/fg, saved-heart fill)           | `FavoriteHeartButton.swift:51` is the single source of truth — full / rail / compact / mapPreview cards and `SelectedListingCard` all tint through the component |
| `statusWarning`    | 2 call sites (star.fill on card + map-preview / selected-card rating row)          | rating stars — commit `a3af1e5` locked this in ("Gold stars not cyan")                             |
| `dividerLine`      | 3 call sites (filter-sheet dividers, price-pin stroke, map-skeleton stroke)        | in real use (already was in previous audit)                                                        |
| `starEmpty`        | 0 call sites                                                                       | still unused; rating row still never renders an empty-star outline                                 |

Ad-hoc alpha compositions (present in code, not tokenized):

- `Color.white.opacity(0.12)` stroke on heart disc — `FavoriteHeartButton.swift:57`
- `Color.white.opacity(0.12)` stroke on verified-icon disc — `VerifiedBadgeView.swift:37` *(the icon badge now reuses the heart's glass-disc stroke value — unified, still not a token)*
- `Color.white.opacity(0.03)` stroke on verified-label capsule — `VerifiedBadgeView.swift:58`
- `Color.surfaceDefault.opacity(0.65)` fill on verified-label capsule — `VerifiedBadgeView.swift:56`
- `Color.black.opacity(0.25–0.35)` shadows — 5 call sites (see Shadows)
- `Color.black.opacity(0.35)` scrim under `.ultraThinMaterial` on the close-button glass disc — `SelectedListingCard.swift:238`
- `Color.textTertiary.opacity(0.4–0.5)` disabled stepper — `FilterSheetView.swift:258,254`
- `Color.statusDanger.opacity(0.12–0.15)` danger icon bg + offline banner bg — `ErrorStateView.swift:11,52`
- `iconTint.opacity(0.15)` empty-state icon disc — `EmptyStateView.swift:32`
- `config.background.opacity(0.5)` tab-bar capsule tint over material — `FloatingTabView.swift:133`

`Assets.xcassets/AccentColor.colorset` is still **empty** (no `Contents.json` color value). The app's sole `.tint(…)` call — `FilterSheetView.swift:204` on the graphical `DatePicker` — explicitly passes `Color.coreAccent`, so the empty accent asset doesn't affect anything visible. Elsewhere `.tint(…)` is never called (every other accent-colored surface references `Color.coreAccent` directly).

## Typography

All type uses `Font.system(…)` — no custom fonts, no asset-catalog fonts, matching intent. Typography tokens live in `DesignTokens.swift:88–111` as `martiDisplay`, `martiHeading3`, `martiHeading4`, `martiHeading5`, `martiBody`, `martiFootnote`, `martiCaption`, `martiLabel1`, `martiLabel2`.

**New since previous audit:** `martiDisplay` (`.largeTitle`, `.rounded` design, `.black` weight) — added for the Discovery hero title. Anchored to `.largeTitle` so Dynamic Type scales up to AX5.

Each token is anchored to a semantic `TextStyle` (`.largeTitle`, `.title2`, `.title3`, `.headline`, `.body`, `.footnote`, `.caption`) so Dynamic Type scales them up to AX5 without per-call-site work.

Token usage (counted from `.font(.marti…)` calls):

- `martiDisplay` — 1 site (`DiscoveryHeroHeaderView.swift:33` — "Feel at home."). New.
- `martiHeading5` — 7 sites (card titles, detail-placeholder title, prices, empty-state title, map-fallback title)
- `martiHeading4` — 5 sites (section headers, filter title, error title, empty-state title)
- `martiHeading3` — 1 site (`ListingDetailPlaceholderView`)
- `martiBody` — 5 sites (search-capsule text, guest count row, filter draft count, stepper center) — +1 from the new hero capsule
- `martiFootnote` — 15 sites (most-common secondary style)
- `martiCaption` — 10 sites
- `martiLabel1` — 6 sites (`PrimaryButtonStyle`, `GhostButtonStyle.regular`, header-pill title, stepper center, etc.)
- `martiLabel2` — 11 sites (chip labels, meta rows, price/date pills, `GhostButtonStyle.compact`)

**Inline `Font.system(size:weight:)` escapes the token system in 24 places across 14 files** (unchanged count — the hero header's `17 semibold` icon button replaces the old `DiscoveryView.iconButton`'s `17 semibold`, so the inline-escape site moved rather than multiplied):

| File                                           | Inline sizes                                  | Typical intent                              |
| ---------------------------------------------- | --------------------------------------------- | ------------------------------------------- |
| `ListingCardView.swift:58,186,219,296,310`     | 12, 14 bold, 10, 28, 10/12                    | icon sizes + compact-card title size        |
| `SelectedListingCard.swift:133,165,224`        | 32, 12, 17 medium                             | photo-placeholder glyph, star, close glyph  |
| `FloatingTabView.swift:150,154`                | `config.iconPointSize` (20), `config.labelPointSize` (10) | tab bar (config-driven, acceptable) |
| `DiscoveryHeroHeaderView.swift:82`             | 17 semibold                                   | list-mode 48pt icon-button glyph            |
| `DiscoveryHeaderPill.swift:60`                 | 17 semibold                                   | map-mode 48pt icon-button glyph             |
| `CategoryRailView.swift:61`                    | 16 semibold                                   | see-all chevron                             |
| `ErrorStateView.swift:14,45`                   | 32 bold, 14 semibold                          | exclamation mark, offline-banner glyph      |
| `EmptyStateView.swift:35`                      | 26 regular                                    | empty-state icon                            |
| `AuthSheetPlaceholderView.swift:13`            | 56                                            | hero icon                                   |
| `ListingMapView.swift:70`                      | 40                                            | map-fallback-state icon                     |
| `MainTabView.swift:73`                         | 32                                            | hammer icon in `ComingSoonView`             |
| `VerifiedBadgeView.swift:30,46`                | 13 semibold, 11 semibold                      | icon-variant + label-variant checkmark glyphs |
| `FeeInclusionTag.swift:20`                     | 11 semibold                                   | xmark glyph                                 |
| `FilterSheetView.swift:253`                    | 14 bold                                       | stepper +/- glyph                           |
| `FavoriteHeartButton.swift:50`                 | 16 semibold / .regular                        | heart glyph (weight switches on save state) |

Many of these are intentional **icon sizing**, not text styling. Still, there is **no `IconSize` token**, so "button-glyph = 17pt semibold" is re-asserted in 2 different files (`DiscoveryHeroHeaderView.iconButton`, `DiscoveryHeaderPill.circularIconButton`) instead of centralized, and "small-inline-glyph = 11pt semibold" appears in two files (`VerifiedBadgeView.labelBadge`, `FeeInclusionTag`).

`.tracking(…)` still appears only at `FilterSheetView.swift:303` (`.tracking(0.5)` on the section-label helper) — matches intent.

## Spacing & layout

`Spacing` token scale (`DesignTokens.swift:39–75`) adds `xs=2`, `sm=4`, `md=8`, `base=16`, `lg=24`, `xl=32`, `xxl=40` plus rail-specific helpers: `screenMargin=16`, `cardGap=12`, `peekWidth=44`, `railCardWidth=170`. The rail helpers are well-commented in the tokens file — e.g. `railCardWidth: 170` carries a math derivation for why 170 fits "two + peek" on a compact iPhone.

Observed usage:

- **Screen edges:** `Spacing.screenMargin` is used everywhere the intent is "screen-edge padding" (`DiscoveryView`, `DiscoveryHeroHeaderView`, `CategoryRailView`, `ListingListView`). Good discipline.
- **Stack spacing:** VStack/HStack spacings almost always reference `Spacing.sm / md / base / lg`.

**Inline literals that bypass the scale:**

| File                                | Literal                       | Intent                                                                                             |
| ----------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------- |
| `ListingCardView.swift:54,64,75,78,80,81` | `14, 10, 6, 12`         | full-card content column padding — intent doc specifies "12–14pt card content padding" so the 14s match design; 10 and 6 are off-scale stopgaps |
| `SkeletonListingCard.swift:16–18`   | `14`                          | mirror of card padding so skeleton and real card align                                             |
| `VerifiedBadgeView.swift:53`        | `Spacing.sm + 1` (5pt)        | label-capsule vertical padding (off-scale — the 1pt addition is a manual contrast hack)            |

No changes here since the previous audit — the outstanding "codify a `Spacing.cardPadding = 14`" recommendation is still open.

Hit-target sizes (44pt and 48pt) are consistent across every interactive component. Card photo heights: `200` (full card), `170×170` (rail, from `Spacing.railCardWidth`), `100×80` (map preview), `130` (compact — still not used anywhere on screen). These numbers remain inline literals; no `CardHeight` token.

## Corner radius

`Radius.xs=4 / sm=8 / md=12 / lg=24 / xl=40 / full=100` (`DesignTokens.swift:79–86`). Grep confirms **every corner radius in the view code goes through a `Radius.*` token** — zero `cornerRadius: 8` style literals. Capsules are used for fully-round chrome (chips, tab bar, header pill, price pins, offline banner). Still the most disciplined dimension of the design system today.

## Iconography

**25 SF Symbols observed**, **0 `Image("assetName")` call sites**. All iconography is SF Symbols.

New pattern since the previous audit: the hero search capsule **swaps its leading glyph based on filter state** — `magnifyingglass` when no filter is active, `slider.horizontal.3` when any filter is set (`DiscoveryHeroHeaderView.swift:60`). This is the "swapped the glyph when filters are active" change from `a3af1e5`.

As a consequence, there are now **three glyphs rotating around the filters concept**:

- `line.3.horizontal.decrease` — list-mode trailing icon button ("open filters") in `DiscoveryHeroHeaderView.swift:48`
- `slider.horizontal.3` — map-mode trailing icon button ("open filters") in `DiscoveryHeaderPill.swift:22` AND the active-filter indicator inside the hero search capsule in `DiscoveryHeroHeaderView.swift:60`
- `magnifyingglass` — inactive-filter indicator inside the hero search capsule in `DiscoveryHeroHeaderView.swift:60`, plus the `.discover` tab-bar icon

Symbols in use: `checkmark.seal.fill`, `magnifyingglass`, `mappin.and.ellipse`, `mappin`, `star.fill`, `heart`, `photo`, `xmark`, `exclamationmark`, `wifi.slash`, `hammer`, `line.3.horizontal.decrease`, `slider.horizontal.3`, `map`, `chevron.left`, `chevron.right`, `plus`, `minus`, `bubble.left`, `calendar`, `person`, `person.crop.circle.badge.checkmark`, plus the dynamic `tab.systemImage` per tab (`magnifyingglass`, `heart`, `calendar`, `bubble.left`, `person`).

Note: `heart.fill` is no longer referenced anywhere — `FavoriteHeartButton` now uses `"heart"` only and distinguishes saved-state with a weight swap instead of a glyph swap.

No raster icon assets in `Assets.xcassets` (only `AppIcon.appiconset` and the empty `AccentColor.colorset`).

## Component patterns

**Extracted since the previous audit:**

- **`DiscoveryHeroHeaderView`** (`DiscoveryHeroHeaderView.swift`, 126 LOC) — list-mode editorial header. One display-sized title (`martiDisplay`, "Feel at home."), a non-interactive search capsule that surfaces the active filter summary and swaps its leading glyph (`magnifyingglass` ↔ `slider.horizontal.3`) based on `viewModel.filter != .default`, and two 48pt `surfaceElevated` icon buttons for `map` / `line.3.horizontal.decrease`. Composed as the first sibling in `DiscoveryView.listLayout` (`DiscoveryView.swift:57`). The capsule is explicitly `.accessibilityHidden(true)` because search is not functional in v1 — a deliberate decision documented in-file. The old inline `DiscoveryView.searchBar` + `DiscoveryView.iconButton` helpers are gone.

**Reshaped since the previous audit:**

- **`FavoriteHeartButton`** (`FavoriteHeartButton.swift`, 90 LOC). Visual recipe changed: the heart is now **outlined everywhere** (`Image(systemName: "heart")`), distinguished on saved state by a **font-weight switch** (`.semibold` when saved, `.regular` when unsaved) rather than a glyph swap (`heart.fill` ↔ `heart`). Tint still `statusDanger` when saved / `textPrimary` when unsaved. Glass disc recipe unchanged (ultraThinMaterial fill, `Color.white.opacity(0.12)` hairline, `black.opacity(0.25)` radius-4 shadow). The component is still wired into every save-heart site: `ListingCardView` (`.full`, `.rail`, `.compact`, `.mapPreview`) and `SelectedListingCard`.
- **`VerifiedBadgeView`** (`VerifiedBadgeView.swift`, 86 LOC). Now has two variants: `.icon` (default) and `.label`. The `.icon` variant is the visible one across Discovery — a **24pt glass disc with a 13pt semibold `checkmark.seal.fill` in `coreAccent`** (`VerifiedBadgeView.swift:28–41`). It explicitly reuses the heart's material + stroke + shadow recipe so the two top-corner overlays on a card read as a matched pair (documented in the docstring). The `.label` variant — the older "Verified" text-in-capsule shape — is now reserved for the unbuilt Listing Detail screen. Every listing-card call site passes the default `.icon` variant.

**Already extracted (unchanged):**

- `PrimaryButtonStyle` / `GhostButtonStyle` (`Buttons.swift:8–46`) + static sugar `.primary`, `.primaryFullWidth`, `.ghost`, `.ghostCompact` — routing 4 primary CTA sites and 2 ghost CTA sites.
- `FloatingTabView` — generic container + `FloatingTabViewHelper` environment helper.
- `ListingCardView` with a `ListingCardVariant` enum (`full`, `rail`, `compact`, `mapPreview`).
- `CityChipView`, `EmptyStateView`, `ErrorStateView`, `OfflineBannerView` (nested inside `ErrorStateView.swift:41`), `SkeletonListingCard`, `SkeletonHeader`.
- `CategoryRailView`, `DiscoveryHeaderPill`, `FeeInclusionTag`, `ListingPricePin`, `MapEmptyStatePill`, `SelectedListingCard`, `PriceRangeSlider`.

**Inline-reassembled chrome that remains:**

- **48pt circle icon button on `surfaceElevated`** — still duplicated across two files, though the list-mode copy has moved. `DiscoveryHeroHeaderView.iconButton:79–89` (list-mode map + filters pair) and `DiscoveryHeaderPill.circularIconButton:53–67` (map-mode back/tune pair). Same visual recipe (48pt circle, `surfaceElevated`, `textPrimary` glyph at `17 semibold`), reconstructed twice.
- **Glass disc** — the heart and the verified-icon now **share the recipe** (ultraThinMaterial + `white.opacity(0.12)` stroke + `black.opacity(0.25)` shadow) but not a component — the two views redeclare it in parallel. A third variant (with a `black.opacity(0.35)` scrim for over-image placement) sits inline in `SelectedListingCard.closeButton:221–232` + `glassBackground:236–240`. Three copies of a now-standardized recipe; one `GlassCircleBackground` modifier would absorb all three.
- **Capsule city/date/chip pill** — `CityChipView` is extracted, but the in-sheet `cityButton` (`FilterSheetView.swift:117–130`) and `datePill` (`FilterSheetView.swift:167–178`) reconstruct the same capsule shape with slightly different constraints (48pt min height, fill width). Near-duplicates of each other and of `CityChipView`.
- **Stepper circle** — `FilterSheetView.stepperButton:250–267`. Outline circle with centered glyph. Only used here today, but likely to reappear for any guest-count / kids / infants row in booking.
- **Section label helper** — `FilterSheetView.label:300–305` (uppercase `martiCaption.bold()` with `.tracking(0.5)`, `textTertiary`). Still a private helper that Auth or Profile will copy-paste when they ship.

`.buttonStyle(.plain)` call count is unchanged (13). Every remaining plain button is a deliberate "reset Apple's default chrome because this button isn't a CTA" — tab-bar items, chip buttons, filter-sheet city/date/stepper buttons, nav-link-wrapping `ListingCardView` in the rail, overlay buttons on the selected card, the hero-header icon buttons.

## Motion & animation

Animation call sites (unchanged list):

- `.animation(.default, value: showFeeTag)` + `.animation(.default, value: viewModel.selectedListing?.id)` — `DiscoveryView.swift:106–107`
- `.animation(.easeInOut(duration: 0.25), value: hideTabBar)` — `FloatingTabView.swift:103`
- `.animation(config.animation, value: activeTab)` — `FloatingTabView.swift:137` (`config.animation` defaults to `.smooth(duration: 0.35, extraBounce: 0)`)
- `.animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isSelected)` — `ListingPricePin.swift:29`
- `withAnimation(.spring(response: 0.45, dampingFraction: 0.85))` — `SelectedListingCard.swift:249` (entrance)
- `withAnimation(.spring(response: 0.35, dampingFraction: 0.85))` — `SelectedListingCard.swift:279` (dismiss-drag spring-back)
- `.transition(.opacity)` × 3 — `DiscoveryView.swift:102, 126, 129`

**Six different curves across six files; still no shared motion tokens.** The intent doc called for `.spring(response: 0.3, dampingFraction: 0.7)` + `.easeInOut` consistency. Reality: `.default` (2×), `.easeInOut(0.25)`, `.smooth(0.35, extraBounce: 0)`, `.easeOut(0.2)`, `.spring(0.45, 0.85)`, `.spring(0.35, 0.85)`.

`@Environment(\.accessibilityReduceMotion)` is respected in **2 places only** (`SelectedListingCard.swift:26` → `animateIn` + drag spring-back, `ListingPricePin.swift:13` → selection transition). The tab-bar hide slide (`FloatingTabView.swift:103`), the fee-tag + selected-card opacity transitions (`DiscoveryView.swift:106–107`), and the tab-bar active-tab `config.animation` (`FloatingTabView.swift:137`) animate regardless of the Reduce Motion setting.

**Haptics** — 2 sites:

- `.sensoryFeedback(.impact(weight: .light), trigger: isSaved)` — `FavoriteHeartButton.swift:64`.
- `.sensoryFeedback(.impact, trigger: hapticsTrigger)` — `FloatingTabView.swift:138`. Tab change.

## Accessibility coverage

42 accessibility-modifier calls across 17 files (up from 41/16 in the previous audit — the new `DiscoveryHeroHeaderView` adds `.accessibilityAddTraits(.isHeader)` on the title and `.accessibilityHidden(true)` on the non-functional search capsule, plus `.accessibilityLabel` on each icon button).

Solid coverage of interactive elements: heart buttons (component-level label switches between "Save listing" / "Remove from saved"), chips, tab bar, map pins, verified badge (`.accessibilityElement(children: .combine)` + "Verified host" label on both variants), header pill, price slider, category-rail cards, selected-listing card (custom actions for save / close / tap body), hero-header icon buttons ("Switch to map view" / "Open filters"). `PriceRangeSlider` still correctly implements `.accessibilityAdjustableAction`.

Known gaps (unchanged from previous audit):

- `AuthSheetPlaceholderView` — the hero `person.crop.circle.badge.checkmark` icon (`AuthSheetPlaceholderView.swift:12`) has no `.accessibilityHidden(true)`.
- `ComingSoonView` (`MainTabView.swift:67–86`) — the `hammer` icon isn't hidden from VoiceOver.
- `EmptyStateView` — icon disc (`EmptyStateView.swift:30–37`) has no `.accessibilityHidden`; VoiceOver will read the SF Symbol name.
- `ErrorStateView` — `exclamationmark` icon disc (`ErrorStateView.swift:9–16`) has no `.accessibilityHidden`.
- `ListingDetailPlaceholderView` — no accessibility overrides (acceptable for a placeholder).
- `FilterSheetView` — individual filter chips, date pills, stepper glyphs, and price-range thumbs rely on native control semantics; only `clearAllButton` has an explicit label.

`.accessibilityHint` is used only twice. Hints remain underused.

Dynamic Type: two views observe `@Environment(\.dynamicTypeSize)` — `ListingCardView.swift:21` (rail title line limit), `DiscoveryView.swift:13` (hides the fee tag at `.accessibility3+`). The filter sheet's `headerRow` also uses `ViewThatFits` (`FilterSheetView.swift:80`) to reflow to a stacked layout at large sizes, and `SelectedListingCard.priceLine` uses `ViewThatFits` (`SelectedListingCard.swift:181`) to stack the SOS line under the USD line when single-line doesn't fit. The new `DiscoveryHeroHeaderView` uses `.lineLimit(2)` + `.minimumScaleFactor(0.9)` on the display title (`DiscoveryHeroHeaderView.swift:35–36`).

## Localization coverage

**Still zero.** No `Localizable.xcstrings`, no `.strings`, no `LocalizedStringKey`, no `NSLocalizedString`, no `String(localized:)`. Every user-facing string is a Swift string literal.

The new hero copy `"Feel at home."` (`DiscoveryHeroHeaderView.swift:18`) is another hardcoded literal on top of the existing ~90 in Discovery alone. Intent-doc V1.1 Somali target will touch every view file.

## Dark mode

One `.preferredColorScheme(.dark)` at `MainTabView.swift:63`. No other `colorScheme` checks. `DesignTokens.swift` colors are fixed dark-mode hex values — the app cannot adapt to system light mode. Matches intent.

## Drift from intent

Comparing `docs/DESIGN.previous.md` (the preserved intent spec) against the shipped code:

| Area                                               | Intent                                                                        | Reality                                                                                                                                                                                                                                                                                                            |
| -------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Verified badge                                     | Tinted green (`statusSuccess` bg at 15% + `#62F1C6` text)                     | `VerifiedBadgeView.icon:28–41` uses `coreAccent` (cyan) checkmark on an ultraThinMaterial glass disc — not green, not a 15%-tinted fill. `statusSuccess` token remains **never used anywhere in code**. The icon variant is now deliberately visually paired with `FavoriteHeartButton` (same glass-disc recipe), which is a sensible product choice but further from the original spec. |
| Saved heart                                        | `statusDanger` (pink) filled (`heart.fill`), everywhere                       | **Resolved in spirit, partial in letter.** `FavoriteHeartButton.swift:49–51` uses `heart` (outlined) always, distinguishing saved state with a weight switch (`.semibold` vs `.regular`) and the `statusDanger` tint. Intent specified `heart.fill` — shipping code never uses `heart.fill`. A deliberate decision ("outlined heart everywhere") per commit `a3af1e5`; worth reconciling with the spec. |
| Rating stars                                       | Gold                                                                          | ✅ `Color.statusWarning` (#FEEB87) is now the single star tint. Commit `a3af1e5` (" Gold stars not cyan") locked this in.                                                                                                                                                                                           |
| Shadows                                            | "No card shadows" + listed `sm/lg` tokens                                     | 5 shadow call sites, all with inline `Color.black.opacity(0.25–0.35)` — no shadow token. Verified-icon now shadows too (`VerifiedBadgeView.swift:40`), adding a 6th inline shadow if counted as new. Most shadows are on floating/elevated elements where shadows are defensible, but the "no card shadows" rule isn't consistent. |
| Button styles                                      | Primary / Secondary / Ghost / Destructive as named styles                     | ✅ **Primary & Ghost resolved.** Secondary and Destructive not yet defined; no caller needs them today.                                                                                                                                                                                                           |
| Skeleton                                           | "Static skeleton shapes (no shimmer animation)"                               | `SkeletonListingCard`, `SkeletonHeader`, and the map's `LoadingPinSkeletons` are all static — matches intent.                                                                                                                                                                                                      |
| Icon stroke weights                                | "1.5pt inactive, 2pt active" tab bar                                          | SF Symbols don't offer a 1.5pt stroke — tab bar uses `.regular` vs `.semibold` as a proxy (`FloatingTabView.swift:150,154`). Close-enough approximation.                                                                                                                                                            |
| Message bubble / status badges                     | Specified                                                                     | Not shipped.                                                                                                                                                                                                                                                                                                       |
| `.tint()`                                          | —                                                                             | Still used once in `FilterSheetView.swift:204`. `AccentColor.colorset` still empty.                                                                                                                                                                                                                                |
| `corePrimary`, `statusSuccess`, `starEmpty` tokens | Defined for specific use cases                                                | **Dead tokens** — zero view-file references (unchanged).                                                                                                                                                                                                                                                           |
| Localization                                       | V1 English-only, scaffold planned for V1.1 Somali                             | No scaffolding in place. Hero copy added one more literal.                                                                                                                                                                                                                                                         |
| Reduce Motion                                      | "All animations wrapped in `@Environment(\.accessibilityReduceMotion)` check" | Honored in 2 of 7 animation call sites (unchanged).                                                                                                                                                                                                                                                                |
| Filter glyph                                       | —                                                                             | Three different glyphs rotate around the filters concept now: `line.3.horizontal.decrease` (list-mode trailing button), `slider.horizontal.3` (map-mode trailing button AND the hero capsule's active-filter indicator), `magnifyingglass` (hero capsule's inactive indicator). One fewer than the previous audit suggested was waste — the capsule's glyph swap is intentional, the two trailing-button glyphs are still redundant. |
| Display type                                       | Intent doc listed no editorial display face                                   | ✅ **New, on purpose.** `martiDisplay` (`.largeTitle`, `.rounded`, `.black`) added for `DiscoveryHeroHeaderView`. Intent doc should be updated to reflect the new style if it's meant to propagate (Saved / Bookings / Detail likely want a hero too). |

## Inconsistencies found

1. **Shadows are still improvised.** Five inline parameterizations across files, now with the verified-icon shadow replicating the heart's values a sixth time:
   - `black.opacity(0.25), radius 4, y 1` — `FavoriteHeartButton.swift:60`, `VerifiedBadgeView.swift:40` (two files, identical tuple)
   - `black.opacity(0.25), radius 4, y 2` — `ListingPricePin.swift:28`, `ListingMapView.swift:134` (skeleton pins)
   - `black.opacity(0.3), radius 8, y 2` — `FloatingTabView.swift:136`
   - `black.opacity(0.35), radius 16, y 6` — `SelectedListingCard.swift:43`
   No shadow tokens exist in `DesignTokens.swift`. Define `Shadow.elevation1/2/3` and replace the inline calls.
2. **Six distinct animation curves with no shared motion tokens.** Unchanged from previous audit: `.default` (2×), `.easeInOut(0.25)`, `.smooth(0.35, extraBounce 0)`, `.easeOut(0.2)`, `.spring(0.45, 0.85)`, `.spring(0.35, 0.85)`. Intent spec called for `.spring(0.3, 0.7)` + `.easeInOut`.
3. **Reduce Motion is honored in 2 of 7 animation sites.** Unchanged.
4. **The 48pt circle icon button is still duplicated** — `DiscoveryHeroHeaderView.iconButton:79–89` and `DiscoveryHeaderPill.circularIconButton:53–67`. Same visual recipe rebuilt in two files; the list-mode copy just moved, it didn't disappear. Extract a `CircleIconButton(systemName:label:size:action:)` with `.plain` / `.glass` variants so `SelectedListingCard.closeButton:221` can also adopt it.
5. **Glass disc chrome now has three inline copies of a single recipe.** `FavoriteHeartButton.swift:53–60`, `VerifiedBadgeView.swift:33–40`, and `SelectedListingCard.closeButton:221–232` + `glassBackground:236–240` all redeclare ultraThinMaterial + 0.12 white stroke + `black.opacity(0.25)` shadow. The addition of the verified-icon variant makes this the clearest extraction target: one `GlassCircleBackground` `ViewModifier` would dedupe all three.
6. **Capsule button chrome is reconstructed.** `CityChipView` (extracted) vs. `FilterSheetView.cityButton:117–130` vs. `FilterSheetView.datePill:167–178` — three near-identical capsule-pill implementations. `CityChipView` could take a `fillWidth: Bool` parameter and absorb the other two.
7. **Verified badge drift from spec.** `VerifiedBadgeView.icon` ships cyan-on-glass, not `statusSuccess` green-on-tint. `statusSuccess` stays a defined-but-unused token. Decide: update the spec to acknowledge cyan-on-glass as the product direction (so `statusSuccess` / `corePrimary` / `starEmpty` can be deleted or retargeted), or re-theme the badge to green.
8. **Heart spec drift.** Intent specified `heart.fill` when saved; shipping code never uses `heart.fill`. The weight-switched outlined heart is arguably a better read (no shape jump on toggle) but isn't in the spec. Update the spec or the code.
9. **Inline padding literals inside `ListingCardView.fullCard`.** Uses `14`, `10`, `6`, `12` (`ListingCardView.swift:54,64,75,78,80,81`) — none of which are in the `Spacing` scale. Intent doc specifies "12–14pt card content padding"; codify `Spacing.cardPadding = 14` so `SkeletonListingCard` and the real card track together.
10. **Off-scale `Spacing.sm + 1` (5pt) in `VerifiedBadgeView.swift:53`.** One-off manual contrast tweak on the label variant that isn't in the spacing scale.
11. **Dead tokens.** `Color.corePrimary`, `Color.statusSuccess`, `Color.starEmpty` defined in `DesignTokens.swift` but zero view-file references. Either wire them up (Verified badge → `statusSuccess`; empty-star outlines in `ratingRow` → `starEmpty`) or delete them.
12. **Empty `AccentColor.colorset`.** Unchanged. `.tint(…)` is called once and passes `Color.coreAccent` explicitly, so the empty asset is inert. Populate it with `coreAccent` and wire `.tint(.coreAccent)` at the root scene, or delete the asset to make the absence intentional.
13. **No `IconSize` token.** `17 semibold` (2 files — `DiscoveryHeroHeaderView`, `DiscoveryHeaderPill`), `13 semibold` (`VerifiedBadgeView.icon`), `11 semibold` (2 files — `VerifiedBadgeView.label`, `FeeInclusionTag`), `16 semibold` (`FavoriteHeartButton` weight-switched), and a scatter of one-offs. A small `IconSize.button / .inline / .hero` helper would retire most of the remaining `.font(.system(size:))` escapes for SF Symbols.
14. **No localization at all.** Every string is an inline literal across 22 view files, including the new `"Feel at home."` hero copy. V1.1 Somali will require a mass `Localizable.xcstrings` migration.

## Recommended cleanups

1. **Add motion and shadow tokens, then retrofit callers.** `Motion.standard = .spring(response: 0.3, dampingFraction: 0.7)`, `Motion.quick = .easeOut(duration: 0.2)`, `Shadow.elevation1 = (.black.opacity(0.25), radius: 4, y: 2)`, `Shadow.elevation2 = …`. Replace the 5-6 inline shadow tuples and 6 inline animation curves. Side effect: makes the Reduce Motion rollout a one-line change inside a `Motion.wrap(value:)` or similar, instead of 5+ patches.
2. **Extract a `GlassCircleBackground` modifier** (or a `CircleIconButton` wrapper around it). With three files (`FavoriteHeartButton`, `VerifiedBadgeView.icon`, `SelectedListingCard.closeButton`) now redeclaring the same material+stroke+shadow recipe, and two files duplicating the 48pt `surfaceElevated` icon button, one small component would absorb 5 call sites.
3. **Codify `Spacing.cardPadding = 14`** and replace the `14 / 10 / 6 / 12` stack inside `ListingCardView.fullCard`. Collapses a repeated-literal cluster and aligns the skeleton card's paddings with the real card.
4. **Scaffold `Localizable.xcstrings` now and migrate Discovery first.** Discovery is the entire shipped V1 surface (~90+ user-facing strings including the new hero copy). Migrating before Auth + Detail + Booking + Messaging ship is far cheaper than after.
5. **Reconcile the Verified badge and the saved heart against the spec.** The shipping visuals for both drifted from `docs/DESIGN.previous.md` in ways that look intentional (matched glass-disc siblings on the card; outlined heart). Update the spec to ratify, or pull the code back. Either way resolves two drift rows and unblocks `statusSuccess` (either delete the token or start using it).

---

## Summary

**What changed since the previous audit (five commits on `dev`, HEAD `ae05b0e`):**

- **New `DiscoveryHeroHeaderView`** replaced the old `DiscoveryView.searchBar` + inline `iconButton` chrome with an editorial list-mode header: a `martiDisplay`-sized "Feel at home." title, a non-interactive search capsule that swaps its glyph on filter state, and two 48pt icon buttons for map / filters.
- **`martiDisplay` typography token added** (`.largeTitle`, `.rounded`, `.black`) — one call site today; a hero pattern likely to repeat across Saved / Bookings / Detail.
- **Two new color tokens: `surfaceGlass` and `surfaceStroke`.** Each is wired in exactly one place today (`DiscoveryHeroHeaderView` capsule stroke; rail-card photo hairline) — tokenizing values that used to be inline.
- **`FavoriteHeartButton` is outlined everywhere.** No more `heart.fill` — saved state is communicated by a weight switch and a `statusDanger` tint. Drifts from the spec's "filled pink heart" but is the product decision from commit `a3af1e5`.
- **`VerifiedBadgeView` has two variants now.** The default `.icon` variant is a 24pt glass disc with a cyan checkmark — deliberately matched to the heart's recipe — and is what every listing card shows. The `.label` (text capsule) variant is reserved for the unbuilt Listing Detail screen.
- **Rating stars are gold, not cyan** (`statusWarning` was already wired; the commit made it official).
- **Accessibility count ticked up** from 41 to 42 modifier calls across one more file.

**Top 3 remaining inconsistencies:**

1. **Motion is still improvisational.** Six distinct curves across six files, Reduce Motion honored in 2 of 7 sites. The highest-leverage cleanup in the codebase — unchanged from the previous audit.
2. **Shadows and glass-disc chrome are repeated-literal clusters.** Five shadow call sites share three different tuples (one shared across files). Three files (`FavoriteHeartButton`, `VerifiedBadgeView.icon`, `SelectedListingCard.closeButton`) now redeclare the same material+stroke+shadow "glass disc" recipe. One `Shadow.*` token group + one `GlassCircleBackground` modifier would absorb 8+ inline call sites.
3. **Heart and verified-badge both drift from the intent spec**, in the same direction: the real app prefers an outlined / glass / unified visual language where the spec prescribed filled / tinted / separate. Worth ratifying the product direction in `docs/DESIGN.previous.md` and reclaiming three unused tokens (`statusSuccess`, `corePrimary`, `starEmpty`).

**Most impactful cleanup to do first:** define `Motion` + `Shadow` token groups in `DesignTokens.swift` and retrofit the existing call sites. Like last audit, this locks motion/elevation behavior in one place before Auth, Listing Detail, and Booking each add another dozen animation/shadow sites. Adding the `GlassCircleBackground` modifier in the same pass folds in the now-tripled glass-disc recipe and retires the last big repeated-chrome pattern visible in Discovery.

*Refreshed 2026-04-19 (late). Intent doc preserved at `docs/DESIGN.previous.md` — not overwritten by this refresh.*
