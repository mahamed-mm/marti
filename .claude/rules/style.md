# Code style

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- `let` > `var`. Value > reference.
- `async`/`await`. No Combine for new code. No completion handlers.
- Force unwraps banned outside `@IBOutlet` and tests.
- `guard` for early returns, not nested `if`.
- Comments explain _why_, not _what_.
- Functions under ~20 lines — extract when they grow.
