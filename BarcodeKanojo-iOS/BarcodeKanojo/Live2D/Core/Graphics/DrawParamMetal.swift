// DrawParamMetal.swift — Metal-based renderer for Live2D meshes
// Ported from live2d-v2/live2d/core/graphics/draw_param_opengl.py
// Adapted from OpenGL ES 1.x/2.0 to Metal

import Foundation
import Metal
import MetalKit
import simd

// MARK: - Vertex layout

struct Live2DVertex {
    var position: SIMD2<Float>
    var texCoord: SIMD2<Float>
}

// MARK: - Uniforms

struct Live2DUniforms {
    var projectionMatrix: simd_float4x4
    var opacity: Float
    var compositionType: Int32  // 0=normal, 1=screen, 2=multiply
    var multiplyColor: SIMD4<Float>
    var screenColor: SIMD4<Float>
    var useClipMask: Int32
    var padding: SIMD2<Float> = .zero
}

// MARK: - DrawParamMetal

final class DrawParamMetal {
    var device: MTLDevice?
    var commandBuffer: MTLCommandBuffer?
    var renderEncoder: MTLRenderCommandEncoder?
    var pipelineState: MTLRenderPipelineState?
    var pipelineStateScreen: MTLRenderPipelineState?
    var pipelineStateMultiply: MTLRenderPipelineState?
    var pipelineStateMask: MTLRenderPipelineState?
    var pipelineStateClipped: MTLRenderPipelineState?

    var textures: [Int: MTLTexture] = [:]
    var projectionMatrix: simd_float4x4 = matrix_identity_float4x4
    var cullingEnabled: Bool = true
    var clipContext: ClipContext?
    var maskTexture: MTLTexture?

    // MARK: - Setup

    func setupDraw() {
        // Log previous frame stats on frame boundaries
        if frameNumber > 0 && frameNumber <= 3 {
            print("[L2D-DRAW] Frame \(frameNumber) stats: total=\(drawCallCount) clipped=\(clippedDrawCount) normal=\(normalDrawCount) texMiss=\(textureMissCount) missTex=\(textureMissSet)")
        }
        // Reset per-frame counters
        drawCallCount = 0
        clippedDrawCount = 0
        normalDrawCount = 0
        textureMissCount = 0
        textureMissSet.removeAll()
        frameNumber += 1
    }

    func setCulling(_ enabled: Bool) {
        cullingEnabled = enabled
    }

    func setClipBufPre_clipContextForDraw(_ ctx: ClipContext?) {
        clipContext = ctx
    }

    // MARK: - Texture management

    func setTexture(_ index: Int, _ texture: MTLTexture) {
        textures[index] = texture
    }

    // MARK: - Draw a textured mesh

    // Debug: track texture misses and clipped draws
    var textureMissCount: Int = 0
    var textureMissSet: Set<Int> = []
    var drawCallCount: Int = 0
    var clippedDrawCount: Int = 0
    var normalDrawCount: Int = 0
    var frameNumber: Int = 0

