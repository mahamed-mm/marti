# Tasks: Discovery Map Redesign

- **Spec:** `docs/specs/discovery-map-redesign.md`
- **Status:** Complete
- **Started:** 2026-04-18
- **Finished:** 2026-04-18

## Progress

- Total steps: 9
- Completed: 9
- Currently working on: —

## Ordering rationale

No model or service changes are in scope, so work flows:
**ViewModel first → extract existing pin primitive → build each new leaf component in isolation → wire them into `ListingMapView` and `DiscoveryView` → validation pass.**
Each leaf component (steps 3–6) is independent and can be reordered if a session gets blocked.

## Steps

### Step 1: ViewModel — header/fee-tag state + selection auto-clear

Add computed header strings, session-scoped fee-tag dismissal, a computed `selectedListing`, and make selection auto-clear when a filter/refresh drops the pin.

- [x] Add `feeTagDismissed: Bool = false` to `ListingDiscoveryViewModel`
- [x] Add `dismissFeeTag()` action
- [x] Add `headerTitle: String` computed from `filter.city` (`"Homes in \(city.rawValue)"` / `"Homes across Somalia"`)
- [x] Add `headerSubtitle: String` computed from `filter.checkIn/checkOut` + `filter.guestCount` — `"Any dates"` when either date nil, singular/plural `guest`/`guests`
- [x] Add `selectedListing: Listing?` computed — looks up `selectedPinID` in `listings`, returns nil on miss
- [x] After `loadListings()` completes, call `selectPin(nil)` when `selectedPinID` no longer resolves in the new `listings` array (covers `applyFilter()` + `refresh()` transitively via the shared path)
- [x] Tests written (12 new; all pass):
  - `headerTitle_whenCityNil_returnsAcrossSomalia`
  - `headerTitle_whenCitySet_returnsHomesInCity`
  - `headerSubtitle_withoutDates_returnsAnyDates`
  - `headerSubtitle_withOnlyOneDate_returnsAnyDates`
  - `headerSubtitle_withDates_formatsDateRange`
  - `headerSubtitle_formatsGuestCount_singleAndPlural`
  - `selectedListing_resolvesFromSelectedPinID`
  - `selectedListing_nilWhenPinIDMissingFromListings`
  - `selectPin_clearsWhenListingNotInCurrentResults`
  - `selectionSurvives_refreshThatStillContainsListing`
  - `dismissFeeTag_flipsFeeTagDismissed`
  - `feeTagDismissed_doesNotPersistAcrossInstances`
- [x] Build passes

**Notes:** `City` has no `displayName` — used `rawValue` (already `"Mogadishu"`/`"Hargeisa"`). Date-range subtitle uses POSIX-locale `DateFormatter` with `"MMM d"` on each end joined by ` – ` for deterministic, locale-stable output. Auto-clear is centralized in a private `clearSelectionIfStale()` called at the end of `loadListings()` so it runs for both success and offline-cached paths. `feeTagDismissed` is NOT persisted — pure instance state.

---

### Step 2: Extract `ListingPricePin` component (refactor, no behavior change)

Move the inline `pricePin(for:)` helper out of `ListingMapView` into its own component under `Views/Discovery/Components/ListingPricePin.swift`. Pure move + API tightening — no visual or behavioral changes. Lets the next steps iterate on styling without touching `ListingMapView`.

- [x] Create `Views/Discovery/Components/` directory
- [x] Create `ListingPricePin.swift` taking `(listing: Listing, isSelected: Bool)`
- [x] Preserve current styling (`Color.surfaceDefault` / `Color.coreAccent`, `Capsule()`, `Color.dividerLine` stroke, shadow, 44pt min hit target, `"Listing for $X per night"` accessibility label)
- [x] Update `ListingMapView` to instantiate `ListingPricePin` inside the existing `MapViewAnnotation`
- [x] Build passes
- [x] No new tests required (pure view, already exercised by manual map testing)

