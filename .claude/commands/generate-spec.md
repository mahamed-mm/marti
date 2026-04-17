---
description: Generate a feature spec from the PRD.
argument-hint: <feature-name>
---

Generate a detailed feature specification for: $ARGUMENTS

1. Read `docs/PRD.md` and find the feature matching `$ARGUMENTS`.
2. Read `docs/specs/template.md` for structure.
3. Read `CLAUDE.md` for project conventions.
4. Write `docs/specs/$ARGUMENTS.md` filling in every section.
5. Think through the technical design carefully — Models, Services, ViewModel, Views, dependencies, edge cases.
6. End with any open questions that need my input before implementation begins.

Do not write any Swift code. This is design only.
