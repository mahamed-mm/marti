# Current state — qa-engineer

> Last updated: 2026-04-28 (Listing Detail verification pass)

## What's in flight

Nothing. Last action was an independent verification pass on `/ship-feature Listing Detail` — full `MartiTests` suite green, 98/98, all 13 new tests confirmed.

## What's clean / stable

- `xcodebuild ... -only-testing:MartiTests test` → `** TEST SUCCEEDED **` (98 cases, 0 failures, run on iPhone 17 Pro simulator, 2026-04-28).
- `ListingDetailViewModelTests` (10 cases, all green): init seed contract, `refresh` happy / network / notFound, `toggleSave` unauth / auth / failure rollback / concurrent guard, `requestToBook`, `currentPhotoIndex` observability.
- `SupabaseListingServiceTests/fetchListing_*` (3 cases, all green): single-row hit, PGRST116 → `.notFound`, URLError → `.network`/`.unknown`.
- `ListingDiscoveryViewModelTests/freshViewModel_startsInLoadingState_soFirstFrameShowsSkeletonsNotEmptyState` regression: still green.

## What's blocked

Nothing.

## Known flaky tests

None confirmed flaky as of 2026-04-28.

## Watch items (not flakes yet, but keep an eye)

| Test                                                                | Observation                                                  | First seen   |
| ------------------------------------------------------------------- | ------------------------------------------------------------ | ------------ |
| `SupabaseListingServiceTests/fetchListing_mapsURLErrorToNetwork()`  | Took 8s vs sub-second peers. Likely SDK internal retry on URLError. Not a failure, but flag if it grows or starts timing out. | 2026-04-28   |

## Coverage gap observations (notes only — DO NOT implement without instruction)

- **`NeighborhoodMapView` is unverified by unit tests.** Acceptable per `.claude/rules/testing.md` (we do not unit-test SwiftUI view bodies), but if Listing Detail ships with map interaction (pan/zoom/marker tap) those flows would only be exercisable via UI tests. Worth a manual-test entry in the ship-prep checklist for Listing Detail.
- **`ListingDetailViewModel` save-success callback `onSavedChanged`** is exercised in the success path and asserted absent on the rollback path. There is no test for the *unauth* path's effect on the parent — we assert the auth sheet appears and the service is not called, but not that `onSavedChanged` was not invoked. Low risk (the implementation calls it only after a successful service round-trip), but a one-line `#expect(observed.isEmpty)` in `toggleSave_whenUnauthenticated_*` would make that contract explicit.
- **`SupabaseListingService.fetchListing(id:)`** has no test for the "row exists but DTO decoding fails" path (e.g. server returns a row missing a non-optional column). The DTO uses `decodeIfPresent` defensively so this is a mid-priority gap, but worth a test if the schema starts churning.
- **No service-level test for `SupabaseListingService.toggleSave(_:listingID:)`.** The VM rollback path is covered, but the wire-level contract (insert vs delete on the `saved_listings` table, RLS-keyed) is not. This will matter when real auth ships.

## Open questions

- None.

## Next actions

- Wait for next inbox message or direct user invocation.
- If `Listing Detail` clears design-review and heads to `/ship-prep`, re-run the suite once more before the gate.
