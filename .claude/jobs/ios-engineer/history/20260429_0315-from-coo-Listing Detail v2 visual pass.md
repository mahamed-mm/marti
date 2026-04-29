# Message — from coo to ios-engineer — 2026-04-29 03:15

**Topic**: Listing Detail v2 — visual + layout pass to match Airbnb reference
**Priority**: high
**Responding to**: (initial — visual revision on top of the 2026-04-28 ship)

## Objective

Restyle the Listing Detail screen to mirror the Airbnb reference at `screenshots/airbnb_141871.webp`, while staying inside Marti's dark-mode token system. **Visual / layout only.** Do not change the ViewModel, services, models, or any tests.

## Acceptance criteria

- The four files listed in the spec's "Files to modify" table are the **only** files you edit. No new files; no test changes; no token additions.
- Hero gallery: native page-dot indicator removed; bottom-trailing "1 / N" counter pill rendered (hidden on empty `photoURLs`); the in-component heart overlay is gone.
- Three floating circular buttons over the hero, owned by `ListingDetailView`: back (top-leading, `dismiss()`), share (decorative), favorite (`FavoriteHeartButton(.large)`). Each on the existing `.glassDisc(diameter: 44)` recipe.
- Title card: section stack wrapped in a rounded-top `Color.surfaceDefault` container offset `-Spacing.lg` to overlap the hero. Title in `.martiHeading3`. Subtitle stacks `"\(neighborhood), \(city)"` then `"\(maxGuests) guest(s)"`. Rating row centered. Divider below.
- Host card: visual unchanged (the locked decision matches the current shape — verify, do not edit unless layout breaks inside the new card).
- Amenities: drop the section heading. Each row has a rounded-square icon container (`Radius.sm`, `dividerLine` stroke) + bold name + secondary description from a new `description(for:)` helper. Row spacing `Spacing.lg`.
- Fee tag: existing `FeeInclusionTag` floats above the footer inside `safeAreaInset(.bottom)`. Local `@State` `isFeeTagDismissed`. Smooth dismiss animation.
- Sticky footer: top "Free cancellation" check row above price (only when `cancellationPolicy != "strict"`); price bumped to `.martiHeading3`; secondary line `"Monthly · {fullSOSPriceLine}"`; trailing red `Capsule()` "Reserve" button on `Color.statusDanger`. New `cancellationPolicy: String` parameter on the footer view.
- All locked decisions in the spec's "Locked decisions" section honored verbatim.
- `xcodebuild build` green on iPhone 17 Pro.
- `xcodebuild ... -only-testing:MartiTests test` reports **98/98 passing** (no test changes; existing suite must pass untouched). If the count drifts, treat that as a regression and stop.
- Park doc written at `.claude/jobs/ios-engineer/park/2026-04-29-ios-engineer.md`.

## Locked decisions (from COO clarification round 2026-04-29)

1. **Card surface** — adapted dark surface (`surfaceDefault` + rounded top corners), not literal white. No new color tokens.
2. **Host tenure copy** — drop "N years hosting" entirely. The model has no host-tenure field; do not invent one.
3. **Footer subtitle** — keep `fullSOSPriceLine` as the secondary text. No date range copy.
4. **Share button** — render the floating disc, label it accessibly, but the action is empty (decorative). Do **not** add a `ShareLink` or any plumbing.
5. **Reserve button color** — `Color.statusDanger`. No new red token.

## Context

Listing Detail shipped end-to-end on 2026-04-28 (see `.claude/jobs/coo/park/2026-04-29-coo.md` for the original ship summary, and `.claude/jobs/ios-engineer/park/2026-04-28-ios-engineer.md` for your prior work). User came back with a visual / layout revision request anchored to the Airbnb reference. They specified each zone in the request — the spec is the canonical interpretation.

The COO clarification round resolved four ambiguities (card surface, host tenure, footer subtitle, share button). All four are locked in the spec — do not reopen them.

Carry-over follow-ups from the 2026-04-28 design audit (m1–m5, n1–n3) are **out of scope** for this ship. Specifically: no `MartiDivider` extraction, no star-size unification, no avatar-size token, no `ComingSoonSheetView`. The user wants a focused visual pass.

## Relevant files / specs

- **Spec (canonical)**: `docs/specs/Listing Detail v2 visual pass.md`
- **Reference image**: `screenshots/airbnb_141871.webp`
- **Original spec (predecessor)**: `docs/specs/Listing Detail.md`
- **Plan file** (COO's working notes): `~/.claude/plans/coo-i-want-quirky-lampson.md`
- **Files to modify** (paths verified):
  - `marti/Marti/Views/ListingDetail/ListingDetailView.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`
- **Reused primitives** (do not modify):
  - `marti/Marti/Views/Shared/FavoriteHeartButton.swift`
  - `marti/Marti/Views/Discovery/Components/FeeInclusionTag.swift`
  - `marti/Marti/Views/Shared/Buttons.swift`
  - `marti/Marti/Extensions/DesignTokens.swift`
- **Architecture / rules**: `.claude/rules/swiftui.md`, `.claude/rules/style.md`, `.claude/rules/gotchas.md`, `.claude/rules/architecture.md`, `.claude/rules/build.md`

## Constraints

- **No new files**. No new tests. No new tokens. No new SPM packages. No new shared components.
- **Do not touch** `ListingDetailViewModel`, services, models, or `ListingHostCardView` / `ListingCancellationPolicyView` / `ListingReviewsAggregateView`.
- **Do not** mutate `PrimaryButtonStyle` to host the red Reserve. Inline the small style block in the footer view; if a second red CTA appears later, extract.
- **Do not** add a `ShareLink`, `UIActivityViewController`, or any share plumbing. The share disc is decorative (per locked decision).
- Swift 6 strict concurrency. Default `MainActor` isolation. `let` > `var`. Functions ≤ ~20 lines.
- The rounded-top corner clip must use `.rect(topLeadingRadius:topTrailingRadius:bottomLeadingRadius:bottomTrailingRadius:)` (iOS 17+ API; project targets iOS 26).
- Money: prices stay `Int USD cents`. SOS routes through `LiveCurrencyService.format(sos:display:)` (already wired via VM helper `fullSOSPriceLine`).
- Accessibility: every interactive control gets an `accessibilityLabel`. Decorative share gets a hint that telegraphs it's not yet wired ("Decorative — share is not available yet").

## Verification commands

After your edits, run both. Both must be green:

```
xcodebuild -project marti/Marti.xcodeproj -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

```
xcodebuild -project marti/Marti.xcodeproj -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MartiTests test
```

Expected test count: **98 passing** (same as the 2026-04-28 baseline). If it drifts up, you added tests — revert. If it drifts down, you broke something — fix.

## Expected response

Process this inbox item, implement the work, verify the build + tests are green, write your park doc, then move this message to `.claude/jobs/ios-engineer/history/`. Return a structured summary in your final message including:

1. **Files modified** — one bullet per file with the relative path and a one-line summary of what you touched.
2. **Build status**: ✅ passed / ❌ failed (with cause). Paste the last ~5 lines of `xcodebuild build` output.
3. **Test status**: ✅ passed / ❌ failed (with cause). For green, paste the test count line. **Must be 98 passing.**
4. **Any deviation from the spec** with rationale. If the spec was wrong (e.g. a token didn't exist, an API was unavailable in our deployment target), flag it and reply — don't silently re-scope.
5. **Anything design-reviewer should know** — open visual questions, layout concerns, AX5 risk hot-spots.
