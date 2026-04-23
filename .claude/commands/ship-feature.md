---
description: Ship a feature end-to-end through the role pipeline. Usage: /ship-feature <feature-name>
argument-hint: feature-name (e.g. wishlist, bookings, messaging)
---

You are acting as **COO** for Marti (see the COO section of CLAUDE.md). You will now ship the feature `$ARGUMENTS` end-to-end by orchestrating the role pipeline.

Do NOT skip the checkpoints. Pause and report to the user at each `→ CHECKPOINT` step, wait for explicit confirmation before continuing.

## Step 1 — Plan and spec (COO, in this session)

1. Read `docs/PRD.md` and find the section describing `$ARGUMENTS`. If the feature isn't in the PRD, stop and ask the user for a brief description.
2. Read `docs/STATUS.md`, `docs/ARCHITECTURE.md`, `.claude/jobs/coo/control/objectives.md`, `.claude/jobs/coo/control/decisions.md`.
3. **Check for existing spec.** If `docs/specs/$ARGUMENTS.md` already exists, read it and use it — do not regenerate. If it doesn't exist, you'll create it below.
4. Propose the scope of this feature in 5–10 bullets. Identify which roles need to be involved (ios-engineer, backend-engineer, maps-engineer, qa-engineer, design-reviewer) and in what order. Flag any ambiguous requirements as open questions.
5. **→ CHECKPOINT 1**: Report the proposed scope, role sequence, and any open questions to the user. Wait for "approved" or adjustments.

Once approved:

6. If no spec exists, run `/generate-spec $ARGUMENTS` to write `docs/specs/$ARGUMENTS.md`.
7. Run `/generate-tasks $ARGUMENTS` to write `docs/tasks/$ARGUMENTS.md`.
8. Append to `.claude/jobs/coo/control/objectives.md`: a new active objective for this feature.
9. If the scope implies an architectural decision, append to `decisions.md`.

## Step 2 — Backend work (delegate, if needed)

If the feature needs schema changes or new Supabase endpoints:

1. Write an inbox message at `.claude/jobs/backend-engineer/inbox/<YYYYMMDD_HHMM>-from-coo-$ARGUMENTS.md` using the template at `.claude/jobs/_templates/message-template.md`. Include: objective, acceptance criteria, relevant spec file, the specific PostgREST shape required by ios-engineer.
2. Invoke the **backend-engineer** subagent with an explicit prompt: "Process your inbox. Implement the migration and PostgREST contract for $ARGUMENTS. Write your park doc. Return a summary including: the migration filename, the PostgREST response shape, any blockers requiring manual Supabase steps."
3. **→ CHECKPOINT 2**: Report backend-engineer's summary to the user. If the migration requires a manual Supabase step, pause for the user to run it and confirm "migration applied" before continuing.

If no backend work is needed, skip this step and log "no backend work needed" in your mental state.

## Step 3 — Maps work (delegate, if needed)

If the feature touches the map view, tiles, annotations, or Mapbox configuration:

1. Write an inbox message to `.claude/jobs/maps-engineer/inbox/`.
2. Invoke the **maps-engineer** subagent with an explicit prompt referencing the spec.
3. Wait for the summary.

If no maps work is needed, skip.

## Step 4 — iOS work (delegate)

Almost every feature has iOS work. Even pure backend features usually need client adaptation.

