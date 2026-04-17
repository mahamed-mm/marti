---
description: Generate Swift Testing tests for a ViewModel or service.
---

Use the `test-writer` agent to add Swift Testing tests for: $ARGUMENTS

The agent will:
1. Read the target type and identify all public surface area.
2. Generate a test file using `@Suite` and `@Test`.
3. Create any test doubles needed (mocking dependencies via protocol conformance).
4. Cover happy path, error paths, edge cases, and state transitions.
5. Output coverage notes at the end.
