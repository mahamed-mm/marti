---
description: Generate ARCHITECTURE.md for this project from your description and existing context.
---

Generate `docs/ARCHITECTURE.md` for this project.

## Process

1. **Read context first:**
   - `CLAUDE.md` for stack, conventions, project-specific rules
   - `docs/PRD.md` if it exists, for what the app does and target users
   - Any existing `docs/specs/*.md` files for feature-level intent

2. **Ask me clarifying questions** if anything is unclear about architectural intent. Specifically probe for:
   - Persistence strategy (SwiftData? UserDefaults? Keychain? Files?)
   - Networking (REST? GraphQL? Offline-first? No network at all?)
   - State management beyond ViewModels (App-level state? Environment objects?)
   - Module/feature organization (single target? Swift packages? Workspace?)
   - Background work (notifications? widgets? background fetch?)
   - Authentication and security model
   - Third-party dependency policy
   - Testing strategy at the architectural level (what's tested, what's not, why)

3. **Do not invent answers.** If I don't know something, write "TBD" rather than guessing. Architecture docs that contain false certainty are worse than no docs.

4. **Write `docs/ARCHITECTURE.md`** with these sections:
   - **Overview** — one paragraph on what this app is, architecturally
   - **Key decisions** — numbered list of architectural choices with the *why* for each
   - **Module structure** — how code is organized (folders, packages, targets)
   - **Data flow** — how information moves through the system, end to end
   - **State management** — where state lives and how it's accessed
   - **Persistence** — what's stored, where, in what format
   - **Networking** — how the app talks to the outside world (or doesn't)
   - **Background & system integration** — notifications, widgets, background tasks
   - **Security & privacy** — what's protected, how
   - **Testing strategy** — what's tested at what level
   - **Known constraints** — things that are hard to change later
   - **Open questions** — anything still TBD

5. **End with a summary** of what's in the doc and any TBDs that need my input later.

## Style rules

- Concise paragraphs, not walls of text. 2-3 pages total, not 20.
- Each architectural decision includes the rationale ("we chose X because Y").
- Use diagrams sparingly — only if a textual explanation genuinely fails. ASCII art is fine.
- No marketing language, no "leveraging" or "best-in-class." Plain English.
- This doc explains the *current intended* architecture. For the *actual built* architecture, use `/audit-architecture` after code exists.

## When NOT to use this command

- Tiny single-screen apps (no architecture worth documenting)
- Throwaway prototypes
- When you have no PRD yet (run `/create-prd` first)

If the project doesn't justify an architecture doc, tell me so honestly instead of generating one for the sake of having one.
