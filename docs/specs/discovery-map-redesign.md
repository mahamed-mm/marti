# Feature Spec: Discovery Map Redesign (Airbnb-style restructure)

- **Status:** Complete
- **Priority:** P1
- **PRD reference:** Feature 1 — Listing Discovery (post-ship UI refinement)
- **Last updated:** 2026-04-18

## Overview

The Discovery map view is functional but visually sparse and structurally dated compared to leading rental marketplace UIs. This spec restructures the Discover → Map experience to match the information density and hierarchy of modern marketplace apps (e.g. Airbnb) while **preserving Marti's existing dark navy + cyan visual language**. The work introduces five new UI primitives — a header context pill, refreshed per-listing price pins, a dismissible "prices include all fees" tag, a rich selected-listing bottom card, and a compact empty-state pill — and refactors `DiscoveryView` / `ListingMapView` to compose them. No backend, model, or service changes are required.

## User Stories

1. As a traveler, I want to see the current city and filter summary at a glance so I know what I'm browsing without re-opening filters.
2. As a traveler, I want every listing to show its price on the map so I can compare locations and budgets visually.
3. As a traveler, I want to tap a price pin and immediately see a rich card for that listing so I can decide to open it without leaving the map.
4. As a traveler, I want to know that the displayed prices include all fees so I'm not surprised at checkout.
5. As a traveler, I want the map to tell me when no listings match my filters so I can adjust them without wondering if the map is loading.

## Acceptance Criteria

- [ ] AC1: Map-mode top bar replaces the current search-field + two-icon layout with: circular back/close (left), centered two-line pill showing `headerTitle` + `headerSubtitle` (center), circular tune icon (right) that opens the existing `FilterSheetView`.
- [ ] AC2: The inline `CityChipView` row (currently rendered by `DiscoveryView` in map mode) is removed. City selection stays in `FilterSheetView` where it already lives.
- [ ] AC3: Price pins get a styling pass — the per-listing `MapViewAnnotation` continues to render for every `viewModel.listings` entry (already implemented), but each pin now uses a capsule label with `$price/night` typography, `Color.surfaceDefault` + `Color.textPrimary` unselected, `Color.coreAccent` fill + `Color.canvas` text when selected, and an elevated z-order on the selected pin.
- [ ] AC4: Tapping a price pin calls `viewModel.selectPin(listing.id)` (existing API), elevates that pin, and presents the new `SelectedListingCard` anchored above `FloatingTabView`.
- [ ] AC5: Pins keep `.allowOverlap(true)` (already set). Clustering is **out of scope for v1** — the Mapbox v11 SwiftUI `MapViewAnnotation` API does not natively cluster, and the imperative `PointAnnotationManager` does not compose cleanly with the declarative map. Density handling is tracked as a follow-up.
- [ ] AC6: A floating `FeeInclusionTag` chip ("Prices include all fees") appears above the selected-listing card (or pinned above the tab bar when no selection). Tapping its close affordance dismisses it for the current session.
- [ ] AC7: `SelectedListingCard` shows: paging photo `TabView` with dim page dots, heart + close circular glass buttons (top-right), title, subtitle (neighborhood / property type), optional date range, star rating + review count, and dual-currency price line. The "Host favorite" badge is **out of scope for v1** (the `is_host_favorite` column does not yet exist on `listings`; see Open Questions).
- [ ] AC8: `SelectedListingCard` dismisses on swipe-down gesture and on tapping the close button. Tapping the card body pushes `ListingDetailView`.
- [ ] AC9: When listings are loading, the map shows skeleton pill pins (navy with shimmer). When no listings match filters, a compact `MapEmptyStatePill` appears in place of the selected card: "No stays match your filters · Adjust filters".
- [ ] AC10: All new surfaces respect the iOS 26 `FloatingTabView` safe-area workaround. Nothing is clipped behind the tab bar.
- [ ] AC11: No hardcoded colors, spacing, radii, or fonts — every value comes from `DesignTokens` (`Color.surfaceDefault`, `Color.surfaceElevated`, `Color.coreAccent`, `Spacing.*`, `Radius.*`, `Font.marti*`).
- [ ] AC12: Every circular button and pin has an `.accessibilityLabel`. Pins keep the existing `"Listing for $X per night"` announcement so the VoiceOver experience does not regress. Layout remains readable at AX5.
- [ ] AC13: No new SPM dependencies are added.
- [ ] AC14: Dark mode only — no light-mode variants are added or required.

