import Foundation

/// A transient, in-memory grouping of `Listing`s under a single `DiscoveryCategory`.
///
/// Rails are composed by the ViewModel from cached `Listing`s + `DiscoveryCategory`s
/// and are never persisted or serialized — they exist only to drive the Discovery
/// list's horizontally-scrolling rows.
///
/// Kept as a plain struct (no `Identifiable`/`Equatable` conformance) to stay out
/// of Swift 6's actor-isolation crosshairs: `Listing` is a SwiftData `@Model` class
/// that is `MainActor`-isolated, and synthesized conformances would need to cross
/// that boundary. Callers use `rail.category.id` for `ForEach` identity.
struct DiscoveryRail {
    let category: DiscoveryCategoryDTO
    let listings: [Listing]
}
