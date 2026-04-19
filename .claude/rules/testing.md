# Testing

- **Swift Testing only** (`@Test`, `#expect`, `#require`).
- Test ViewModels and Services. Do **not** test SwiftUI view bodies.
- Snapshot tests only for design-system primitives.
- One test file per ViewModel, mirroring source folder structure.
- Mock via test doubles conforming to the service protocol. No mocking frameworks.
- Annotate `@Suite(.serialized)` on suites sharing mutable static state (e.g. `StubURLProtocol`).
- Cover: happy path, error path, edge cases (empty, nil, boundary).
