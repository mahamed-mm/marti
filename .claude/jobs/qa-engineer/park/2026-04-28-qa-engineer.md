# Park Document — qa-engineer — 2026-04-28

## Session summary

Independent verification pass on `/ship-feature Listing Detail` post-implementation. Goal: run the full `MartiTests` suite, confirm the 13 new tests pin the right behaviors, and confirm the existing Discovery regression test is still green. Outcome: clean pass — `** TEST SUCCEEDED **`, 98/98 test cases passed on `iPhone 17 Pro` simulator. All 13 new tests are present and exercise the contracts implied by `docs/specs/Listing Detail.md`. No failures, no inbox messages dispatched.

## Files touched

| File                                                          | Change   | Why                              |
| ------------------------------------------------------------- | -------- | -------------------------------- |
| `.claude/jobs/qa-engineer/context/current.md`                 | Modified | End-of-session state update      |
| `.claude/jobs/qa-engineer/park/2026-04-28-qa-engineer.md`     | Created  | Mandatory park doc               |
| `.claude/jobs/qa-engineer/history/20260428_1700-from-coo-Listing Detail.md` | Moved    | Inbox item processed             |

No production or test code modified — verification-only pass per the inbox brief.

## Decisions made

None. This pass was verification-only; no architecture or test-strategy choices were made.

Watch item only (not a decision): `SupabaseListingServiceTests/fetchListing_mapsURLErrorToNetwork()` reported 8s for this run while the rest of the suite is sub-second. The other two `fetchListing_*` tests are 0s. The 8s is consistent with the test stub returning `nil` from the responder which causes `URLProtocol` to fail with `URLError(.notConnectedToInternet)` only after the SDK's internal retry/timeout machinery exhausts. Not flaky in this run; flagging in current.md so we notice if it grows.

## Open questions / blockers

None.

## Inbox state at session end

- Processed and moved to history: `20260428_1700-from-coo-Listing Detail.md`
- Remaining unread: none

## Outbox summary

No messages sent. Suite was green; nothing to escalate.

## What the next session should do first

1. Read `docs/STATUS.md` to learn whether `/ship-feature Listing Detail` has shipped past design-review.
2. Read `.claude/jobs/qa-engineer/inbox/` for new bug or flake reports.
3. If `fetchListing_mapsURLErrorToNetwork()` has now appeared in two consecutive runs over 5s, dig into the SDK retry timeout and either:
   - Configure the test's stub session with a tighter timeout, OR
   - Message `backend-engineer` if the production `SupabaseListingService` retries are unbounded.
4. Once `Listing Detail` is post-design-review, confirm the suite still passes before any `/ship-prep`.

## Gotchas for next session

- `ListingDetailViewModelTests` uses a private `AsyncContinuationHolder` to deterministically interleave concurrent `toggleSave` taps without `sleep`. If you ever see this test flake, the issue is almost certainly that the production code changed when it captures `isSavingInFlight` — fix the production code, do not insert `sleep`.
- `SupabaseListingServiceTests` has its own `SupabaseStubURLProtocol` (separate from `StubURLProtocol` used by `CachedImageServiceTests`) so the two suites don't race the same static responder slot when Swift Testing parallelizes suites. Do not collapse them.
- `xcodebuild` will still emit SPM dependency-graph noise in stderr before the run starts — that is informational, not a failure. The truth is the `** TEST SUCCEEDED **` / `** TEST FAILED **` line at the very end.
- Default simulator is `iPhone 17 Pro` per `.claude/rules/build.md`. iPhone 16 Pro does not ship with Xcode 26.x.
- `Test Suite 'All tests'` summary line is sometimes absent from the tail of the log because Swift Testing intermixes its own summary; trust the `** TEST SUCCEEDED **` marker plus the per-test passed count.

## Session metadata

- **Duration**: approx. 6 minutes
- **Build state at end**: clean (verification-only; no source touched)
- **Test state at end**: passing — 98 test cases, 0 failures