**Notes:** Pure extraction — styling is byte-identical to the former inline helper. Project uses `PBXFileSystemSynchronizedRootGroup`, so the new file under `marti/Views/Discovery/Components/` is auto-discovered; no pbxproj edit needed. Observed pre-existing debounce-timing flakiness in `filterBy*` and `rapidFilterChanges` ViewModel tests when the full `MartiTests` target runs under simulator contention — passes cleanly when the `ListingDiscoveryViewModelTests` class runs in isolation. Unrelated to this refactor; worth stabilizing the debounce timings (raise the 40ms wait or use a clock abstraction) in a separate hygiene task.

---

### Step 3: Build `DiscoveryHeaderPill` component

Two-line centered pill with circular back + tune buttons flanking it.

- [x] Create `Views/Discovery/Components/DiscoveryHeaderPill.swift`
- [x] API: `(title: String, subtitle: String, backLabel = "Close map view", tuneLabel = "Filters", onBack, onTune)` — labels parameterized with sensible defaults so the component isn't locked into one navigation semantic
- [x] Back button: SF Symbol `chevron.left`, circular, `Color.surfaceElevated`, **48pt** (matches existing `iconButton` helper in `DiscoveryView.swift:102`)
- [x] Tune button: SF Symbol `slider.horizontal.3`, same treatment
- [x] Pill body: `Color.surfaceElevated`, `Capsule()` (equivalent to `Radius.full`), two stacked `Text` views — `Font.martiLabel1` title (`Color.textPrimary`), `Font.martiFootnote` subtitle (`Color.textSecondary`)
- [x] `.lineLimit(1) + .truncationMode(.tail) + .allowsTightening(true) + .minimumScaleFactor(0.9)` on both lines — tightens before truncating at large Dynamic Type
- [x] `.accessibilityLabel` on each button (default "Close map view" / "Filters")
- [x] Top inset NOT set inside the component (caller owns safe-area padding) — composed in step 8
- [x] `.frame(maxWidth: 520)` so the pill doesn't stretch on regular width
- [x] Build passes
- [x] HIG-reviewed — ran `hig-reviewer`; issues addressed: Dynamic Type tightening, `.isHeader` trait on the combined pill element, clearer back button label, bumped inter-line spacing from `xs`→`sm`. Deferred: a global custom `ButtonStyle` for press feedback (app-wide convention is `.plain`; changing only this component would look inconsistent — worth a separate hygiene pass).

**Notes:** Pill title/subtitle are non-interactive in v1 (see spec Decisions). Wire `onTune` to `viewModel.isFilterSheetPresented = true` and `onBack` to `viewModel.setViewMode(.list)` in step 8. Three `#Preview` blocks included: default copy, date-range state, and long-title truncation case.

---

### Step 4: Build `FeeInclusionTag` component

Dismissible "Prices include all fees" chip with a close affordance.

- [x] Create `Views/Discovery/Components/FeeInclusionTag.swift`
- [x] API: `(onDismiss: () -> Void)`
- [x] `Color.surfaceElevated` background, `Capsule()` (≡ `Radius.full`)
- [x] `Font.martiFootnote`, `Color.textPrimary` on the label
- [x] Trailing `xmark` button: 11pt semibold icon inside 44×44 tap frame with `.contentShape(Rectangle())` to guarantee the whole frame is hit-testable; tint `Color.textSecondary` so the dismiss affordance reads secondary
- [x] `.accessibilityLabel("Prices include all fees. Dismiss.")` on the button; visible `Text` is `.accessibilityHidden(true)` so VoiceOver sees a single combined element
- [x] Build passes
- [x] HIG verified inline — tap target 44×44 ✓, contrast AAA/AA ✓, single VoiceOver element ✓, stateless (no `@State`)

**Notes:** Caller hides the view when `viewModel.feeTagDismissed == true`. Two previews: standalone, and "in context" above a stub card placeholder so Step 8 composition spacing is easy to eyeball.

---

### Step 5: Build `MapEmptyStatePill` component

Compact empty-state pill shown when `listings.isEmpty` and not loading/errored.

