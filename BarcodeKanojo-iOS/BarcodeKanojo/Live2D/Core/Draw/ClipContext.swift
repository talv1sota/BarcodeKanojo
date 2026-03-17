// ClipContext.swift — Clipping mask system for Metal renderer
// Ported from live2d-v2/live2d/core/graphics/clip_context.py
//              and live2d-v2/live2d/core/graphics/clipping_manager_opengl.py

import Foundation
import Metal
import simd

// MARK: - ClipRectF

struct ClipRectF {
    var x: Float = 0
    var y: Float = 0
    var width: Float = 0
    var height: Float = 0
    var isSet: Bool = false

    var right: Float { x + width }
    var bottom: Float { y + height }

    mutating func expand(_ dx: Float, _ dy: Float) {
        x -= dx
        y -= dy
        width += 2 * dx
        height += 2 * dy
    }
}

// MARK: - ClipUniforms (matches Metal shader ClipUniforms struct)

struct ClipUniforms {
    var clipMatrix: simd_float4x4 = matrix_identity_float4x4
    var channelFlag: SIMD4<Float> = .zero
    var clipBounds: SIMD4<Float> = .zero
}

// MARK: - ClipContext

/// Represents one unique set of clip mask meshes. Multiple clipped meshes that
/// share the same clip IDs share a single ClipContext.
final class ClipContext {
    var clipIDList: [String] = []
    /// Indices into ModelContext.drawDataList for meshes that form the mask
    var clippingMaskDrawIndexList: [Int] = []
    /// Indices into ModelContext.drawDataList for meshes that are clipped by this mask
    var clippedDrawDataIndices: [Int] = []
    var isUsing: Bool = true
    var layoutChannelNo: Int = 0
    var layoutBounds: ClipRectF = ClipRectF()
    var allClippedDrawRect: ClipRectF = ClipRectF()
    var matrixForMask: simd_float4x4 = matrix_identity_float4x4
    var matrixForDraw: simd_float4x4 = matrix_identity_float4x4

    init(mc: ModelContext, clipIDs: [String]) {
        self.clipIDList = clipIDs
        for idStr in clipIDs {
            let lid = Live2DId.getID(idStr)
            let idx = mc.getDrawDataIndex(lid)
            clippingMaskDrawIndexList.append(idx)
            if idx < 0 {
                print("[L2D-CLIP] Warning: clip mask ID '\(idStr)' not found in draw data")
            }
        }
    }

    func addClippedDrawData(drawIndex: Int) {
        clippedDrawDataIndices.append(drawIndex)
    }
}

// MARK: - ClippingManagerMetal

/// Manages clip masks: allocates offscreen texture, renders mask meshes,
/// and provides the mask texture + matrices for clipped mesh drawing.
final class ClippingManagerMetal {
    static let CHANNEL_COUNT = 4
    static let CLIP_BUFFER_SIZE = 256

    weak var drawParam: DrawParamMetal?
    var clipContextList: [ClipContext] = []
    var maskTexture: MTLTexture?
    private var frameCount: Int = 0

    /// RGBA channel selector colors for packing multiple masks
    static let channelColors: [SIMD4<Float>] = [
        SIMD4<Float>(0, 0, 0, 1),  // Channel 0: Alpha
        SIMD4<Float>(1, 0, 0, 0),  // Channel 1: Red
        SIMD4<Float>(0, 1, 0, 0),  // Channel 2: Green
        SIMD4<Float>(0, 0, 1, 0),  // Channel 3: Blue
    ]

    init(_ dp: DrawParamMetal?) {
        self.drawParam = dp
        createMaskTexture()
    }

