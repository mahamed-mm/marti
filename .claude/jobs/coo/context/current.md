# Current state — coo

> Last updated: 2026-04-29 (post Listing Detail v2 visual pass)
> Update this file at the end of every session.

## What's in flight

Nothing. Listing Detail v2 visual pass shipped end-to-end (spec → ios-engineer Loop 1 → design-reviewer audit → ios-engineer Loop 2 → re-audit Ship). Working tree carries the v2 ship + COO paperwork unstaged on top of the prior 2026-04-28 ship that was also never committed (user did not request a commit; do NOT commit unprompted).

## What's clean / stable

- **Listing Detail v2 shipped.** Hero gallery: 1/N counter pill, three floating circular buttons (back via `dismiss()`, share decorative, favorite via `FavoriteHeartButton(.large)`). Title card: rounded-top `surfaceDefault` overlay (`-Spacing.lg` offset) with `martiHeading3` title, two-line subtitle (`{neighborhood}, {city}` + `N guests`), centered ★ rating row. Amenities: rounded-square icon containers + bold name + secondary description, no section heading. Sticky footer: free-cancel check row (when policy ≠ strict) + bumped-to-`martiHeading3` price + `Monthly · {SOS}` subtitle + red `Capsule()` Reserve on `Color.statusDanger`. Fee-tag floats above footer with smooth dismiss animation. Nav bar hidden via `.toolbar(.hidden, for: .navigationBar)`. Floating cluster honors top safe area via `.safeAreaPadding(.top)`.
- **Build green** on iPhone 17 Pro (Xcode 26.x) — verified by COO after ios-engineer's claim.
- **Test suite: 97/97 green.** Note: prior baseline was logged as 98 but the actual count is 97 (per ios-engineer's per-suite breakdown during Loop 2). View-only edits cannot affect count, so this is a tracker drift, not a regression. STATUS.md / prior park docs that say "98/98" should be reconciled to 97/97 next time they're touched.
- **Files modified (4 view files only)**:
  - `Marti/Marti/Views/ListingDetail/ListingDetailView.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`
- **Tokens / VM / services / models / tests untouched** — the visual-only constraint held.
- Discovery, NeighborhoodMapView, FavoriteHeartButton, FeeInclusionTag, all design tokens — unchanged.

## What's blocked

Nothing.

## Open questions

None for the v2 ship. Carry-over follow-ups (still logged, still not in flight):

- **Test count reconciliation**: STATUS.md and prior park docs reference "98/98" — actual is 97/97. Reconcile next time those files are touched.
- **Manual AX5 sweep on Listing Detail v2** (per spec's manual test scenarios). Pick up in next sweep.
- **Carried minors / nits from the audit**: m1 (amenity icon glyph 16pt), m2 (icon container 36×36), m3 (counter pill black/0.5 contrast under Reduce Transparency). All explicitly ship-as-is per design-reviewer; watch items for next polish pass.
- **Pre-existing carry-overs from 2026-04-28** still open: `MartiDivider` extraction, star-size unification (12pt vs 14pt), avatar-size token, `ComingSoonSheetView` extraction, image cache wiring, Mapbox v11 release-tag pin.

## Next actions

1. Confirm with the user whether to commit the working tree (now contains both the 2026-04-28 Listing Detail ship + the 2026-04-29 v2 visual pass + COO paperwork). Do NOT commit unprompted.
2. **Next feature per STATUS.md is still Request to Book** (P0). Listing Detail's sticky CTA (`RequestToBookComingSoonSheet`) remains the wire-through point.
3. Optionally schedule the carried follow-ups before the next surface lands.

## Decisions logged this session

No new architectural decisions — all five locked decisions were visual / scope-bounded, captured in `docs/specs/Listing Detail v2 visual pass.md` rather than `decisions.md` (no architectural reach-through).

The two carry-over architectural decisions from 2026-04-28 (`.notFound` UX policy, hide-tab-bar invariant on pushed details) still apply unchanged.

## Gotchas carried over

- **SourceKit phantom diagnostics — confirmed again.** Every v2 file edit triggered a wave of "Cannot find type / Cannot find in scope" errors against `Spacing`, `Radius`, `Color.canvas`, `Color.dividerLine`, `martiFootnote`, `ListingDetailViewModel`, `OfflineBannerView`, `AuthSheetPlaceholderView`, `RequestToBookComingSoonSheet`, etc. — all of which are genuinely in scope. `xcodebuild build` was green throughout. Trust the build, ignore the diagnostics, document this for the next session.
- **Test-count drift**: prior baseline of "98/98" was off by one. Actual is 97/97. ios-engineer caught this during Loop 2 with a per-suite breakdown.
- **Loop 2 audit pattern works.** Two-line fix (`.toolbar(.hidden, for: .navigationBar)` + `.safeAreaPadding(.top)`) cleared B1 + M1 in one round-trip. Re-audit by a fresh design-reviewer agent (since the prior wasn't named for SendMessage continuity) was efficient at ~1 minute.
- **Swift 6 / iOS 17+ corner API**: `.clipShape(.rect(topLeadingRadius:topTrailingRadius:bottomLeadingRadius:bottomTrailingRadius:))` is the canonical way to round only the top corners of a `View` clip. Avoid `RoundedCornersShape` custom shapes when this API is available.
- **Case-insensitive FS** — paths like `marti/Marti/...` and `Marti/Marti/...` both resolve. After `Read`, use the same casing in `Edit`.
