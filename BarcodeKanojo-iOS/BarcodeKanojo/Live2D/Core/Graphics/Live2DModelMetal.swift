// Live2DModelMetal.swift — Concrete Metal-backed Live2D model
// Ported from live2d-v2/live2d/core/live2d_model_opengl.py

import Foundation
import Metal
import MetalKit
import UIKit

final class Live2DModelMetal: ALive2DModel {
    private var drawParam: DrawParamMetal

    override init() {
        drawParam = DrawParamMetal()
        super.init()
    }

    override func getDrawParam() -> DrawParamMetal? {
        return drawParam
    }

    // MARK: - Setup

    func setupMetal(device: MTLDevice) {
        drawParam.device = device
        setupPipelines(device: device)
    }

    private func setupPipelines(device: MTLDevice) {
        // Load shaders from the default library
        guard let library = device.makeDefaultLibrary() else {
            print("[Live2D] Failed to load Metal shader library")
            return
        }

        let vertexFunc = library.makeFunction(name: "live2d_vertex")
        let fragmentNormal = library.makeFunction(name: "live2d_fragment_normal")
        let fragmentScreen = library.makeFunction(name: "live2d_fragment_screen")
        let fragmentMultiply = library.makeFunction(name: "live2d_fragment_multiply")

        // Vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        // position
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // texCoord
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        // layout
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 4
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // Normal blend pipeline
        let normalDesc = MTLRenderPipelineDescriptor()
        normalDesc.vertexFunction = vertexFunc
        normalDesc.fragmentFunction = fragmentNormal
        normalDesc.vertexDescriptor = vertexDescriptor
        normalDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        normalDesc.colorAttachments[0].isBlendingEnabled = true
        normalDesc.colorAttachments[0].rgbBlendOperation = .add
        normalDesc.colorAttachments[0].alphaBlendOperation = .add
        normalDesc.colorAttachments[0].sourceRGBBlendFactor = .one
        normalDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        normalDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        normalDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            drawParam.pipelineState = try device.makeRenderPipelineState(descriptor: normalDesc)
        } catch {
            print("[Live2D] Failed to create normal pipeline: \(error)")
        }

        // Screen blend pipeline
        let screenDesc = normalDesc.copy() as! MTLRenderPipelineDescriptor
        screenDesc.fragmentFunction = fragmentScreen
        screenDesc.colorAttachments[0].sourceRGBBlendFactor = .one
        screenDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceColor
        do {
            drawParam.pipelineStateScreen = try device.makeRenderPipelineState(descriptor: screenDesc)
        } catch {
            print("[Live2D] Failed to create screen pipeline: \(error)")
        }

        // Multiply blend pipeline
        let multiplyDesc = normalDesc.copy() as! MTLRenderPipelineDescriptor
        multiplyDesc.fragmentFunction = fragmentMultiply
        multiplyDesc.colorAttachments[0].sourceRGBBlendFactor = .destinationColor
        multiplyDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        do {
            drawParam.pipelineStateMultiply = try device.makeRenderPipelineState(descriptor: multiplyDesc)
        } catch {
            print("[Live2D] Failed to create multiply pipeline: \(error)")
        }

        // --- Clip mask pipelines ---

