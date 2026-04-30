# Park Document — coo — 2026-04-30 (cancellation-policy whitespace hardening)

> This is the end-of-session handoff. The next session of this role reads it first.
> This is the **third** piece of 2026-04-30 work after the doc reconcile and the photo-index clamp captured in `2026-04-30-coo.md`.

## Session summary

`/fix-bug` invoked under the rubric "verify each finding against the current
code and only fix it if needed." Finding: the free-cancellation gate at
`ListingDetailStickyFooterView.swift:103-105` lowercases but does not trim
the `cancellationPolicy` string, so a hand-edited `" strict "` row would
slip past the gate and render "Free cancellation" on top of a Strict
listing.

Verified the finding directly against the source. The finding is correct.
Risk profile is low today — DB schema (`docs/db/001_listings.sql:22`)
defaults to `'flexible'` and there is no host-write path yet — but the
schema also has no CHECK constraint, so any malformed string can in
principle be persisted. Cost of the hardening is one expression per call
site.

While verifying, found a parallel site at
`ListingCancellationPolicyView.swift:32` (`policy.lowercased()` feeding
both `displayName` and `subtitle`). Hardening only the footer would have
left the two surfaces disagreeing on the same listing — footer would say
"Free cancellation" while the policy section would render the raw
`" strict "` string with no subtitle. Hardened both for consistency.

Executed directly in the COO main session per CLAUDE.md trivial-fix
routing. The prior 2026-04-30 park doc already records that subagent
delegation has been getting trapped in harness plan-mode gates for edits
this small.

Build: green on iPhone 17 Pro. Tests: 99/99 passing (count unchanged —
view-only edits cannot move the count).

## Files touched

| File | Change | Why |
| ---- | ------ | --- |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift` | Modified | `showFreeCancellation` now trims whitespace+newlines before lowercasing the policy. |
| `marti/Marti/Views/ListingDetail/Components/ListingCancellationPolicyView.swift` | Modified | `key` (used by both `displayName` and `subtitle`) now trims whitespace+newlines before lowercasing. |
| `.claude/jobs/coo/context/current.md` | Modified | Logged the hardening + the deferred backend follow-up. |
| `.claude/jobs/coo/park/2026-04-30-coo-cancellation-policy.md` | Created | This park doc. |

## Decisions made

- **What**: Apply whitespace-trim hardening at both UI surfaces of the cancellation-policy gating. Do not touch the DTO, the model, the schema, or introduce a `CancellationPolicy` enum.
  - **Why**: The finding identifies a real defensive gap. The fix is one expression per site, with zero behavioral change for clean data. Anything bigger (enum, schema CHECK, DTO normalization) is the right structural answer but lives in the backend-engineer + ios-engineer lanes and should land alongside the host-write path, not as a drive-by today.
  - **Alternatives considered**:
    - Single-site fix (footer only). Rejected — would leave footer and section disagreeing on the same listing.
    - Postgres CHECK constraint + Swift enum. Right call long-term, but premature with no host-write path; would need a backend-engineer entry in `decisions.md` and is overkill for a fenced-off field.
    - Trim at the DTO `init(from:)` boundary. Cleaner conceptually (one place fixes all consumers) but touches the Codable path and the model layer for one ambiguous field.
  - **Reversibility**: Cheap. Two one-line reverts if the DB enum / Swift enum lands later.
- **What**: Skip the regression test.
  - **Why**: `.claude/rules/testing.md` says "Test ViewModels and Services. Do **not** test SwiftUI view bodies." Both affected computed properties (`showFreeCancellation`, `key`) are `private` View internals. Adding a test would require either lifting the helper into a testable namespace (overkill for hardening) or reaching into a private property via `@testable` (against project convention). The `/fix-bug` rubric explicitly allows skipping tests for untestable-by-convention code provided the reason is logged.
  - **Reversibility**: One-way for this fix, but reversible structurally — the right time to add coverage is when the policy enum lands and the helper moves out of the View.

Neither decision is architectural; not appending to `decisions.md`.

## Open questions / blockers

None.

## Inbox state at session end

Empty. No new inbox traffic this session.

## Outbox summary

No outbound messages — work executed in the main session, no specialist delegation.

## What the next session should do first

1. Read `.claude/jobs/coo/context/current.md` and both 2026-04-30 park docs (the AM photo-index doc and this PM cancellation-policy doc).
2. Confirm with the user whether to commit the working tree. Three pieces are now uncommitted: the v2 visual pass, the photo-index clamp + its test, and today's cancellation-policy hardening. None have been pushed.
3. Pick up Request to Book (P0 per `STATUS.md`) — Listing Detail's sticky CTA (`RequestToBookComingSoonSheet`) is still the wire-through point.

## Gotchas for next session

- **SourceKit phantom diagnostics struck again.** Both view files threw a wave of "Cannot find 'Spacing' / 'Color.dividerLine' / 'martiHeading4'" errors after the edits — every one of those identifiers is genuinely in scope and the build was green. Trust `xcodebuild`, ignore the editor diagnostics. Pattern is identical to the 2026-04-29 v2 ship.
- **Case-insensitive FS, mixed casing in tools.** Initial `Edit` to `ListingCancellationPolicyView.swift` failed with "File has not been read yet" because the prior `Read` used `marti/Marti/...` (capital M) and the `Edit` retried with `marti/marti/...` (lowercase). The Read tracker is case-sensitive even though the FS isn't. Re-Read with the same casing as the planned Edit and it works. Worth remembering if you bounce between absolute paths.
- **Test count is 99/99**, not 98 and not 97. `STATUS.md` still references the older "98/98" baseline — reconcile next time `STATUS.md` is touched (carry-over from the AM session).
- **Deferred follow-up logged**: cancellation-policy CHECK constraint + `CancellationPolicy` Swift enum should land alongside the host-write path. Both client-side trims become dead weight once the schema rejects malformed values. Don't forget this when host-write begins.

## Session metadata

- **Duration**: ~10 minutes (verify, plan, two edits, build, tests, COO docs).
- **Build state at end**: clean. `xcodebuild build` succeeded on iPhone 17 Pro (Xcode 26.x).
- **Test state at end**: 99/99 passing. `** TEST SUCCEEDED **`.
