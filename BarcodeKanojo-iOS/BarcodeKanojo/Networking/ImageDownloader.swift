import UIKit
import SwiftUI

/// Async image downloader with two-level caching.
final class ImageDownloader {

    static let shared = ImageDownloader()

    private let cache = ImageCache.shared
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        // Disable URLSession's own disk cache — we manage caching via ImageCache
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        session = URLSession(configuration: config)
    }

    /// Clear all cached images (memory + disk). Call on pull-to-refresh.
    func clearCache() {
        cache.clearAll()
    }

    /// Download an image from a full URL string, using cache if available.
    func image(from urlString: String) async -> UIImage? {
        guard !urlString.isEmpty else { return nil }

        if let cached = cache.image(for: urlString) {
            return cached
        }

        guard let url = URL(string: urlString) else {
            print("[ImageDL] Bad URL: \(urlString)")
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                print("[ImageDL] HTTP \(http.statusCode) for \(urlString)")
                return nil
            }
            guard let img = UIImage(data: data) else {
                print("[ImageDL] Failed to decode image data (\(data.count) bytes) from \(urlString)")
                return nil
            }
            cache.store(img, for: urlString)
            return img
        } catch {
            print("[ImageDL] Error loading \(urlString): \(error.localizedDescription)")
            return nil
        }
    }

    /// Build full URL and download from a relative path + base URL.
    func image(relativePath: String) async -> UIImage? {
        let base = AppSettings.shared.baseURL
        return await image(from: base + relativePath)
    }
}

// MARK: - SwiftUI async image view with cache

/// Drop-in async image view backed by ImageDownloader.
/// Usage: AsyncCachedImage(url: kanojo.profileImageIconURL)
struct AsyncCachedImage: View {
    let url: String
    var placeholder: Image = Image(systemName: "person.fill")

    @State private var image: UIImage?
    @State private var retryCount = 0
    private let maxRetries = 3

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: "\(url)-\(retryCount)") {
            guard image == nil else { return }
            let result = await ImageDownloader.shared.image(relativePath: url)
            if let result {
                image = result
            } else if retryCount < maxRetries {
                // Server may still be generating the image; retry after delay
                try? await Task.sleep(nanoseconds: UInt64(2_000_000_000 * (retryCount + 1)))
                retryCount += 1
            }
        }
    }
}
