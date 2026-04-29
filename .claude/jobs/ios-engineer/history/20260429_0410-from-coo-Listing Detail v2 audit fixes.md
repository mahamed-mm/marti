# Message — from coo to ios-engineer — 2026-04-29 04:10

**Topic**: Listing Detail v2 — Loop 2 audit fixes
**Priority**: high
**Responding to**: `.claude/jobs/ios-engineer/history/20260429_0315-from-coo-Listing Detail v2 visual pass.md` (Loop 1)

## Objective

Apply the two issues design-reviewer flagged as blocker / major in their 2026-04-29 audit (`docs/audits/2026-04-29-design-audit-Listing Detail v2.md`). Two-line fix surface, both inside `ListingDetailView.swift`.

## Acceptance criteria

- **B1 — duplicate back affordance**: hide the system nav bar so the floating chevron disc is the single back affordance. In `ListingDetailView.swift`, replace
  ```swift
  .navigationTitle(viewModel.listing.title)
  .navigationBarTitleDisplayMode(.inline)
  ```
  with
  ```swift
  .toolbar(.hidden, for: .navigationBar)
  ```
  (lines ~52–53 in the post-Loop-1 file). Verify on simulator that the system back chevron is gone but the floating disc still calls `dismiss()` correctly.

- **M1 — floating cluster ignores top safe area**: replace `.padding(.top, Spacing.base)` on the hero floating-buttons cluster (line ~107 in the post-Loop-1 file) with `.safeAreaPadding(.top)` so the discs sit clear of the Dynamic Island / status bar on Pro-class devices.

- Build still green.
- Test count still **98 passing** — no test changes.
- The minors (m1, m2, m3) and nits (n1, n2) in the audit are explicitly **out of scope** — design-reviewer signed off on them as ship-as-is or watch-items. Do not address them in this loop.

## Constraints

- **Only `ListingDetailView.swift`** is touched in this loop. No other files.
- Do not re-litigate the locked decisions.
- The 2026-04-29 SourceKit phantom diagnostics on the four Loop 1 files are expected and benign — `xcodebuild build` is the truth source.

## Verification commands

```
xcodebuild -project marti/Marti.xcodeproj -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

```
xcodebuild -project marti/Marti.xcodeproj -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MartiTests test
```

Both must be green; test count must remain 98.

## Expected response

Apply both fixes, run both verification commands, move this message to `.claude/jobs/ios-engineer/history/`, append a short follow-up note to your existing 2026-04-29 park doc (do not write a fresh one), and reply with:

1. The exact diff (a few lines either way) for both edits.
2. Build status (last ~3 lines of `xcodebuild build`).
3. Test status (the test count line).
4. Confirmation that the floating chevron disc still pops the screen (manually verify the tap-handler still invokes `dismiss()`; the visible `chevron.left` glyph is unchanged).
