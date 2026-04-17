---
description: Break a feature spec into implementable tasks.
argument-hint: <feature-name>
---

Break the feature spec into concrete, ordered tasks for: $ARGUMENTS

1. Read `docs/specs/$ARGUMENTS.md`.
2. Read `docs/tasks/template.md` for structure.
3. Identify every implementation step needed, ordered by dependency (Models first, then Services, then ViewModel, then View, then tests).
4. Each task should be small enough to complete in one focused Claude Code session.
5. Include explicit checkboxes for: implementation, tests, build passes, HIG review (for UI tasks).
6. Write to `docs/tasks/$ARGUMENTS.md`.

Do not write Swift code. This is task planning only.
