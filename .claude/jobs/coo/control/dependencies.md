# Dependencies — Marti

> COO-maintained. Cross-role blocking relationships and dependencies.
> Update when a role becomes blocked or unblocked.

## Active blockers

| Blocked role | Waiting on | What's needed | Since |
| ------------ | ---------- | ------------- | ----- |
| _(none)_     |            |               |       |

## External dependencies

Things outside the project that block or constrain work.

| Item                          | Type             | Status              | Impact           |
| ----------------------------- | ---------------- | ------------------- | ---------------- |
| Mapbox SDK v11 pinned tag     | Upstream release | Currently on `main` | Blocks ship-prep |
| Supabase project provisioning | Infra            | Provisioned         | —                |

## Standing cross-role relationships

These aren't blockers, but they're the normal contracts between roles.

- **ios-engineer ← backend-engineer**: Service protocol shapes. When backend changes a query contract, ios-engineer adapts.
- **ios-engineer ← maps-engineer**: Map view binding surface. When maps changes what's exposed to SwiftUI parents, ios-engineer adapts.
- **qa-engineer ← all engineers**: New features come with unit tests from the implementing engineer; qa-engineer owns suite health and integration coverage.
- **design-reviewer ← ios-engineer**: ios-engineer ships features; design-reviewer audits them before each milestone.
- **All ← coo**: COO sets priorities. Conflicts route to COO for arbitration.
