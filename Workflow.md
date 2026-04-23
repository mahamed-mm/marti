# Workflow: Marti

The day-to-day loop for building Marti. `CLAUDE.md` owns the _rules_ (stack, conventions, file layout) and defines the **COO role** the main Claude Code session plays. This file owns the _sequencing_ — which slash command to run when, and how roles hand off work.

For current status (shipped features, active blockers, what's next), see [`docs/STATUS.md`](docs/STATUS.md). This file is evergreen — no dates, no per-feature bookkeeping.

---

## How the role system works

The main Claude Code session **is the COO** — orchestrator, spec writer, decision logger. It never writes Swift code directly (except trivial glue). For implementation, COO delegates to five specialist subagents:

| Subagent           | Owns                                                                  |
| ------------------ | --------------------------------------------------------------------- |
| `ios-engineer`     | SwiftUI views, `@Observable` ViewModels, SwiftData models, navigation |
| `backend-engineer` | Supabase schema, SQL migrations, RLS, Auth, Realtime                  |
| `maps-engineer`    | Mapbox SDK, map views, tiles, clustering, tokens                      |
| `qa-engineer`      | Swift Testing suite health, failure triage, quality gates             |
| `design-reviewer`  | HIG compliance, design tokens, visual audits                          |

Each role runs in its own fresh context window when invoked, and each has persistent state under `.claude/jobs/<role>/` (context, inbox, park docs). Full protocol: [`.claude/jobs/README.md`](.claude/jobs/README.md).

COO additionally maintains strategic docs in `.claude/jobs/coo/control/`:

- `objectives.md` — current feature priorities
- `decisions.md` — append-only architectural decision log
- `dependencies.md` — cross-role blockers
- `index.md` — hand-maintained pointer index

---

## Feature-dev loop

For each new feature:

1. **`/ship-feature <feature>`** — runs the full pipeline end-to-end:
   - Step 1: COO reads PRD, proposes scope → **CHECKPOINT 1** (approve scope)
   - Step 2: Delegate to `backend-engineer` if schema changes needed → **CHECKPOINT 2** (apply migration)
   - Step 3: Delegate to `maps-engineer` if map changes needed
   - Step 4: Delegate to `ios-engineer` for SwiftUI + tests → **CHECKPOINT 3** (build status)
   - Step 5: Delegate to `qa-engineer` for full test suite
   - Step 6: Delegate to `design-reviewer` if UI-facing
   - Step 7: COO close-out: updates `objectives.md`, logs decisions, updates PRD + STATUS.md → **CHECKPOINT 4** (approve diffs)

2. **`/build` · `/test` · `/run-app`** — verify in the iPhone 17 Pro simulator after each meaningful chunk.
3. **Commit when green.** No AI-attribution in messages (see `CLAUDE.md`).

For trivial work (typo, single-field addition, copy tweak) skip `/ship-feature` — invoke the relevant specialist directly, or do it in the main session. Always write a brief park doc even for small changes.

---

## Narrower commands (single-step)

`/ship-feature` wraps these, but you can invoke them individually for partial work:

| Command           | Purpose                                                 |
| ----------------- | ------------------------------------------------------- |
| `/generate-spec`  | Spec for one feature from the PRD                       |
| `/generate-tasks` | Ordered task list from a spec                           |
| `/add-tests`      | Generate Swift Testing tests for a ViewModel or service |
| `/review-ui`      | HIG audit of a specific SwiftUI screen or component     |

---

---

## Bug-fix loop

Bugs have a different shape than features — you don't know yet which layer owns the problem, so you can't start with a spec. The pipeline is diagnose → scope → fix → verify.

Use **`/fix-bug <description>`** when the root cause is unclear. The pipeline:

- Step 1: COO gathers the report (steps to reproduce, expected vs actual) → **CHECKPOINT 1** (confirm reproduction)
- Step 2: COO proposes ranked hypotheses about which layer owns the bug → **CHECKPOINT 2** (approve investigation path)
- Step 3: Delegate to the most-likely-owner role for **read-only** investigation → **CHECKPOINT 3** (approve fix plan)
- Step 4: Delegate to `qa-engineer` to write a failing regression test → **CHECKPOINT 4** (confirm test is red)
- Step 5: Delegate the fix to the owning role → **CHECKPOINT 5** (verify test turns green)
- Step 6: Full QA pass to catch any new regressions
- Step 7: COO close-out logs the bug and fix in `decisions.md` → **CHECKPOINT 6** (approve log entry)

For small, obvious bugs where the layer is already clear (e.g., "this ViewModel doesn't publish its empty state"), skip `/fix-bug` — invoke the relevant specialist directly with a terse bug description. Reserve `/fix-bug` for bugs where diagnosis matters more than the fix.

For regressions caught by `/ship-feature` Step 5 (QA), no new command is needed — the feature pipeline loops automatically back to the owning engineer with the failing test info.

## Audit cadence

Re-run both audits after every 3–5 features, and always before App Store submission:

- **`/audit-architecture`** — reads the real code and writes `docs/audits/YYYY-MM-DD-architecture.md`. Never touches the lean spec at `docs/ARCHITECTURE.md`.
- **`/audit-design`** — reads SwiftUI views and writes `docs/audits/YYYY-MM-DD-design.md`. Never touches the lean spec at `docs/DESIGN.md`.

Audits catch drift that's invisible from inside the work: dead tokens, duplicated chrome, stale file paths, animations that forgot about Reduce Motion. Read the latest audit, then update the lean spec and `docs/STATUS.md` with concrete cleanup items.

If an audit's findings should become a rule, promote them into `.claude/rules/*.md` — that's how Claude learns the project's house style without re-discovering it every session. If a finding should become a role-level constraint, add it to the relevant `.claude/agents/<role>.md` instead.

---

## Ship prep

- **`/ship-prep`** — full App Store readiness checklist.
- **`/review-ui <view>`** — HIG audit of a single screen.

Active submission blockers live in [`docs/STATUS.md`](docs/STATUS.md), not here.

---

## Command reference

| Command                  | Purpose                                                 |
| ------------------------ | ------------------------------------------------------- |
| `/ship-feature`          | End-to-end feature pipeline through the role system     |
| `/fix-bug`               | Diagnose and fix a bug through the role pipeline        |
| `/create-prd`            | One-off: (re)generate `docs/PRD.md` from a description  |
| `/generate-spec`         | Spec for one feature from the PRD                       |
| `/generate-tasks`        | Ordered task list from a spec                           |
| `/build`                 | `xcodebuild` for the iPhone 17 Pro simulator            |
| `/test`                  | Run the Swift Testing suite                             |
| `/run-app`               | Build + install + launch on the booted simulator        |
| `/add-tests`             | Generate Swift Testing tests for a ViewModel or service |
| `/review-ui`             | HIG audit of a specific SwiftUI screen or component     |
| `/audit-architecture`    | Write dated architecture snapshot to `docs/audits/`     |
| `/audit-design`          | Write dated design snapshot to `docs/audits/`           |
| `/document-architecture` | Generate the lean `docs/ARCHITECTURE.md` spec           |
| `/document-design`       | Generate the lean `docs/DESIGN.md` spec                 |
| `/ship-prep`             | App Store submission readiness checklist                |

---

## Conventions

- **Stack, conventions, style, testing policy →** `CLAUDE.md` + `.claude/rules/*.md`.
- **Role definitions (subagent prompts) →** `.claude/agents/*.md`.
- **Role-state protocol →** `.claude/jobs/README.md`.
- **Architecture spec (hand-maintained) →** `docs/ARCHITECTURE.md`.
- **Design-system spec (hand-maintained) →** `docs/DESIGN.md`.
- **Point-in-time observations →** `docs/audits/YYYY-MM-DD-*.md` (never edited after write).
- **Per-feature specs →** `docs/specs/<feature>.md`. Task breakdowns → `docs/tasks/<feature>.md`.
- **Current status, blockers, roadmap →** `docs/STATUS.md` (updates per feature ship).
- **Architectural decisions →** `.claude/jobs/coo/control/decisions.md` (append-only log).
- **SQL migrations run in order** — any new file under `docs/db/` must be numerically later than the previous one and idempotent for sample data.

---

_Edit this file only when the workflow itself changes — not when a feature ships._
