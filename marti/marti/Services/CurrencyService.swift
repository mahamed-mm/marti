import Foundation

enum CurrencyDisplay: Sendable {
    case abbreviated
    case full
}

protocol CurrencyService: Sendable {
    /// Converts USD cents to a display-formatted SOS string.
    /// Returns nil if no cached rate exists or the cached rate is older than 7 days.
    func usdToSOS(_ usdCents: Int, display: CurrencyDisplay) -> String?

    /// Refreshes the USD→SOS rate from the network if the cached rate is older than 24h.
    /// No-op if the cache is fresh.
    func refreshRate() async throws
}

extension CurrencyService {
    func usdToSOS(_ usdCents: Int) -> String? {
        usdToSOS(usdCents, display: .abbreviated)
    }
}
