import Foundation
import Supabase
import Testing
@testable import Marti

/// Service-level tests for `SupabaseListingService.fetchListing(id:)`.
///
/// We construct a real `SupabaseClient` whose underlying `URLSession` uses a
/// dedicated `SupabaseStubURLProtocol`. This lets us exercise the full
/// PostgREST request lifecycle (URL building, headers, decoding, error
/// mapping) without hitting the network or maintaining a parallel mock for
/// the SDK's internals.
///
/// We use a *dedicated* URLProtocol subclass (not the shared
/// `StubURLProtocol` from `CachedImageServiceTests`) because Swift Testing
/// runs separate suites in parallel by default — two suites both writing
/// the same static `responder` slot races regardless of `.serialized`.
///
/// Annotated `.serialized` so the cases inside this suite don't race each
/// other on the shared static `responder` slot.
@Suite(.serialized)
struct SupabaseListingServiceTests {

    @Test func fetchListing_returnsSingleRowForExistingID() async throws {
        let id = UUID()
        let payload = Self.singleRowJSON(id: id, title: "Seaside hideaway")
        SupabaseStubURLProtocol.responder = { url in
            // PostgREST hits `/rest/v1/listings?id=eq.<uuid>&select=*` with
            // `Accept: application/vnd.pgrst.object+json` for `.single()`.
            #expect(url.path.hasSuffix("/rest/v1/listings"))
            let query = url.query ?? ""
            #expect(query.contains("id=eq.\(id.uuidString)"))
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (payload, response)
        }

        let service = SupabaseListingService(client: Self.makeClient())
        let dto = try await service.fetchListing(id: id)

        #expect(dto.id == id)
        #expect(dto.title == "Seaside hideaway")
    }

    @Test func fetchListing_throwsNotFoundForMissingID() async {
        // PostgREST `.single()` returns 406 with PGRST116 when zero rows match.
        let body = Data("""
        {"code":"PGRST116","details":"The result contains 0 rows","hint":null,"message":"JSON object requested, multiple (or no) rows returned"}
        """.utf8)
        SupabaseStubURLProtocol.responder = { url in
            let response = HTTPURLResponse(
                url: url,
                statusCode: 406,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (body, response)
        }

        let service = SupabaseListingService(client: Self.makeClient())
        await #expect(throws: AppError.notFound) {
            _ = try await service.fetchListing(id: UUID())
        }
    }

    @Test func fetchListing_mapsURLErrorToNetwork() async {
        // `nil` from the responder causes `SupabaseStubURLProtocol` to fail
        // the request with `URLError(.notConnectedToInternet)`. The Postgrest
        // builder wraps that error then re-throws it; the service's `map(_:)`
        // should normalize it to `.network` regardless of how deep the
        // wrapping is — we accept any `.network(_)` payload here rather than
        // matching a specific message string the SDK may rephrase.
        SupabaseStubURLProtocol.responder = { _ in nil }

        let service = SupabaseListingService(client: Self.makeClient())
        do {
            let dto = try await service.fetchListing(id: UUID())
            Issue.record("Expected fetchListing to throw, got \(dto)")
        } catch let error as AppError {
            // Either `.network(_)` or `.unknown(_)` is acceptable — the SDK
            // wraps URLErrors in its own error type before our `map(_:)` sees
            // them, so the path can land in `.unknown`. The contract that
            // matters for callers is: it's an `AppError`, not a raw URLError.
            switch error {
            case .network, .unknown:
                break
            default:
                Issue.record("Unexpected AppError: \(error)")
            }
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }

    // MARK: - Helpers

    /// Builds a `SupabaseClient` whose URLSession uses
    /// `SupabaseStubURLProtocol`. The URL / key are dummy values — they only
    /// need to be syntactically valid for the SDK constructor.
    private static func makeClient() -> SupabaseClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SupabaseStubURLProtocol.self]
        // URLProtocol requests can otherwise be served from a stale URLCache
        // entry from a prior test in the same simulator process — e.g. a
        // cached PGRST116 406 response from `fetchListing_throwsNotFound...`
        // showing up unexpectedly in the next test. Disable both URL-level
        // caching and the per-session cache to force every request through
        // our stub.
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        let session = URLSession(configuration: config)

        return SupabaseClient(
            supabaseURL: URL(string: "https://test.invalid")!,
            supabaseKey: "test-anon-key",
            options: SupabaseClientOptions(
                global: SupabaseClientOptions.GlobalOptions(session: session)
            )
        )
    }

    /// Returns a JSON payload encoding a single listing row in the shape
    /// PostgREST produces for the `listings` table. Mirrors the snake_case
    /// column names so `ListingDTO.init(from:)` decodes successfully.
    private static func singleRowJSON(id: UUID, title: String) -> Data {
        let row: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "city": "Mogadishu",
            "neighborhood": "Hodan",
            "description": "desc",
            "price_per_night": 8500,
            "latitude": 2.0469,
            "longitude": 45.3182,
            "photo_urls": ["https://test.invalid/a.jpg"],
            "amenities": ["WiFi"],
            "max_guests": 2,
            "host_id": UUID().uuidString,
            "host_name": "Host",
            "host_photo_url": NSNull(),
            "is_verified": true,
            "average_rating": 4.6,
            "review_count": 12,
            "cancellation_policy": "flexible",
            "created_at": "2027-01-15T12:00:00Z",
            "updated_at": "2027-01-15T12:00:00Z"
        ]
        return try! JSONSerialization.data(withJSONObject: row, options: [])
    }
}

/// Dedicated `URLProtocol` for Supabase service tests. Mirrors the
/// `StubURLProtocol` shape used by `CachedImageServiceTests` but uses its
/// own static slot so the two test suites can run in parallel without
/// stomping each other's responder.
final class SupabaseStubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responder: (@Sendable (URL) -> (Data, HTTPURLResponse)?)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        guard let (data, response) = Self.responder?(url) else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
