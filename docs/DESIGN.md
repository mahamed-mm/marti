# Design System: Marti — Observed

## Snapshot

- **Audit run:** 2026-04-19 (re-audit after `Buttons.swift` + `FavoriteHeartButton` + `Discovery/Components/` extraction work landed)
- **Views surveyed:** 23 Swift files under `Marti/Marti/Views/` + `Extensions/DesignTokens.swift` + `Marti/Marti/Views/Shared/Buttons.swift` (`ButtonStyle` definitions)
- **Only shipped screen:** Discovery (list + map + filters). Auth, Listing Detail, Saved, Bookings, Messages, Profile are all placeholder `ComingSoonView` / placeholder sheets (`MainTabView.swift:67–86`, `ListingDetailPlaceholderView.swift`, `AuthSheetPlaceholderView.swift`).
- **Source of truth for intent:** `docs/DESIGN.previous.md` (the original spec) is left untouched — the prior audit flagged it as intent-doc-preserved, and this audit does the same rather than overwriting with the previous audit.

## Visual identity

Dark-only. Every surveyed screen renders on `Color.canvas` (#010913) with card elevation carried by progressively lighter surface colors (`surfaceDefault` → `surfaceElevated` → `surfaceHighlight`) rather than shadows. Cyan (`coreAccent` #84E9FF) is the single primary accent, used for CTAs, active chips, active tab icons, the verified-badge glyph, and the selected price pin fill. Chrome is reduced to pill headers, a floating tab capsule, and a single cyan CTA. The shipped flow (Discovery) reads calm and photo-driven — listing photography dominates, and the map mode strips everything but a header pill, a floating card, and the tab bar. `.preferredColorScheme(.dark)` is set once on `MainTabView` (`MainTabView.swift:63`); nothing else checks `colorScheme`, and every token in `DesignTokens.swift` points at a dark value, so the app cannot render a light mode even if `preferredColorScheme` were dropped.

## Color system

All colors flow through `Extensions/DesignTokens.swift:5–25`. That file is the sole source of hex values — grep confirms **zero `Color(red:…)` / `Color("…")` / `Color(hex:…)` / `Color(UIColor:…)` literals anywhere under `Views/`**. This is unchanged from the previous audit.

Tokens actually used across views:

| Token              | Used in                                                                            | Notes                                                                                              |
| ------------------ | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `canvas`           | 6+ call sites (screen bg, `PrimaryButtonStyle` text color, selected price pin text) | matches intent                                                                                     |
| `surfaceDefault`   | 9+ call sites (cards, verified bg, header pill bg, price pin idle)                  | matches intent                                                                                     |
| `surfaceElevated`  | 8+ call sites (search pill, chips, 48pt icon buttons, filter rows, date/stepper)   | matches intent                                                                                     |
| `surfaceHighlight` | 3 call sites (`SkeletonListingCard` bars, `SkeletonHeader`, map-skeleton pins)     | matches intent                                                                                     |
| `textPrimary`      | ~45 call sites                                                                     | most-used foreground                                                                               |
| `textSecondary`    | ~18 call sites                                                                     | secondary metadata, inactive tab label                                                             |
| `textTertiary`     | ~25 call sites                                                                     | placeholders, captions, SOS price, inactive tab icon                                               |
| `coreAccent`       | ~18 call sites                                                                     | CTAs (`PrimaryButtonStyle`, `GhostButtonStyle`), active chip, active tab, verified glyph, selected price pin, range slider, date-picker `.tint` |
| `corePrimary`      | 0 call sites under `Views/`                                                        | **unused token** (unchanged since last audit)                                                      |
| `statusSuccess`    | 0 call sites under `Views/`                                                        | **unused token** (unchanged — design intended it for Verified badge, see drift)                    |
| `statusDanger`     | 4 call sites (error icon + ring, offline banner bg/fg, saved-heart fill)           | `FavoriteHeartButton` uses this for saved state, so the rail/full/compact/mapPreview/selected card all share one tint |
| `statusWarning`    | 2 call sites (star.fill on card + card-preview / selected card rating row)         |                                                                                                    |
| `dividerLine`      | 3 call sites (filter-sheet dividers, price-pin stroke, map-skeleton stroke)        | now in real use after being dead in the previous audit                                             |
| `starEmpty`        | 0 call sites                                                                       | still unused; the rating row never renders an empty-star outline                                   |

Ad-hoc alpha compositions (present in code, not tokenized):

- `Color.white.opacity(0.12)` stroke on heart disc — `FavoriteHeartButton.swift:57`
- `Color.white.opacity(0.03)` stroke on verified badge — `VerifiedBadgeView.swift:28`
- `Color.surfaceDefault.opacity(0.65)` fill on verified badge — `VerifiedBadgeView.swift:26`
- `Color.black.opacity(0.25–0.35)` shadows — 5 call sites (see Shadows)
- `Color.black.opacity(0.35)` scrim under `.ultraThinMaterial` on the close-button glass disc — `SelectedListingCard.swift:238`
- `Color.textTertiary.opacity(0.4–0.5)` disabled stepper — `FilterSheetView.swift:258,254`
- `Color.statusDanger.opacity(0.12–0.15)` danger icon bg + offline banner bg — `ErrorStateView.swift:11,52`
- `iconTint.opacity(0.15)` empty-state icon disc — `EmptyStateView.swift:32`
- `config.background.opacity(0.5)` tab-bar capsule tint over material — `FloatingTabView.swift:133`

`Assets.xcassets/AccentColor.colorset` is still **empty** (no `Contents.json` color value). The app's sole `.tint(…)` call — `FilterSheetView.swift:204` on the graphical `DatePicker` — explicitly passes `Color.coreAccent`, so the empty accent asset doesn't affect anything visible. Elsewhere `.tint(…)` is never called (every other accent-colored surface references `Color.coreAccent` directly).

## Typography

All type uses `Font.system(…)` — no custom fonts, no asset-catalog fonts, matching intent. Typography tokens live in `DesignTokens.swift:83–92` as `martiHeading3`, `martiHeading4`, `martiHeading5`, `martiBody`, `martiFootnote`, `martiCaption`, `martiLabel1`, `martiLabel2`.

Each token is anchored to a semantic `TextStyle` (`.title2`, `.title3`, `.headline`, `.body`, `.footnote`, `.caption`) so Dynamic Type scales them up to AX5 without per-call-site work. The previous audit's note that "designed sizes stay close to the intent scale at default Dynamic Type" is still accurate.

Token usage (counted from `.font(.marti…)` calls):

- `martiHeading5` — 7 sites (card titles, detail-placeholder title, prices, empty-state title, map-fallback title)
- `martiHeading4` — 5 sites (section headers, filter title, error title, empty-state title)
- `martiHeading3` — 1 site (`ListingDetailPlaceholderView`)
- `martiBody` — 4 sites (search-bar text, guest count row, filter draft count, stepper center)
- `martiFootnote` — 15 sites (most-common secondary style)
- `martiCaption` — 10 sites
- `martiLabel1` — 6 sites (`PrimaryButtonStyle`, `GhostButtonStyle.regular`, header-pill title, stepper center, etc.)
- `martiLabel2` — 11 sites (chip labels, meta rows, price/date pills, `GhostButtonStyle.compact`)

**Inline `Font.system(size:weight:)` escapes the token system in 24 places across 14 files** (unchanged count from last audit — new extractions didn't remove any, and the new `FavoriteHeartButton` adds one at `size: 16, weight: .semibold` while folding in what used to be two inline uses):

| File                                           | Inline sizes                                  | Typical intent                              |
| ---------------------------------------------- | --------------------------------------------- | ------------------------------------------- |
| `ListingCardView.swift:58,179,212,286,294`     | 12, 14 bold, 10, 28, 10/12                    | icon sizes + compact-card title size        |
| `SelectedListingCard.swift:133,165,224`        | 32, 12, 17 medium                             | photo-placeholder glyph, star, close glyph  |
| `FloatingTabView.swift:150,154`                | `config.iconPointSize` (20), `config.labelPointSize` (10) | tab bar (config-driven, acceptable) |
| `DiscoveryView.swift:200`                      | 17 semibold                                   | list-mode 48pt icon-button glyph            |
| `DiscoveryHeaderPill.swift:60`                 | 17 semibold                                   | map-mode 48pt icon-button glyph             |
| `CategoryRailView.swift:61`                    | 16 semibold                                   | see-all chevron                             |
| `ErrorStateView.swift:14,45`                   | 32 bold, 14 semibold                          | exclamation mark, offline-banner glyph      |
| `EmptyStateView.swift:35`                      | 26 regular                                    | empty-state icon                            |
| `AuthSheetPlaceholderView.swift:13`            | 56                                            | hero icon                                   |
| `ListingMapView.swift:70`                      | 40                                            | map-fallback-state icon                     |
| `MainTabView.swift:73`                         | 32                                            | hammer icon in `ComingSoonView`             |
| `VerifiedBadgeView.swift:15`                   | 11 semibold                                   | checkmark glyph                             |
| `FeeInclusionTag.swift:20`                     | 11 semibold                                   | xmark glyph                                 |
| `FilterSheetView.swift:253`                    | 14 bold                                       | stepper +/- glyph                           |
| `FavoriteHeartButton.swift:50`                 | 16 semibold                                   | heart glyph                                 |

Many of these are intentional **icon sizing**, not text styling — SF Symbols use `.font(.system(size:))` to scale. Still, there is **no `IconSize` token**, so "button-glyph = 17pt semibold" is re-asserted in 2 different files (`DiscoveryView.iconButton`, `DiscoveryHeaderPill.circularIconButton`) instead of centralized, and "small-inline-glyph = 11pt semibold" appears in two files (`VerifiedBadgeView`, `FeeInclusionTag`).

`.tracking(…)` still appears only at `FilterSheetView.swift:303` (`.tracking(0.5)` on the section-label helper) — matches intent.

## Spacing & layout

`Spacing` token scale (`DesignTokens.swift:29–65`) adds `xs=2`, `sm=4`, `md=8`, `base=16`, `lg=24`, `xl=32`, `xxl=40` plus rail-specific helpers: `screenMargin=16`, `cardGap=12`, `peekWidth=44`, `railCardWidth=170`. The rail helpers (all added since the previous audit was initially drafted) are well-commented in the tokens file — e.g. `railCardWidth: 170` carries a math derivation for why 170 fits "two + peek" on a compact iPhone.

Observed usage:

- **Screen edges:** `Spacing.screenMargin` is used everywhere the intent is "screen-edge padding" (`DiscoveryView`, `CategoryRailView`, `ListingListView`). Good discipline.
- **Stack spacing:** VStack/HStack spacings almost always reference `Spacing.sm / md / base / lg`.

**Inline literals that bypass the scale:**

| File                                | Literal                       | Intent                                                                                             |
| ----------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------- |
| `ListingCardView.swift:54,64,75,78,80,81` | `14, 10, 6, 12`         | full-card content column padding — intent doc specifies "12–14pt card content padding" so the 14s match design; 10 and 6 are off-scale stopgaps |
| `SkeletonListingCard.swift:16–18`   | `14`                          | mirror of card padding so skeleton and real card align                                             |
| `VerifiedBadgeView.swift:23`        | `Spacing.sm + 1` (5pt)        | capsule vertical padding (off-scale — the 1pt addition is a manual contrast hack)                  |

No changes here since the previous audit — the outstanding "codify a `Spacing.cardPadding = 14`" recommendation is still open.

Hit-target sizes (44pt and 48pt) are consistent across every interactive component. Card photo heights: `200` (full card), `170×170` (rail, from `Spacing.railCardWidth`), `100×80` (map preview), `130` (compact — still not used anywhere on screen). These numbers remain inline literals; no `CardHeight` token.

## Corner radius

`Radius.xs=4 / sm=8 / md=12 / lg=24 / xl=40 / full=100` (`DesignTokens.swift:69–76`). Grep confirms **every corner radius in the view code goes through a `Radius.*` token** — zero `cornerRadius: 8` style literals. Capsules are used for fully-round chrome (chips, tab bar, header pill, price pins, offline banner). Still the most disciplined dimension of the design system today.

## Iconography

**25 SF Symbols observed**, **0 `Image("assetName")` call sites**. All iconography is SF Symbols. The set of symbols grew since the previous audit: `chevron.left` and `slider.horizontal.3` entered via `DiscoveryHeaderPill`; `chevron.right` became prominent via `CategoryRailView`. `line.3.horizontal.decrease` (list-mode filter icon) and `slider.horizontal.3` (map-mode filter icon) both exist — the same action has two different glyphs depending on context.

Symbols in use: `checkmark.seal.fill`, `magnifyingglass`, `mappin.and.ellipse`, `mappin`, `star.fill`, `heart`, `heart.fill`, `photo`, `xmark`, `exclamationmark`, `wifi.slash`, `hammer`, `line.3.horizontal.decrease`, `slider.horizontal.3`, `map`, `chevron.left`, `chevron.right`, `plus`, `minus`, `bubble.left`, `calendar`, `person`, `person.crop.circle.badge.checkmark`, plus the dynamic `tab.systemImage` per tab (`magnifyingglass`, `heart`, `calendar`, `bubble.left`, `person`).

No raster icon assets in `Assets.xcassets` (only `AppIcon.appiconset` and the empty `AccentColor.colorset`).

## Component patterns

The previous audit called out a big gap between the intent doc's "dozen named components" and reality. Two of those components have since been extracted:

**Now extracted (since the previous audit):**

- **`PrimaryButtonStyle`** (`Buttons.swift:8–22`) + static sugar `.primary` / `.primaryFullWidth`. Used at 4 CTA sites: `EmptyStateView:56`, `ErrorStateView:32`, `FilterSheetView:293` (apply), `AuthSheetPlaceholderView:33` (continue). Visual recipe: 48pt min-height, `coreAccent` bg, `canvas` fg, `Radius.sm`, `martiLabel1`, opacity dip on press.
- **`GhostButtonStyle`** (`Buttons.swift:34–46`) + static sugar `.ghost` / `.ghostCompact`. Used at 2 sites: `EmptyStateView:60` ("Clear filters"), `FilterSheetView:101` ("Clear all"). Visual recipe: `coreAccent` fg, 44pt min-height, `martiLabel1` (regular) or `martiLabel2` (compact), opacity dip on press.
- **`FavoriteHeartButton`** (`FavoriteHeartButton.swift`). One component now used at every save-heart site: `ListingCardView.full`, `.rail`, `.compact`, `.mapPreview` (variants), and `SelectedListingCard.hero`. Fixes the "pink on one screen, cyan on another" bug the previous audit flagged. Glass disc, white 0.12 hairline stroke, black 0.25 shadow, 16pt semibold glyph, `statusDanger` fill when saved / `textPrimary` when unsaved. `Size.small` (32pt disc) and `.large` (44pt disc) both hit-target to 44pt. Uses `.onTapGesture`-on-`Image` (not a `Button`) to survive being nested inside a `NavigationLink` label on iOS 26 — this is documented inline in the view's docstring.

**Already extracted (unchanged):**

- `FloatingTabView` — generic container + `FloatingTabViewHelper` environment helper
- `ListingCardView` with a `ListingCardVariant` enum (`full`, `rail`, `compact`, `mapPreview`)
- `VerifiedBadgeView`, `CityChipView`, `EmptyStateView`, `ErrorStateView`, `OfflineBannerView` (nested inside `ErrorStateView.swift:41`), `SkeletonListingCard`, `SkeletonHeader`
- `CategoryRailView`, `DiscoveryHeaderPill`, `FeeInclusionTag`, `ListingPricePin`, `MapEmptyStatePill`, `SelectedListingCard`, `PriceRangeSlider`

**Inline-reassembled chrome that remains:**

- **48pt circle icon button on `surfaceElevated`** — still duplicated across two files: `DiscoveryView.iconButton:197–207` (list-mode search/filters/map trio) and `DiscoveryHeaderPill.circularIconButton:53–67` (map-mode back/tune pair). Same visual recipe (48pt circle, `surfaceElevated`, `textPrimary` glyph at `17 semibold`), reconstructed twice.
- **Glass disc** — now only one inline copy remains: `SelectedListingCard.closeButton:221–232` + `glassBackground:236–240` reconstruct the glass-over-scrim disc for the close button. `FavoriteHeartButton` collapsed the other two inline copies from the previous audit. One-more extraction (or generalizing `FavoriteHeartButton`'s disc into a `GlassIconButton` and composing the heart/close on top) would finish the job.
- **Capsule city/date/chip pill** — `CityChipView` is extracted, but the in-sheet `cityButton` (`FilterSheetView:117–130`) and `datePill` (`FilterSheetView:167–178`) reconstruct the same capsule shape with slightly different constraints (48pt min height, fill width). Near-duplicates of each other and of `CityChipView`.
- **Stepper circle** — `FilterSheetView.stepperButton:250–267`. Outline circle with centered glyph. Only used here today, but likely to reappear for any guest-count / kids / infants row in booking.
- **Section label helper** — `FilterSheetView.label:300–305` (uppercase `martiCaption.bold()` with `.tracking(0.5)`, `textTertiary`). Still a private helper that Auth or Profile will copy-paste when they ship.

`.buttonStyle(.plain)` is called **13 times** (down from 18 in the previous audit — every removal was replaced with a `PrimaryButtonStyle` or `GhostButtonStyle`). Every remaining `.buttonStyle(.plain)` is a deliberate "reset Apple's default chrome because this button isn't a CTA" — e.g. tab-bar items, chip buttons, filter-sheet city/date/stepper buttons, nav-link-wrapping `ListingCardView` in the rail, overlay buttons on the selected card.

## Motion & animation

Animation call sites:

- `.animation(.default, value: showFeeTag)` + `.animation(.default, value: viewModel.selectedListing?.id)` — `DiscoveryView.swift:102–103`
- `.animation(.easeInOut(duration: 0.25), value: hideTabBar)` — `FloatingTabView.swift:103`
- `.animation(config.animation, value: activeTab)` — `FloatingTabView.swift:137` (`config.animation` defaults to `.smooth(duration: 0.35, extraBounce: 0)`, `FloatingTabView.swift:22`)
- `.animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isSelected)` — `ListingPricePin.swift:29`
- `withAnimation(.spring(response: 0.45, dampingFraction: 0.85))` — `SelectedListingCard.swift:249` (entrance)
- `withAnimation(.spring(response: 0.35, dampingFraction: 0.85))` — `SelectedListingCard.swift:279` (dismiss-drag spring-back)
- `.transition(.opacity)` × 3 — `DiscoveryView.swift:98, 122, 125`

**Six different curves across six files; still no shared motion tokens.** The intent doc called for `.spring(response: 0.3, dampingFraction: 0.7)` + `.easeInOut` consistency. Reality: `.default` (2×), `.easeInOut(0.25)`, `.smooth(0.35, extraBounce: 0)`, `.easeOut(0.2)`, `.spring(0.45, 0.85)`, `.spring(0.35, 0.85)`.

`@Environment(\.accessibilityReduceMotion)` is respected in **2 places only** (`SelectedListingCard.swift:26` → `animateIn` + drag spring-back, `ListingPricePin.swift:13` → selection transition). The tab-bar hide slide (`FloatingTabView.swift:103`), the fee-tag + selected-card opacity transitions (`DiscoveryView.swift:102–103`), and the tab-bar active-tab `config.animation` (`FloatingTabView.swift:137`) animate regardless of the Reduce Motion setting.

**Haptics** — 2 sites:

- `.sensoryFeedback(.impact(weight: .light), trigger: isSaved)` — `FavoriteHeartButton.swift:64`. Consolidates two previous inline haptic calls into one.
- `.sensoryFeedback(.impact, trigger: hapticsTrigger)` — `FloatingTabView.swift:138`. Tab change.

## Accessibility coverage

41 accessibility-modifier calls across 16 files (up from 37/17 in the previous audit — new `CategoryRailView`, `DiscoveryHeaderPill`, `MapEmptyStatePill`, `SelectedListingCard` accessibility actions pushed the total). Solid coverage of interactive elements: heart buttons, chips, tab bar, map pins, verified badge, header pill, price slider, category-rail cards (via `accessibilityElement(children: .combine)` + `accessibilityLabel`), selected-listing card (custom actions for save / close / tap body). `PriceRangeSlider` still correctly implements `.accessibilityAdjustableAction`.

Known gaps:

- `AuthSheetPlaceholderView` — the hero `person.crop.circle.badge.checkmark` icon (`AuthSheetPlaceholderView.swift:12`) has no `.accessibilityHidden(true)`.
- `ComingSoonView` (`MainTabView.swift:67–86`) — the `hammer` icon isn't hidden from VoiceOver.
- `EmptyStateView` — icon disc (`EmptyStateView.swift:30–37`) has no `.accessibilityHidden`; VoiceOver will read the SF Symbol name.
- `ErrorStateView` — `exclamationmark` icon disc (`ErrorStateView.swift:9–16`) has no `.accessibilityHidden`.
- `ListingDetailPlaceholderView` — no accessibility overrides (acceptable for a placeholder).
- `FilterSheetView` — individual filter chips, date pills, stepper glyphs, and price-range thumbs rely on native control semantics; only `clearAllButton` has an explicit label.
- `searchBar` (`DiscoveryView.swift:179–195`) is explicitly `accessibilityHidden(true)` because search isn't functional in v1 — that's a deliberate choice, not a gap.

`.accessibilityHint` is used only twice (`SelectedListingCard.swift:51` "Opens listing details"). Hints remain underused.

Dynamic Type: two views observe `@Environment(\.dynamicTypeSize)` — `ListingCardView.swift:21` (rail title line limit), `DiscoveryView.swift:13` (hides the fee tag at `.accessibility3+`). The filter sheet's `headerRow` also uses `ViewThatFits` (`FilterSheetView.swift:80`) to reflow to a stacked layout at large sizes, and `SelectedListingCard.priceLine` uses `ViewThatFits` (`SelectedListingCard.swift:181`) to stack the SOS line under the USD line when single-line doesn't fit.

## Localization coverage

**Still zero.** No `Localizable.xcstrings`, no `.strings`, no `LocalizedStringKey`, no `NSLocalizedString`, no `String(localized:)`. Every user-facing string is a Swift string literal.

Sample: `"Homes in \(city.rawValue)"`, `"Remove from saved"`, `"Any dates"`, `"Search Mogadishu, Hargeisa…"`, `"Coming soon"`, `"Show listings"`, `"No stays match your filters"`, `"Sign in to save"`, `"Continue"`, `"Cancel"`, `"Clear all"`, `"Prices include all fees"`, `"Try Again"`, `"No connection"`.

Intent doc scoped V1 to English UI, with "Somali greetings, confirmations, and cultural flavor throughout" and "full Somali localization in v1.1". Today there is no scaffolding, so the V1.1 transition will touch every view file.

## Dark mode

One `.preferredColorScheme(.dark)` at `MainTabView.swift:63`. No other `colorScheme` checks. `DesignTokens.swift` colors are fixed dark-mode hex values — the app cannot adapt to system light mode. Matches intent.

## Drift from intent

Comparing `docs/DESIGN.previous.md` (the preserved intent spec) against the shipped code:

| Area                                               | Intent                                                                        | Reality                                                                                                                                                                                                                                                                                                            |
| -------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Verified badge                                     | Tinted green (`statusSuccess` bg at 15% + `#62F1C6` text)                     | `VerifiedBadgeView:11–34` uses `coreAccent` (cyan) checkmark on `surfaceDefault.opacity(0.65)` — not green, not a 15%-tinted fill. `statusSuccess` token remains **never used anywhere in code**.                                                                                                                 |
| Saved heart                                        | `statusDanger` (pink) filled, everywhere                                      | ✅ **Resolved.** `FavoriteHeartButton.swift:51` is now the single source for heart tint, and every save-site uses it — full / rail / compact / mapPreview variants of `ListingCardView`, and `SelectedListingCard.hero`.                                                                                          |
| Shadows                                            | "No card shadows" + listed `sm/lg` tokens                                     | 5 shadow call sites, all with inline `Color.black.opacity(0.25–0.35)` — no shadow token. Most shadows are on floating/elevated elements (tab bar, selected card, price pins, heart disc, map-skeleton pins) where shadows are defensible, but the "no card shadows" rule isn't consistent.                         |
| Button styles                                      | Primary / Secondary / Ghost / Destructive as named styles                     | ✅ **Primary & Ghost resolved.** `PrimaryButtonStyle` + `GhostButtonStyle` live in `Buttons.swift`. Secondary and Destructive styles are not yet defined; no caller needs them yet, so this is latent not broken.                                                                                                 |
| Skeleton                                           | "Static skeleton shapes (no shimmer animation)"                               | `SkeletonListingCard`, `SkeletonHeader`, and the map's `LoadingPinSkeletons` are all static — matches intent.                                                                                                                                                                                                      |
| Icon stroke weights                                | "1.5pt inactive, 2pt active" tab bar                                          | SF Symbols don't offer a 1.5pt stroke — tab bar uses `.regular` vs `.semibold` as a proxy (`FloatingTabView.swift:150,154`). Close-enough approximation; can't achieve the spec literally with SF Symbols.                                                                                                         |
| `textTertiary` contrast tweak                      | "#95A0AE" for 5:1 on canvas                                                   | Token matches. ✅                                                                                                                                                                                                                                                                                                   |
| Message bubble component                           | Specified sent/received                                                       | Not shipped (messaging feature not built). Out of scope.                                                                                                                                                                                                                                                           |
| Status badges (Confirmed/Pending/Declined)         | Tinted pill with colored text                                                 | Not yet needed; `VerifiedBadgeView` is the only "status-style" component today and it doesn't follow the 15%-tinted-background pattern.                                                                                                                                                                           |
| `.tint()`                                          | —                                                                             | Used once in `FilterSheetView.swift:204` on the graphical `DatePicker`. Otherwise every accent tint is applied via `.foregroundStyle(Color.coreAccent)` directly. `AccentColor.colorset` is still an empty asset.                                                                                                 |
| `corePrimary`, `statusSuccess`, `starEmpty` tokens | Defined for specific use cases                                                | **Dead tokens** — zero view-file references (unchanged since last audit).                                                                                                                                                                                                                                         |
| Localization                                       | V1 English-only, scaffold planned for V1.1 Somali                             | No scaffolding in place — every string is a hardcoded literal (unchanged since last audit).                                                                                                                                                                                                                       |
| Reduce Motion                                      | "All animations wrapped in `@Environment(\.accessibilityReduceMotion)` check" | Honored in 2 of 7 animation call sites (unchanged since last audit).                                                                                                                                                                                                                                              |
| Filter-icon consistency                            | —                                                                             | List-mode uses `line.3.horizontal.decrease` (`DiscoveryView.swift:165`); map-mode uses `slider.horizontal.3` (`DiscoveryHeaderPill.swift:22`). Two glyphs for the same "open filters" action.                                                                                                                     |

## Inconsistencies found

1. **Shadows are still improvised.** Five distinct parameterizations across five files:
   - `black.opacity(0.25), radius 4, y 1` — `FavoriteHeartButton.swift:60`
   - `black.opacity(0.25), radius 4, y 2` — `ListingPricePin.swift:28`, `ListingMapView.swift:134` (skeleton pins)
   - `black.opacity(0.3), radius 8, y 2` — `FloatingTabView.swift:136`
   - `black.opacity(0.35), radius 16, y 6` — `SelectedListingCard.swift:43`
   No shadow tokens exist in `DesignTokens.swift`. Define `Shadow.elevation1/2/3` and replace the inline calls.
2. **Six distinct animation curves with no shared motion tokens.** `.default` (2×), `.easeInOut(0.25)`, `.smooth(0.35, extraBounce 0)`, `.easeOut(0.2)`, `.spring(0.45, 0.85)`, `.spring(0.35, 0.85)`. Intent spec called for `.spring(0.3, 0.7)` + `.easeInOut`. Define `Motion.standard`, `Motion.emphasized`, `Motion.bounce` (or similar) and route callers through them — that also makes the Reduce Motion retrofit a one-line change everywhere motion tokens are applied.
3. **Reduce Motion is honored in 2 of 7 animation sites.** Only `SelectedListingCard` and `ListingPricePin` check the environment. `FloatingTabView` (two animations), `DiscoveryView` (two `.default` animations + three `.transition(.opacity)` calls) animate regardless.
4. **The 48pt circle icon button is still duplicated.** `DiscoveryView.iconButton:197–207` and `DiscoveryHeaderPill.circularIconButton:53–67` reconstruct the same 48pt `surfaceElevated` circle, `textPrimary` glyph at `17 semibold`. Extract a `CircleIconButton(systemName:label:size:action:)` (variants: `.plain` → surfaceElevated, `.glass` → ultraThinMaterial scrim for `SelectedListingCard.closeButton:221`).
5. **Glass disc chrome — 1 inline copy remains.** `SelectedListingCard.closeButton:221–232` + `glassBackground:236–240` rebuild the glass-over-scrim disc that `FavoriteHeartButton` has already proven. Either generalize `FavoriteHeartButton`'s disc into a standalone `GlassIconButton` background and compose the heart/close glyph on top, or factor out a `GlassCircleBackground` `ViewModifier`.
6. **Capsule button chrome is reconstructed.** `CityChipView` (extracted) vs. `FilterSheetView.cityButton:117–130` vs. `FilterSheetView.datePill:167–178` — three near-identical capsule-pill implementations. `CityChipView` could take a `fillWidth: Bool` parameter and absorb the other two.
7. **Verified badge drift from spec.** `VerifiedBadgeView.swift:11–34` uses `coreAccent` + 65%-opacity `surfaceDefault`, not `statusSuccess` + 15% tint. `statusSuccess` is defined but unused. Either update the spec to match shipped behavior, or re-theme the badge to green.
8. **Two glyphs for "open filters".** `line.3.horizontal.decrease` in list mode (`DiscoveryView.swift:165`) and `slider.horizontal.3` in map mode (`DiscoveryHeaderPill.swift:22`). Same action; one glyph is enough.
9. **Inline padding literals inside `ListingCardView.fullCard`.** Uses `14`, `10`, `6`, `12` (`ListingCardView.swift:54,64,75,78,80,81`) — none of which are in the `Spacing` scale. Intent doc specifies "12–14pt card content padding"; codify `Spacing.cardPadding = 14` so `SkeletonListingCard` and the real card track together.
10. **Off-scale `Spacing.sm + 1` (5pt) in `VerifiedBadgeView.swift:23`.** One-off manual contrast tweak that isn't in the spacing scale.
11. **Dead tokens.** `Color.corePrimary`, `Color.statusSuccess`, `Color.starEmpty` defined in `DesignTokens.swift` but zero view-file references. Either wire them up (Verified badge → `statusSuccess`; empty-star outlines in `ratingRow` → `starEmpty`) or delete them.
12. **Empty `AccentColor.colorset`.** No color defined. `.tint(…)` is called once (`FilterSheetView.swift:204`) and passes `Color.coreAccent` explicitly, so the empty asset is inert. Either populate it with `coreAccent` and wire `.tint(.coreAccent)` at the root scene, or delete the asset to make the absence intentional.
13. **No `IconSize` token.** `17 semibold` (2 files), `11 semibold` (2 files), `16 semibold` (2 files, though with different contexts), and a scatter of one-offs. Not hurting anyone today but a small `IconSize.button / .inline / .hero` helper would retire the remaining `.font(.system(size:))` inline escapes for SF Symbols.
14. **No localization at all.** Every string is an inline literal across 22 view files. V1.1 Somali will require a mass `Localizable.xcstrings` migration.

## Recommended cleanups

1. **Add motion and shadow tokens, then retrofit callers.** `Motion.standard = .spring(response: 0.3, dampingFraction: 0.7)`, `Motion.quick = .easeOut(duration: 0.2)`, `Shadow.elevation1 = (.black.opacity(0.25), radius: 4, y: 2)`, `Shadow.elevation2 = …`. Replace the 5 inline shadow tuples and 6 inline animation curves. Side effect: makes the Reduce Motion rollout a one-line change inside `Motion.wrap(value:)` or similar, instead of 5+ patches to individual callers.
2. **Extract a `CircleIconButton`** and fold in the two list-mode/header-pill duplications plus the `SelectedListingCard.closeButton` glass variant. Keeps glyph sizing (`17 semibold`) in one place and lets future screens (Saved, Bookings) adopt the same back/filters/close affordances instantly.
3. **Codify `Spacing.cardPadding = 14` (or add it as a scale step) and replace the `14 / 10 / 6 / 12` stack inside `ListingCardView.fullCard`.** Collapses a repeated-literal cluster and aligns the skeleton card's paddings with the real card.
4. **Scaffold `Localizable.xcstrings` now and migrate Discovery first.** Discovery is the entire shipped V1 surface (~90 user-facing strings counting header copy, filter labels, empty/error states, accessibility labels). Migrating before Auth + Detail + Booking + Messaging ship is far cheaper than after.
5. **Decide the Verified badge color once.** Either update `VerifiedBadgeView.swift` to use `statusSuccess` (aligning with spec, giving the unused token a job) or update the intent doc in `docs/DESIGN.previous.md` and this audit's "Drift" table to acknowledge cyan-on-glass as the real direction.

---

## Summary

**What changed since the previous audit (2026-04-19):** `Buttons.swift` now hosts `PrimaryButtonStyle` + `GhostButtonStyle`, and all four primary CTAs (`EmptyStateView`, `ErrorStateView`, `FilterSheetView.applyButton`, `AuthSheetPlaceholderView`) plus two ghost CTAs route through them. `FavoriteHeartButton` replaced 3 inline glass-heart copies with one component, fixing the "pink vs. cyan saved heart" bug the previous audit called out. Accessibility coverage grew (37 → 41 modifier calls). The `dividerLine` token is now actually used. Discovery/map mode added `DiscoveryHeaderPill`, `SelectedListingCard`, `MapEmptyStatePill`, `FeeInclusionTag`, `ListingPricePin` as first-class extracted components.

**Top 3 remaining inconsistencies:**

1. **Motion is still improvisational.** Six distinct curves across six files, and Reduce Motion is honored in 2 of 7 animation sites. The spec called for `.spring(0.3, 0.7)` + `.easeInOut`; reality is a grab bag.
2. **Shadows are tuple literals, not tokens.** Five different `(opacity, radius, y)` combos across five files, with no shadow tokens in `DesignTokens.swift`.
3. **The 48pt circle icon button is duplicated twice** (`DiscoveryView.iconButton`, `DiscoveryHeaderPill.circularIconButton`), and the glass variant is a third copy inside `SelectedListingCard.closeButton`. With heart + CTA chrome now unified, this is the next-most-visible extraction candidate.

**Most impactful cleanup to do first:** define `Motion` + `Shadow` token groups in `DesignTokens.swift` and retrofit the 5+6 call sites. Unlike the button/heart extractions, this doesn't change what the app looks like — but it locks motion/elevation behavior in one place before Auth, Listing Detail, and Booking add another dozen animation/shadow sites.

*Audit completed 2026-04-19. Intent doc preserved at `docs/DESIGN.previous.md` (left untouched — this audit did not overwrite it, since the prior audit already set it up as the permanent intent reference).*