## Technical Design

### Models

**No model changes.** Uses existing `Listing` (SwiftData `@Model`) and `ListingDTO`.

The draft previously proposed adding `isHostFavorite: Bool` to drive a "Host favorite" badge. The `is_host_favorite` column does not yet exist on the Supabase `listings` table, so this field is deferred and the badge is dropped from v1 scope.

### Services

**No service changes.** `ListingService`, `LiveCurrencyService`, `CachedImageService`, and `AuthManager` are unchanged. Price formatting continues to use `LiveCurrencyService.format(sos:display:)` (static).

### ViewModel Responsibilities

**`ListingDiscoveryViewModel`** — additions only. No removals of existing state.

Existing state that this feature reuses as-is:

- `selectedPinID: UUID?` — already the source of truth for selection (`ListingDiscoveryViewModel.swift:25`).
- `selectPin(_ id: UUID?)` — existing action called on pin tap and card dismiss.
- `filter: ListingFilter`, `listings: [Listing]`, `applyFilter()`, `clearFilters()` — unchanged.
- `viewMode: ViewMode`, `setViewMode(_:)` — unchanged.

New state:

```
feeTagDismissed: Bool                  // Session-scoped dismissal of FeeInclusionTag (default false)
headerTitle: String (computed)         // e.g. "Homes in Mogadishu" or "Homes across Somalia"
headerSubtitle: String (computed)      // e.g. "Any dates · 1 guest" or "Dec 17–24 · 2 guests"
selectedListing: Listing? (computed)   // Looks up `selectedPinID` in `listings`; nil if no match
```

New actions:

```
dismissFeeTag()                        // Flips feeTagDismissed = true for session
```

Behavior:

- `headerTitle` derives from `filter.city`: `"Homes in \(city.displayName)"` or `"Homes across Somalia"` when `city == nil`.
- `headerSubtitle` derives from `filter.checkIn/checkOut` and `filter.guestCount`. Format: `"\(dateLabel) · \(guestCount) guest(s)"`. `dateLabel` is `"Any dates"` when either date is nil.
- `feeTagDismissed` is **not** persisted to `UserDefaults` — resets each app launch.
- When `applyFilter()` or `loadListings()` produces a `listings` array that no longer contains `selectedPinID`, the ViewModel must call `selectPin(nil)` to auto-dismiss the card.
- `selectedListing` is derived — no parallel state, no risk of drift.

### Views

**New files — all under `Views/Discovery/Components/` (subdirectory to be created)**

| File | Purpose |
|---|---|
| `DiscoveryHeaderPill.swift` | Two-line centered pill with back + tune buttons |
| `ListingPricePin.swift` | Per-listing price annotation with selected/unselected states (extracted from the current `pricePin(for:)` helper in `ListingMapView`) |
| `FeeInclusionTag.swift` | Dismissible "Prices include all fees" chip |
| `SelectedListingCard.swift` | Rich bottom card for the tapped listing (replaces the current `.sheet` preview) |
| `MapEmptyStatePill.swift` | Compact empty state for zero-match filters |

**Modified files**

| File | Change |
|---|---|
| `Views/Discovery/DiscoveryView.swift` | Remove inline `CityChipView` row in map mode. In map mode, compose `DiscoveryHeaderPill` over the map, plus `FeeInclusionTag` + `SelectedListingCard` / `MapEmptyStatePill` anchored above `FloatingTabView`. |
| `Views/Discovery/ListingMapView.swift` | Remove the `.sheet` presentation block (`ListingMapView.swift:21-32`) and the `.hideFloatingTabBar(...)` modifier. Replace the inline `pricePin(for:)` helper with `ListingPricePin`. Tap handlers still call `viewModel.selectPin(listing.id)` / `selectPin(nil)`. |
| `ViewModels/ListingDiscoveryViewModel.swift` | Add `feeTagDismissed`, `headerTitle`, `headerSubtitle`, `selectedListing` (computed), `dismissFeeTag()`. Add selection auto-clear logic in `applyFilter()` and after `loadListings()` completes. |

**No changes** to `ListingCardView`, `FloatingTabView`, `ListingListView`, `FilterSheetView`, services, or models. `CityChipView` stays in the shared layer; only its inline usage in `DiscoveryView`'s map-mode header is removed.

### Navigation

