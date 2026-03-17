// Mesh.swift — Textured mesh drawable
// Ported from live2d-v2/live2d/core/draw/mesh.py

import Foundation

final class Mesh: IDrawData {
    static var INSTANCE_COUNT: Int = 0
    static let MASK_COLOR_COMPOSITION: Int32 = 30
    static let COLOR_COMPOSITION_NORMAL: Int = 0
    static let COLOR_COMPOSITION_SCREEN: Int = 1
    static let COLOR_COMPOSITION_MULTIPLY: Int = 2
    private static var paramOutsideFlag: [Bool] = [false]

    var textureNo: Int = -1
    var pointCount: Int = 0
    var polygonCount: Int = 0
    var optionFlag: Int32 = 0
    var indexArray: [Int16]?
    var pivotPoints: [Any?]?
    var uvs: [Float]?
    var colorCompositionType: Int = COLOR_COMPOSITION_NORMAL
    var culling: Bool = true
    var instanceNo: Int = 0
    var bkOptionColor: Int32 = 0
    /// Tracks whether UV V-coordinates have already been flipped.
    /// Prevents double-flip when initContext() is called multiple times
    /// (e.g., once during loadModel, again after parts replacement in initModel).
    var uvsFlipped: Bool = false

    override init() {
        super.init()
        instanceNo = Mesh.INSTANCE_COUNT
        Mesh.INSTANCE_COUNT += 1
    }

    func setTextureNo(_ v: Int) { textureNo = v }
    func getTextureNo() -> Int { textureNo }
    func getUvs() -> [Float]? { uvs }
    func getOptionFlag() -> Int32 { optionFlag }
    func getNumPoints() -> Int { pointCount }
    override func getType() -> Int { IDrawData.TYPE_MESH }
    func getIndexArray() -> [Int16]? { indexArray }

    override func read(_ br: BinaryReader) {
        super.read(br)
        textureNo = Int(br.readInt32())
        pointCount = Int(br.readInt32())
        polygonCount = Int(br.readInt32())

        // Read index array
        let indexObj = br.readObject()
        indexArray = [Int16](repeating: 0, count: polygonCount * 3)
        if let srcIndices = indexObj as? [Int32] {
            for j in stride(from: polygonCount * 3 - 1, through: 0, by: -1) {
                indexArray![j] = Int16(srcIndices[j])
            }
        }

        pivotPoints = br.readObject() as? [Any?]
        uvs = br.readObject() as? [Float]

        if br.getFormatVersion() >= Live2DDEF.LIVE2D_FORMAT_VERSION_V2_8_TEX_OPTION {
            optionFlag = br.readInt32()
            if optionFlag != 0 {
                if (optionFlag & 1) != 0 {
                    // BK_OPTION_COLOR: Cybird custom color-type flag
                    bkOptionColor = br.readInt32()
                }
                if (optionFlag & Mesh.MASK_COLOR_COMPOSITION) != 0 {
                    colorCompositionType = Int((optionFlag & Mesh.MASK_COLOR_COMPOSITION) >> 1)
                } else {
                    colorCompositionType = Mesh.COLOR_COMPOSITION_NORMAL
                }
                if (optionFlag & 32) != 0 {
                    culling = false
                }
            }
        } else {
            optionFlag = 0
        }
    }

    func initContext(_ mc: ModelContext) -> MeshContext {
        let ctx = MeshContext(self)
        let coordCount = pointCount * Live2DDEF.VERTEX_STEP
        let needsTransform = needTransform()

        ctx.interpolatedPoints = [Float](repeating: 0, count: coordCount)
        ctx.transformedPoints = needsTransform ? [Float](repeating: 0, count: coordCount) : nil

        // Flip V coordinate for texture mapping (only once!)
        // Guard against double-flip: initModel() is called twice —
        // first in ALive2DModel.loadModel(), then again after parts replacement
        // in KanojoModel.load(). Base model meshes that aren't replaced would
        // get their UVs flipped back to the wrong orientation without this guard.
        if Live2DDEF.VERTEX_TYPE == Live2DDEF.VERTEX_TYPE_OFFSET0_STEP2 {
            if !uvsFlipped && Live2DDEF.REVERSE_TEXTURE_T, var uvsArr = uvs {
                for j in stride(from: pointCount - 1, through: 0, by: -1) {
                    let idx = j << 1
                    uvsArr[idx + 1] = 1 - uvsArr[idx + 1]
                }
                uvs = uvsArr
                uvsFlipped = true
            }
        }

        return ctx
    }

