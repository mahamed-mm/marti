---
description: Diagnose and fix a bug through the role pipeline. Usage: /fix-bug <short-description>
argument-hint: short bug description (e.g. "map shows deleted listings", "auth state leaks across sessions")
---

You are acting as **COO** for Marti (see the COO section of CLAUDE.md). A bug has been reported: `$ARGUMENTS`.

Bugs are different from features. You do NOT start with a spec — you start with a diagnosis. Follow this pipeline in order, and do not skip the checkpoints.

## Step 1 — Gather the report (COO, in this session)

1. Read `CLAUDE.md`, `.claude/jobs/coo/context/current.md`, and your most recent park doc.
2. Ask the user for enough information to reproduce the bug. Specifically:
   - What exact steps reproduce it?
   - What's the expected behavior vs actual?
   - Which devices / simulator / OS version / auth state?
   - Is it new, or has it always been there?
   - Any recent changes that might have introduced it (check git log if needed)
3. **→ CHECKPOINT 1**: Summarize the bug report back to the user in a "Given/When/Then" structure. Wait for confirmation that you've understood correctly before investigating.

## Step 2 — Hypothesis and investigation plan

1. Based on the symptoms, propose 2–4 hypotheses about which layer owns the bug. Examples:
   - UI state not updating (ios-engineer)
   - Cache returning stale data (ios-engineer + possibly backend-engineer)
   - RLS policy leak (backend-engineer)
   - Map annotation lifecycle (maps-engineer)
   - Race condition in Swift concurrency (ios-engineer)
2. Rank them by likelihood given the symptoms.
3. For each hypothesis, identify which role should investigate and what they should look at.
4. **→ CHECKPOINT 2**: Show the hypotheses ranked, and which role you propose to invoke first. Wait for user to approve or redirect.

## Step 3 — Investigate (delegate, read-only)

Invoke the **most-likely-owner role** as a subagent, with an **investigation-only** prompt. Example for ios-engineer:

> "READ-ONLY investigation. Bug: `$ARGUMENTS`. Hypothesis: <hypothesis>. Read the relevant files: <list>. Do NOT fix anything yet. Return a summary including: confirmed/rejected hypothesis, root cause if found, affected files, estimated fix size (trivial / small / medium / large), whether other roles need to be involved. Write your park doc."

The specialist reads its mandatory files, reads the suspect code, returns a diagnosis. It does not modify anything.

If the first role rejects the hypothesis or identifies another layer as the real owner, invoke the next role the same way. You may invoke 2–3 roles in sequence during investigation — but stop as soon as you have a confirmed root cause.

**→ CHECKPOINT 3**: Report the diagnosis to the user:

- Confirmed root cause
- Affected files
- Which role(s) will implement the fix
- Estimated size
- Any open questions

Wait for user to approve the fix plan.

## Step 4 — Write the regression test FIRST

Before fixing, delegate to **qa-engineer** with a prompt to write a test that reproduces the bug:

> "Write a Swift Testing unit test that reproduces the following bug: `$ARGUMENTS`. Root cause: <from step 3>. The test MUST fail on current code. Place in `marti/MartiTests/` mirroring source structure. Do NOT fix the production code. Return the test file path and confirmation that the test fails. Write your park doc."

If QA cannot write a test (e.g., bug is in SwiftUI View body that's hard to unit-test), it reports back and you skip this step for this bug — but log the untestable nature in `decisions.md`.

**→ CHECKPOINT 4**: Confirm the regression test is red. User approves to proceed to fix.

## Step 5 — Fix (delegate)

Invoke the owning role (or roles) with an explicit fix prompt. Include:

- Bug description
- Root cause from investigation
- Affected files
- Path to the failing regression test
- Instruction to verify the test turns green after the fix

Example:

> "Fix bug: `$ARGUMENTS`. Root cause: <from step 3>. Affected files: <list>. Failing regression test: <path>. After fix, verify the test passes. Run the full build. Write your park doc. Return a summary including: files changed, test status (regression test + full suite), build status."

If the fix crosses layers (e.g., backend-engineer removes a leaking RLS policy AND ios-engineer invalidates a cache), invoke the roles in the order the changes need to land. Pass each role's results forward to the next.

**→ CHECKPOINT 5**: Report fix results. If any test still fails, decide with user: iterate, revert, or park.

## Step 6 — Full QA pass

Invoke **qa-engineer** to run the full MartiTests suite. If any other test now fails (a fix that broke something else), return to Step 5 with the new failure info.

## Step 7 — COO close-out

Back in this session, acting as COO:

1. **Read all park docs** written during this bug investigation and fix.
2. **Log the bug in decisions.md.** Append an entry with:
   - Date
   - Bug description
   - Root cause
   - Fix summary
   - Files changed
   - Regression test path
   - Whether any architectural change was made to prevent the class of bug recurring
3. **Update PRD only if relevant.** Most bugs don't need PRD updates. If the bug revealed that a "shipped" feature wasn't actually working, update the PRD status back to 🚧 Partial or similar, and note what's now actually working.
4. **Update STATUS.md only if significant.** Small bugs don't get STATUS.md entries. Reserve for regressions that the user would want to see in the project timeline.
5. **→ CHECKPOINT 6**: Show any proposed PRD / STATUS.md / decisions.md changes. Wait for approval before writing.
6. Write your COO park doc at `.claude/jobs/coo/park/<YYYY-MM-DD>-coo.md`.

## Final output

Structured summary:

- **Bug**: `$ARGUMENTS`
- **Root cause**: one-line
- **Owning layer**: which role(s) fixed it
- **Files changed**: list with paths
- **Regression test**: path + status (green / untestable with reason)
- **Full suite**: ✅ passed / ❌ still failing
- **Time to diagnose**: (rough)
- **Time to fix**: (rough)
- **Logged in decisions.md**: ✅
- **Prevents recurrence**: yes/no (and how, if yes)

---

**Guardrails**:

- Step 3 investigation MUST be read-only. Do not let any subagent modify code during investigation. Diagnosis first, fix second.
- Step 4 regression test MUST be red before you invoke the fix in Step 5. Tests that are written alongside fixes (green from the start) don't prove the bug is actually fixed.
- If investigation reveals the bug is in production data (not code), STOP. Escalate to the user — production data issues require human judgment.
- If the fix introduces a new decision (e.g., "we're switching from optimistic to pessimistic UI updates"), append to `decisions.md` with full rationale.
- Never skip the regression test unless genuinely untestable, and log the untestable reason when you do.
