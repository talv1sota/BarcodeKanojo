// IDrawData.swift — Base class for drawable data
// Ported from live2d-v2/live2d/core/draw/idraw_data.py

import Foundation

class IDrawData: Live2DSerializable {
    static let DEFORMER_INDEX_NOT_INIT: Int = -2
    static let DEFAULT_ORDER: Int = 500
    static let TYPE_MESH: Int = 2
    static var totalMinOrder: Int = DEFAULT_ORDER
    static var totalMaxOrder: Int = DEFAULT_ORDER

    var clipIDList: [String]?
    var clipID: Live2DId?
    var id: Live2DId?
    var targetId: Live2DId?
    var pivotMgr: PivotManager?
    var averageDrawOrder: Int = 0
    var pivotDrawOrders: [Int32]?
    var pivotOpacities: [Float]?

    func read(_ br: BinaryReader) {
        id = br.readObject() as? Live2DId
        targetId = br.readObject() as? Live2DId
        pivotMgr = br.readObject() as? PivotManager
        averageDrawOrder = Int(br.readInt32())
        pivotDrawOrders = br.readInt32Array()
        pivotOpacities = br.readFloat32Array()
        if br.getFormatVersion() >= Live2DDEF.LIVE2D_FORMAT_VERSION_AVAILABLE {
            clipID = br.readObject() as? Live2DId
            clipIDList = IDrawData.convertClipIDForV2_11(clipID)
        } else {
            clipIDList = nil
        }
        if let orders = pivotDrawOrders {
            IDrawData.setDrawOrders(orders)
        }
    }

    func getClipIDList() -> [String]? { clipIDList }

    static func convertClipIDForV2_11(_ idObj: Live2DId?) -> [String]? {
        guard let idObj = idObj else { return nil }
        let s = idObj.id
        if s.isEmpty { return nil }
        if !s.contains(",") {
            return [s]
        }
        return s.components(separatedBy: ",")
    }

    func setupInterpolate(_ mc: ModelContext, _ dc: IDrawContext) {
        guard let pm = pivotMgr, let drawOrders = pivotDrawOrders, let opacities = pivotOpacities else { return }
        dc.paramOutside = [false]
        var outside = dc.paramOutside
        dc.interpolatedDrawOrder = Int(UtInterpolate.interpolateInt(mc, pm, &outside, drawOrders))
        dc.paramOutside = outside
        if !Live2D.L2D_OUTSIDE_PARAM_AVAILABLE && dc.paramOutside[0] {
            return
        }
        dc.interpolatedOpacity = UtInterpolate.interpolateFloat(mc, pm, &outside, opacities)
        dc.paramOutside = outside
    }

    func setupTransform(_ mc: ModelContext, _ dc: IDrawContext? = nil) {
        // Override in subclass
    }

    func getId() -> Live2DId? { id }
    func setId(_ v: Live2DId) { id = v }
    func getTargetId() -> Live2DId? { targetId }
    func setTargetId(_ v: Live2DId) { targetId = v }

    static func getOpacity(_ ctx: IDrawContext) -> Float { ctx.interpolatedOpacity }
    static func getDrawOrder(_ ctx: IDrawContext) -> Int { ctx.interpolatedDrawOrder }

    func needTransform() -> Bool {
        return targetId != nil && targetId != Live2DId.DST_BASE_ID()
    }

    func getType() -> Int {
        fatalError("subclass must override")
    }

    static func setDrawOrders(_ orders: [Int32]) {
        for i in stride(from: orders.count - 1, through: 0, by: -1) {
            let order = Int(orders[i])
            if order < totalMinOrder {
                totalMinOrder = order
            } else if order > totalMaxOrder {
                totalMaxOrder = order
            }
        }
    }

    static func getTotalMinOrder() -> Int { totalMinOrder }
    static func getTotalMaxOrder() -> Int { totalMaxOrder }
}