        // Mask rendering pipeline: renders mask meshes into offscreen rgba8Unorm texture
        let vertexMask = library.makeFunction(name: "live2d_vertex_mask")
        let fragmentMask = library.makeFunction(name: "live2d_fragment_mask")
        let maskDesc = MTLRenderPipelineDescriptor()
        maskDesc.vertexFunction = vertexMask
        maskDesc.fragmentFunction = fragmentMask
        maskDesc.vertexDescriptor = vertexDescriptor
        maskDesc.colorAttachments[0].pixelFormat = .rgba8Unorm  // offscreen mask texture
        maskDesc.colorAttachments[0].isBlendingEnabled = true
        maskDesc.colorAttachments[0].rgbBlendOperation = .add
        maskDesc.colorAttachments[0].alphaBlendOperation = .add
        // Must match Python's GL_ONE, GL_ONE_MINUS_SRC_ALPHA (premultiplied alpha blend)
        // NOT additive — especially matters for channel 0 (Alpha) where srcAlpha != 0
        maskDesc.colorAttachments[0].sourceRGBBlendFactor = .one
        maskDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        maskDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        maskDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            drawParam.pipelineStateMask = try device.makeRenderPipelineState(descriptor: maskDesc)
            print("[Live2D] Created mask pipeline (rgba8Unorm, additive)")
        } catch {
            print("[Live2D] Failed to create mask pipeline: \(error)")
        }

        // Clipped drawing pipeline: draws meshes with mask texture sampling
        // Target is the main screen (bgra8Unorm), uses normal alpha blending
        let vertexClipped = library.makeFunction(name: "live2d_vertex_clipped")
        let fragmentClipped = library.makeFunction(name: "live2d_fragment_clipped")
        let clippedDesc = MTLRenderPipelineDescriptor()
        clippedDesc.vertexFunction = vertexClipped
        clippedDesc.fragmentFunction = fragmentClipped
        clippedDesc.vertexDescriptor = vertexDescriptor
        clippedDesc.colorAttachments[0].pixelFormat = .bgra8Unorm  // main screen
        clippedDesc.colorAttachments[0].isBlendingEnabled = true
        clippedDesc.colorAttachments[0].rgbBlendOperation = .add
        clippedDesc.colorAttachments[0].alphaBlendOperation = .add
        clippedDesc.colorAttachments[0].sourceRGBBlendFactor = .one
        clippedDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        clippedDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        clippedDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            drawParam.pipelineStateClipped = try device.makeRenderPipelineState(descriptor: clippedDesc)
            print("[Live2D] Created clipped pipeline (bgra8Unorm, normal blend)")
        } catch {
            print("[Live2D] Failed to create clipped pipeline: \(error)")
        }
    }

    // MARK: - Texture loading

    func setTexture(_ index: Int, _ texture: MTLTexture) {
        drawParam.setTexture(index, texture)
    }

    func loadTexture(_ index: Int, from image: UIImage) {
        guard let device = drawParam.device, let cgImage = image.cgImage else { return }

        let w = cgImage.width
        let h = cgImage.height
        let alphaInfo = cgImage.alphaInfo

        // Log alpha state for diagnostics
        let alphaDesc: String
        switch alphaInfo {
        case .premultipliedLast:  alphaDesc = "premultipliedLast"
        case .premultipliedFirst: alphaDesc = "premultipliedFirst"
        case .last:               alphaDesc = "last(straight)"
        case .first:              alphaDesc = "first(straight)"
        case .noneSkipLast:       alphaDesc = "noneSkipLast"
        case .noneSkipFirst:      alphaDesc = "noneSkipFirst"
        case .alphaOnly:          alphaDesc = "alphaOnly"
        case .none:               alphaDesc = "none"
        @unknown default:         alphaDesc = "unknown"
        }
        print("[Live2D] Texture \(index): \(w)x\(h), alpha=\(alphaDesc)")

        // Ensure straight alpha for the shader (which does color.rgb *= color.a).
        // iOS CGImage from PNG is typically premultipliedLast; if we upload that
        // as-is, the shader would double-premultiply semi-transparent pixels.
        // Render into a context and manually unpremultiply to guarantee straight alpha.
        let isPremultiplied = (alphaInfo == .premultipliedLast || alphaInfo == .premultipliedFirst)

        if isPremultiplied {
            // Create RGBA context, draw image, then unpremultiply pixel data in-place
            guard let ctx = CGContext(data: nil, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                print("[Live2D] Failed to create unpremuliply context for texture \(index)")
                return
            }
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
            guard let ptr = ctx.data else { return }
            let pixels = ptr.bindMemory(to: UInt8.self, capacity: w * h * 4)

            // Unpremultiply: divide RGB by A to get straight alpha
            for i in 0..<(w * h) {
                let off = i * 4
                let a = pixels[off + 3]
                guard a > 0 && a < 255 else { continue }  // skip fully opaque/transparent
                let aF = Float(a) / 255.0
                pixels[off]     = UInt8(min(255, Int(Float(pixels[off])     / aF)))
                pixels[off + 1] = UInt8(min(255, Int(Float(pixels[off + 1]) / aF)))
                pixels[off + 2] = UInt8(min(255, Int(Float(pixels[off + 2]) / aF)))
            }

            // Create Metal texture directly from raw pixel data
            let texDesc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm, width: w, height: h, mipmapped: false)
            texDesc.usage = .shaderRead
            texDesc.storageMode = .shared
            guard let tex = device.makeTexture(descriptor: texDesc) else {
                print("[Live2D] Failed to create texture \(index)")
                return
            }
            tex.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0,
                        withBytes: pixels, bytesPerRow: w * 4)
            drawParam.setTexture(index, tex)
            print("[Live2D] Texture \(index): unpremultiplied \(w)x\(h) → straight alpha (rgba8Unorm)")
        } else {
            // Already straight alpha or no alpha — load directly via MTKTextureLoader
            let textureLoader = MTKTextureLoader(device: device)
            do {
                let tex = try textureLoader.newTexture(cgImage: cgImage, options: [
                    .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                    .textureStorageMode: MTLStorageMode.shared.rawValue,
                    .SRGB: false
                ])
                drawParam.setTexture(index, tex)
            } catch {
                print("[Live2D] Failed to load texture \(index): \(error)")
            }
        }
    }

    // MARK: - Projection

    func setProjection(_ width: Float, _ height: Float) {
        // Match Android's AndroidES1Renderer projection exactly:
        //   BASE_MODEL_CANVAS_W = 1280, DEFAULT_VISIBLE_HEIGHT = 1200
        //   logicalH = 1200
        //   logicalW = 1200 * viewWidth / viewHeight
        //   marginW = 0.5 * (1280 - logicalW)
        //   glOrthof(marginW, marginW + logicalW, logicalH, 0, 0.5, -0.5)
        //
        // This maps model coordinates [marginW..marginW+logicalW] x [0..1200]
        // to NDC [-1,1] x [-1,1], centered at X=640 (half of 1280).
        let BASE_MODEL_CANVAS_W: Float = 1280.0
        let DEFAULT_VISIBLE_HEIGHT: Float = 1200.0

        let logicalH = DEFAULT_VISIBLE_HEIGHT
        let logicalW = logicalH * width / height
        let marginW = 0.5 * (BASE_MODEL_CANVAS_W - logicalW)

        // Orthographic projection: [left, right] x [bottom, top] → NDC
        let left = marginW
        let right = marginW + logicalW
        let bottom = logicalH   // model Y increases downward
        let top: Float = 0.0    // model Y=0 is at the top

        // Standard orthographic matrix (column-major for Metal/simd)
        // x_ndc = 2*(x - left)/(right - left) - 1
        // y_ndc = 2*(y - bottom)/(top - bottom) - 1
        let tx = -(right + left) / (right - left)   // = -1280/logicalW
        let ty = -(top + bottom) / (top - bottom)   // = 1.0

        drawParam.projectionMatrix = simd_float4x4(
            SIMD4<Float>(2.0 / (right - left), 0, 0, 0),
            SIMD4<Float>(0, 2.0 / (top - bottom), 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(tx, ty, 0, 1)
        )
    }

    // MARK: - Draw

    /// Two-pass draw: first renders clip masks (offscreen), then draws all meshes to screen.
    /// The renderPassDescriptor is for the main screen pass.
    func draw(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) {
        drawParam.commandBuffer = commandBuffer

        // Phase 1: Pre-draw — render clip masks into offscreen texture.
        // This creates its own render encoder internally (targeting the mask texture).
        drawParam.renderEncoder = nil
        modelContext.preDraw(drawParam)

        // Phase 2: Create the main screen render encoder and draw all meshes.
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("[Live2D] Failed to create main render encoder")
            return
        }
        drawParam.renderEncoder = encoder
        modelContext.draw(drawParam)
        encoder.endEncoding()
        drawParam.renderEncoder = nil
    }

    // MARK: - Static loader

    static func loadModel(from data: Data) -> Live2DModelMetal {
        let model = Live2DModelMetal()
        ALive2DModel.loadModel(model, data)
        return model
    }
}
