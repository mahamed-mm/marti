---
description: Audit SwiftUI views and write a dated design snapshot to docs/audits/.
---

Audit the SwiftUI views in this project and write `docs/audits/YYYY-MM-DD-design.md` based on what's actually built. **Do not touch `docs/DESIGN.md`** — that's the lean spec, maintained separately.

## Process

1. **Read context first:**
   - `CLAUDE.md` for stack and conventions
   - `docs/PRD.md` if it exists
   - `docs/DESIGN.md` (the lean spec — treat as intent)
   - Most recent file in `docs/audits/*-design.md` if present (for diff vs prior audit)

2. **Explore the UI codebase systematically.** Use Glob and Read on:
   - Every `.swift` file under `Views/` (or wherever views live)
   - `Assets.xcassets/` for color sets, image assets, app icons
   - Any custom `View` extensions, `ViewModifier` definitions
   - Any design system files (`DesignSystem.swift`, `DesignTokens.swift`, `Colors.swift`, etc.)
   - `Localizable.xcstrings` or `.strings` files for languages supported

3. **Extract observed patterns:**
   - **Colors used:** every `.foregroundStyle()`, `.background()`, `.tint()`, `Color(...)`. Group into semantic vs hardcoded vs asset catalog.
   - **Fonts used:** every `.font(...)` call. Group by Dynamic Type style and any custom font usage.
   - **Spacing values:** observed `.padding()` values, `Spacer()` minimum lengths, `VStack(spacing:)` values. Identify the implicit spacing scale.
   - **Corner radius:** every `.cornerRadius()`, `.clipShape(.rect(cornerRadius:))`, `RoundedRectangle(cornerRadius:)`. Identify the implicit radius scale.
   - **Icons:** every `Image(systemName:)` (SF Symbols) vs `Image("name")` (raster).
   - **Component patterns:** repeated view structures (e.g. "card with shadow", "primary button style"). Note where they're defined inline vs extracted.
   - **Animations:** every `.animation(...)`, `withAnimation`, `.transition(...)`. Note style and duration.
   - **Accessibility:** count of `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityHidden`, `.accessibilityAdjustableAction`. Identify gaps.
   - **Localization:** which strings use `LocalizedStringKey` / `String(localized:)` vs hardcoded literals.
   - **Dark mode:** any explicit `.preferredColorScheme()` or `colorScheme` checks.

4. **Write `docs/audits/YYYY-MM-DD-design.md`** (use today's date) with sections:
   - **Snapshot** — audit date, head commit, branch, view count surveyed
   - **Visual identity** — one paragraph, how the app actually looks and feels, observed from code
   - **Color system** — semantic colors used, hardcoded values found (with file references), asset catalog colors. Flag inconsistencies.
   - **Typography** — Dynamic Type styles in use, custom fonts, observed hierarchy
   - **Spacing & layout** — observed spacing scale, padding conventions, anomalies
   - **Corner radius** — observed radius scale, off-scale literals
   - **Iconography** — SF Symbols used, custom icons used, ratio
   - **Component patterns** — repeated visual patterns with file references. Flag candidates for extraction.
   - **Motion & animation** — observed animation usage, style consistency, Reduce Motion respect
   - **Accessibility coverage** — what's labeled, what's not, with file references
   - **Localization coverage** — what's localized, what's hardcoded
   - **Dark mode** — observed support
   - **Drift from spec** — places where code has drifted from `docs/DESIGN.md`
   - **Inconsistencies found** — concrete list (e.g. "3 different shades of blue used for primary actions in `Login.swift`, `Settings.swift`, `Profile.swift`")
   - **Recommended cleanups** — 3–5 specific actions to improve consistency
   - **Diff vs prior audit** — what changed since the last dated audit file

5. **End with a summary**: top 3 inconsistencies and the most impactful cleanup to do first.

## Style rules

- **Cite files and lines for every observation.** "Hardcoded color found" → "Hardcoded color `#3478F6` in `LoginView.swift:42`."
- **Be specific about counts.** "Most views" → "23 of 28 views."
- **Don't invent design intent.** Describe what's there, suggest what could be improved, but don't claim the developer "wanted" something they didn't write down.
- Inconsistency findings should be actionable: not just "colors are inconsistent" but "extract `Color.brandPrimary` from the 4 places where `#3478F6` appears."

## Important

- **Never overwrite `docs/DESIGN.md`.** That file is the lean, stable spec.
- **Never create `docs/DESIGN.previous.md`.** Historical audits live in `docs/audits/` with dated filenames — that's the archive.
- If `docs/audits/` doesn't exist, create it.

## When this command earns its place

- After 3–5 views have been built
- Before App Store submission, as a visual consistency sanity check
- When you notice screens looking subtly different
- When extracting a real design system from grown-organically views
- After a sprint of fast prototyping, before locking in patterns
