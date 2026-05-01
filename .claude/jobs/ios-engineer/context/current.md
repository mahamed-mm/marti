# Current state — ios-engineer

> Last updated: 2026-05-01 (Listing Detail v3 + Loop 2 fast-follow fix round)
> Update this file at the end of every session.

## What's in flight

Nothing finalized. Today's two sessions on this surface:

1. **Listing Detail v3 visual + scroll-rhythm pass** (Loop 1) — full
   restructure landed.
2. **Loop 2 fast-follow fix round** — 2 blockers + 4 majors flagged by
   design-reviewer addressed in one round (B1, B2, M1, M2, M3, M4 — see
   the v3 park doc's "Loop 2 — fix round" section for the per-fix table).

Working tree is dirty by COO design (v1 + v2 + 4 fixes + COO paperwork +
v3 Loop 1 + v3 Loop 2). No commits yet — COO will decide grouping.
**Awaiting design-reviewer re-audit** of the post-Loop 2 state.

v3 restructured the content card into the spec's §B → §C → §D → §E → §F →
§G → §I → §J → §K → §L order, with sticky §M unchanged in placement but
restructured internally. §H "Where you'll sleep" is intentionally deferred
(per-room photos schema gap) with a marker comment in `contentCard`.

Loop 2 made the §D host preview row tappable (scrolls to §K via
`ScrollViewReader`), collapsed §L's triple-buzz haptic to a single
section-level fire, fixed §J's accessibility-header erasure, gave §G's
"Show all" button its `surfaceElevated` fill + `.selection` haptic, and
bumped the §I expand-disc glyph from 16pt to 20pt per spec.

**Test count is still 99/99 passing.** No tests added or removed across
either loop per COO scope override (AC #12 — test count 99 → 100 for
`isAmenitiesSheetPresented_defaultsFalse` — overridden because sheet
state lives on the View, not the VM, in v3).

Build green on iPhone 17 Pro (Xcode 26.x), no warnings.

## What's clean / stable

- `ListingService.fetchListing(id:)` + Supabase impl + PGRST116 → `.notFound` mapping. **Untouched this loop.**
- `ListingDetailViewModel` (`@Observable`, `@MainActor`) — **untouched this loop** (locked off by COO scope override #2).
- `ListingDetailView` (v3 visual pass): rounded-top `surfaceDefault` overlay
  card, §B–§L stack, sticky §M footer, hero gallery + floating-trio cluster.
  Two new local `@State` flags: `isDescriptionExpanded` (§F) and
  `isAmenitiesSheetPresented` (§G). The §L `enum DetailSheet` lives inside
  `ListingDetailThingsToKnowSection` and routes its own `.sheet(item:)`.
- New components (created this session, all under `Views/ListingDetail/Components/`):
  - `ListingDetailHighlightsRow.swift` — §C 3-column stat row.
  - `ListingDetailWhyStaySection.swift` — §E 3 bare-glyph rows.
  - `ListingDetailExpandedHostCard.swift` — §K `surfaceElevated` host card.
  - `ListingDetailThingsToKnowSection.swift` — §L 3 tappable rows + sheet routing.
  - `ListingAmenitiesSheet.swift` — §G destination sheet.
- New shared component: `Views/Shared/ComingSoonSheetView.swift` — generic
  "ships with feature X" sheet (closes 2026-04-28 carry-over `n3`).
- Restructured (across Loops 1+2):
  - `ListingAmenitiesSection.swift` — bare-glyph rows, 6-row preview cap, "Show all" button. **Loop 2 M2**: stroked button → `surfaceElevated` fill (hairline dropped, fill-only matches spec recipe + `PrimaryButtonStyle` precedent). **Loop 2 M4**: added `@State showAllHapticTrigger` + `.sensoryFeedback(.selection, trigger:)`. `description(for:)` exposed at file-internal scope so the sheet can re-use it.
  - `ListingReviewsAggregateView.swift` — centered hero rating block (`martiDisplay`) when `averageRating != nil`, "Based on N ratings and reviews." footnote, Guest-favorite gate (`>= 4.8 && reviewCount >= 3`) shared with §C. Pre-v3 "New" branch retained for `nil` rating. **Loop 2 M1**: removed root-level `.accessibilityElement(children: .combine)` so the "Reviews" header keeps its own AT element + `.isHeader` trait. Combine + label moved to wrap only the centered hero / new-row.
  - `ListingDetailStickyFooterView.swift` — §M: `secondaryLine` is now `String?`, omitted entirely when SOS unavailable (was rendering bare "Monthly").
  - `ListingDetailThingsToKnowSection.swift` — **Loop 2 B2**: lifted the `.sensoryFeedback(.selection, trigger:)` from per-row to the section's outer VStack. Single haptic per state change.
  - `ListingDetailView.swift` — **Loop 2 B1**: wrapped `contentCard`'s VStack in `ScrollViewReader`; tagged §K with `.id(Self.expandedHostCardAnchor)`; extracted `hostPreviewRow(scrollProxy:)` with tap-to-scroll + haptic + `isButton` AT trait. **Loop 2 M3**: §I expand-disc glyph 16pt → 20pt. Added `@State hostPreviewHapticTrigger`.
- Map view (`Views/Shared/NeighborhoodMapView.swift`): **untouched**. §I
  expand-disc + Show-more affordances live at the call-site in
  `ListingDetailView` so the map view stays a leaf primitive.
- `ListingHostCardView.swift` — verified, no edit needed (copy already correct after v2).
- 11 ViewModel tests on `ListingDetailViewModelTests` + 3 service tests + ~85 others across the suite. **Full suite count 99/99 green** as of 2026-05-01.

## What's blocked

Nothing.

## Open questions

- None.

## Next actions

- **Design-reviewer re-audit** of the post-Loop 2 state.
- If audit passes: qa-engineer step (full suite from clean build).
- COO to decide commit grouping for the dirty tree.

## Decisions made this session (worth noting; none architectural)

### Loop 1 (v3 Loop 1)

1. **§C column-3 fallback**: em-dash placeholder when neither Guest-favorite nor Verified applies. Spec recommended duplicating the review count; rejected because column 3 already shows it.
2. **§I expand-disc + Show-more caption**: both call `MKMapItem(location:address:).openInMaps()`. Spec gave it as engineer's call; the implementation reads cleanly as one helper.
3. **§F description-expanded toggle**: lives on the View as `@State`. Per spec.
4. **`ListingAmenitiesSection.description(for:)`**: promoted from `private static` to `static internal` so `ListingAmenitiesSheet` can re-use the lookup table.

### Loop 2 (fix round)

5. **M2 — "Show all" button hairline stroke dropped, fill-only.** The spec's "View all" recipe is fill-only (no stroke), and `PrimaryButtonStyle` is the project precedent. Hairline on top of `surfaceElevated` adds chrome without information.
6. **B1 — §D scroll animation = `.smooth(duration: 0.35)`, anchor = `.top`.** Felt-out duration; `.top` lands "Meet your host" header at the visible top, which reads as the most intentional landing for a "more about the host" tap.
7. **B1 — `expandedHostCardAnchor` lifted to `private static let`** on `ListingDetailView`. Anchor strings as inline literals are a class of bug the compiler can't catch.
8. **B1 + M4 — haptic style = `.sensoryFeedback(.selection, …)`** for sheet/scroll triggers; `.impact` reserved for primary CTAs (Reserve pill keeps it).

None of these are architectural enough to push to `decisions.md`. Recorded
in the v3 park doc.

## Deferred from prior audits (out of scope this loop, still valid)

- m1 — `lineSpacing(4)` magic number in description block → `Spacing.sm`.
- m2 — `avatarDiameter: CGFloat = 50` magic number; either define
  `Spacing.avatarMedium = 50` or document the local constant.
- m3 — `markerDiameter: CGFloat = 18` in `NeighborhoodMapView`
  (**maps-engineer's lane**).
- m4 — Rating-star size differs across surfaces. v3 introduces a third
  size (10pt for `ListingDetailHighlightsRow.starRow`). Three sizes is
  intentional (hero / compact column / preview), but flagged for review.
- m5 — `MartiDivider` extraction in Shared. v3 added two more
  `Divider().background(Color.dividerLine)` callsites; pressure increasing.
- n1 — `aspectRatio(4.0 / 3.0)` applied twice in
  `ListingPhotoGalleryView.content`; can lift to parent.
- n3 — `ComingSoonSheet` extraction. **DONE this session** as
  `ComingSoonSheetView` in `Views/Shared/`. Scratch this from the list.

## v3 follow-ups filed (not implemented)

- f1 — Per-room photos schema + `ListingBedroomsRail` (§H slot).
- f2 — `host_languages: [String]` column (§K placeholder).
- f3 — `host_city: String` column (§K placeholder).
- f4 — Years-hosting / response-rate / response-time stats (§K stat rows).
- f5 — Per-review carousel below §J hero block.
- f6 — Real Send-message button (Feature 4).
- f7 — Collapsing nav-bar morph (v4 polish).
- f8 — Translate notice + Trust banner (later features).
- f9 — Rating-star size unification (carry-over m4 update).
- f10 — `MartiDivider` extraction (carry-over m5 update).

## Decisions worth surfacing to COO

(Carried forward from prior loops — still relevant.)

1. `ListingDiscoveryViewModel.makeDetailViewModel(for:)` factory pattern.
2. `makeDetailViewModel` prop on `CategoryRailView` for the rail's
   `NavigationLink`.
3. Test-only `SupabaseStubURLProtocol` class (separate from `StubURLProtocol`)
   to avoid `.serialized`-suite races.
4. `.notFound` UX matches Apple's Mail/Photos/Maps "resource gone" pattern:
   alert with single OK, then pop.
5. Footer's "Free cancellation" row keys off `cancellationPolicy.lowercased() != "strict"`
   — defensive against seed-data capitalization drift.
6. Reserve red pill is an inline style block in `ListingDetailStickyFooterView`,
   not a mutation of `PrimaryButtonStyle`. If a second red CTA shows up,
   extract a `DangerCapsuleButtonStyle` then.
7. Share disc is decorative (empty closure) per the spec's locked decision.
8. **(New, v3)** Sheet state for ad-hoc UI navigation (§G amenities sheet,
   §F description-expanded, §L cancellation/houseRules/safety) lives on
   the View, not the VM. Project precedent already established by
   `isFeeTagDismissed`. Codified as the rule for v3+.
9. **(New, Loop 2 M1 / B2)** Two SwiftUI accessibility/haptics rules
   discovered the hard way this loop, worth codifying in
   `.claude/rules/swiftui.md` if COO wants:
   - **Never `.accessibilityElement(children: .combine)` at a section
     root that contains a true header `Text`** — combining flattens the
     `.isHeader` trait. Combine on the contentful child instead.
   - **`.sensoryFeedback` belongs on the surface that owns the state
     change, not on each surface that emits the gesture.** A group of
     rows sharing one trigger should attach the modifier once at the
     section level, otherwise every row fires simultaneously when the
     trigger flips (the §L triple-buzz).