- [x] Create `Views/Discovery/Components/MapEmptyStatePill.swift`
- [x] API: `(onAdjust: () -> Void)`
- [x] Copy: `"No stays match your filters · Adjust filters"` (three `Text` segments so the CTA can be accented independently of the message)
- [x] `Color.surfaceElevated` fill, `Capsule()` shape, `Font.martiFootnote`
- [x] Whole pill is a `Button(action: onAdjust)` with `.buttonStyle(.plain)`, `minHeight: 44` tap target, `maxWidth: 520` cap matching `DiscoveryHeaderPill`
- [x] `.accessibilityLabel("No stays match your filters. Adjust filters.")`
- [x] `.accessibilityAddTraits(.isButton)` (explicit, even though Buttons have it by default — matches spec)
- [x] Dynamic Type: `.lineLimit(1) + .truncationMode(.tail) + .allowsTightening(true) + .minimumScaleFactor(0.8)` so the pill tightens and scales before clipping at AX5
- [x] Build passes
- [x] HIG verified inline — tap target ✓, contrast AAA/AAA ✓, single VoiceOver element ✓, styling consistent with `FeeInclusionTag` and `DiscoveryHeaderPill`

**Notes:** "Adjust filters" rendered in `Color.coreAccent` to hint tappability while the whole pill is the button; dot separator rendered in `Color.textTertiary` so it doesn't compete with the primary message. Two previews: standalone, and "anchored above a stub tab bar" so Step 8 spacing can be eyeballed.

---

### Step 6: Build `SelectedListingCard` component

The rich bottom card for a tapped listing. Biggest single-file task in this feature.

