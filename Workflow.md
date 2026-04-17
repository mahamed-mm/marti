# Workflow: Starting a new iOS project

This is the step-by-step checklist for going from "I have an idea" to "I'm building features" using this kit. Follow it in order the first few times. After 3-4 projects you'll know which steps you can compress.

---

## Prerequisites (one-time, ever)

Done once on your Mac. Skip this section if you've already set these up.

```bash
brew install node          # required by XcodeBuildMCP
brew install swiftlint     # required by the post-edit hook
curl -fsSL https://claude.ai/install.sh | bash    # Claude Code itself
```

Verify:

```bash
node --version
swiftlint --version
claude --version
```

If any of these fail, fix that first. The kit assumes all three are present.

---

## The 7-step workflow

### Step 1 — Create the repo from the template

On GitHub: go to `github.com/mahamed-mm/ios-claude-kit` → click the green **Use this template** button → **Create a new repository**.

- **Owner:** mahamed-mm
- **Repository name:** lowercase with hyphens (e.g. `saakin-v2`, `matspor`, `billbuddy-ios`)
- **Visibility:** Private for client work, Public if it's a portfolio piece
- Click **Create repository**

Or with `gh` CLI:

```bash
gh repo create <app-name> --template mahamed-mm/ios-claude-kit --private --clone
```

### Step 2 — Clone it to your Mac

If you used the GitHub website (skip if you used `gh` above):

```bash
cd ~/Developer    # or wherever you keep iOS projects
git clone https://github.com/mahamed-mm/<app-name>.git
cd <app-name>
```

### Step 3 — Rename the templates to real files

```bash
mv CLAUDE.md.template CLAUDE.md
mv docs/PRD.md.template docs/PRD.md
```

These two files were templates in the repo so you wouldn't accidentally use them as-is. Now they're your project's real files.

### Step 4 — Customize CLAUDE.md

Open `CLAUDE.md` in your editor. Two things to do:

1. **Replace every `[App Name]`** with your actual app name.
2. **Fill in the "Project-specific notes"** section at the bottom with anything specific to this app — domain rules, integrations, conventions.
3. **This** is the most important file in your project. Spend 5 minutes on it.

### Step 5 — Create the Xcode project inside the folder

This is the part the kit doesn't automate. Create the Xcode project manually:

1. Open **Xcode** → **File → New → Project**
2. Choose **App** under iOS → **Next**
3. Fill in:
   - **Product Name:** match the folder name in PascalCase (e.g. `SaakinV2`, `MatSpor`)
   - **Organization Identifier:** `com.mahamed-mm` (or whatever you use)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** SwiftData (or None for simple apps)
   - **Include Tests:** ✅ checked
4. Click **Next**
5. **Critical:** Save it inside your cloned folder (`~/Developer/<app-name>/`), and **uncheck "Create Git repository on my Mac"** — you already have one
6. Click **Create**

Your folder structure now looks like:

```
<app-name>/
├── .claude/                    ← from kit
├── .mcp.json                   ← from kit
├── .gitignore                  ← from kit
├── CLAUDE.md                   ← customized
├── README.md                   ← from kit
├── WORKFLOW.md                 ← from kit
├── docs/                       ← from kit
│   ├── PRD.md                  ← empty, fill via /create-prd
│   ├── specs/template.md
│   └── tasks/template.md
├── YourAppName/                ← Xcode created this
├── YourAppName.xcodeproj/      ← Xcode created this
└── YourAppNameTests/           ← Xcode created this
```

### Step 6 — Initial commit and push

Lock in the baseline before changing anything:

```bash
git add -A
git commit -m "Initial setup: kit + Xcode project scaffold"
git push
```

### Step 7 — Open Claude Code and verify

```bash
claude
```

First time in the project, Claude Code reads `.mcp.json` and asks if you want to load XcodeBuildMCP. **Approve it.**

Then verify:

```
/mcp
```

You should see `XcodeBuildMCP` listed as connected. First invocation downloads it via `npx` (~20 seconds). After that, it's instant on subsequent sessions.

If `/mcp` shows nothing, close Claude Code and reopen it from the project root. The `cd` matters.

---

## After setup: the build flow

The full lifecycle for a non-trivial app:

```
/create-prd                    ← What is the app?
       ↓
/document-architecture         ← How will it be built? (optional)
       ↓
/document-design               ← How will it look? (optional)
       ↓
/generate-spec <feature>       ← Detailed plan for one feature
       ↓
/generate-tasks <feature>      ← Break the spec into ordered steps
       ↓
/new-feature <feature>         ← Implement, test, build, HIG-review
       ↓
/build  /test  /run-app        ← Verify in simulator anytime
       ↓
   ... build several features ...
       ↓
/audit-architecture            ← Reality check: code vs plan
/audit-design                  ← Reality check: visual consistency
       ↓
/ship-prep                     ← App Store readiness
```

For your **first feature** in any new app, do all the planning commands. After 2-3 features, you'll know when to skip steps for trivial work.

---

## When to use the architecture and design commands

These four commands are deliberate, not default. Use them when the project earns them.

### `/document-architecture` — right after `/create-prd`, before any feature spec

You've defined *what* the app does. Now decide *how* it'll be built before you commit to the first feature. This is the moment to make architectural choices deliberately rather than letting them emerge accidentally from your first three features.

