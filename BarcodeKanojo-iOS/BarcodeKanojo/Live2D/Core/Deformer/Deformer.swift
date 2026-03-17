// Deformer.swift — Base class for deformers (rotation, warp)
// Ported from live2d-v2/live2d/core/deformer/deformer.py

import Foundation

class Deformer: Live2DSerializable {
    static let DEFORMER_INDEX_NOT_INIT: Int = -2
    static let TYPE_ROTATION: Int = 1
    static let TYPE_WARP: Int = 2

    var id: Live2DId?
    var targetId: Live2DId?
    var dirty: Bool = true
    var pivotOpacities: [Float]?

    func read(_ br: BinaryReader) {
        id = br.readObject() as? Live2DId
        targetId = br.readObject() as? Live2DId
    }

    func readOpacity(_ br: BinaryReader) {
        if br.getFormatVersion() >= Live2DDEF.LIVE2D_FORMAT_VERSION_V2_10_SDK2 {
            pivotOpacities = br.readFloat32Array()
        }
    }

    func initContext(_ mc: ModelContext) -> DeformerContext {
        fatalError("subclass must override")
    }

    func setupInterpolate(_ mc: ModelContext, _ dc: DeformerContext) {
        fatalError("subclass must override")
    }

    func interpolateOpacity(_ mdc: ModelContext, _ pivotMgr: PivotManager,
                            _ dc: DeformerContext, _ ret: inout [Bool]) {
        if pivotOpacities == nil {
            dc.setInterpolatedOpacity(1)
        } else {
            dc.setInterpolatedOpacity(
                UtInterpolate.interpolateFloat(mdc, pivotMgr, &ret, pivotOpacities!)
            )
        }
    }

    func setupTransform(_ mc: ModelContext, _ dc: DeformerContext) -> Bool {
        fatalError("subclass must override")
    }

    func transformPoints(_ mc: ModelContext, _ dc: DeformerContext,
                         _ srcPoints: [Float], _ dstPoints: inout [Float],
                         _ numPoint: Int, _ ptOffset: Int, _ ptStep: Int) {
        fatalError("subclass must override")
    }

    func getType() -> Int {
        fatalError("subclass must override")
    }

    func setTargetId(_ v: Live2DId?) { targetId = v }
    func setId(_ v: Live2DId?) { id = v }
    func getTargetId() -> Live2DId? { targetId }
    func getId() -> Live2DId? { id }

    func needTransform() -> Bool {
        return targetId != nil && targetId != Live2DId.DST_BASE_ID()
    }
}