    func setupInterpolateMesh(_ mc: ModelContext, _ dc: MeshContext) {
        guard self === dc.getDrawData() as? Mesh else {
            print("### assert!! ###")
            return
        }
        guard let pm = pivotMgr else { return }
        if !pm.checkParamUpdated(mc) { return }

        // Call base interpolation (draw order, opacity)
        setupInterpolate(mc, dc)
        if dc.paramOutside[0] { return }

        // Interpolate vertex positions
        var outsideFlag = Mesh.paramOutsideFlag
        outsideFlag[0] = false
        guard var interpPts = dc.interpolatedPoints else { return }
        UtInterpolate.interpolatePoints(mc, pm, &outsideFlag, pointCount,
                                        pivotPoints ?? [], &interpPts,
                                        Live2DDEF.VERTEX_OFFSET, Live2DDEF.VERTEX_STEP)
        dc.interpolatedPoints = interpPts
    }

    func setupTransformMesh(_ mc: ModelContext, _ dc: MeshContext) {
        guard self === dc.getDrawData() as? Mesh else {
            fatalError("context not match")
        }

        if dc.paramOutside[0] { return }

        if needTransform() {
            guard let tid = getTargetId() else { return }
            if dc.tmpDeformerIndex == IDrawData.DEFORMER_INDEX_NOT_INIT {
                dc.tmpDeformerIndex = mc.getDeformerIndex(tid)
            }
            if dc.tmpDeformerIndex < 0 {
                print("[L2D-DBG] ⚠ Mesh deformer NOT FOUND: \(id?.id ?? "?") target=\(tid.id)")
                dc.available = false
            } else {
                let d = mc.getDeformer(dc.tmpDeformerIndex)
                let dctx = mc.getDeformerContext(dc.tmpDeformerIndex)
                if let d = d, !dctx.isOutsideParam() {
                    guard let srcPts = dc.interpolatedPoints else { return }
                    var dstPts = dc.transformedPoints ?? [Float](repeating: 0, count: srcPts.count)
                    d.transformPoints(mc, dctx, srcPts, &dstPts, pointCount,
                                      Live2DDEF.VERTEX_OFFSET, Live2DDEF.VERTEX_STEP)
                    dc.transformedPoints = dstPts
                    dc.available = true
                } else {
                    dc.available = false
                }
                dc.baseOpacity = dctx.getTotalOpacity()
            }
        }
    }

    func draw(_ dp: DrawParamMetal, _ mctx: ModelContext, _ dctx: MeshContext) {
        guard self === dctx.getDrawData() as? Mesh else {
            fatalError("context not match")
        }
        if dctx.paramOutside[0] { return }

        var texNr = textureNo
        if texNr < 0 { texNr = 1 }

        let opacity = IDrawData.getOpacity(dctx) * dctx.partsOpacity * dctx.baseOpacity
        let vertices = dctx.transformedPoints ?? dctx.interpolatedPoints!
        let pctx = mctx.getPartsContext(dctx.partsIndex)

        dp.setClipBufPre_clipContextForDraw(dctx.clipBufPre_clipContext)
        dp.setCulling(culling)
        dp.drawTexture(texNr, pctx.screenColor, indexArray!, vertices, uvs!,
                       opacity, colorCompositionType, pctx.multiplyColor)
    }
}
