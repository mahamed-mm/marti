# Park Document — <role> — YYYY-MM-DD

> This is the end-of-session handoff. The next session of this role reads it first.
> Be specific. Future-you and future-other-roles will thank present-you.

## Session summary

One paragraph. What did this session accomplish? What was the goal going in vs. what actually happened?

## Files touched

| File                 | Change                       | Why             |
| -------------------- | ---------------------------- | --------------- |
| `path/to/file.swift` | Created / Modified / Deleted | One-line reason |

## Decisions made

For each decision, include:

- **What**: the decision in one sentence
- **Why**: rationale in 2–3 sentences
- **Alternatives considered**: what you rejected and why
- **Reversibility**: cheap to change later / expensive / one-way door

If the decision is architectural, also write an inbox message to COO so it lands in `control/decisions.md`.

## Open questions / blockers

- Anything you couldn't resolve. Be specific about what's needed to unblock.

## Inbox state at session end

- Which inbox items were processed (moved to history/)
- Which remain (name them, with priority)

## Outbox summary

- Messages sent this session, to whom, summary

## What the next session should do first

Ordered list. Be directive. "Read X. Then do Y. If Y succeeds, do Z."

## Gotchas for next session

Things that bit you this session that the next session should know about. Tribal knowledge goes here.

- Example: "The iPhone 17 Pro simulator needs to be booted manually first — `xcrun simctl boot 'iPhone 17 Pro'` — before `xcodebuild build` will find it. This cost me 20 minutes."

## Session metadata

- **Duration**: approx. X minutes
- **Build state at end**: clean / warnings / failing
- **Test state at end**: passing / N failures / not run