    private func createMaskTexture() {
        guard let device = drawParam?.device else { return }
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Self.CLIP_BUFFER_SIZE,
            height: Self.CLIP_BUFFER_SIZE,
            mipmapped: false
        )
        desc.usage = [.renderTarget, .shaderRead]
        desc.storageMode = .private
        maskTexture = device.makeTexture(descriptor: desc)
        if maskTexture != nil {
            print("[L2D-CLIP] Created mask texture \(Self.CLIP_BUFFER_SIZE)x\(Self.CLIP_BUFFER_SIZE)")
        }
    }

    // MARK: - Initialize clip contexts from draw data

    func initContext(_ mc: ModelContext) {
        clipContextList.removeAll()

        let drawDataList = mc.drawDataList
        let drawContextList = mc.drawContextList

        for i in 0..<drawDataList.count {
            guard let dd = drawDataList[i],
                  let clipIDs = dd.getClipIDList(), !clipIDs.isEmpty else { continue }

            // Find or create a ClipContext for this set of clip IDs
            let ctx = findSameClip(clipIDs) ?? {
                let newCtx = ClipContext(mc: mc, clipIDs: clipIDs)
                clipContextList.append(newCtx)
                return newCtx
            }()

            ctx.addClippedDrawData(drawIndex: i)

            if i < drawContextList.count {
                drawContextList[i]?.clipBufPre_clipContext = ctx
            }
        }

        print("[L2D-CLIP] Initialized \(clipContextList.count) clip contexts")
        for (idx, ctx) in clipContextList.enumerated() {
            print("[L2D-CLIP]  ctx[\(idx)] masks=\(ctx.clipIDList) clipped=\(ctx.clippedDrawDataIndices.count) meshes maskIndices=\(ctx.clippingMaskDrawIndexList)")
        }
    }

    private func findSameClip(_ clipIDs: [String]) -> ClipContext? {
        for ctx in clipContextList {
            if ctx.clipIDList.count == clipIDs.count {
                var allMatch = true
                for id in clipIDs {
                    if !ctx.clipIDList.contains(id) {
                        allMatch = false
                        break
                    }
                }
                if allMatch { return ctx }
            }
        }
        return nil
    }

    // MARK: - Per-frame clip mask setup and rendering

    func setupClip(_ mc: ModelContext, _ dp: DrawParamMetal) {
        if clipContextList.isEmpty { return }
        frameCount += 1
        let isFirstFrame = (frameCount == 1)

        // Lazy-create mask texture if it wasn't created during init()
        // (device may not have been available during the first initModel() call)
        if maskTexture == nil {
            self.drawParam = dp
            createMaskTexture()
            if isFirstFrame {
                print("[L2D-CLIP] Lazy mask texture creation: \(maskTexture != nil ? "OK" : "FAILED") device=\(dp.device != nil)")
            }
        }
        guard let maskTexture = maskTexture else {
            if isFirstFrame { print("[L2D-CLIP] ⚠ No mask texture — aborting setupClip") }
            return
        }

        // Phase 1: Calculate bounding rects for all clipped meshes
        var activeCount = 0
        for ctx in clipContextList {
            calcClippedDrawTotalBounds(mc, ctx)
            if ctx.isUsing { activeCount += 1 }
        }

        if isFirstFrame {
            print("[L2D-CLIP] Frame 1: \(clipContextList.count) contexts, \(activeCount) active")
            for (idx, ctx) in clipContextList.enumerated() {
                let b = ctx.allClippedDrawRect
                print("[L2D-CLIP]   ctx[\(idx)] using=\(ctx.isUsing) bounds=(\(b.x),\(b.y),\(b.width),\(b.height)) masks=\(ctx.clippingMaskDrawIndexList) clipped=\(ctx.clippedDrawDataIndices)")
            }
        }

        if activeCount == 0 {
            if isFirstFrame { print("[L2D-CLIP] ⚠ No active clip contexts — all clipped meshes unavailable") }
            return
        }

        // Phase 2: Assign tile layout positions
        setupLayoutBounds(activeCount)

        // Phase 3: Create offscreen render pass and render all mask meshes
        let passDesc = MTLRenderPassDescriptor()
        passDesc.colorAttachments[0].texture = maskTexture
        passDesc.colorAttachments[0].loadAction = .clear
        passDesc.colorAttachments[0].storeAction = .store
        passDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        guard let commandBuffer = dp.commandBuffer,
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDesc),
              let maskPipeline = dp.pipelineStateMask else {
            if isFirstFrame {
                print("[L2D-CLIP] ⚠ Failed to create mask render encoder: cmdBuf=\(dp.commandBuffer != nil) maskPipeline=\(dp.pipelineStateMask != nil)")
            }
            return
        }

        encoder.setViewport(MTLViewport(originX: 0, originY: 0,
                                         width: Double(Self.CLIP_BUFFER_SIZE),
                                         height: Double(Self.CLIP_BUFFER_SIZE),
                                         znear: 0, zfar: 1))

        var totalMaskDrawCalls = 0

        for (ctxIdx, ctx) in clipContextList.enumerated() {
            if !ctx.isUsing { continue }

            let bounds = ctx.allClippedDrawRect
            let layout = ctx.layoutBounds

            // Expand bounds by 5% on each side
            var expanded = bounds
            expanded.expand(bounds.width * 0.05, bounds.height * 0.05)

            // Guard against zero-size bounds
            guard expanded.width > 0.0001 && expanded.height > 0.0001 else { continue }

            // Compute scale from model-space to tile-space
            let scaleX = layout.width / expanded.width
            let scaleY = layout.height / expanded.height

            // Build matrixForMask: model-space → offscreen NDC [-1,+1]
            // Operations compose right-to-left: last translate applied first to the point
            var mfm = matrix_identity_float4x4
            mfm = simd_mul(mfm, makeTranslation(-1, -1, 0))
            mfm = simd_mul(mfm, makeScale(2, 2, 1))
            mfm = simd_mul(mfm, makeTranslation(layout.x, layout.y, 0))
            mfm = simd_mul(mfm, makeScale(scaleX, scaleY, 1))
            mfm = simd_mul(mfm, makeTranslation(-expanded.x, -expanded.y, 0))
            ctx.matrixForMask = mfm

            // Build matrixForDraw: model-space → [0,1] texture UV
            var mfd = matrix_identity_float4x4
            mfd = simd_mul(mfd, makeTranslation(layout.x, layout.y, 0))
            mfd = simd_mul(mfd, makeScale(scaleX, scaleY, 1))
            mfd = simd_mul(mfd, makeTranslation(-expanded.x, -expanded.y, 0))
            ctx.matrixForDraw = mfd

            // Clip bounds in NDC for the isInside test
            let clipBoundsNDC = SIMD4<Float>(
                layout.x * 2 - 1,
                layout.y * 2 - 1,
                layout.right * 2 - 1,
                layout.bottom * 2 - 1
            )

            let channelColor = Self.channelColors[ctx.layoutChannelNo]

            if isFirstFrame {
                print("[L2D-CLIP]   ctx[\(ctxIdx)] layout=(\(layout.x),\(layout.y),\(layout.width),\(layout.height)) ch=\(ctx.layoutChannelNo) expanded=(\(expanded.x),\(expanded.y),\(expanded.width),\(expanded.height))")
                print("[L2D-CLIP]   ctx[\(ctxIdx)] scaleXY=(\(scaleX),\(scaleY)) clipBoundsNDC=\(clipBoundsNDC) channelColor=\(channelColor)")
                let m = ctx.matrixForMask
                print("[L2D-CLIP]   ctx[\(ctxIdx)] matrixForMask diag=(\(m.columns.0.x),\(m.columns.1.y),\(m.columns.2.z),\(m.columns.3.w)) trans=(\(m.columns.3.x),\(m.columns.3.y))")
                let d = ctx.matrixForDraw
                print("[L2D-CLIP]   ctx[\(ctxIdx)] matrixForDraw diag=(\(d.columns.0.x),\(d.columns.1.y),\(d.columns.2.z),\(d.columns.3.w)) trans=(\(d.columns.3.x),\(d.columns.3.y))")
            }

            // Render each mask mesh into the offscreen texture
            for maskIdx in ctx.clippingMaskDrawIndexList {
                if maskIdx < 0 {
                    if isFirstFrame { print("[L2D-CLIP]     ⚠ maskIdx=\(maskIdx) INVALID (not found)") }
                    continue
                }
                guard let mesh = mc.getDrawData(maskIdx) as? Mesh,
                      let dctx = mc.getDrawContext(maskIdx) as? MeshContext else {
                    if isFirstFrame { print("[L2D-CLIP]     ⚠ maskIdx=\(maskIdx) no Mesh/MeshContext") }
                    continue
                }

                // Match Python: mesh.draw() checks paramOutside and availability
                if dctx.isParamOutside() {
                    if isFirstFrame { print("[L2D-CLIP]     ⚠ maskIdx=\(maskIdx) paramOutside — skipping") }
                    continue
                }

                let vertices = dctx.transformedPoints ?? dctx.interpolatedPoints
                guard let vertices = vertices,
                      let uvs = mesh.getUvs(),
                      let indices = mesh.getIndexArray(),
                      !indices.isEmpty else {
                    if isFirstFrame { print("[L2D-CLIP]     ⚠ maskIdx=\(maskIdx) no vertices/uvs/indices") }
                    continue
                }

                let pointCount = uvs.count / 2

                // Build vertex buffer
                var vertexData = [Live2DVertex]()
                vertexData.reserveCapacity(pointCount)
                for i in 0..<pointCount {
                    let vIdx = i * Live2DDEF.VERTEX_STEP + Live2DDEF.VERTEX_OFFSET
                    let uIdx = i * 2
                    guard vIdx + 1 < vertices.count && uIdx + 1 < uvs.count else { break }
                    vertexData.append(Live2DVertex(
                        position: SIMD2<Float>(vertices[vIdx], vertices[vIdx + 1]),
                        texCoord: SIMD2<Float>(uvs[uIdx], uvs[uIdx + 1])
                    ))
                }

                let metalIndices = indices.map { UInt16(bitPattern: $0) }

                guard let device = dp.device,
                      let vb = device.makeBuffer(bytes: vertexData,
                                                  length: vertexData.count * MemoryLayout<Live2DVertex>.stride,
                                                  options: .storageModeShared),
                      let ib = device.makeBuffer(bytes: metalIndices,
                                                  length: metalIndices.count * MemoryLayout<UInt16>.stride,
                                                  options: .storageModeShared) else { continue }

                // Uniforms: use matrixForMask as the projection matrix
                var uniforms = Live2DUniforms(
                    projectionMatrix: ctx.matrixForMask,
                    opacity: 1.0,
                    compositionType: 0,
                    multiplyColor: SIMD4<Float>(1, 1, 1, 1),
                    screenColor: SIMD4<Float>(0, 0, 0, 0),
                    useClipMask: 0
                )

                var clipUniforms = ClipUniforms(
                    clipMatrix: matrix_identity_float4x4,
                    channelFlag: channelColor,
                    clipBounds: clipBoundsNDC
                )

                encoder.setRenderPipelineState(maskPipeline)
                encoder.setCullMode(.none)
                encoder.setVertexBuffer(vb, offset: 0, index: 0)
                encoder.setVertexBytes(&uniforms, length: MemoryLayout<Live2DUniforms>.stride, index: 1)
                encoder.setFragmentBytes(&clipUniforms, length: MemoryLayout<ClipUniforms>.stride, index: 0)

                // Bind the mesh's diffuse texture for alpha sampling
                let texNo = mesh.getTextureNo()
                if let tex = dp.textures[texNo] {
                    encoder.setFragmentTexture(tex, index: 0)
                } else if isFirstFrame {
                    print("[L2D-CLIP]     ⚠ maskIdx=\(maskIdx) MISSING texture \(texNo)!")
                }

                encoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: metalIndices.count,
                    indexType: .uint16,
                    indexBuffer: ib,
                    indexBufferOffset: 0
                )
                totalMaskDrawCalls += 1

                if isFirstFrame {
                    let v0 = vertexData.first
                    let vLast = vertexData.last
                    print("[L2D-CLIP]     maskIdx=\(maskIdx) \(mesh.getId()?.id ?? "?") pts=\(pointCount) tris=\(metalIndices.count/3) texNo=\(texNo) v0=(\(v0?.position.x ?? 0),\(v0?.position.y ?? 0)) vN=(\(vLast?.position.x ?? 0),\(vLast?.position.y ?? 0))")
                }
            }
        }

        encoder.endEncoding()

        if isFirstFrame {
            print("[L2D-CLIP] Mask pass complete: \(totalMaskDrawCalls) draw calls into \(Self.CLIP_BUFFER_SIZE)x\(Self.CLIP_BUFFER_SIZE) texture")
        }

        // Store mask texture reference for main draw pass
        dp.maskTexture = maskTexture
    }

    // MARK: - Bounding rect calculation

    private func calcClippedDrawTotalBounds(_ mc: ModelContext, _ ctx: ClipContext) {
        var minX: Float = .greatestFiniteMagnitude
        var minY: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var maxY: Float = -.greatestFiniteMagnitude
        var found = false

        for drawIndex in ctx.clippedDrawDataIndices {
            guard let dctx = mc.getDrawContext(drawIndex) as? MeshContext else { continue }
            if !dctx.isAvailable() { continue }

            let pts = dctx.transformedPoints ?? dctx.interpolatedPoints
            guard let pts = pts else { continue }

            let count = pts.count / Live2DDEF.VERTEX_STEP
            for i in 0..<count {
                let idx = i * Live2DDEF.VERTEX_STEP + Live2DDEF.VERTEX_OFFSET
                guard idx + 1 < pts.count else { break }
                let x = pts[idx]
                let y = pts[idx + 1]
                if x < minX { minX = x }
                if y < minY { minY = y }
                if x > maxX { maxX = x }
                if y > maxY { maxY = y }
                found = true
            }
        }

        if found && maxX > minX && maxY > minY {
            ctx.allClippedDrawRect = ClipRectF(x: minX, y: minY,
                                                width: maxX - minX, height: maxY - minY,
                                                isSet: true)
            ctx.isUsing = true
        } else {
            ctx.allClippedDrawRect = ClipRectF()
            ctx.isUsing = false
        }
    }

    // MARK: - Layout tiling (distributes clip contexts across RGBA channels)

    private func setupLayoutBounds(_ activeCount: Int) {
        let perChannel = activeCount / Self.CHANNEL_COUNT
        let remainder = activeCount % Self.CHANNEL_COUNT
        var contextIndex = 0

        for ch in 0..<Self.CHANNEL_COUNT {
            let count = perChannel + (ch < remainder ? 1 : 0)

            for i in 0..<count {
                // Find next active context
                while contextIndex < clipContextList.count && !clipContextList[contextIndex].isUsing {
                    contextIndex += 1
                }
                guard contextIndex < clipContextList.count else { break }
                let ctx = clipContextList[contextIndex]
                contextIndex += 1

                ctx.layoutChannelNo = ch

                if count == 1 {
                    ctx.layoutBounds = ClipRectF(x: 0, y: 0, width: 1, height: 1, isSet: true)
                } else if count == 2 {
                    let col = Float(i)
                    ctx.layoutBounds = ClipRectF(x: col * 0.5, y: 0, width: 0.5, height: 1, isSet: true)
                } else if count <= 4 {
                    let col = Float(i % 2)
                    let row = Float(i / 2)
                    ctx.layoutBounds = ClipRectF(x: col * 0.5, y: row * 0.5, width: 0.5, height: 0.5, isSet: true)
                } else {
                    let col = Float(i % 3)
                    let row = Float(i / 3)
                    ctx.layoutBounds = ClipRectF(x: col / 3.0, y: row / 3.0,
                                                  width: 1.0 / 3.0, height: 1.0 / 3.0, isSet: true)
                }
            }
        }
    }

    // MARK: - Matrix helpers

    private func makeTranslation(_ tx: Float, _ ty: Float, _ tz: Float) -> simd_float4x4 {
        simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(tx, ty, tz, 1)
        )
    }

    private func makeScale(_ sx: Float, _ sy: Float, _ sz: Float) -> simd_float4x4 {
        simd_float4x4(
            SIMD4<Float>(sx, 0, 0, 0),
            SIMD4<Float>(0, sy, 0, 0),
            SIMD4<Float>(0, 0, sz, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
}