```
DiscoveryView (map mode)
├── Tap header pill title → no-op (future: city picker)
├── Tap tune icon → present FilterSheetView (.sheet) — unchanged
├── Tap price pin → viewModel.selectPin(id) → SelectedListingCard appears
├── Swipe down on SelectedListingCard → viewModel.selectPin(nil)
├── Tap close on SelectedListingCard → viewModel.selectPin(nil)
├── Tap card body → push ListingDetailView (existing)
├── Tap empty map → viewModel.selectPin(nil) (existing)
└── Tap close on FeeInclusionTag → viewModel.dismissFeeTag()
```

### Dependencies

- No new SPM packages.
- Depends on existing `DesignTokens`, `LiveCurrencyService`, `CachedImageService`, and the Mapbox v11 SwiftUI declarative annotation API.

## UI/UX

### Design Reference

Inspiration: Airbnb map view (full-screen map, centered header pill, price pins, fee-inclusion tag, selected-listing bottom card). Visual tokens remain 100% Marti — use only what `DesignTokens.swift` already exposes:

- **Surfaces:** `Color.surfaceDefault` (pin base, card base), `Color.surfaceElevated` (pill, fee tag, empty-state pill), `Color.surfaceHighlight` (image placeholder), `Color.canvas` (page bg, selected-pin text).
- **Accent:** `Color.coreAccent` (selected pin fill, heart-saved state).
- **Text:** `Color.textPrimary`, `Color.textSecondary`, `Color.textTertiary`.
- **Strokes:** `Color.dividerLine` for 0.5pt capsule hairlines.
- **Radii:** capsule pills use `Radius.full`; the selected-listing card uses `Radius.lg` (24pt).
- **Typography:** `Font.martiLabel2` for pin price, `Font.martiHeading5` / `Font.martiBody` / `Font.martiFootnote` / `Font.martiCaption` for card content.

### Key Interactions

- **Header pill:** Title/subtitle are non-interactive in v1 (future: inline city/date editors). Back button dismisses map mode or returns to list. Tune icon opens the filter sheet.
- **Price pin tap:** Haptic `selectionChanged`. Pin animates fill from `surfaceDefault` → `coreAccent` (0.2s ease-out). Camera does NOT auto-pan — the user stays where they are.
- **Selected card entrance:** Slides up from bottom with spring response 0.45, damping 0.85. Respects `accessibilityReduceMotion` — falls back to fade.
- **Card swipe-down dismiss:** Threshold 80pt or velocity > 600pt/s. Below threshold, springs back.
- **Fee tag dismiss:** Close affordance is a small `xmark` on the trailing side of the pill. Tap-target is 44pt minimum even if the visible icon is smaller.
- **Empty state pill:** Replaces the selected-card anchor when the listings array is empty. Tapping it opens the filter sheet.

### Layout Notes

- Header pill sits in the top safe area with a 12pt top inset.
- Fee tag floats 12pt above the selected card. When no card is visible, the fee tag pins to 16pt above the floating tab bar.
- Selected card bottom edge sits 8pt above the floating tab bar's top edge. `FloatingTabView` measures its own height via `onGeometryChange` and passes it into the content closure — use that measurement to anchor, don't hardcode.

## Edge Cases

1. **Pin overlap with city labels or other pins** → Selected pin gets a z-order bump. Clustering is deferred (see AC5); overlap is accepted in v1.
2. **Listing has no photos** → `SelectedListingCard` hero shows `Color.surfaceHighlight` placeholder with an image SF Symbol.
3. **Listing has no rating** → Hide the star + count row entirely. Do not render "No ratings".
4. **SOS rate unavailable** → Price line collapses to USD only. No stale SOS is shown.
5. **User rotates device** → Card and pill widths adapt via `.frame(maxWidth: 520)` on regular-width size classes.
6. **Selected listing removed from results** (e.g. filter change) → ViewModel auto-calls `selectPin(nil)` when `selectedPinID` no longer resolves against `listings`. Card dismisses automatically.
7. **Rapid pin tapping** → Selection state is the latest tap. Card animates a subtle crossfade when the backing listing changes.
8. **Fee tag already dismissed** → On next selection, the tag stays hidden for the rest of the session.
9. **Listings array empty but not errored** → Show `MapEmptyStatePill`, hide pins, hide fee tag.
10. **Network error while loading** → Existing error state in list mode continues to apply. On the map, show a small inline retry pill anchored where the empty state would be.
11. **Swipe-down during card photo pager swipe** → Card drag gesture should coexist with the horizontal `TabView` by using `simultaneousGesture` and directional filtering.
12. **VoiceOver** → Pins keep the existing `"Listing for $X per night"` announcement. The card announces its full contents as one grouped element with a separate action for "Save".
13. **Reduce Motion** → Card slide-up becomes a fade. Pin fill change is instantaneous.
14. **Dynamic Type AX5** → Card content wraps and grows. Header pill title truncates with `.lineLimit(1)`, subtitle with `.lineLimit(1)`.

