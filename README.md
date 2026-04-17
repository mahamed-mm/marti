# ios-claude-kit

A minimal, opinionated Claude Code setup for modern iOS development.
SwiftUI + MVVM, `@Observable`, Swift Testing, Swift 6 concurrency, XcodeBuildMCP.

Built and maintained by [@mahamed-mm](https://github.com/mahamed-mm).

---

## Using this kit on a new project

See **[WORKFLOW.md](./WORKFLOW.md)** for the full step-by-step checklist of how to start a new iOS project from this template — from `gh repo create` through your first feature.

The short version:

1. `gh repo create <app-name> --template mahamed-mm/ios-claude-kit --private --clone`
2. Rename `CLAUDE.md.template` → `CLAUDE.md` and customize it
3. Create the Xcode project inside the cloned folder
4. Open Claude Code, verify with `/mcp`
5. Run `/create-prd` → `/document-architecture` → `/document-design` → `/generate-spec` → `/new-feature`

Full details, troubleshooting, and the quick-reference card are in WORKFLOW.md.

---

## What's in here

```
ios-claude-kit/
├── CLAUDE.md.template              — project context, customize per app
├── WORKFLOW.md                     — how to use this kit (start here)
├── .mcp.json                       — XcodeBuildMCP server config
├── docs/
│   ├── PRD.md.template             — Product Requirements Document template
│   ├── specs/template.md           — feature spec template
│   └── tasks/template.md           — task breakdown template
└── .claude/
    ├── settings.json               — permissions + hook wiring
    ├── hooks/
    │   └── post-swift-edit.sh      — runs SwiftLint after Claude edits Swift files
    ├── agents/
    │   ├── swiftui-builder.md      — implements features (Model → Service → ViewModel → View)
    │   ├── hig-reviewer.md         — audits screens against Apple HIG
    │   └── test-writer.md          — generates Swift Testing tests
    └── commands/
        ├── create-prd.md           — /create-prd
        ├── document-architecture.md — /document-architecture
        ├── document-design.md      — /document-design
        ├── generate-spec.md        — /generate-spec <feature>
        ├── generate-tasks.md       — /generate-tasks <feature>
        ├── new-feature.md          — /new-feature <description>
        ├── build.md                — /build
        ├── test.md                 — /test
        ├── run-app.md              — /run-app
        ├── review-ui.md            — /review-ui [file]
        ├── add-tests.md            — /add-tests <type>
        ├── audit-architecture.md   — /audit-architecture
        ├── audit-design.md         — /audit-design
        └── ship-prep.md            — /ship-prep
```

15 slash commands, 3 agents, 1 hook, 1 MCP server. Covers the full lifecycle: planning → design → build → test → audit → ship.

---

## Prerequisites

Before using this kit on a real iOS project, install these once on your Mac:

### 1. Claude Code

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Or via npm: `npm install -g @anthropic-ai/claude-code`

### 2. XcodeBuildMCP

XcodeBuildMCP is the MCP server that gives Claude direct control over Xcode builds, simulators, tests, and logs. Without it, the `/build`, `/test`, and `/run-app` commands won't work.

The `.mcp.json` in this kit configures it automatically — but the server itself runs via `npx`, so you need Node.js installed:

```bash
# If you don't have Node.js
brew install node
```

That's it. When you open Claude Code in a project with this kit, it'll auto-install XcodeBuildMCP on first use.

Verify inside Claude Code with `/mcp` — you should see `XcodeBuildMCP` listed.

### 3. SwiftLint (optional, recommended)

The `post-swift-edit.sh` hook runs SwiftLint after Claude writes or edits Swift files, so style violations surface immediately.

```bash
brew install swiftlint
```

Create a `.swiftlint.yml` in each project root. The hook silently skips if SwiftLint isn't installed or no config is present — it won't break anything.

---

## Quick start

### Option A — Use as a GitHub template (recommended)

1. On GitHub, click **Use this template** → **Create a new repository**.
2. Clone the new repo locally.
3. Rename `CLAUDE.md.template` → `CLAUDE.md` and fill in the bracketed sections.
4. Rename `docs/PRD.md.template` → `docs/PRD.md` (or run `/create-prd` later).
5. Open the project in Claude Code. Run `/mcp` to verify XcodeBuildMCP loaded.
6. Start building.

### Option B — Clone into an existing project

```bash
cd path/to/your-existing-app
git clone --depth 1 https://github.com/mahamed-mm/ios-claude-kit /tmp/ios-kit
cp -r /tmp/ios-kit/.claude .
cp -r /tmp/ios-kit/docs .
cp /tmp/ios-kit/.mcp.json .
cp /tmp/ios-kit/CLAUDE.md.template CLAUDE.md
cp /tmp/ios-kit/docs/PRD.md.template docs/PRD.md
rm -rf /tmp/ios-kit
```

Edit `CLAUDE.md` and `docs/PRD.md` to match the project. Commit.

### Option C — Install globally (user-level)

For the agents, commands, and hooks to be available in every project:

```bash
mkdir -p ~/.claude
cp -r .claude/agents ~/.claude/
cp -r .claude/commands ~/.claude/
cp -r .claude/hooks ~/.claude/
```

Note: `.mcp.json` and `.claude/settings.json` are project-specific and should not be copied globally. XcodeBuildMCP should only activate in iOS projects.

---

## The 15 commands

Detailed usage and timing in [WORKFLOW.md](./WORKFLOW.md). Quick overview:

| Command | What it does | When to run |
|---|---|---|
| `/create-prd` | Interviews you and writes `docs/PRD.md` | At project start |
| `/document-architecture` | Generates `docs/ARCHITECTURE.md` from your description | After PRD, before any feature |
| `/document-design` | Generates `docs/DESIGN.md` (visual system) from your description | After architecture, before any view |
| `/generate-spec <feature>` | Writes `docs/specs/<feature>.md` from the PRD | Before implementing a feature |
| `/generate-tasks <feature>` | Breaks the spec into ordered steps | After spec, before implementation |
| `/new-feature <feature>` | Implements, tests, builds, HIG-reviews | When ready to build |
| `/build` | Builds for iPhone 16 simulator | Anytime |
| `/test` | Runs the test suite | Anytime |
| `/run-app` | Builds, installs, launches, captures logs | Anytime |
| `/review-ui <file>` | HIG audit of a specific SwiftUI file | After any view change |
| `/add-tests <ViewModel>` | Generates Swift Testing tests | After any ViewModel change |
| `/audit-architecture` | Reads code, writes ARCHITECTURE.md from reality | After 3-5 features |
| `/audit-design` | Reads views, writes DESIGN.md from observed patterns | After 3-5 views |
| `/ship-prep` | App Store readiness checklist | Before submission |

---

## Permissions

The included `.claude/settings.json` sets a sensible default:

- ✅ Allows: reading, writing, editing, all XcodeBuildMCP tools, safe git commands, Swift/SwiftLint.
- ❌ Denies: reading or writing `.env*`, `Secrets.swift`, `GoogleService-Info.plist`. Also denies `rm -rf`, `git push`, and `git reset --hard`.

You can tighten or loosen this per project. For sensitive client work, consider starting sessions in plan mode: `claude --permission-mode plan`.

---

## Customizing per project

The things that change per project:

- `CLAUDE.md` — stack, architecture notes, project-specific rules.
- `docs/PRD.md` — what the app is and who it's for.
- `docs/ARCHITECTURE.md` — generated by `/document-architecture` or `/audit-architecture`.
- `docs/DESIGN.md` — generated by `/document-design` or `/audit-design`.
- `.swiftlint.yml` — lint rules for this codebase.
- (Optional) extra entries in `.claude/settings.json` if the project has unusual tooling.

The things that stay the same:

- Agents (`swiftui-builder`, `hig-reviewer`, `test-writer`).
- Slash commands.
- The hook script.

That separation is the point: context changes, tools don't.

---

## Philosophy

This kit is intentionally minimal. Three agents, fifteen commands, one hook, one MCP server. Add more only when you feel a real gap — never preemptively.

When you find yourself doing the same thing manually three times, that's the signal to add an agent or command. Until then, less is more.

---

## Version history

- **v2.1** — Added four documentation commands: `/document-architecture`, `/document-design`, `/audit-architecture`, `/audit-design`. The `document-*` pair captures intent before building; the `audit-*` pair captures reality after building. Updated WORKFLOW.md with timing guidance.
- **v2** — Added XcodeBuildMCP integration, PRD/spec/tasks workflow, SwiftLint post-edit hook, project settings with safe defaults, planning commands (`/create-prd`, `/generate-spec`, `/generate-tasks`), build commands (`/build`, `/test`, `/run-app`). Updated `/new-feature` to verify the build after implementation.
- **v1** — Initial release. Three agents, four commands, CLAUDE.md template.

---

## License

MIT. Use it, fork it, change it, ship it.
