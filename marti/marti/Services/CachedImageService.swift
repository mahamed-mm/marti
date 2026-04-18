import UIKit

/// Thin wrapper around `NSCache` (memory) + `URLCache` (disk) for image loading.
/// Generic — not listing-specific. Used wherever we render remote images.
nonisolated final class CachedImageService: ImageCacheService {
    static let defaultMemoryItemLimit = 50
    static let defaultDiskCapacity = 200 * 1024 * 1024  // 200 MB

    private let memoryCache: NSCache<NSURL, UIImage>
    private let urlSession: URLSession

    init(
        memoryItemLimit: Int = CachedImageService.defaultMemoryItemLimit,
        diskCapacity: Int = CachedImageService.defaultDiskCapacity,
        urlSession: URLSession? = nil
    ) {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = memoryItemLimit
        self.memoryCache = cache

        if let urlSession {
            self.urlSession = urlSession
        } else {
            let config = URLSessionConfiguration.default
            config.urlCache = URLCache(memoryCapacity: 0, diskCapacity: diskCapacity)
            config.requestCachePolicy = .returnCacheDataElseLoad
            self.urlSession = URLSession(configuration: config)
        }
    }

    func loadImage(from url: URL) async -> UIImage? {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }
        do {
            let (data, response) = try await urlSession.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return nil
            }
            guard let image = UIImage(data: data) else { return nil }
            memoryCache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }
}
