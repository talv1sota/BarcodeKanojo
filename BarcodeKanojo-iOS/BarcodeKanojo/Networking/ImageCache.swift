import UIKit

/// Two-level image cache: in-memory NSCache + disk cache.
/// Mirrors Android DynamicImageCache + ImageDiskCache behavior.
final class ImageCache {

    static let shared = ImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private let diskURL: URL
    private let fileManager = FileManager.default

    private init() {
        // In-memory: ~1/6 of available RAM (matches Android LRU cache sizing)
        let maxBytes = Int(ProcessInfo.processInfo.physicalMemory / 6)
        memory.totalCostLimit = maxBytes

        // Disk cache directory
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskURL = caches.appendingPathComponent("kanojo_images")
        try? fileManager.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    // MARK: - Read

    func image(for key: String) -> UIImage? {
        let nsKey = key as NSString

        // 1. Memory hit
        if let img = memory.object(forKey: nsKey) {
            return img
        }

        // 2. Disk hit
        let fileURL = diskURL.appendingPathComponent(sanitize(key))
        guard let data = try? Data(contentsOf: fileURL),
              let img = UIImage(data: data) else {
            return nil
        }

        // Promote to memory
        memory.setObject(img, forKey: nsKey, cost: data.count)
        return img
    }

    // MARK: - Write

    func store(_ image: UIImage, for key: String) {
        let nsKey = key as NSString
        let data = image.pngData() ?? Data()
        memory.setObject(image, forKey: nsKey, cost: data.count)

        let fileURL = diskURL.appendingPathComponent(sanitize(key))
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Clear

    /// Remove all cached images from memory and disk.
    func clearAll() {
        memory.removeAllObjects()
        if let files = try? fileManager.contentsOfDirectory(at: diskURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
        print("[ImageCache] Cleared all cached images")
    }

    // MARK: - Helpers

    private func sanitize(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
           .replacingOccurrences(of: ":", with: "_")
    }
}