- **Skip if:** tiny single-screen app (BillBuddy-sized).
- **Use if:** the app has multiple features, persistence, networking, or non-obvious technical decisions (Saakin v2, MatSpor).

### `/document-design` — right after `/document-architecture`, before any view code

Define your design system *once* before you start building views, so every feature inherits the same colors, typography, spacing, and component patterns.

- **Skip if:** you're prototyping fast and don't care about consistency yet.
- **Use if:** you're building anything you intend to ship to App Store.

### `/audit-architecture` — after 3-5 features are built

Reality check. The architecture you *planned* has probably drifted from what you *actually built*. This command reads the real code and writes `ARCHITECTURE.md` from what exists.

The audit backs up the existing `ARCHITECTURE.md` to `ARCHITECTURE.previous.md` first, so you can compare intent vs reality side-by-side.

- **Use when:** losing track of how things connect, before a big refactor, before App Store submission, or when handing off to someone.

### `/audit-design` — after 3-5 views are built

Same principle for UI. Reads your actual SwiftUI code and infers your real design system: colors used, fonts, spacing patterns, repeated components. Often catches drift like "I thought I was using only semantic colors but I have three hardcoded hex values."

- **Use when:** noticing visual inconsistencies between screens, extracting a real component library, or before App Store submission.

### The honest pattern

The two `/document-*` commands are **forward-looking** — set intentions before building.
The two `/audit-*` commands are **backward-looking** — document reality after building.

Both have value, but they serve different jobs. Don't confuse them.

---

## Quick reference card

```
NEW iOS APP CHECKLIST

Setup (10 min):
[ ] gh repo create <n> --template mahamed-mm/ios-claude-kit --private --clone
[ ] cd <n>
[ ] mv CLAUDE.md.template CLAUDE.md
[ ] mv docs/PRD.md.template docs/PRD.md
[ ] Edit CLAUDE.md: app name + project-specific notes
[ ] Xcode → New Project → SwiftUI → save inside the folder
[ ] git add -A && git commit -m "Initial setup" && git push
[ ] claude → /mcp (verify XcodeBuildMCP)

Project planning:
[ ] /create-prd
[ ] /document-architecture        (skip for trivial apps)
[ ] /document-design              (skip for trivial apps)

First feature:
[ ] /generate-spec <feature>
[ ] /generate-tasks <feature>
[ ] /new-feature <feature>
[ ] Review diff, /run-app, commit

Subsequent features:
[ ] /generate-spec <feature> (skip if trivial)
[ ] /new-feature <feature>
[ ] /run-app, commit

Reality check (after 3-5 features):
[ ] /audit-architecture           (compares plan vs reality)
[ ] /audit-design                 (catches visual drift)

Pre-release:
[ ] /ship-prep
[ ] Fix any blockers
[ ] Archive in Xcode → App Store Connect
```

---

## Three things people get wrong on the first try

**1. Forgetting to create the Xcode project inside the kit folder.**
They make a folder, clone the kit, then create the Xcode project elsewhere on disk. Now Claude Code can't find the Xcode project. Always create the Xcode project *inside* the cloned folder.

**2. Skipping the CLAUDE.md customization.**
Leaving `[App Name]` in there and diving straight into building. Claude then generates code with weird placeholder names. Spend 5 minutes on CLAUDE.md before anything else — it's the highest-leverage file in the project.

**3. Running `/new-feature` without `/generate-spec` first.**
Sometimes fine for trivial work, but for anything non-trivial it skips the design step and you end up with a feature built on assumptions Claude made instead of decisions you approved. Use the planning commands at least for your first 2-3 features per app, then trust your instincts.

---

## Troubleshooting

**`/mcp` shows nothing connected**
Close Claude Code, reopen from the project root (`cd` matters). Check that `.mcp.json` exists in the current directory.

**XcodeBuildMCP fails to start**
Verify Node.js is installed (`node --version`). If very old, `brew upgrade node`.

**`/new-feature` says it can't find a spec**
You skipped `/generate-spec`. Either run it first, or tell Claude "skip the spec check, implement directly."

**SwiftLint complains about files Claude writes**
Either tighten the rules in `CLAUDE.md` (Claude follows style more precisely if it's written down), or relax the SwiftLint rule if it's being pedantic. Make sure `.swiftlint.yml` exists in the project root or the hook silently does nothing.

**Build is slow on first run**
Expected. XcodeBuildMCP's first build on a project is slow (cold cache). Second build onward is fast.

**`/audit-architecture` overwrote my existing ARCHITECTURE.md**
By design, but it backed up the original to `ARCHITECTURE.previous.md` in the same folder. Same for `/audit-design`.

---

## Adding optional MCPs per project (advanced)

The kit ships only with XcodeBuildMCP because that's what *every* iOS project needs. Other MCPs are useful situationally — add them to the specific project that needs them, not to the kit template.

**Apple's Xcode MCP** (Xcode 26.3+, requires Xcode running):
```bash
claude mcp add --transport stdio xcode -- xcrun mcpbridge
```
Then enable it in Xcode → Settings → Intelligence → Model Context Protocol.

**GitHub MCP** (when you start collaborating or doing PR-heavy work):
Look up the official Microsoft server when you reach that point. Don't add preemptively.

Rule of thumb: if you've manually added the same MCP to three different projects, then promote it to the kit template. Until then, project-local.

---

*Last updated: kit v2.1 (added architecture and design commands). Update this file when the workflow itself changes.*
