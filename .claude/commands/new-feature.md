---
description: Implement a new feature end-to-end — scaffold, test, and HIG-review.
---

Implement a new feature: $ARGUMENTS

Run this pipeline:

1. **Check for spec.** If `docs/specs/$ARGUMENTS.md` exists, read it. If it doesn't, ask whether I want to skip the spec or run `/generate-spec $ARGUMENTS` first.

2. **Plan briefly.** State in 3–5 bullets what you understand the feature to be, what files will be created/modified, and any open questions. If anything is ambiguous, ask before proceeding.

3. **Build.** Use the `swiftui-builder` agent to scaffold Model → Service → ViewModel → View, following the rules in `CLAUDE.md`.

4. **Test.** Use the `test-writer` agent to generate Swift Testing tests for the new ViewModel.

5. **Verify build.** Use `mcp__xcodebuildmcp__build_sim_name_proj` to confirm the project still compiles. If it fails, identify the cause and propose a fix before continuing.

6. **Review UI.** Use the `hig-reviewer` agent to audit the new View(s).

7. **Update PRD.** Read `docs/PRD.md`. For the feature just shipped:
   - Update the `**Status:**` line (✅ Shipped / 🚧 Partial / ⏳ Not started).
   - Tick the acceptance-criteria checkboxes that this change actually satisfies.
   - If the feature added behaviour outside the original spec, append it under a `**Recent additions not in original spec:**` sub-bullet on that feature.
   - Bump the footer `*Last updated:*` date.
   Show the diff and ask for confirmation before writing. Skip silently if the change isn't represented in the PRD (e.g., infrastructure-only refactor, design-system polish) and note that in step 8.

8. **Summarize.** Output:
   - Files created/modified (with paths)
   - Test coverage summary
   - Build status (✅ passed / ❌ failed with cause)
   - HIG verdict (✅ / ⚠️ / ❌) with any blockers/majors listed
   - One-line wiring note (how to integrate into existing navigation)
   - PRD update (✅ updated / ⏭ skipped — reason)
