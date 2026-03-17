// KanojoThumbnailRenderer.swift — Renders Live2D kanojo models offscreen to UIImage thumbnails.
// Replaces broken server-side Pillow compositor with actual Live2D rendering on-device.

import UIKit
import Metal
import MetalKit

/// Renders a kanojo Live2D model offscreen to produce a static thumbnail UIImage.
/// Results are cached to disk so each kanojo is only rendered once.
final class KanojoThumbnailRenderer {

    static let shared = KanojoThumbnailRenderer()

    /// Thumbnail size in pixels (rendered at 2x for retina)
    private let thumbSize = 180  // 90pt * 2x

    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let cacheDir: URL
    private let fileManager = FileManager.default

    /// In-memory cache to avoid repeated disk reads
    private let memoryCache = NSCache<NSString, UIImage>()

    /// Dedicated serial queue for rendering — avoids blocking Swift concurrency thread pool
    /// and ensures only one model loads at a time (Live2D has shared global state).
    private let renderQueue = DispatchQueue(label: "com.barcodekanojo.thumbnailRenderer", qos: .userInitiated)

    private init() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDir = caches.appendingPathComponent("kanojo_thumbnails")
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        memoryCache.countLimit = 50

        if device != nil {
            print("[ThumbRenderer] Initialized with Metal device")
        } else {
            print("[ThumbRenderer] WARNING: No Metal device available")
        }
    }

    // MARK: - Public API

    /// Get a cached thumbnail or render one. Returns nil if rendering fails.
    func thumbnail(for kanojo: Kanojo, avatarDataDir: URL) async -> UIImage? {
        let key = cacheKey(for: kanojo)

        // 1. Memory cache
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        // 2. Disk cache
        let diskURL = cacheDir.appendingPathComponent("\(key).png")
        if let data = try? Data(contentsOf: diskURL),
           let img = UIImage(data: data) {
            memoryCache.setObject(img, forKey: key as NSString)
            return img
        }

        // 3. Render on dedicated serial queue (bridged to async).
        //    Serial queue ensures only one model loads at a time (Live2D has shared static state).
        //    Strong self capture is safe — this is a singleton that lives for the app's lifetime.
        let img: UIImage? = await withCheckedContinuation { continuation in
            self.renderQueue.async {
                let result = self.renderOffscreen(kanojo: kanojo, avatarDataDir: avatarDataDir)
                continuation.resume(returning: result)
            }
        }

        guard let img = img else { return nil }

        // 4. Cache to disk and memory
        if let pngData = img.pngData() {
            try? pngData.write(to: diskURL, options: .atomic)
        }
        memoryCache.setObject(img, forKey: key as NSString)

        return img
    }

    /// Clear all cached thumbnails (call when avatar data changes)
    func clearCache() {
        memoryCache.removeAllObjects()
        if let files = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
        print("[ThumbRenderer] Cleared thumbnail cache")
    }

    /// Invalidate cache for a specific kanojo
    func invalidate(kanojoId: Int) {
        if let files = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.hasPrefix("k\(kanojoId)_") {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    // MARK: - Offscreen Rendering (runs on renderQueue)

    private func renderOffscreen(kanojo: Kanojo, avatarDataDir: URL) -> UIImage? {
        guard let device = device, let commandQueue = commandQueue else {
            print("[ThumbRenderer] No Metal device")
            return nil
        }

        print("[ThumbRenderer] Rendering kanojo \(kanojo.id) (\(kanojo.name ?? "?"))...")

        // Create and configure the Live2D model
        let model = KanojoModel(avatarDataDir: avatarDataDir)
        model.configure(from: kanojo.toLive2DDict())
        model.load(device: device)

        guard let live2d = model.live2dModel else {
            print("[ThumbRenderer] ✗ Model load failed for kanojo \(kanojo.id)")
            return nil
        }
        print("[ThumbRenderer] Model loaded: \(live2d.getCanvasWidth())x\(live2d.getCanvasHeight())")

        // Run one update to set default pose (eyes open, breathing, etc.)
        model.update(deltaTime: 1.0 / 30.0)  // simulate one frame at 30fps

        // Create offscreen render target
        let texDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: thumbSize,
            height: thumbSize,
            mipmapped: false
        )
        texDesc.usage = [.renderTarget, .shaderRead]
        texDesc.storageMode = .shared

        guard let targetTexture = device.makeTexture(descriptor: texDesc) else {
            print("[ThumbRenderer] ✗ Failed to create render target texture")
            return nil
        }

        // Set up render pass descriptor targeting our offscreen texture
        let renderPassDesc = MTLRenderPassDescriptor()
        renderPassDesc.colorAttachments[0].texture = targetTexture
        renderPassDesc.colorAttachments[0].loadAction = .clear
        renderPassDesc.colorAttachments[0].storeAction = .store
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        // Render
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("[ThumbRenderer] ✗ Failed to create command buffer")
            return nil
        }

        model.draw(
            commandBuffer: commandBuffer,
            renderPassDescriptor: renderPassDesc,
            viewWidth: Float(thumbSize),
            viewHeight: Float(thumbSize)
        )

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Check for Metal errors
        if commandBuffer.status == .error {
            print("[ThumbRenderer] ✗ Command buffer error: \(commandBuffer.error?.localizedDescription ?? "unknown")")
            return nil
        }

        // Read back pixels from the texture
        guard let img = imageFromTexture(targetTexture) else {
            print("[ThumbRenderer] ✗ Failed to create image from texture")
            return nil
        }

        print("[ThumbRenderer] ✓ Rendered kanojo \(kanojo.id) thumbnail (\(img.size.width)x\(img.size.height))")
        return img
    }

    private func imageFromTexture(_ texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        let totalBytes = bytesPerRow * height

        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        texture.getBytes(
            &pixelData,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )

        // Check if texture has any non-zero pixels
        var nonZero = 0
        for i in stride(from: 3, to: min(totalBytes, 4000), by: 4) {
            if pixelData[i] > 0 { nonZero += 1 }
        }
        print("[ThumbRenderer] Texture readback: \(width)x\(height), non-zero alpha pixels in first 1000: \(nonZero)")

        // Metal renders BGRA — swap B and R for RGBA CGImage
        for i in stride(from: 0, to: totalBytes, by: 4) {
            let b = pixelData[i]
            let r = pixelData[i + 2]
            pixelData[i] = r
            pixelData[i + 2] = b
        }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ),
              let cgImage = context.makeImage() else {
            print("[ThumbRenderer] ✗ CGContext/CGImage creation failed")
            return nil
        }

        return UIImage(cgImage: cgImage, scale: 2.0, orientation: .up)
    }

    // MARK: - Cache Key

    private func cacheKey(for kanojo: Kanojo) -> String {
        let attrs = "\(kanojo.bodyType)_\(kanojo.faceType)_\(kanojo.eyeType)_\(kanojo.browType)_\(kanojo.mouthType)_\(kanojo.noseType)_\(kanojo.earType)_\(kanojo.fringeType)_\(kanojo.hairType)_\(kanojo.clothesType)_\(kanojo.glassesType)_\(kanojo.accessoryType)_\(kanojo.skinColor)_\(kanojo.hairColor)_\(kanojo.eyeColor)"
        var hash: UInt64 = 5381
        for byte in attrs.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return "k\(kanojo.id)_\(hash)"
    }
}
