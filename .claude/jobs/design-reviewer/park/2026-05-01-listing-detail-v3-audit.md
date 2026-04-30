# Park Document — design-reviewer — 2026-05-01

> Listing Detail v3 visual-pass audit. AC #1–#14 with #12 overridden (sheet state moved from VM to View `@State` per COO instruction; no new test). Test count remains 99/99.

## Session summary

Audit of ios-engineer's Listing Detail v3 ship against `docs/specs/Listing Detail v3 visual pass.md`. Read all six new components + four modified components + spec end-to-end. Verdict: **fix-and-ship** — 2 blockers, 4 majors, 5 minors. The structural restructure is solid (section order, hairlines, header treatment, sticky-footer redesign all correct), but the §D host preview is missing the spec's required scroll-to-§K tap behavior, the §J reviews section flattens its header out of VoiceOver via `.accessibilityElement(.combine)`, the §G "Show all" button drops the spec-mandated `surfaceElevated` fill, and the §L sheet trigger fires three haptics instead of one.

## Files touched

| File | Change | Why |
| ---- | ------ | --- |
| `.claude/jobs/design-reviewer/park/2026-05-01-listing-detail-v3-audit.md` | Created | This park doc. |

(No code touched — review only. Findings routed back to ios-engineer via the structured summary returned to COO.)

## Decisions made

- **§C col-3 fallback verdict: keep em-dash, but flip `Color.textTertiary` → `Color.textSecondary` and add an `.accessibilityHidden(true)` exception**. The em-dash is correct geometrically (col-3 already shows `reviewCount`, so duplicating it in col-2 would double up). The risk the COO flagged ("reads as missing data") is real but small — the em-dash is the pan-app convention for "neutral fact". Engineer's already hidden it from VoiceOver.
- **§I expand-disc verdict: keep Apple Maps hand-off; disc + Show-more are not redundant**. Disc = map-overlay affordance for thumb users on the map; Show-more = text affordance for VoiceOver / Dynamic Type users who are reading top-down. Same destination, two entry points — not the same UX bug.
- **§K avatar background verdict: keep `surfaceDefault`**. `canvas` is too deep on a `surfaceElevated` card — reads as a hole, not a recessed circle. The current step-down delta is correct.

## Open questions / blockers

- B2 (haptic firing 3x in §L) is a structural mistake worth a one-line decision-log entry: "`.sensoryFeedback(_, trigger:)` should be applied at the **owning** view, not per-row, when multiple rows watch the same trigger." Worth a `decisions.md` entry so the same shape doesn't reappear in Bookings detail / Message thread.
- B1 (§D scroll-to-§K) is a real spec miss but the ergonomic shape is "tap small avatar row → scroll page" which iOS users may or may not expect. Worth COO checking whether the spec should be relaxed (drop the requirement) vs. enforced (engineer wires it).

## Inbox state at session end

- No inbox items processed (audit started from the COO delegation in this session).
- No outstanding inbox.

## Outbox summary

- Findings list returned to COO (caller); ios-engineer will pick up B1, B2, M1, M2 from there.

## What the next session should do first

1. If ios-engineer messages back saying B1, B2, M1, M2 are resolved, re-audit those specific four spots.
2. Run an AX5 manual sweep on the rebuilt surface — title block, §C 3-column row, §J centered hero, §K card, §L tappable rows, §M sticky footer. Fold into a re-audit note in this same park doc.
3. If verdict flips to ship-as-is, drop a confirmation in COO's inbox.

## Gotchas for next session

- `ListingAmenitiesSection.symbolName(for:)` and `description(for:)` are `static` and shared with `ListingAmenitiesSheet`. If either tightens its match table, both surfaces shift in lockstep — good, but worth knowing before changing the lookup.
- The §I expand-disc `glassDisc(diameter: 36)` is correct, but the **glyph size** inside is 16pt — spec wants 20pt. One-line fix.
- `.accessibilityElement(children: .combine)` will collapse a header trait in VoiceOver. Avoid wrapping a section's outer container in `combine` when there's a header inside; `.contain` is the safer alternative when you do want grouped reads.

## Session metadata

- **Duration**: approx. 25 minutes
- **Build state at end**: clean (engineer reported `** BUILD SUCCEEDED **` on iPhone 17 Pro; not re-run by reviewer)
- **Test state at end**: 99/99 passing (engineer reported; not re-run by reviewer)

---

## Loop 2 re-audit — 2026-05-01 (same day)

### Per-fix verification

