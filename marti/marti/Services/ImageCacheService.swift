import UIKit

protocol ImageCacheService: Sendable {
    /// Loads an image from the given URL, returning a cached copy when available.
    /// Returns `nil` on any network or decoding failure — callers should render a placeholder.
    func loadImage(from url: URL) async -> UIImage?
}
