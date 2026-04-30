# Current state — coo

> Last updated: 2026-05-01 (Listing Detail v3 ship through full role pipeline)
> Update this file at the end of every session.

## What's in flight

Nothing. v3 ship is complete and parked.

## Session 2026-05-01 — Listing Detail v3 (visual + scroll-rhythm pass) — SHIPPED

User invoked COO to kick off Listing Detail v3 per `docs/specs/Listing Detail v3 visual pass.md`. Full role pipeline ran end-to-end:

1. **Preflight + plan** — flagged spec-path mismatch, dirty-tree state, test baseline drift, prior subagent gating issues, and a **VM-scope conflict** (user's "no VM" instruction vs spec §G + AC #12). Resolved via `AskUserQuestion`: **View `@State`** (not VM), **stack on dirty tree** (no commits in-session). Plan written + approved.
2. **ios-engineer Loop 1** (~26 min) — created 6 new component files + restructured 4 existing + 1 verify-only no-op. Build green, 99/99 tests. Three engineering judgment calls flagged for design-reviewer: §C col-3 em-dash fallback (chose em-dash over spec's `reviewCount`), §I expand-disc (Apple Maps hand-off via `MKMapItem(location:address:)`), §K avatar `surfaceDefault` background.
3. **design-reviewer Loop 1** (~5 min) — **fix-and-ship** with **2 blockers + 4 majors + 5 minors**:
   - **B1** §D host preview row not tappable (spec demands scroll-to-§K).
   - **B2** §L `.sensoryFeedback` per-row → triple-buzz on tap (all rows watch same trigger).
   - **M1** §J `.accessibilityElement(.combine)` at outer VStack erases header `.isHeader` trait.
   - **M2** §G "Show all" missing `surfaceElevated` fill (was stroke-only).
   - **M3** §I disc glyph 16pt vs spec's 20pt.
   - **M4** §G "Show all" missing haptic.
   - All three engineering judgment calls validated.
4. **ios-engineer Loop 2** (~9 min, via SendMessage continuation) — all 6 fixes landed across 4 files. Build green, 99/99 tests. M2 stroke dropped entirely (defensible: `PrimaryButtonStyle` precedent + dark-mode contrast).
5. **design-reviewer Loop 2** (~4 min) — **SHIP**. All 6 cleared, zero regressions. AC #6/#7/#13 flipped Partial → Pass. Net: AC #1–#11, #13, #14 all Pass; #12 overridden as planned. Endorsed M2 stroke-drop as the right read.
6. **Close-out** — this file + park doc at `.claude/jobs/coo/park/2026-05-01-coo-listing-detail-v3.md`.

**Ship verdict**: SHIP. v3 is ready for STATUS.md reconcile + commit when user is ready.

## What's clean / stable

- **Listing Detail v3 shipped.** New scroll order: §B title (centered) → §C 3-column highlights stat row → §D host preview (tappable, scrolls to §K) → §E 3 bare-glyph why-stay rows → §F about-this-place prose with show-more → §G amenities preview (≤6) + show-all sheet → §I neighborhood map + expand-disc + show-more (Apple Maps hand-off) → §J reviews aggregate centered hero → §K expanded host card → §L things-to-know 3 tappable rows (cancellation policy + house rules + safety, latter two as ComingSoon) → (sticky §M footer with restructured price layout).
- **6 new components in `Views/ListingDetail/Components/` + `Views/Shared/`**: `ListingDetailHighlightsRow`, `ListingDetailWhyStaySection`, `ListingDetailExpandedHostCard`, `ListingDetailThingsToKnowSection`, `ListingAmenitiesSheet`, `ComingSoonSheetView` (the last also closes a 2026-04-28 carry-over).
- **`ComingSoonSheetView` extraction** — closed (was a 2026-04-28 carry-over).
- **AC #1–#11, #13, #14 all Pass.** AC #12 (test count 99→100) overridden by user instruction; test count holds at 99/99.
- **`ListingDetailViewModel` untouched.** Sheet presentation state lives on the View as `@State` (project-precedent-aligned: matches `isFeeTagDismissed` + the §L `enum DetailSheet`).
- **No new design tokens, no schema changes, no service changes, no SPM additions.** Only addition was `import MapKit` (system framework) for Apple Maps hand-off.
- **Build green** on iPhone 17 Pro (Xcode 26.x) after both loops. **Test suite: 99/99 passing**, 0 failures, 0 regressions.
- **Mapbox ornaments still ToS-compliant** on both surfaces (Discovery + NeighborhoodMapView). v3 was a callsite-only change to the map embed; the leaf `NeighborhoodMapView` was untouched.
- **Cancellation-policy gating remains whitespace-tolerant** at every consumer surface (footer + section + new §L cancellation sheet).
- **Files modified by v3 (10 new/modified, plus paperwork)** — full list in the park doc; mid-session test-count and build-state both held throughout.
- Discovery, FavoriteHeartButton, FeeInclusionTag, all design tokens — unchanged.

## What's blocked

Nothing.

## Open questions

None for the v3 ship.

### Carry-over follow-ups (still open, still not in flight)

**New from v3 — implementation gaps & nits:**

- **f1–f4** (schema): per-room photos column (§H deferred slot), `host_languages` column (§K hard-code), `host_city` column (§K hard-code), host tenure / response-rate / response-time columns (§K skipped stats).
- **f5–f6** (feature blockers): per-review carousel below §J hero (Feature 5), real Send-message host button (Feature 4).
- **f7–f8** (later polish): collapsing nav-bar morph (v4), translate notice + Trust banner.
- **f9** — Rating-star size unification: v3 introduced a 10pt star size; surface now has 10/12/14pt stars across §C / §J / cards.
- **f10** — `MartiDivider` extraction: pressure increasing (v3 added five more inline `Divider().background(Color.dividerLine)` instances).
- **m1** — §C col-3 em-dash foreground `textTertiary` → `textSecondary` (one-line tweak).
- **m2** — §I disc accessibility hint redundancy (label already telegraphs the action).
- **m3** — `ListingAmenitiesSheet` divider gating uses `amenity != amenities.last` (fragile under duplicate strings).
- **m4** — `ComingSoonSheetView` has both "Got it" + toolbar "Cancel" — pick one (HIG: prefer toolbar dismiss).
- **m5** — §L row `Spacer(minLength: Spacing.md)` may push chevron off-screen at AX5 with very long subtitles. Watch.

**Pre-existing carry-overs (still open):**

- **2026-04-29 v2 audit minors**: amenity icon glyph 16pt, icon container 36×36, counter pill black/0.5 contrast under Reduce Transparency.
- **2026-04-28 carry-overs**: avatar-size token, image cache wiring, **Mapbox v11 release-tag pin** (still tracking `main`; submission blocker per STATUS.md).
- **Cancellation-policy schema hardening**: deferred to backend-engineer + ios-engineer when host-write ships.
- **`.claude/rules/` entry for map-ornament visibility**: deferred until a third map surface ships.
- **STATUS.md reconcile owed**: test count `98/98` → `99/99` + Listing Detail v3 paragraph under "Shipped." Holding for user's commit decision.
- **Manual AX5 sweep**: still owed for both v2 + v3. Programmatic AT side green per design-reviewer Loop 2.

### Two candidate `.claude/rules/swiftui.md` additions

Both well-evidenced by today's session, both would prevent repeat footguns:

1. **Combine-at-root pitfall**: never `.accessibilityElement(children: .combine)` at a section root if the section has a header `Text` — combine on the contentful child. The combine modifier silently flattens nested AT traits including `.isHeader`. (Root cause of M1 in Loop 1.)
2. **`.sensoryFeedback` ownership**: belongs on the surface that owns the state change, not the surface that emits the gesture. When N rows watch the same trigger, all N fire on each state change. (Root cause of B2 in Loop 1.)

User decision needed before adding to the rules file.

## Next actions

1. **Confirm with user the commit decision.** v3 is ship-ready. Working tree now carries 6 days of uncommitted work + ~14 files modified in v3. Do NOT commit unprompted — but flag at next session opener.
2. **STATUS.md reconcile** (paired with the commit when user OKs): `98/98` → `99/99`, Listing Detail v3 paragraph under "Shipped".
3. **Decide on the two `.claude/rules/swiftui.md` candidate additions** above.
4. **Manual AX5 sweep** on Listing Detail v2 + v3 (bundled).
5. **Next feature per STATUS.md is still Request to Book** (P0). Listing Detail's sticky CTA (`RequestToBookComingSoonSheet`) remains the wire-through point.
6. Optionally schedule carried follow-ups before next surface lands.

## Decisions logged this session

No purely-architectural decisions — v3 was a visual/UI restructure on an existing surface. All four notable decisions (VM scope override, commit posture, three engineering judgment calls, M2 stroke drop) are captured in the v3 spec + the role park docs + this `current.md`. Nothing appended to `.claude/jobs/coo/control/decisions.md`.

The two carry-over architectural decisions from 2026-04-28 (`.notFound` UX policy, hide-tab-bar invariant on pushed details) still apply unchanged.

## Gotchas carried over

- **SourceKit phantom diagnostics — confirmed yet again** today on every v3 file edit (`Spacing`, `Radius`, all `Color.*` and `Font.marti*` tokens, plus `ListingDetailViewModel` and `ComingSoonSheetView` ghosts). Build was clean throughout both loops. Same gotcha as 2026-04-29 + 2026-04-30. Trust the build, ignore the editor.
- **SendMessage UUID-addressing works.** Despite the tool description saying "name not UUID," sending to a UUID returned in `agentId` resumes the agent's transcript first-try. Used twice this session (Loop 2 ios-engineer, Loop 2 design-reviewer).
- **`MKMapItem(placemark:)` is deprecated in iOS 26** — use `MKMapItem(location:address:)`. ios-engineer caught this without prompting.
- **`ScrollViewReader` placement** — wrap the **child** of the outer `ScrollView`, not the `ScrollView` itself, for `proxy.scrollTo(...)` to scroll the page. (Confirmed in Loop 2 B1 fix.)
- **Test-count drift in STATUS.md persists**: still says 98/98; actual is 99/99 since 2026-04-30. Reconcile when STATUS.md is next touched.
- **Working tree pressure increasing**: 6 days of uncommitted work + ~14 v3 files. Worth a soft nudge to user at next session opener.
- **Case-insensitive FS** — paths like `marti/Marti/...` and `Marti/Marti/...` both resolve. Use the same casing in `Edit` after `Read`.
