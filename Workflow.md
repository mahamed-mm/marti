# Workflow: Marti

The day-to-day loop for building Marti. `CLAUDE.md` owns the _rules_ (stack, conventions, file layout); this file owns the _sequencing_ — which slash command to run when, and in what order.

For current status (shipped features, active blockers, what's next), see [`docs/STATUS.md`](docs/STATUS.md). This file is evergreen — no dates, no per-feature bookkeeping.

---

## Feature-dev loop

For each new feature:

1. **`/generate-spec <feature>`** — writes `docs/specs/<feature>.md` derived from `PRD.md`.
2. **`/generate-tasks <feature>`** — breaks the spec into ordered tasks in `docs/tasks/<feature>.md`.
3. **`/new-feature <feature>`** — implements, adds Swift Testing coverage for ViewModels / Services, HIG-reviews.
4. **`/build` · `/test` · `/run-app`** — verify in the iPhone 17 Pro simulator after each meaningful chunk.
5. **Commit when green.** No AI-attribution in messages (see `CLAUDE.md`).

Skip `/generate-spec` only for trivial work (typo, single-field addition, copy tweak). For anything non-trivial, going straight to `/new-feature` means Claude makes design decisions you never approved.

---

## Audit cadence

Re-run both audits after every 3–5 features, and always before App Store submission:

- **`/audit-architecture`** — reads the real code and writes `docs/audits/YYYY-MM-DD-architecture.md`. Never touches the lean spec at `docs/ARCHITECTURE.md`.
- **`/audit-design`** — reads SwiftUI views and writes `docs/audits/YYYY-MM-DD-design.md`. Never touches the lean spec at `docs/DESIGN.md`.

Audits catch drift that's invisible from inside the work: dead tokens, duplicated chrome, stale file paths, animations that forgot about Reduce Motion. Read the latest audit, then update the lean spec and `docs/STATUS.md` with concrete cleanup items.

If an audit's findings should become a rule, promote them into `.claude/rules/*.md` — that's how Claude learns the project's house style without re-discovering it every session.

---

## Ship prep

- **`/ship-prep`** — full App Store readiness checklist.
- **`/review-ui <view>`** — HIG audit of a single screen.

Active submission blockers live in [`docs/STATUS.md`](docs/STATUS.md), not here.

---

## Command reference

| Command                  | Purpose                                                  |
| ------------------------ | -------------------------------------------------------- |
| `/create-prd`            | One-off: (re)generate `docs/PRD.md` from a description.  |
| `/generate-spec`         | Spec for one feature from the PRD.                       |
| `/generate-tasks`        | Ordered task list from a spec.                           |
| `/new-feature`           | Implement + test + HIG-review a feature end to end.      |
| `/build`                 | `xcodebuild` for the iPhone 17 Pro simulator.            |
| `/test`                  | Run the Swift Testing suite.                             |
| `/run-app`               | Build + install + launch on the booted simulator.        |
| `/add-tests`             | Generate Swift Testing tests for a ViewModel or service. |
| `/review-ui`             | HIG audit of a specific SwiftUI screen or component.     |
| `/audit-architecture`    | Write dated architecture snapshot to `docs/audits/`.     |
| `/audit-design`          | Write dated design snapshot to `docs/audits/`.           |
| `/document-architecture` | Generate the lean `docs/ARCHITECTURE.md` spec.           |
| `/document-design`       | Generate the lean `docs/DESIGN.md` spec.                 |
| `/ship-prep`             | App Store submission readiness checklist.                |

---

## Conventions

- **Stack, conventions, style, testing policy →** `CLAUDE.md` + `.claude/rules/*.md`.
- **Architecture spec (hand-maintained) →** `docs/ARCHITECTURE.md`.
- **Design-system spec (hand-maintained) →** `docs/DESIGN.md`.
- **Point-in-time observations →** `docs/audits/YYYY-MM-DD-*.md` (never edited after write).
- **Per-feature specs →** `docs/specs/<feature>.md`. Task breakdowns → `docs/tasks/<feature>.md`.
- **Current status, blockers, roadmap →** `docs/STATUS.md` (the one file that updates per feature ship).
- **SQL migrations run in order** — any new file under `docs/db/` must be numerically later than the previous one and idempotent for sample data.

---

_Edit this file only when the workflow itself changes — not when a feature ships._