| ID | Verdict | Evidence |
| -- | ------- | -------- |
| **B1** §D scroll-to-§K | **Cleared** | `ListingDetailView.swift:172` defines `expandedHostCardAnchor`. `:174-269` wraps `contentCard` in `ScrollViewReader { proxy in ... }`. `:193` calls `hostPreviewRow(scrollProxy: proxy)`. `:246` tags the §K VStack with `.id(Self.expandedHostCardAnchor)`. `:283-300` wraps `ListingHostCardView` with `.contentShape(Rectangle())` + `.onTapGesture` that toggles `hostPreviewHapticTrigger` and calls `proxy.scrollTo(...)` inside `withAnimation(.smooth(duration: 0.35))`. AT block: `.accessibilityElement(children: .combine)` + `.accessibilityAddTraits(.isButton)` + `.accessibilityHint("Scrolls to the host details below.")`. |
| **B2** §L per-row haptic | **Cleared** | `ListingDetailThingsToKnowSection.swift:71` — exactly one `.sensoryFeedback(.selection, trigger: presentedSheet?.id ?? "")` modifier, attached to the outer body VStack. `row(...)` body in `:79-117` carries no `.sensoryFeedback`. Trigger flips when any row's `Button` action sets `presentedSheet = sheet` (line 87). One haptic per state change. |
| **M1** §J header AT collapse | **Cleared** | `ListingReviewsAggregateView.swift:24-46` — outer VStack carries no `.accessibilityElement` modifier. Header `Text("Reviews")` at `:25-28` retains its standalone element + `.isHeader` trait. `combine` + `.accessibilityLabel(ratingBlockAccessibilityLabel)` are scoped to `centeredHero` (`:31-34`) and `newRow` (`:36-38`). Footnote `Text` at `:41-44` is its own element. VoiceOver focus: "Reviews, heading" -> combined rating block -> footnote. The "New" branch keeps its own AT treatment (returns "New listing, no reviews yet."). |
| **M2** §G "Show all" fill | **Cleared** | `ListingAmenitiesSection.swift:99-102` — `.background(RoundedRectangle(cornerRadius: Radius.md).fill(Color.surfaceElevated))`. Stroke dropped per documented engineer call (`:82-89` rationale). Foreground `martiLabel1` + `textPrimary` + `minHeight: 48` preserved. See M2 stroke-drop verdict below. |
| **M3** §I disc glyph 20pt | **Cleared** | `ListingDetailView.swift:400-403` — `Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 20, weight: .semibold))`. Inline comment at `:398-399` references the spec line and Loop 1 finding ID. 20/36 ratio reads as an icon on a button, not a button-shaped icon. |
| **M4** §G haptic | **Cleared** | `ListingAmenitiesSection.swift:29` adds `@State private var showAllHapticTrigger = false`. `:91-93` — button action toggles the flag before `onShowAll()`. `:105` — `.sensoryFeedback(.selection, trigger: showAllHapticTrigger)` attached to the button. Toggle-then-call ordering matches `ListingDetailStickyFooterView.hapticTrigger` precedent. |

### Regressions

None. Specific watch points all clean:
- `contentCard` frame/padding chain unchanged (`:255-268`).
- §H deferral comment preserved at `:217`.
- `safeAreaInset(.bottom)` footer wiring (`:69-71`) untouched.
- §K scroll target is the §K VStack root, so `proxy.scrollTo(..., anchor: .top)` lands on the "Meet your host" header rather than the avatar — keeps the contextual title visible.
- §J header retains `.isHeader` trait; footnote stays its own AT element.

### Updated AC table — only rows that changed verdict from Loop 1

| AC | Loop 1 | Loop 2 | Note |
| -- | ------ | ------ | ---- |
| #6 | Partial | **Pass** | M2 cleared. |
| #7 | Partial | **Pass** | M3 cleared. |
| #13 | Partial | **Pass** | M1 cleared (header reads as header); B2 haptic correctness restored. |

Net AC table for v3: #1-#11, #13, #14 all Pass. #12 overridden.

### Minors hygiene

All five Loop 1 minors still open as carry-overs — none accidentally swept in:

- **m1** §C em-dash `textTertiary`: `ListingDetailHighlightsRow.swift:60` unchanged. Open.
- **m2** §I disc redundant hint: `ListingDetailView.swift:407-408` unchanged. Open.
- **m3** `amenity != amenities.last`: `ListingAmenitiesSheet.swift:30` unchanged. Open.
- **m4** `ComingSoonSheetView` two-dismiss: `ComingSoonSheetView.swift:51` + `:60` both present. Open.
- **m5** §L `Spacer(minLength: Spacing.md)` AX5 risk: `ListingDetailThingsToKnowSection.swift:105` unchanged. Open.

### M2 stroke-drop verdict

**Ship as-is. Fill-only is the right read.**

Engineer's three-part rationale checks out:

1. **Spec literalism** — §G's "View all-style buttons" invariant lists fill + radius + min-height + font + foreground only. No stroke. The Loop 1 stroked outline was a deviation, not the spec.
2. **Project precedent** — `PrimaryButtonStyle` / `.primaryFullWidth` is fill-only. A stroke would diverge from the only other "View all"-shape affordance in the app.
3. **Dark-mode contrast** — `surfaceElevated` (#1F2D42) on `surfaceDefault` (#131D2B) is ~12 luminance units of separation. Plenty without an additional 0.5pt hairline; the hairline was adding chrome without information.

Tappability remains clear against the matte `surfaceDefault` content card. If this surface ever moves to a light theme (not in roadmap), revisit; for v3 dark-only, fill-only is correct.

### Final ship verdict

**Ship.** Listing Detail v3 is ready for STATUS.md / commit. All Loop 1 blockers + majors cleared, no regressions, AC table clean across #1-#11, #13, #14 (with #12 overridden). Five minors (m1-m5) are documented carry-overs and don't gate ship.

### Re-audit metadata

- **Duration**: approx. 8 minutes (Loop 2)
- **Build state at end**: clean (engineer reported `** BUILD SUCCEEDED **` on iPhone 17 Pro; not re-run by reviewer)
- **Test state at end**: 99/99 passing (engineer reported; not re-run by reviewer)
- **Working tree at end**: dirty by design — engineer made no commits.
