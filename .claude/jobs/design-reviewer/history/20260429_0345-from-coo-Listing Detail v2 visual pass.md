# Message — from coo to design-reviewer — 2026-04-29 03:45

**Topic**: Listing Detail v2 — HIG + token-adherence audit
**Priority**: high
**Responding to**: (initial — visual revision audit)

## Objective

Audit the Listing Detail visual pass that ios-engineer just landed. Score it against HIG, design-token adherence, and the spec at `docs/specs/Listing Detail v2 visual pass.md`. The reference image is `screenshots/airbnb_141871.webp`. Return a blocker / major / minor findings list.

## Acceptance criteria

- Read the spec, the reference image, and the four modified Swift files in full.
- Verify every color, font, spacing, and radius lands on a `DesignTokens.swift` token. No inline hex, no hardcoded RGB, no `Spacing`/`Radius` magic numbers (other than the explicitly approved `4` for the counter pill vertical padding routed through `Spacing.sm`).
- Verify the locked decisions (see below) were honored verbatim.
- Verify SwiftUI rules (`.claude/rules/swiftui.md`): `@State` for view-local only, extract subviews if body > ~50 lines, SF Symbols only, `.accessibilityLabel` on every interactive control without visible text.
- Verify the rounded-top overlay card behaves under (a) long titles (8+ words at default Dynamic Type), (b) AX5 dynamic type, and (c) zero-photos / strict-policy edge cases.
- Note the share button is **decorative by user decision** — pass on this, but verify the accessibility hint reads correctly.
- Write your audit document at `docs/audits/2026-04-29-design-audit-Listing Detail v2.md`. Use the same shape as the 2026-04-28 audit doc.
- Park doc at `.claude/jobs/design-reviewer/park/2026-04-29-design-reviewer.md`.

## Locked decisions (from COO clarification round 2026-04-29)

These are **not subject to your audit** — the user explicitly chose them. Note them as decisions, do not score them as gaps:

1. **Card surface** = `Color.surfaceDefault` rounded-top overlay (not literal white).
2. **Host tenure copy dropped** entirely. No "N years hosting" line.
3. **Footer subtitle** keeps `fullSOSPriceLine` (no date range).
4. **Share button is decorative** — empty action, accessibility-labeled.
5. **Reserve button uses `Color.statusDanger`** (closest brand-red token Marti owns).

If you find a *new* HIG concern with any of these (e.g. the decorative share button is genuinely confusing in VoiceOver), flag it as a minor with a "user pre-approved this trade-off" note — do not block on it.

## Context

ios-engineer landed the visual pass at 2026-04-29 ~03:30. Build green, 98/98 tests green (untouched). Their hand-off (in the response message and in their park doc at `.claude/jobs/ios-engineer/park/2026-04-29-ios-engineer.md`) flags these specific risk hot-spots they want a second pair of eyes on:

- **Title block centering at AX5** — title and subtitle leading-aligned, rating row centered. Optical balance may shift when the subtitle wraps.
- **Hero floating-button top inset on Dynamic Island devices** — back disc may visually collide with the island in some orientations.
- **Counter pill contrast on dark photos** — 50% black capsule + white text; might blur into very dark imagery. Reduce-Transparency mode also weakens it.
- **Fee-tag dismissal transition** — they used `.opacity.combined(with: .move(edge: .trailing))`; tunable.

Carry-over follow-ups m1–m5 / n1–n3 from the 2026-04-28 audit are **out of scope** for this loop (user explicitly said no).

## Files to audit

- `marti/Marti/Views/ListingDetail/ListingDetailView.swift` (restructured)
- `marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift` (counter pill, removed heart)
- `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift` (rounded-square icons, descriptions)
- `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift` (Free-cancel row, red Reserve pill)

Reference primitives (do not score these — they're shared and stable):
- `Marti/Marti/Views/Shared/FavoriteHeartButton.swift`
- `Marti/Marti/Views/Discovery/Components/FeeInclusionTag.swift`
- `Marti/Marti/Extensions/DesignTokens.swift`

## Constraints

- Audit-only. Do not modify Swift files. If you find a blocker, write it up — COO will route the fix back to ios-engineer.
- Do not re-litigate the locked decisions.
- Do not bundle the carry-over follow-ups into your verdict.

## Expected response

Return a structured summary in your final message:

1. **Verdict**: Ship / Loop 2 (with explicit list of items ios-engineer must fix) / Block (rare).
2. **Findings list**: Blocker / Major / Minor / Nit. Each finding: `<severity>` — `<one-line summary>` — `<file:line>` — `<suggested fix>`.
3. **Token adherence score**: any inline hex, magic number, or off-token color. Brief.
4. **HIG compliance score**: hit-target sizes (44pt min), Dynamic Type behavior, VoiceOver labels.
5. **Audit doc path**: confirm `docs/audits/2026-04-29-design-audit-Listing Detail v2.md` is written.
6. **Park doc path**: confirm `.claude/jobs/design-reviewer/park/2026-04-29-design-reviewer.md` is written.
7. **Inbox state**: confirm this message has been moved to your `history/`.
