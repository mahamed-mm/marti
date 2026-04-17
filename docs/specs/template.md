# Feature Spec: [Feature Name]

- **Status:** Draft / In Review / Approved / In Progress / Complete
- **Priority:** P0 / P1 / P2
- **PRD reference:** [section or feature name in PRD.md]
- **Last updated:** [date]

## Overview

One paragraph: what this feature is, why it exists, how it fits into the product.

## User Stories

1. As a [user], I want [action] so that [benefit].
2. ...

## Acceptance Criteria

- [ ] AC1: [specific, testable]
- [ ] AC2: ...
- [ ] AC3: ...

## Technical Design

### Models

```swift
struct Example: Identifiable, Codable {
    let id: UUID
    // ...
}
```

### Services

What protocols does this feature need? What concrete implementations?

### ViewModel responsibilities

What state does the ViewModel hold? What actions does it expose?

### Views

What screens are needed? How do they navigate to/from each other?

### Dependencies

- New SPM packages (if any — list and justify)
- Other features this depends on

## UI/UX

- Figma link (if any)
- Key screens listed
- Notable interactions

## Edge Cases

1. [Edge case → how handled]
2. ...

## Testing Plan

- ViewModel unit tests for: [list of behaviors]
- Service tests for: [list]
- Manual test scenarios: [list]

## Open Questions

- Question 1?
