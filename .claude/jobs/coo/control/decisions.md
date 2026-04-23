# Decisions — Marti

> COO-maintained. Append-only log of architectural and project-level decisions.
> Never delete or rewrite entries. If a decision is reversed, add a new entry referencing the old one.

Format per entry:

```
## YYYY-MM-DD — <Short decision title>

**Context**: What was the situation.
**Decision**: What we decided to do.
**Rationale**: Why.
**Alternatives considered**: What we rejected and why.
**Reversibility**: cheap / moderate / one-way door
**Proposed by**: <role>
```

---

## 2026-04-22 — Adopt role-based subagent pipeline for Claude Code

**Context**: Single-dev iOS project. Claude Code sessions forget state between invocations, causing repeated context re-explanation and occasional architectural drift when one session doesn't know what a prior session decided. Also, pushing all work through a single generic session causes context-window bloat on multi-concern features.

**Decision**: Adopt the `.claude/agents/` + `.claude/jobs/` pattern. The **main Claude Code session acts as COO** (instructions in `CLAUDE.md`). Five specialist subagents live in `.claude/agents/`: `ios-engineer`, `backend-engineer`, `maps-engineer`, `qa-engineer`, `design-reviewer`. A `/ship-feature <name>` slash command orchestrates the full feature pipeline with human checkpoints. Each role gets a persistent working directory under `.claude/jobs/<role>/` with `context/`, `history/`, `inbox/`, `outbox/`, `park/`. COO additionally writes to `.claude/jobs/coo/control/`.

**Rationale**:

- Park documents + persistent per-role context solve session state loss.
- Role separation isolates context windows — ios-engineer doesn't carry backend schema deliberation in its context, and vice versa.
- Main-session-as-COO (rather than COO as its own subagent) works around the constraint that subagents cannot chain-delegate to other subagents.
- COO centralization prevents two engineers making contradictory architectural calls without a tiebreaker.
- `/ship-feature` with checkpoints gives one-prompt pipeline UX without sacrificing human oversight at key moments (scope approval, manual Supabase migration, build-green gate, STATUS.md update).

**Alternatives considered**:

- Keep the existing linear command workflow only (`/generate-spec` → `/generate-tasks` → `/new-feature`). Rejected because it doesn't address session-state loss or context bloat.
- Make COO a subagent too. Rejected because Claude Code subagents cannot reliably chain-delegate to other subagents; the orchestrator needs to be the main session.
- Use a single generic "assistant" agent instead of five roles. Rejected because a one-prompt agent blurs UI/backend separation and the role prompts also function as guardrails.
- Full 20-job model from the Reddit reference that inspired this approach. Rejected as overkill for a one-person project.
- Fully autonomous `/ship-feature` with no checkpoints. Rejected because a pipeline that goes wrong 20 minutes in is worse than a checkpointed one that takes 30.

**Reversibility**: Cheap. `.claude/agents/`, `.claude/commands/ship-feature.md`, and `.claude/jobs/` can all be deleted without touching production code. CLAUDE.md revisions are in git history.

**Proposed by**: user / initial setup
