# Spec — Listing Detail v2 (visual + layout pass)

**Status**: Approved 2026-04-29 (COO).
**Predecessor**: `docs/specs/Listing Detail.md` (original ship). This spec layers a visual / layout revision on top — the original spec remains the source of truth for behavior, data flow, and tests.

## Goal

Restyle the Listing Detail screen to mirror the Airbnb reference at `screenshots/airbnb_141871.webp`, while staying inside Marti's dark-mode-only token system. **Visual / layout only.** No new features, no schema changes, no new ViewModel surface.

## Non-goals

- No changes to `ListingDetailViewModel` (state, init, refresh, toggleSave, requestToBook all stay).
- No changes to `ListingService`, `SupabaseListingService`, or any other service.
- No new tests. `ListingDetailViewModelTests` (10 tests) and `SupabaseListingServiceTests/fetchListing_*` (3 tests) must remain untouched and green.
- No new SPM packages. No new design tokens. No new shared components.
- No date picker, no nightly-vs-monthly framing, no share-sheet plumbing — those land with their owner features.

## Locked decisions (from COO clarification round, 2026-04-29)

1. **Title card surface** — render the title block + section stack on `Color.surfaceDefault` with rounded top corners overlapping the hero by `Spacing.lg` (24pt). No literal white card; the dark surface is the adapted recipe.
2. **Host tenure copy** — drop the "N years hosting" line entirely. The `Listing` model has no host-tenure field; do not invent it. Render `Hosted by {name}` on line 1 and the existing `VerifiedBadgeView(variant: .label)` on line 2 when `isVerified == true`.
3. **Footer subtitle** — keep the existing `fullSOSPriceLine` as the secondary text. Add a "Free cancellation" check pill above the price row when `cancellationPolicy != "strict"`. No date range copy.
4. **Hero floating buttons** — render all three (back, share, favorite). **Share is decorative** (empty action). Annotate the share button `accessibilityLabel("Share")` for parity with the visual; do not omit the label. Decorative trade-off is explicit and pre-approved.
5. **Reserve button color** — use `Color.statusDanger` (#FF649C). Closest brand-red token Marti owns. No new red token.

## Visual recipe — zone by zone

### A. Hero photo gallery (`ListingPhotoGalleryView.swift`)

**Behavior unchanged**: paged swipe through `photoURLs`, `currentIndex` bound to VM, 4:3 aspect, `placeholderPane` on empty / load-failure.

**Visual changes**:
- Drop the native page-dot indicator. Set `.tabViewStyle(.page(indexDisplayMode: .never))`.
- Overlay a photo counter pill **bottom-trailing** of the gallery:
  - Text: `"\(currentIndex + 1) / \(photoURLs.count)"` in `.martiLabel2`.
  - Background: `Capsule().fill(Color.black.opacity(0.5))`.
  - Padding: `.horizontal, Spacing.md` + `.vertical, 4`.
  - Margin from edges: `Spacing.base`.
  - Hidden entirely when `photoURLs.isEmpty`.
- **Remove** the in-component `FavoriteHeartButton` overlay. The heart now lives in the floating-trio cluster owned by `ListingDetailView` (see B).
- Component signature stays:
  ```swift
  struct ListingPhotoGalleryView: View {
      let photoURLs: [String]
      @Binding var currentIndex: Int
      let isSaved: Bool       // ← will be removed; see below
      let onToggleSave: () -> Void  // ← will be removed; see below
  }
  ```
  After the heart move, `isSaved` and `onToggleSave` are no longer needed in this component. Drop them; update the callsite in `ListingDetailView` accordingly.

### B. Hero floating buttons (new cluster owned by `ListingDetailView`)

Three circular buttons floating over the hero photo, each at 44pt visible diameter using the existing `.glassDisc(diameter: 44)` recipe:

| Position | Symbol | Action |
| --- | --- | --- |
| Top-leading | `chevron.left` | `dismiss()` (uses `@Environment(\.dismiss)`, already in the view) |
| Top-trailing pair, left of heart | `square.and.arrow.up` | **Decorative** — empty closure |
| Top-trailing, rightmost | `heart` / `heart.fill` (via `FavoriteHeartButton(.large)`) | `Task { await viewModel.toggleSave() }` |

Layout: an `HStack` for the trailing pair separated by `Spacing.md`; pad both edges with `Spacing.base`. Place the cluster inside a `ZStack` overlay over the gallery, aligned `.top`.

Accessibility:
- Back: `accessibilityLabel("Back")`.
- Share: `accessibilityLabel("Share")` and `accessibilityHint("Decorative — share is not available yet")` to telegraph the decorative state to VoiceOver users.
- Heart: `FavoriteHeartButton` already self-labels (`"Save listing"` / `"Remove from saved"`).

### C. Title card (`ListingDetailView.swift` — restructure)

Replace the existing inline `titleRow` and the first `Divider` with a single rounded-top card that wraps the entire downstream section stack.

- Outer container: `VStack(alignment: .leading, spacing: Spacing.lg)`.
- Background: `Color.surfaceDefault`.
- Clip: top corners rounded to `Radius.lg` (24pt) using `.clipShape(.rect(topLeadingRadius: Radius.lg, topTrailingRadius: Radius.lg, bottomLeadingRadius: 0, bottomTrailingRadius: 0))` (iOS 17+ API).
- Vertical offset: `.offset(y: -Spacing.lg)` so the card overlaps the hero photo.
- Inset content with `.padding(.horizontal, Spacing.screenMargin).padding(.top, Spacing.lg)` and `.padding(.bottom, Spacing.xl)`.

Top of the card (replaces `titleRow`):

```
[Title]                                martiHeading3, textPrimary, .leading
[Neighborhood, City]                   martiFootnote, textSecondary, .leading
[N guests]                             martiFootnote, textSecondary, .leading
[★ rating · (N reviews)]               martiLabel2 / footnote, CENTERED
[Divider]                              dividerLine, full-width inside card
```

- The rating row is **center-aligned** under the subtitle. Wrap the existing `ratingRow` `HStack` in `frame(maxWidth: .infinity, alignment: .center)`.
- Star size stays at the existing 12pt (carry-over `m4` divergence with `ListingReviewsAggregateView`'s 14pt is a separate cleanup, **not** in scope for this ship).
- Drop the leading `mappin.and.ellipse` glyph from the location line — reference has no glyph here.

### D. Host row (`ListingHostCardView.swift`)

The current host card already renders the recipe demanded by the locked decisions:
- 50pt circular avatar (or initial fallback).
- `Hosted by {name}` in `martiHeading5`.
- `VerifiedBadgeView(variant: .label)` when `isVerified`.

**Action**: leave the component itself unchanged. Verify visually post-implementation that it composes correctly inside the new title card. If the avatar size feels out of balance against the new card's heavier title, leave it — `avatarDiameter: 50` is also a carry-over (`m1`) and out of scope.

### E. Amenities (`ListingAmenitiesSection.swift`)

Replace each amenity row's icon-only treatment with a card-style row containing a rounded-square icon container, a bold heading, and a secondary description.

- **Drop** the section heading "Amenities". Reference has no top-level heading; each row stands alone.
- New row recipe:
  ```swift
  HStack(alignment: .top, spacing: Spacing.base) {
      Image(systemName: symbolName(for: amenity))
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(Color.textPrimary)
          .frame(width: 36, height: 36)
          .background(
              RoundedRectangle(cornerRadius: Radius.sm)
                  .stroke(Color.dividerLine, lineWidth: 1)
          )
      VStack(alignment: .leading, spacing: Spacing.xs) {
          Text(amenity)
              .font(.martiLabel1)
              .foregroundStyle(Color.textPrimary)
          if let desc = description(for: amenity) {
              Text(desc)
                  .font(.martiFootnote)
                  .foregroundStyle(Color.textSecondary)
                  .fixedSize(horizontal: false, vertical: true)
          }
      }
      Spacer(minLength: 0)
  }
  ```
- Vertical spacing between rows: `Spacing.lg` (24pt).
- New private static helper `description(for amenity: String) -> String?` mirroring the existing `symbolName(for:)` lookup table:
  ```swift
  // Lower-cased contains-match. Out-of-table amenities return nil — row collapses to heading-only.
  // Keep the table tight (≤ 8 entries) and evergreen.
  private static func description(for amenity: String) -> String? {
      let key = amenity.lowercased()
      if key.contains("wifi") { return "Reliable connection in every room." }
      if key.contains("ac") || (key.contains("air") && key.contains("cond")) { return "Cool, dry air for warm-weather stays." }
      if key.contains("kitchen") { return "Equipped for home-cooked meals during your stay." }
      if key.contains("pool") { return "Shared pool access on the property." }
      if key.contains("wash") || key.contains("laundry") { return "On-site laundry — no laundromat run." }
      if key.contains("parking") || key.contains("park") { return "On-site parking included." }
      if key.contains("workspace") || key.contains("desk") { return "A comfortable spot to get work done." }
      if key.contains("balcon") || key.contains("terrace") { return "Outdoor space attached to the unit." }
      return nil
  }
  ```
- Empty-amenities behavior is unchanged: collapse to `EmptyView()`.

### F. Fee inclusion tag (reuse existing `FeeInclusionTag`)

Float the existing `FeeInclusionTag` above the sticky footer, anchored to the bottom safe-area inset.

- Move the placement out of the scrolling content; render it inside `safeAreaInset(edge: .bottom)` **above** `ListingDetailStickyFooterView` in a `VStack(spacing: Spacing.base)`.
- Local UI state: `@State private var isFeeTagDismissed = false` on `ListingDetailView`. UI-only — no VM change.
- Render only when `!isFeeTagDismissed`.
- Anchor: trailing-aligned (`HStack { Spacer(); FeeInclusionTag(onDismiss: …) }.padding(.horizontal, Spacing.base)`).
- Wrap dismiss in `withAnimation(.smooth(duration: 0.18)) { isFeeTagDismissed = true }`.
- Optional: persist via `@AppStorage("listingDetailFeeTagDismissed")` — not required for this ship.

### G. Sticky footer (`ListingDetailStickyFooterView.swift`)

Two stacked rows inside the bar:

**Top row** (only when `cancellationPolicy != "strict"`):
- `HStack(spacing: Spacing.xs) { Image(systemName: "checkmark"); Text("Free cancellation") }`.
- `.font(.martiFootnote)`, `.foregroundStyle(Color.textSecondary)`.
- Leading-aligned. No background — flat icon+text reads cleaner against the existing `.thinMaterial`.

**Bottom row** (existing layout, restyled):
- Leading column:
  - Price: `"$\(usd)"` in `.martiHeading3` `Color.textPrimary` (was `martiLabel1` — bumped for visual emphasis to match reference).
  - Secondary line: `"Monthly · \(fullSOSPriceLine)"` when SOS is present, else just `"Monthly"`. `.martiFootnote`, `.textSecondary`. Single line, line-limit 1.
- Trailing: pill-shaped Reserve CTA.
  - Replace `.buttonStyle(.primary)` with an inline pill style:
    ```swift
    Button("Reserve") { hapticTrigger.toggle(); onRequestToBook() }
        .font(.martiLabel1)
        .foregroundStyle(Color.canvas)
        .frame(minHeight: 48)
        .padding(.horizontal, Spacing.lg)
        .background(Color.statusDanger)
        .clipShape(Capsule())
    ```
  - Do **not** mutate `PrimaryButtonStyle`. This red CTA is detail-screen-specific.
  - Keep `sensoryFeedback(.impact(weight: .light))` on the same trigger.
  - `accessibilityLabel("Reserve this listing")` (changed from "Request to book").

**Component signature change**:
```swift
struct ListingDetailStickyFooterView: View {
    let pricePerNightUSDCents: Int
    let fullSOSPriceLine: String?
    let cancellationPolicy: String   // ← NEW
    let onRequestToBook: () -> Void
}
```
Update the single callsite in `ListingDetailView` to pass `viewModel.listing.cancellationPolicy`.

### H. Sections downstream of amenities (no shape change)

`descriptionSection`, `NeighborhoodMapView`, `ListingCancellationPolicyView`, `ListingReviewsAggregateView` all remain inside the new title card on `surfaceDefault`. Existing dividers (`Divider().background(Color.dividerLine)`) stay. The "About this place" section header and copy are unchanged. The `ListingCancellationPolicyView` section stays — the footer pill is additive, not a replacement.

### I. Offline banner

`OfflineBannerView` keeps its current placement above the gallery. No visual change.

## Files to modify

| Path | Change |
| --- | --- |
| `marti/Marti/Views/ListingDetail/ListingDetailView.swift` | Restructure body: hero zone with floating-buttons cluster, rounded-top overlay card containing the section stack, `safeAreaInset(.bottom)` carrying the fee tag + footer. Add `@State private var isFeeTagDismissed = false`. |
| `marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift` | Switch index display mode to `.never`. Add bottom-trailing counter pill overlay. Remove the heart overlay; remove the now-unused `isSaved` and `onToggleSave` parameters. |
| `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift` | Drop section heading. Replace icon style with rounded-square container. Add bold heading + secondary description per row; new private static `description(for:)` helper. Increase row spacing to `Spacing.lg`. |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift` | New top "Free cancellation" pill row. Restyled Reserve pill in `statusDanger`. Add `cancellationPolicy: String` parameter. Bump price to `.martiHeading3`. Relabel CTA "Reserve". |

## Files NOT to touch

- `marti/Marti/ViewModels/ListingDetailViewModel.swift` — no behavior, state, or signature changes.
- `marti/Marti/Services/*` — no service changes.
- `marti/Marti/Models/Listing.swift` — no model changes.
- `marti/Marti/Views/Discovery/Components/FeeInclusionTag.swift` — reused as-is.
- `marti/Marti/Views/Shared/FavoriteHeartButton.swift` — reused as-is at `.large`.
- `marti/Marti/Views/Shared/Buttons.swift` — `PrimaryButtonStyle` stays.
- `marti/Marti/Extensions/DesignTokens.swift` — no new tokens.
- `marti/MartiTests/ViewModels/ListingDetailViewModelTests.swift` — must remain untouched and green.
- `marti/MartiTests/Services/SupabaseListingServiceTests.swift` — must remain untouched and green.
- `marti/Marti/Views/ListingDetail/Components/ListingHostCardView.swift` — visual sanity check only; no edits expected.
- `marti/Marti/Views/ListingDetail/Components/ListingCancellationPolicyView.swift` — visual stays.
- `marti/Marti/Views/ListingDetail/Components/ListingReviewsAggregateView.swift` — visual stays. Carry-over `m4` star-size divergence is **not** addressed here.

## Tokens & primitives reused

- **Colors**: `surfaceDefault`, `surfaceHighlight`, `dividerLine`, `textPrimary`, `textSecondary`, `statusDanger`, `canvas`, `coreAccent` (existing amenity tint stays for symbol foreground if preserved — but the new spec uses `textPrimary` inside the rounded-square container).
- **Spacing**: `xs`, `sm`, `md`, `base`, `lg`, `xl`, `screenMargin`.
- **Radius**: `sm` (amenity icon container), `lg` (overlay card top corners), `full` (counter pill via `Capsule()`).
- **Components**: `FavoriteHeartButton(.large)`, `FeeInclusionTag`, `VerifiedBadgeView(.label)`, `NeighborhoodMapView`, `glassDisc(diameter:)`, `OfflineBannerView`.
- **Fonts**: `martiHeading3`, `martiHeading4`, `martiHeading5`, `martiLabel1`, `martiLabel2`, `martiBody`, `martiFootnote`.

## Constraints

- Swift 6 strict concurrency, default `MainActor` isolation.
- `swiftui.md` rules: `@Bindable` (not `@ObservedObject`), `@State` for view-local state only, extract subviews when body > ~50 lines, SF Symbols only, `.accessibilityLabel` on every interactive control without visible text.
- `style.md` rules: `let` > `var`, comments explain *why* not *what*, functions ≤ ~20 lines.
- No new SPM packages, no singletons (Apple-provided only), no global state.
- `gotchas.md`: prices stay `Int USD cents`; route SOS through `LiveCurrencyService.format(sos:display:)` (already done by VM helper). Don't introduce float math on money.

## Acceptance criteria

- All four files above are edited; no new files created; no new tests added.
- `xcodebuild build` green on iPhone 17 Pro.
- `xcodebuild ... -only-testing:MartiTests test` reports 98/98 passing — same count, no test-level changes.
- Manual inspection on simulator (`/run-app`) matches the verification checklist below.

## Verification

End-to-end smoke on iOS Simulator (iPhone 17 Pro, Xcode 26.x):

1. Tap a Discovery listing → `ListingDetailView` pushes.
2. Hero: photo full-bleed, three floating circular buttons (back / share / favorite) clear and tappable, counter pill bottom-trailing reads `1 / N`.
3. Swipe the gallery → counter increments. Tap heart → toggles (or auth sheet if unauthed). Tap share → no action (decorative).
4. Title card overlaps hero with rounded top, large bold title, neighborhood + city line, capacity line, centered ★ rating row, divider.
5. Host row: avatar + `Hosted by {name}` + verified badge label (when applicable). No "years hosting" copy.
6. Amenities: each row has a rounded-square icon container, bold amenity name, secondary description for known amenities (heading-only for unknown). No section heading "Amenities".
7. Description, neighborhood map, cancellation-policy section, reviews aggregate render unchanged inside the card.
8. "Prices include all fees" tag floats above the footer; tap × dismisses with a smooth animation.
9. Sticky footer: large `$NN`, "Monthly · ~N,NNN,NNN SOS" below, "Free cancellation" check row above price (only on flexible/moderate), red `Reserve` pill on the right. Tap Reserve → existing coming-soon sheet.
10. Edge cases: long title (8+ words) wraps without clipping under hero. Zero photos → counter pill hidden. `cancellationPolicy == "strict"` → free-cancel row hidden. Unauthenticated heart tap → `AuthSheetPlaceholderView`. `.notFound` refresh → existing alert + pop unchanged.

## Out of scope (do not bundle)

- Carry-over follow-ups m1–m5 / n1–n3 from the 2026-04-28 design audit (e.g. `MartiDivider`, star-size unification, avatar-size token, `ComingSoonSheetView` extraction).
- AX5 dynamic-type sweep (manual test scenario, separate ticket).
- Image-cache wiring (`CachedImageService`).
- Mapbox v11 release-tag pin (separate ship-prep blocker).
- Anything requiring a model/schema change.
