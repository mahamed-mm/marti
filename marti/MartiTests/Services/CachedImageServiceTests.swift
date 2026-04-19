import Foundation
import Synchronization
import Testing
import UIKit
@testable import Marti

@Suite(.serialized)
struct CachedImageServiceTests {

    @Test func returnsImageOnSuccessfulLoad() async {
        let url = URL(string: "https://test.invalid/photo.png")!
        let pngData = Self.pngData(color: .red)
        StubURLProtocol.responder = { requestURL in
            #expect(requestURL == url)
            let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (pngData, response)
        }
        let service = CachedImageService(urlSession: Self.makeSession())
        let image = await service.loadImage(from: url)
        #expect(image != nil)
    }

    @Test func cachesImageInMemoryAfterFirstLoad() async {
        let url = URL(string: "https://test.invalid/cached.png")!
        let pngData = Self.pngData(color: .blue)
        let callCount = Mutex(0)
        StubURLProtocol.responder = { requestURL in
            callCount.withLock { $0 += 1 }
            let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (pngData, response)
        }
        let service = CachedImageService(urlSession: Self.makeSession())
        _ = await service.loadImage(from: url)
        _ = await service.loadImage(from: url)
        #expect(callCount.withLock { $0 } == 1)
    }

    @Test func returnsNilOnHTTPError() async {
        let url = URL(string: "https://test.invalid/missing.png")!
        StubURLProtocol.responder = { requestURL in
            let response = HTTPURLResponse(url: requestURL, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (Data(), response)
        }
        let service = CachedImageService(urlSession: Self.makeSession())
        let image = await service.loadImage(from: url)
        #expect(image == nil)
    }

    @Test func returnsNilOnInvalidImageData() async {
        let url = URL(string: "https://test.invalid/garbage.png")!
        StubURLProtocol.responder = { requestURL in
            let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (Data("not an image".utf8), response)
        }
        let service = CachedImageService(urlSession: Self.makeSession())
        let image = await service.loadImage(from: url)
        #expect(image == nil)
    }

    @Test func returnsNilWhenURLLoadFails() async {
        let url = URL(string: "https://test.invalid/network-fail.png")!
        StubURLProtocol.responder = { _ in nil }
        let service = CachedImageService(urlSession: Self.makeSession())
        let image = await service.loadImage(from: url)
        #expect(image == nil)
    }

    // MARK: - Helpers

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func pngData(color: UIColor) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        return image.pngData()!
    }
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
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
