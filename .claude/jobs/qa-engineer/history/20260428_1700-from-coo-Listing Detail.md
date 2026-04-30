# Message — from coo to qa-engineer — 2026-04-28 17:00

**Topic**: Verify Listing Detail ship — full suite + new coverage
**Priority**: high
**Responding to**: (initial)

## Objective

Run the full `MartiTests` suite. Triage any failures. Confirm the 13 new tests added for Listing Detail pin the right behaviors.

## Acceptance criteria

- Run:
  ```
  xcodebuild -project marti/Marti.xcodeproj -scheme Marti -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MartiTests test
  ```
  Suite ends in `** TEST SUCCEEDED **`.
- The 10 new `ListingDetailViewModelTests` and 3 new `SupabaseListingServiceTests/fetchListing_*` are present and green.
- The pre-existing Discovery regression tests are still green, particularly:
  - `ListingDiscoveryViewModelTests/freshViewModel_startsInLoadingState_soFirstFrameShowsSkeletonsNotEmptyState`
- If anything is RED, write an inbox message back to the owning engineer (`ios-engineer` for VM/View tests; `maps-engineer` if `NeighborhoodMapView` is implicated; `coo` for spec-level ambiguity) at `.claude/jobs/<owner>/inbox/<timestamp>-from-qa-Listing Detail.md` with crisp repro steps.
- Park doc written at `.claude/jobs/qa-engineer/park/2026-04-28-qa-engineer.md`.

## Context

`/ship-feature Listing Detail` is post-implementation. ios-engineer reported full suite green (98 tests, 13 new). I want a clean independent verification before design-review. Note: SourceKit may show "Cannot find type / No such module" diagnostics on newly-added files — those are indexer artifacts; xcodebuild is the truth source.

## Relevant files / specs

- Spec: `docs/specs/Listing Detail.md`
- Tasks: `docs/tasks/Listing Detail.md`
- ios-engineer park doc: `.claude/jobs/ios-engineer/park/2026-04-28-ios-engineer.md`
- New test files:
  - `marti/MartiTests/ViewModels/ListingDetailViewModelTests.swift`
  - `marti/MartiTests/Services/SupabaseListingServiceTests.swift`
- Relevant rules: `.claude/rules/testing.md`, `.claude/rules/build.md`

## Constraints

- Don't modify production code. If you see a real test failure, hand it back via inbox; don't fix it yourself.
- Don't run UI tests — they're flaky in CI and not gating per `.claude/rules/build.md`.
- Don't add new tests in this pass. If you see a coverage gap, note it in the park doc and reply via outbox.

## Expected response

Reply by writing the park doc and returning a structured summary including:
1. Final test result line (`** TEST SUCCEEDED **` or the failures).
2. Total test count + count of new tests confirmed present.
3. Any flake observed across two runs (don't run twice unless you suspect a flake).
4. Any inbox messages dispatched to other roles (paths).
5. Coverage gap observations (notes only — no implementation).
