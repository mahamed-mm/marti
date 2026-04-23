# Current state — coo

> Last updated: 2026-04-23
> Update this file at the end of every session.

## What's in flight

Nothing. Bug fix landed; working tree has the fix + new regression test unstaged (not committed by COO since the user did not request a commit).

## What's clean / stable

- Discovery loading state: `ListingDiscoveryViewModel.isLoading` now defaults to `true` so the first render of `DiscoveryView` picks the skeleton branch instead of flashing `EmptyStateView`. Pinned by `freshViewModel_startsInLoadingState_soFirstFrameShowsSkeletonsNotEmptyState`. Full `MartiTests` suite green on iPhone 17 Pro (iOS 26.3.1 sim).
- Listing Discovery feature remains shipped per `docs/STATUS.md`.

## What's blocked

Nothing.

## Open questions

- None for this bug. One follow-up exists (see Next actions) — not currently blocked on input.

## Next actions

- **Follow-up bug** (not scoped to this /fix-bug): `DiscoveryView.anchoredItem` (`marti/Marti/Views/Discovery/DiscoveryView.swift:234-266`) has no loading-state branch, so the map-mode bottom chrome is blank during first-load while pin skeletons render over the map. Logged under today's entry in `control/decisions.md`. Wait for user to prioritize before scheduling.
- Next feature per STATUS.md is Listing Detail — kick off with `/generate-spec listing-detail` when the user is ready.

## Gotchas carried over

- Swift Testing `#expect` tests do NOT match `-only-testing:MartiTests/SuiteName/testName` when the suite is Swift Testing (not XCTest). Running the whole `-only-testing:MartiTests` target runs all Swift Testing tests correctly. First build after touching test sources may surface a transient "Cannot find 'MainTabView' in scope" error from stale DerivedData; `clean test` resolves it without code changes.
