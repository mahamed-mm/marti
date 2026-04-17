---
description: Read the existing codebase and generate ARCHITECTURE.md from what actually exists.
---

Audit the codebase and write `docs/ARCHITECTURE.md` based on what actually exists, not what was intended.

## Process

1. **Read context first:**
   - `CLAUDE.md` for stack and conventions
   - `docs/PRD.md` if it exists
   - Existing `docs/ARCHITECTURE.md` if present (to compare intent vs reality)

2. **Explore the codebase systematically.** Use Glob and Read to map:
   - Project/workspace structure (`.xcodeproj`, `.xcworkspace`, `Package.swift`)
   - Folder hierarchy under the main app target
   - Every `.swift` file in `Models/`, `Services/`, `ViewModels/`
   - `App.swift` (or equivalent `@main` entry point)
   - Test folders and what they cover
   - Any `.mcp.json`, `Info.plist`, entitlements, capabilities
   - SPM dependencies in `Package.swift` or `.xcodeproj`

3. **Infer from code, don't guess:**
   - **Persistence:** look for `@Model`, `Core Data`, `UserDefaults`, `FileManager`, `Keychain` usage
   - **Networking:** look for `URLSession`, `Alamofire`, `URLRequest`, async networking patterns
   - **State management:** count `@Observable` classes, `@State`, `@Environment`, `@AppStorage` usage
   - **Module boundaries:** see what depends on what (imports across folders)
   - **Background:** look for `BGTaskScheduler`, `WidgetKit`, `UNUserNotificationCenter`
   - **Auth/security:** look for Keychain, biometric APIs, secure enclave
   - **Testing:** check what types are tested, ratio of unit to integration

4. **Write `docs/ARCHITECTURE.md`** with these sections:
   - **Snapshot** — when this audit was run, code state at that moment
   - **Overview** — one paragraph describing the architecture as observed
   - **Module structure** — actual folder/target organization with brief descriptions
   - **Data flow** — how data actually moves through the system, traced from one real example end to end
   - **State management** — what state lives where, observed from the code
   - **Persistence** — what's stored where, in what format (with file references)
   - **Networking** — actual network layer if any, or "no network layer present"
   - **Background & system integration** — observed widgets, notifications, background tasks
   - **Security & privacy** — observed protections, with caveats about what was NOT verified
   - **Testing coverage** — what types have tests, what doesn't, observed gaps
   - **Drift from intent** — if `docs/ARCHITECTURE.md` already existed, list places where the code has drifted from the original architecture
   - **Smells observed** — things that look architecturally suspicious (god objects, tight coupling, missing abstractions). Be honest but not preachy.
   - **Open questions** — things the audit couldn't determine from code alone

5. **End with a summary**: what changed since the last audit (if any), key drift points, and 2-3 concrete things worth addressing.

## Style rules

- **Cite specific files.** "ViewModels are `@Observable` classes" → "ViewModels are `@Observable` classes (see `App/ViewModels/SettingsViewModel.swift:12`)."
- **Don't editorialize beyond evidence.** If a pattern is suspicious, describe it factually first, opinion second.
- **Don't invent architecture that isn't there.** If there's no real persistence layer, say so plainly.
- Mark inferences as inferences when you can't verify ("Appears to use SwiftData based on `@Model` usage in 4 files; no migration files found yet").

## Important

If `docs/ARCHITECTURE.md` already exists, **back it up to `docs/ARCHITECTURE.previous.md`** before overwriting, so the original intent doc isn't lost. Mention this in your summary.

## When this command earns its place

- After 3-5 features have been built
- Before a major refactor (establish baseline)
- When onboarding someone (or future-you) to the project
- When you suspect drift between intent and reality
- Before App Store submission, as a sanity check
