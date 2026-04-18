import Foundation

/// Default `CurrencyService` backed by https://open.er-api.com (HTTPS, no key).
/// Caches the rate in `UserDefaults` with a 24h refresh TTL and a 7d staleness cutoff.
final class LiveCurrencyService: CurrencyService, @unchecked Sendable {
    static let rateKey = "currency.usdToSosRate"
    static let timestampKey = "currency.usdToSosFetchedAt"
    static let refreshInterval: TimeInterval = 24 * 60 * 60       // 24h
    static let staleCutoff: TimeInterval = 7 * 24 * 60 * 60       // 7d

    private let urlSession: URLSession
    private let userDefaults: UserDefaults
    private let endpoint: URL
    private let now: @Sendable () -> Date

    init(
        urlSession: URLSession = .shared,
        userDefaults: UserDefaults = .standard,
        endpoint: URL = URL(string: "https://open.er-api.com/v6/latest/USD")!,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.urlSession = urlSession
        self.userDefaults = userDefaults
        self.endpoint = endpoint
        self.now = now
    }

    func usdToSOS(_ usdCents: Int, display: CurrencyDisplay) -> String? {
        guard let rate = cachedRate(),
              let fetched = lastFetchedAt(),
              now().timeIntervalSince(fetched) <= Self.staleCutoff
        else {
            return nil
        }
        let usd = Double(usdCents) / 100.0
        let sos = usd * rate
        return Self.format(sos: sos, display: display)
    }

    func refreshRate() async throws {
        if let fetched = lastFetchedAt(),
           now().timeIntervalSince(fetched) < Self.refreshInterval {
            return
        }

        let (data, response) = try await urlSession.data(from: endpoint)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw AppError.network("Exchange rate request failed: HTTP \(http.statusCode)")
        }

        let decoded: ExchangeRateResponse
        do {
            decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        } catch {
            throw AppError.network("Could not parse exchange rate response: \(error.localizedDescription)")
        }

        guard let sosRate = decoded.rates["SOS"], sosRate > 0 else {
            throw AppError.unknown("SOS rate missing from exchange rate response")
        }

        userDefaults.set(sosRate, forKey: Self.rateKey)
        userDefaults.set(now(), forKey: Self.timestampKey)
    }

    // MARK: - Cache reads

    private func cachedRate() -> Double? {
        let value = userDefaults.double(forKey: Self.rateKey)
        return value > 0 ? value : nil
    }

    private func lastFetchedAt() -> Date? {
        userDefaults.object(forKey: Self.timestampKey) as? Date
    }

    // MARK: - Formatting

    static func format(sos: Double, display: CurrencyDisplay) -> String {
        switch display {
        case .abbreviated:
            return abbreviated(sos: sos)
        case .full:
            return full(sos: sos)
        }
    }

    private static func abbreviated(sos: Double) -> String {
        let value = sos.rounded()
        if value >= 1_000_000 {
            return "~\(trim(value / 1_000_000))M SOS"
        }
        if value >= 1_000 {
            return "~\(trim(value / 1_000))K SOS"
        }
        return "~\(Int(value)) SOS"
    }

    private static func full(sos: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.groupingSeparator = ","
        let number = NSNumber(value: sos.rounded())
        let formatted = formatter.string(from: number) ?? "\(Int(sos.rounded()))"
        return "~\(formatted) SOS"
    }

    private static func trim(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded)
    }
}

private struct ExchangeRateResponse: Decodable {
    let rates: [String: Double]
}
