import SwiftUI

/// Default service used when a view tree has no `CurrencyService` injected.
/// Always returns `nil` so SOS lines simply hide.
nonisolated final class NoOpCurrencyService: CurrencyService {
    func usdToSOS(_ usdCents: Int, display: CurrencyDisplay) -> String? { nil }
    func refreshRate() async throws {}
}

private struct CurrencyServiceKey: EnvironmentKey {
    static let defaultValue: any CurrencyService = NoOpCurrencyService()
}

extension EnvironmentValues {
    var currencyService: any CurrencyService {
        get { self[CurrencyServiceKey.self] }
        set { self[CurrencyServiceKey.self] = newValue }
    }
}
