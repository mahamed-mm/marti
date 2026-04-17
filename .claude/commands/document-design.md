---
description: Generate DESIGN.md (visual design system) for this project from your description and existing context.
---

Generate `docs/DESIGN.md` for this project.

## Process

1. **Read context first:**
   - `CLAUDE.md` for stack and conventions
   - `docs/PRD.md` for target users and product personality
   - `docs/ARCHITECTURE.md` if it exists
   - Any existing SwiftUI views in the project (to detect existing patterns)

2. **Ask me clarifying questions** about visual identity. Specifically probe for:
   - Brand personality (calm and minimal? bold and energetic? playful? serious?)
   - Color approach (light mode only? dark mode required? brand colors? semantic only?)
   - Typography (system fonts? custom font? what hierarchy?)
   - Spacing system (default Apple? custom scale? what unit?)
   - Iconography (SF Symbols only? custom icons? style?)
   - Component philosophy (native iOS feel? distinctive custom components?)
   - Animation style (subtle and quick? expressive? minimal?)
   - Accessibility requirements (Dynamic Type up to AX5? VoiceOver-first? high-contrast mode?)
   - Localization considerations (RTL languages? variable text length?)

3. **Do not invent visual decisions.** If I don't know yet, write "TBD" with a note about when this should be decided. Half the value of a design doc is forcing decisions before they happen accidentally.

4. **Write `docs/DESIGN.md`** with these sections:
   - **Visual identity** — one paragraph on the app's design personality and what it should feel like to use
   - **Color system** — semantic colors used, brand colors if any, dark mode approach. Include hex values or asset catalog names.
   - **Typography** — font family, scale (which Dynamic Type styles used where), weight conventions
   - **Spacing & layout** — base unit, padding conventions (edges, between elements, between sections), grid if any
   - **Iconography** — SF Symbols vs custom, sizing conventions, color treatment
   - **Component patterns** — reusable visual primitives (buttons, cards, lists, forms) with intended usage
   - **Motion & animation** — when animations are used, their style, what's never animated
   - **Accessibility** — Dynamic Type range supported, VoiceOver labeling conventions, contrast requirements, Reduce Motion behavior
   - **Localization** — languages supported, RTL handling, text-length budget
   - **What this app deliberately does NOT do** — anti-patterns, things you're avoiding (e.g. "no skeuomorphism," "no custom navigation," "no carousels")
   - **Open questions** — anything still TBD

5. **End with a summary** of decisions made and any TBDs.

## Style rules

- Concrete and specific. "16pt edges, 8pt between elements" beats "consistent spacing."
- Use Apple's semantic vocabulary (`.title`, `.body`, `.systemBackground`) not raw values where possible.
- Include reasoning for non-obvious choices.
- No design jargon for jargon's sake. If you'd say "skeuomorphic" to a designer, say "looks like a real-world object" to anyone else.
- This doc explains the *intended* design system. For the *actual built* design system, use `/audit-design` after views exist.

## When NOT to use this command

- Throwaway prototypes
- Apps with no UI of their own (extensions that look fully native)
- When you haven't decided what the app does yet (run `/create-prd` first)

If the project is too simple or too early for a design doc, tell me so honestly.