## Testing Plan

### ViewModel Unit Tests (Swift Testing)

Mirror the existing pattern in `ListingDiscoveryViewModelTests` — `@MainActor struct`, `@Test` functions, handler-closure mocks (`MockListingService.fetchHandler`), `#expect(...)` assertions, factory helper `makeViewModel(service:currency:auth:pageSize:debounce:)`.

- `test_headerTitle_whenCityNil_returnsAcrossSomalia`
- `test_headerTitle_whenCitySet_returnsHomesInCity`
- `test_headerSubtitle_withoutDates_returnsAnyDates`
- `test_headerSubtitle_withDates_formatsDateRange`
- `test_headerSubtitle_formatsGuestCount_singleAndPlural`
- `test_selectedListing_resolvesFromSelectedPinID`
- `test_selectedListing_nilWhenPinIDMissingFromListings`
- `test_selectPin_clearsWhenListingNotInCurrentResults` — set `selectedPinID`, apply a filter that removes that listing, expect `selectedPinID` to become nil after `applyFilter()` settles
- `test_dismissFeeTag_flipsFeeTagDismissed`
- `test_feeTagDismissed_doesNotPersistAcrossInstances`
- `test_selectionSurvives_refreshThatStillContainsListing`

### Service Tests

None. No service changes.

### Manual Test Scenarios

- [ ] Open Discover → Map → header pill shows "Homes across Somalia · Any dates · 1 guest"
- [ ] Tap tune icon → filter sheet opens; city buttons work
- [ ] Select Mogadishu in the filter sheet → map refreshes, header updates to "Homes in Mogadishu"
- [ ] Confirm price pins appear for every listing (not just one), styled as capsules
- [ ] Tap a pin → pin turns cyan, `SelectedListingCard` slides up
- [ ] Confirm "Prices include all fees" tag is visible above the card
- [ ] Tap the fee tag close → it disappears
- [ ] Swipe the card down → it dismisses
- [ ] Tap a different pin → new card appears, fee tag stays dismissed
- [ ] Apply filters that return zero listings → `MapEmptyStatePill` appears, pins disappear
- [ ] With a card open, change filters so the selected listing is no longer in the results → card auto-dismisses
- [ ] Kill app, relaunch → fee tag reappears (session-only dismissal)
- [ ] AX5 Dynamic Type → layout wraps cleanly, tab bar still visible
- [ ] VoiceOver → pin announces `"Listing for $X per night"`, card and header announce correctly
- [ ] Reduce Motion → no slide animations on card or pin

## Decisions

- **Header pill title is non-interactive in v1.** Inline city/date editing from the pill is deferred to v2. Filters stay the single entry point via the tune icon.
- **Fee-tag dismissal is session-only** — not persisted to `UserDefaults`. On relaunch the tag reappears. This matches the draft and keeps the reminder useful for infrequent users without punishing first-time viewers forever.
- **"Host favorite" badge is out of scope.** `is_host_favorite` is not in the Supabase `listings` table or `ListingDTO` today. When the column lands, file a follow-up spec to add it to `ListingDTO`, map it into `Listing`, and re-introduce the badge on `SelectedListingCard`.
- **Clustering is deferred.** Revisit only if user telemetry shows real occlusion complaints — Mogadishu + Hargeisa inventory in v1 is small enough that `.allowOverlap(true)` is acceptable. The follow-up would evaluate whether to drop down to Mapbox's imperative `PointAnnotationManager` or cluster Swift-side before feeding annotations to the map.

---

*Generated from PRD Feature 1 (post-ship UI refinement pass) and Airbnb map-view structural reference. Preserves all Marti visual tokens; aligned with the current `ListingDiscoveryViewModel`, `ListingMapView`, `DiscoveryView`, and `DesignTokens` implementation.*