    func drawTexture(_ textureNo: Int, _ screenColor: [Float], _ indexArray: [Int16],
                     _ vertices: [Float], _ uvs: [Float], _ opacity: Float,
                     _ compositionType: Int, _ multiplyColor: [Float]) {
        drawCallCount += 1
        guard let encoder = renderEncoder else { return }
        guard let texture = textures[textureNo] else {
            textureMissCount += 1
            textureMissSet.insert(textureNo)
            return
        }
        if opacity < 0.001 { return }

        let pointCount = uvs.count / 2

        // Build vertex buffer
        var vertexData = [Live2DVertex]()
        vertexData.reserveCapacity(pointCount)
        for i in 0..<pointCount {
            let vIdx = i * Live2DDEF.VERTEX_STEP + Live2DDEF.VERTEX_OFFSET
            let uIdx = i * 2
            vertexData.append(Live2DVertex(
                position: SIMD2<Float>(vertices[vIdx], vertices[vIdx + 1]),
                texCoord: SIMD2<Float>(uvs[uIdx], uvs[uIdx + 1])
            ))
        }

        // Build index buffer
        let indices = indexArray.map { UInt16(bitPattern: $0) }

        // Create uniforms
        var uniforms = Live2DUniforms(
            projectionMatrix: projectionMatrix,
            opacity: opacity,
            compositionType: Int32(compositionType),
            multiplyColor: SIMD4<Float>(multiplyColor[0], multiplyColor[1],
                                        multiplyColor[2], multiplyColor[3]),
            screenColor: SIMD4<Float>(screenColor[0], screenColor[1],
                                      screenColor[2], screenColor[3]),
            useClipMask: clipContext != nil ? 1 : 0
        )

        guard let device = device else { return }

        // Create vertex buffer
        let vertexBuffer = device.makeBuffer(
            bytes: vertexData, length: vertexData.count * MemoryLayout<Live2DVertex>.stride,
            options: .storageModeShared
        )

        // Create index buffer
        let indexBuffer = device.makeBuffer(
            bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride,
            options: .storageModeShared
        )

        // Decide whether to use clipped pipeline (with mask texture sampling)
        let useClipped = clipContext != nil && maskTexture != nil && pipelineStateClipped != nil

        if useClipped {
            clippedDrawCount += 1
            // --- Clipped drawing path ---
            // Use clipped vertex/fragment shaders that sample from the mask texture
            let ctx = clipContext!

            if frameNumber == 1 && clippedDrawCount <= 10 {
                let d = ctx.matrixForDraw
                print("[L2D-DRAW] Clipped draw #\(clippedDrawCount): texNo=\(textureNo) pts=\(pointCount) opacity=\(opacity) ch=\(ctx.layoutChannelNo) maskTex=\(maskTexture != nil) matForDraw_diag=(\(d.columns.0.x),\(d.columns.1.y)) trans=(\(d.columns.3.x),\(d.columns.3.y))")
            }

            encoder.setRenderPipelineState(pipelineStateClipped!)
            encoder.setCullMode(cullingEnabled ? .back : .none)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Live2DUniforms>.stride, index: 1)

            // ClipUniforms at vertex buffer index 2 (clipMatrix = matrixForDraw)
            var clipUniforms = ClipUniforms(
                clipMatrix: ctx.matrixForDraw,
                channelFlag: ClippingManagerMetal.channelColors[ctx.layoutChannelNo],
                clipBounds: .zero  // not used for clipped drawing
            )
            encoder.setVertexBytes(&clipUniforms, length: MemoryLayout<ClipUniforms>.stride, index: 2)

            // Fragment uniforms
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Live2DUniforms>.stride, index: 0)
            encoder.setFragmentBytes(&clipUniforms, length: MemoryLayout<ClipUniforms>.stride, index: 1)

            // Textures: slot 0 = model texture, slot 1 = mask texture
            encoder.setFragmentTexture(texture, index: 0)
            encoder.setFragmentTexture(maskTexture!, index: 1)

            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indices.count,
                indexType: .uint16,
                indexBuffer: indexBuffer!,
                indexBufferOffset: 0
            )
        } else {
            normalDrawCount += 1
            // --- Normal (unclipped) drawing path ---
            // Select pipeline based on composition type
            let pipeline: MTLRenderPipelineState?
            switch compositionType {
            case Mesh.COLOR_COMPOSITION_SCREEN:
                pipeline = pipelineStateScreen ?? pipelineState
            case Mesh.COLOR_COMPOSITION_MULTIPLY:
                pipeline = pipelineStateMultiply ?? pipelineState
            default:
                pipeline = pipelineState
            }

            guard let selectedPipeline = pipeline else { return }

            encoder.setRenderPipelineState(selectedPipeline)
            encoder.setCullMode(cullingEnabled ? .back : .none)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Live2DUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Live2DUniforms>.stride, index: 0)
            encoder.setFragmentTexture(texture, index: 0)

            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indices.count,
                indexType: .uint16,
                indexBuffer: indexBuffer!,
                indexBufferOffset: 0
            )
        }
    }
}