1. Write an inbox message to `.claude/jobs/ios-engineer/inbox/` including:
   - Link to the spec
   - PostgREST contract from backend-engineer (from step 2's summary)
   - Map interface contract from maps-engineer (from step 3's summary, if applicable)
   - Acceptance criteria from the tasks file
2. Invoke the **ios-engineer** subagent. Prompt: "Process your inbox. Implement $ARGUMENTS per spec, following Model → Service → ViewModel → View order. Write Swift Testing unit tests for any new ViewModel. Verify the build succeeds (use `mcp__xcodebuildmcp__build_sim_name_proj` if available, otherwise `xcodebuild`). Write your park doc. Return a summary including: files created/modified with paths, test coverage summary, build status (✅ passed / ❌ failed with cause), any blockers."
3. **→ CHECKPOINT 3**: Report ios-engineer's summary. If build failed, ask the user whether to retry or stop.

## Step 5 — QA

1. Write an inbox message to `.claude/jobs/qa-engineer/inbox/` referencing the feature and its tasks file.
2. Invoke the **qa-engineer** subagent. Prompt: "Run the full MartiTests suite. Triage any failures. If failures touch $ARGUMENTS, write inbox messages to the owning engineer with repro steps. Write your park doc. Return a summary."
3. If QA reports failures owned by engineers, return to Step 4 (iOS) or Step 2 (backend) with the repro info. Do NOT proceed to design review with a red suite.

## Step 6 — Design review (if UI-facing)

If the feature has UI surface:

1. Write an inbox message to `.claude/jobs/design-reviewer/inbox/`.
2. Invoke the **design-reviewer** subagent. Prompt: "Run an audit on the new $ARGUMENTS surfaces. Write findings to `docs/audits/<YYYY-MM-DD>-design-audit-$ARGUMENTS.md`. Write your park doc. Return a summary of severities (blocker / major / minor / nit)."
3. If design reports blockers or majors, loop back to Step 4 with the findings. Do NOT proceed to close-out with unresolved blockers.

## Step 7 — COO close-out

Back in this session, acting as COO:

1. **Read all park docs written this session**: backend (if applicable), maps (if applicable), ios, qa, design (if applicable).
2. **Update objectives.md**: move `$ARGUMENTS` from Active to Completed in `.claude/jobs/coo/control/objectives.md`.
3. **Log decisions**: if any architectural decisions emerged during implementation (from park docs or your own calls during arbitration), append to `.claude/jobs/coo/control/decisions.md` with date, rationale, alternatives considered, reversibility.
4. **Update PRD.** Read `docs/PRD.md`. For the feature just shipped:
   - Update the `**Status:**` line (✅ Shipped / 🚧 Partial / ⏳ Not started).
   - Tick the acceptance-criteria checkboxes that this change actually satisfies, based on what the engineer park docs reported.
   - If the feature added behaviour outside the original spec, append it under a `**Recent additions not in original spec:**` sub-bullet on that feature.
   - Bump the footer `*Last updated:*` date.
   - If the shipped work isn't represented in the PRD (e.g., infrastructure-only refactor, design-system polish), skip the PRD update silently and note it in the final summary.
5. **Propose STATUS.md updates** reflecting the shipped feature at the phase/milestone level.
6. **→ CHECKPOINT 4**: Show the proposed PRD diff and STATUS.md diff to the user. Wait for approval before writing either file.
7. On approval, write both updates. Then write your COO park doc at `.claude/jobs/coo/park/<YYYY-MM-DD>-coo.md`.
8. Update `.claude/jobs/coo/context/current.md` to reflect the new baseline.

## Final output

Once complete, report to the user in this structure:

- **Files changed** (grouped by role, with paths)
- **Test coverage summary** (new tests written, suite pass rate)
- **Build status** (✅ passed / ❌ failed with cause)
- **Design verdict** (✅ / ⚠️ / ❌) with any blockers/majors listed, and path to the audit report
- **One-line wiring note**: how to integrate into existing navigation or app state
- **Decisions logged**: any new entries added to `decisions.md`
- **PRD update status** (✅ updated / ⏭ skipped — reason)
- **STATUS.md update status** (✅ updated)
- **Unresolved items**: anything parked for follow-up

---

**Guardrails**:

- If any subagent fails or returns an error, STOP. Do not attempt to proceed. Report the error and ask the user how to handle it.
- If the scope of the feature expands mid-pipeline (a role discovers the spec was incomplete), STOP at the next checkpoint, write what was learned into the spec file, and ask the user to re-approve scope before continuing.
- Never skip writing the park docs, even if the user is in a hurry. They are the durable record.
- Never write to `docs/PRD.md` or `docs/STATUS.md` without explicit user approval at CHECKPOINT 4. Show the diff first.
