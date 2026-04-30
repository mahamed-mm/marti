# Current state — ios-engineer

> Last updated: 2026-04-29 (Listing Detail v2 audit fixes — Loop 2)
> Update this file at the end of every session.

## What's in flight

Nothing. Listing Detail v2 Loop 2 audit fixes landed (B1 + M1, single
file `ListingDetailView.swift`). Build green; tests pass 97/97 (note:
prior loop's "98" claim was off-by-one — actual baseline is 97 and
remains 97 after this loop, see Loop 2 follow-up section in the
2026-04-29 park doc). Awaiting design-reviewer re-audit or COO
direction.

## What's clean / stable

- `ListingService.fetchListing(id:)` + Supabase impl + PGRST116 → `.notFound` mapping. **Untouched this loop.**
- `ListingDetailViewModel` (`@Observable`, `@MainActor`) — **untouched this loop.**
- `ListingDetailView` (Loop 3 / v2 visual pass): hero zone with floating
  three-button cluster (back / share / favorite) on `.glassDisc(diameter: 44)`
  discs, section stack on a rounded-top `surfaceDefault` overlay card offset
  `-Spacing.lg`, fee tag floats above the sticky footer via
  `safeAreaInset(.bottom)`, mappin glyph dropped from the title block.
  Local `@State isFeeTagDismissed` for the fee-tag dismissal (UI-only).
- `ListingPhotoGalleryView`: page dots removed (`indexDisplayMode: .never`),
  bottom-trailing counter pill ("N / M" on a 50% black capsule, hidden when
  empty), in-component heart removed. Signature trimmed — `isSaved` and
  `onToggleSave` are gone.
- `ListingAmenitiesSection`: section heading dropped, rounded-square icon
  containers (36×36, `Radius.sm`, `dividerLine` stroke), bold name +
  secondary description copy via a new private static `description(for:)`
  helper.
- `ListingDetailStickyFooterView`: "Free cancellation" check row above the
  price (when `cancellationPolicy != "strict"`), price bumped to
  `.martiHeading3`, secondary line restyled to `"Monthly · {fullSOSPriceLine}"`,
  inline red `Capsule()` Reserve pill on `Color.statusDanger` (CTA renamed
  from "Request to Book" to "Reserve"). New `cancellationPolicy: String`
  parameter.
- 10 ViewModel tests + 3 service tests. **Test count 98/98, untouched.**

## What's blocked

Nothing.

## Open questions

- None.

## Next actions

- Wait on design-reviewer audit of the v2 visual pass.
- If audit passes, qa-engineer step.

## Deferred from prior audits (out of scope this loop)

(All of these were explicitly out of scope for the v2 visual pass per
the inbox message — only relist if COO escalates.)

- m1 — `lineSpacing(4)` magic number in description block → `Spacing.sm`.
- m2 — `avatarDiameter: CGFloat = 50` magic number; either define
  `Spacing.avatarMedium = 50` or document the local constant.
- m3 — `markerDiameter: CGFloat = 18` in `NeighborhoodMapView`
  (**maps-engineer's lane**).
- m4 — Rating-star size differs between `ListingDetailView.ratingRow` (12pt)
  and `ListingReviewsAggregateView.ratingRow` (14pt). Pick one.
- m5 — Seven `Divider().background(Color.dividerLine)` callsites; queue a
  `MartiDivider` extraction in Shared.
- n1 — `aspectRatio(4.0 / 3.0)` applied twice in
  `ListingPhotoGalleryView.content`; can lift to parent.
- n2 — Page-dot indicator visibility was the original concern; v2 removed
  the dots in favor of a counter pill, so this concern is **resolved**.
- n3 — Coming-soon sheet duplication with `AuthSheetPlaceholderView`;
  queue extraction before a third "coming soon" surface lands.

## Decisions worth surfacing to COO

(Carried forward from prior loops — still relevant.)

1. `ListingDiscoveryViewModel.makeDetailViewModel(for:)` factory pattern.
2. `makeDetailViewModel` prop on `CategoryRailView` for the rail's
   `NavigationLink`.
3. Test-only `SupabaseStubURLProtocol` class (separate from `StubURLProtocol`)
   to avoid `.serialized`-suite races.
4. `.notFound` UX matches Apple's Mail/Photos/Maps "resource gone" pattern:
   alert with single OK, then pop.

(New from v2 visual pass — none of these are architectural enough to
warrant a `decisions.md` entry. Recorded in the park doc only for
reference.)

5. Footer's "Free cancellation" row keys off `cancellationPolicy.lowercased() != "strict"`
   — defensive against seed-data capitalization drift.
6. Reserve red pill is an inline style block in `ListingDetailStickyFooterView`,
   not a mutation of `PrimaryButtonStyle`. If a second red CTA shows up,
   extract a `DangerCapsuleButtonStyle` then.
7. Share disc is decorative (empty closure) per the spec's locked decision
   — `accessibilityHint("Decorative — share is not available yet")` keeps
   VoiceOver users informed.
