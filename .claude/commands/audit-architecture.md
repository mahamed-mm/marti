---
description: Audit the codebase and write a dated architecture snapshot to docs/audits/.
---

Audit the codebase and write `docs/audits/YYYY-MM-DD-architecture.md` based on what actually exists, not what was intended. **Do not touch `docs/ARCHITECTURE.md`** — that's the lean spec, maintained separately.

## Process

1. **Read context first:**
   - `CLAUDE.md` for stack and conventions
   - `docs/PRD.md` if it exists
   - `docs/ARCHITECTURE.md` (the lean spec — treat as intent)
   - Most recent file in `docs/audits/*-architecture.md` if present (for diff vs prior audit)

2. **Explore the codebase systematically.** Use Glob and Read to map:
   - Project/workspace structure (`.xcodeproj`, `.xcworkspace`, `Package.swift`)
   - Folder hierarchy under the main app target
   - Every `.swift` file in `Models/`, `Services/`, `ViewModels/`
   - `App.swift` (or equivalent `@main` entry point)
   - Test folders and what they cover
   - Any `.mcp.json`, `Info.plist`, entitlements, capabilities
   - SPM dependencies in `Package.resolved`

3. **Infer from code, don't guess:**
   - **Persistence:** `@Model`, Core Data, `UserDefaults`, `FileManager`, Keychain
   - **Networking:** `URLSession`, Supabase SDK, async patterns
   - **State management:** `@Observable`, `@State`, `@Environment`, `@AppStorage`
   - **Module boundaries:** cross-folder imports
   - **Background:** `BGTaskScheduler`, `WidgetKit`, `UNUserNotificationCenter`
   - **Auth/security:** Keychain, biometric APIs, RLS
   - **Testing:** what's tested, unit vs integration ratio

4. **Write `docs/audits/YYYY-MM-DD-architecture.md`** (use today's date) with sections:
   - **Snapshot** — audit date, head commit, branch, working-tree state
   - **Overview** — one paragraph, architecture as observed
   - **Module structure** — actual folder/target organization
   - **Data flow** — one real example traced end-to-end
   - **State management** — where state lives, from the code
   - **Persistence** — what's stored where, with file references
   - **Networking** — observed network layer or "none"
   - **Background & system integration** — widgets, notifications, background tasks
   - **Security & privacy** — observed protections + what was NOT verified
   - **Testing coverage** — what's tested, gaps
   - **Drift from spec** — places where code has drifted from `docs/ARCHITECTURE.md`
   - **Smells observed** — factually suspicious patterns
   - **Open questions** — things code alone couldn't answer
   - **Diff vs prior audit** — what changed since the last dated audit file

5. **End with a summary**: key drift points, and 2-3 concrete things worth addressing before the next feature lands.

## Style rules

- **Cite specific files.** `ViewModels/ListingDiscoveryViewModel.swift:42`, not "the discovery view model".
- **Don't editorialize beyond evidence.** Describe factually first, opinion second.
- **Don't invent architecture that isn't there.** If there's no real persistence layer, say so plainly.
- Mark inferences as inferences ("Appears to use SwiftData based on `@Model` usage in 4 files; no migration files found").

## Important

- **Never overwrite `docs/ARCHITECTURE.md`.** That file is the lean, stable spec.
- **Never create `docs/ARCHITECTURE.previous.md`.** Historical audits live in `docs/audits/` with dated filenames — that's the archive.
- If `docs/audits/` doesn't exist, create it.

## When this command earns its place

- After 3–5 features have been built
- Before a major refactor (establish baseline)
- When onboarding someone (or future-you) to the project
- When you suspect drift between intent and reality
- Before App Store submission, as a sanity check
