import Foundation
import Observation

/// Minimal auth state holder. Real sign-in / sign-out flows land with the Auth feature.
/// Until then, callers can flip `isAuthenticated` directly to drive auth-gated UI.
@Observable
@MainActor
final class AuthManager {
    var isAuthenticated: Bool

    init(isAuthenticated: Bool = false) {
        self.isAuthenticated = isAuthenticated
    }
}