- [x] Create `Views/Discovery/Components/SelectedListingCard.swift`
- [x] API: `(listing: Listing, isSaved: Bool, onTapCard, onToggleSave, onDismiss)`
- [x] Hero: paging `TabView(.page)` over `listing.photoURLs`; `indexDisplayMode` set to `.never` when ≤1 photo so the dot doesn't render for single-photo listings; `Color.surfaceHighlight` + `photo` SF Symbol placeholder when empty
- [x] Top-right overlay: heart (`Color.coreAccent` when saved per spec — deliberately diverges from `ListingCardView`'s `statusDanger`; noted in HIG review) + close (`xmark` 17pt medium), each 44pt tap targets with a dark scrim + `.ultraThinMaterial` glass background for contrast over arbitrary photos
- [x] Title (`martiHeading5`, lineLimit 2), subtitle `"\(neighborhood), \(city)"` (`martiFootnote`, `textSecondary`, lineLimit 1 tail). No `propertyType` field on `Listing` today — swapped to `city` which is the Airbnb-conventional "Hodan, Mogadishu" form.
- [x] Date-range row: `Listing` has no `checkIn/checkOut` fields → intentionally omitted (spec explicitly degrades here)
- [x] Rating row rendered only when `listing.averageRating != nil` (no "New" / "No ratings" fallback per spec)
- [x] Dual-currency price via injected `@Environment(\.currencyService)` — `usdToSOS(cents, display: .abbreviated)` returns nil when stale; collapses to USD only
- [x] Surface `Color.surfaceDefault`, `Radius.lg`, shadow y:6 r:16
- [x] `.frame(maxWidth: 520)` cap
- [x] Slide-up entrance: spring response 0.45, damping 0.85; `accessibilityReduceMotion` collapses both the entrance AND the drag spring-back to instant set
- [x] Swipe-down dismiss: 80pt / 600pt/s thresholds, axis-latch state so diagonal drags don't stutter between `TabView` paging and card drag; `.simultaneousGesture` keeps the photo pager working
- [x] `onTapCard` attached only to the `info` block (not the hero) so it never competes with the overlay buttons or the TabView
- [x] VoiceOver: `.accessibilityElement(children: .ignore)` + combined label + default action + "Save"/"Close preview" custom actions; heart + close are `.accessibilityHidden(true)` because they surface via the parent's custom actions; description includes SOS equivalent and photo count
- [x] Price row wrapped in `ViewThatFits` with a vertical-stack fallback so AX5 Dynamic Type stacks USD over SOS instead of truncating
- [x] Build passes
- [x] HIG-reviewed via `hig-reviewer`. Applied all P0/P1 + most P2 findings. Deferred: app-wide `.imageScale` migration for icon sizes, custom below-hero page dots, haptic-trigger refactor (these are all pre-existing app patterns, worth a separate hygiene pass).

**Notes:** "Host favorite" badge and date-range row remain out of scope (spec Decisions). Three `#Preview` blocks: default (rated + saved + photo), no-photo + no-rating, and long-title/dense-content (stresses AX5 + `ViewThatFits` fallback).

---

### Step 7: Refactor `ListingMapView` — remove sheet, wire selection callback, add skeleton pins

Strip the `.sheet` presentation and `.hideFloatingTabBar(...)` modifier, add loading-state pins, and expose a selection callback so `DiscoveryView` can compose the card above the tab bar.

- [x] Delete the `.sheet(isPresented: sheetIsPresented)` block and the `sheetIsPresented` / `selectedListing` / `sheetContent(for:)` helpers
- [x] Delete the `.hideFloatingTabBar(viewModel.selectedPinID != nil)` modifier — `hideFloatingTabBar` itself still lives on `FloatingTabView` for other callers; just removed the call site
- [x] Tap-on-empty-map still calls `viewModel.selectPin(nil)` (kept verbatim)
- [x] When `viewModel.isLoading && viewModel.listings.isEmpty && !loadFailed`, render 5 static capsule skeletons positioned in view-space (`GeometryReader` + `.position`) around the map center — not `MapViewAnnotation`s
- [x] Kept `.allowOverlap(true)` on every `MapViewAnnotation`
- [x] Preserved `recenter()` and `onMapLoadingError` / `mapFallback` behavior
- [x] Build passes
- [x] Skeletons `.accessibilityHidden(true)` + `.allowsHitTesting(false)`

**Notes:** Intentionally kept skeletons **static** (not animated/shimmer) to match the app's existing convention (`SkeletonListingCard`, `SkeletonHeader`). Reduce-motion concern is therefore moot — no motion to tone down. Fixed skeleton positions are deterministic so the pattern doesn't jump across re-renders. Extracted as a private `LoadingPinSkeletons` struct in the same file to keep the public surface of `ListingMapView` clean. `ListingDetailPlaceholderView` stays in the project — still referenced by `ListingListView`.

During the test rerun one pre-existing debounce-timing flake reappeared (`filterByDates_reloadsListings` on a single clone) and then passed on immediate rerun. Same pattern tracked in earlier steps — not caused by this refactor.

---

### Step 8: Refactor `DiscoveryView` — remove inline city chips, compose new chrome

Wire all the new components into the map-mode layout.

- [x] Removed the inline map-mode header entirely — map mode now uses `DiscoveryHeaderPill` instead of the search bar + chip row + icon toggle. List mode retained verbatim (separate `listModeHeader` private view).
- [x] Overlay `DiscoveryHeaderPill` at the top: title/subtitle bound to `viewModel.headerTitle`/`headerSubtitle`, `onBack` → `viewModel.setViewMode(.list)`, `onTune` → `viewModel.isFilterSheetPresented = true`
- [x] Bottom chrome stack anchored above `FloatingTabView` using `tabBarHeight` plumbed through from `MainTabView` (which already received it via the `FloatingTabView` content closure — no hardcoding)
  - Fee tag renders when `!viewModel.feeTagDismissed && !viewModel.listings.isEmpty && dynamicTypeSize < .accessibility3` (last guard added after HIG review to avoid AX5 vertical clipping on small devices)
  - Mutually exclusive anchored item: `SelectedListingCard` when `selectedListing != nil`, else `MapEmptyStatePill` when `listings.isEmpty && !isLoading && error == nil`
- [x] Callbacks wired: tune → filter sheet; fee tag close → `dismissFeeTag()`; card dismiss → `selectPin(nil)`; card tap → `pushedListing = selected` + `.navigationDestination(item:)` to `ListingDetailPlaceholderView`; card heart → `toggleSave`; empty-state tap → filter sheet
- [x] Spacing: 12pt between fee tag and card (spec); 16pt between fee tag and tab bar when no card; **12pt (not 8pt) between card and tab bar** — bumped after HIG review because `FloatingTabView.onGeometryChange` measures the capsule but not its 8pt drop-shadow radius
- [x] Card/pill transitions use `.transition(.opacity)` + animations on `showFeeTag` and `selectedListing.id`; `.id(listing.id)` makes the card remount on selection change so its internal `animateIn()` (already reduce-motion-aware) re-runs
- [x] Build passes
- [x] HIG-reviewed via `hig-reviewer`. Applied P1/P2 fixes: bumped top padding `Spacing.md`→`Spacing.base` (iPad safe-area breathing room), bumped card-to-tab-bar gap `8pt`→`12pt` (shadow clearance), hide fee tag at AX3+ (small-device clipping), `Spacer(minLength: Spacing.base)` (guarantee floating-group separation), added `.transition(.opacity)` on anchored item. Verified `NavigationStack` ancestor is provided by `MainTabView` (not a P0).

**Notes:** List mode is pixel-identical — only map mode restructured. Visual validation: installed + launched on iPhone 17 Pro simulator, switched to map mode; header pill, fee tag, selected card, and tab bar all render with correct spacing and no clipping. `MainTabView` updated to plumb `tabBarHeight` through — previously unused from the content-closure parameter.

---

### Step 9: Validation pass — accessibility, dynamic type, reduce motion, offline

Final manual sweep in simulator before marking the feature complete.

- [x] Cold launch → map mode → header reads `"Homes across Somalia"` / `"Any dates · 1 guest"` ✓
- [x] Tune opens filter sheet; selecting Mogadishu updates header to `"Homes in Mogadishu"` and zooms the map to Mogadishu ✓
- [x] Price pins render on the map (AX tree exposes `"Listing for $X per night"` for each); tapping one raises `SelectedListingCard` with title/location/rating/price; the selected pin turns cyan ✓
- [x] `"Prices include all fees"` tag visible; tapping close dismisses it; kill + relaunch brings it back (session-only dismissal confirmed) ✓
- [x] Tapping a different pin cross-fades to the new card ✓; tapping the card's close dismisses it ✓. Swipe-down dismiss + TabView photo-pager are gestural (hard to synthesize via CGEvent) — validated in Step 6 HIG review and visible in the implementation
- [x] Apply filters producing zero results (Hargeisa + guestCount=10) → `MapEmptyStatePill` appears, pins disappear, fee tag correctly hides (because `listings.isEmpty`) ✓
- [x] With a card open in Mogadishu, switching filter to Hargeisa auto-dismisses the card (selected listing dropped from results — `clearSelectionIfStale()` fires end-to-end in production) ✓
- [x] AX5 Dynamic Type (`accessibility-extra-extra-extra-large`) → header pill truncates (`"Homes a..."` / `"Any dates ·..."`), card title+location truncate cleanly, rating + price fit, tab bar still visible, fee tag correctly hidden per the `< .accessibility3` guard ✓
- [x] VoiceOver — verified via code + AX tree dumps during this pass: `ListingPricePin` announces `"Listing for $X per night"`; `SelectedListingCard` uses `.accessibilityElement(children: .ignore)` + combined label + "Save"/"Close preview" custom actions + default tap action (Step 6); `DiscoveryHeaderPill` combines title+subtitle with `.isHeader` trait (Step 3); heart + close on the card are `.accessibilityHidden(true)` so the card stays a single rotor item
- [x] Reduce Motion — verified via code: `SelectedListingCard.animateIn()` and `dismissDrag.onEnded` both gate their springs on `accessibilityReduceMotion`. `simctl ui` has no reduce-motion toggle so runtime eyeball wasn't feasible — covered by Step 6's HIG review which explicitly flagged and fixed this
- [x] Offline — covered by the regression test `cacheHit_surfacesListingsDetachedFromModelContext` (in-memory `ModelContainer`, simulated network failure, asserts cached listings surface as detached `Listing` instances). `onMapLoadingError` fallback preserved through Step 7. `OfflineBannerView` in list mode untouched
- [x] Build passes (`xcodebuild … build` → **BUILD SUCCEEDED**)
- [x] HIG-reviewed — Steps 3, 4, 5, 6, 8 each ran the `hig-reviewer` agent (or inline equivalent for trivial components). Step 8 composition review surfaced P1 items (bottom-chrome shadow clearance, AX5 fee-tag-at-small-devices) which were applied before proceeding.

**Validation screenshots** are stashed in `/tmp/marti-s9-*.png` for reference; not checked in.

---

## Changes Log

| Date | Step | What changed |
|---|---|---|
| 2026-04-18 | — | Tasks generated from `docs/specs/discovery-map-redesign.md` |
| 2026-04-18 | 1 | ViewModel additions implemented with TDD: `feeTagDismissed`, `dismissFeeTag()`, `headerTitle`, `headerSubtitle`, computed `selectedListing`, and auto-clear stale selection after `loadListings()`. 12 new tests, all 28 ViewModel tests green. |
| 2026-04-18 | 1 (fix) | SwiftData fault fix: `readCache()` now returns detached `[ListingDTO]` snapshots, `loadListings()` rebuilds non-context `Listing(dto:)` instances. Prevents `BackingData detached from context` crash when `writeCache` purges rows a View still holds. Added regression test `cacheHit_surfacesListingsDetachedFromModelContext`. |
| 2026-04-18 | 2 | Extracted `ListingPricePin` into `Views/Discovery/Components/`. Pure refactor — styling unchanged. `ListingMapView` now instantiates the component directly; private `pricePin(for:)` helper removed. Build succeeds; ViewModel suite 58/58. |
| 2026-04-18 | — | Investigated intermittent Mapbox `Invalid size … fall back to the default size {64, 64}` warning (~20% of cold launches). Tried a `GeometryReader` gate in `ListingMapView`; empirically made it worse (100% rate, doubled warnings). Reverted. Documented as a known SDK-level quirk inside Mapbox's `UIViewRepresentable.makeUIView` — not reliably fixable from user code. |
| 2026-04-18 | 3 | Created `DiscoveryHeaderPill` component: 48pt circular back + tune buttons flanking a two-line centered pill. HIG audit applied (Dynamic Type tightening, `.isHeader` trait, clearer back label). Build passes. Three previews included. |
| 2026-04-18 | 4 | Created `FeeInclusionTag` component: stateless capsule chip with "Prices include all fees" label and a 44×44 xmark dismiss button. Visible text hidden from VoiceOver; combined label on the button. Build passes. Two previews. |
| 2026-04-18 | 5 | Created `MapEmptyStatePill` component: whole-capsule Button with message + `Color.coreAccent` "Adjust filters" CTA hint. `maxWidth: 520`, `minHeight: 44`, Dynamic Type tightening/scale factor applied. Build passes. Two previews. |
| 2026-04-18 | 6 | Created `SelectedListingCard` component — paging photo `TabView`, heart + close glass overlay buttons with dark scrim, title/location/rating/price stack with `ViewThatFits` AX5 fallback, axis-locked swipe-down dismiss, reduce-motion-gated spring animations, combined VoiceOver element with `Save`/`Close` custom actions. `hig-reviewer` P0/P1 fixes applied. Build passes. Three previews. |
| 2026-04-18 | 7 | Refactored `ListingMapView`: removed the `.sheet` preview, the `sheetIsPresented`/`selectedListing`/`sheetContent(for:)` helpers, and the `.hideFloatingTabBar` call. Added a static `LoadingPinSkeletons` overlay rendered when `isLoading && listings.isEmpty && !loadFailed`. All other behavior (map, `onMapLoadingError` fallback, `recenter`, tap-to-dismiss) preserved. Build passes; VM tests 57/57 clean. |
| 2026-04-18 | 8 | Composed the new map-mode chrome in `DiscoveryView`: `DiscoveryHeaderPill` top, `FeeInclusionTag` + `SelectedListingCard`/`MapEmptyStatePill` bottom stack anchored above `FloatingTabView` via a new `tabBarHeight` init param plumbed through `MainTabView`. Card tap wires into `.navigationDestination(item:)` to `ListingDetailPlaceholderView`. List mode untouched. HIG fixes: Spacing.base top padding, 12pt card-to-tab-bar (shadow clearance), fee tag hidden at AX3+, `.transition(.opacity)` on anchored item. Build passes; VM tests 58/58; visually verified on iPhone 17 Pro. |
| 2026-04-18 | 9 | Validation pass — ran the feature end-to-end on iPhone 17 Pro (iOS 26.3 simulator) via CGEvent-synthesized taps: cold launch, filter to Mogadishu, pin tap → card, close, different pin, fee tag dismiss + relaunch, Mogadishu→Hargeisa auto-clear, zero-result filter → empty pill, AX5 Dynamic Type. All 10 active scenarios pass. Reduce Motion + offline verified via code inspection + existing test coverage. Feature complete. |
