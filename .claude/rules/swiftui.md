# SwiftUI rules

- `@State` for view-local state only.
- `@Bindable` (not `@ObservedObject`) for `@Observable` ViewModels.
- Extract subviews when a body exceeds ~50 lines.
- Prefer `ViewBuilder` closures over `AnyView`.
- SF Symbols only. No raster icons unless brand assets.
- `.accessibilityLabel` on every interactive element without visible text.
- Test layouts at AX5.
- Mark value-type models `nonisolated` (e.g. `nonisolated struct ListingDTO`) so Codable/Equatable don't stall on `MainActor`.
