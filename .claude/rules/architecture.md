# Architecture rules

- **Views are dumb.** No business logic, no networking, no persistence in `View` bodies.
- **ViewModels** are `@Observable` classes, one per screen. Dependencies injected via init.
- **Models** are pure Swift value types. Exception: SwiftData `@Model` (reference type). Pair each `@Model` with a Codable DTO (e.g. `Listing` + `ListingDTO`) and map at the service boundary.
- **Services** = protocol + concrete impl. Protocol lives next to the impl.
- **No singletons** except Apple-provided.
- **No global state.** Flow through ViewModels or environment.
- **`AuthManager`** is in environment; check `authManager.isAuthenticated` at save/book/message.

See full layout: @docs/ARCHITECTURE.md
