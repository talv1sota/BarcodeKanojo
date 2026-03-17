// ModelContext.swift — Core rendering context managing all model state
// Ported from live2d-v2/live2d/core/model_context.py

import Foundation

final class ModelContext {
    static let NOT_USED_ORDER: Int16 = -1
    static let NO_NEXT: Int16 = -1
    static let DEFAULT_PARAM_UPDATE_FLAG: Bool = false
    static let PARAM_UPDATED: Bool = true
    static let PARAM_FLOAT_MIN: Float = -1000000
    static let PARAM_FLOAT_MAX: Float = 1000000

    var needSetup: Bool = true
    var initVersion: Int = -1
    var nextParamPos: Int = 0

    var paramIdList: [Live2DId?] = []
    var paramValues: [Float] = []
    var lastParamValues: [Float] = []
    var paramMinValues: [Float] = []
    var paramMaxValues: [Float] = []
    var savedParamValues: [Float] = []
    var updatedParamFlags: [Bool] = []

    var deformerList: [Deformer?] = []
    var drawDataList: [IDrawData?] = []
    var tmpDrawDataList: [Live2DId: IDrawData]?
    var partsDataList: [PartsData?] = []

    var deformerContextList: [DeformerContext?] = []
    var drawContextList: [IDrawContext?] = []
    var partsContextList: [PartsDataContext?] = []

    var orderList_firstDrawIndex: [Int16]?
    var orderList_lastDrawIndex: [Int16]?
    var nextList_drawIndex: [Int16]?

    var tmpPivotTableIndices: [Int16]
    var tempTArray: [Float]

    weak var model: ALive2DModel?
    var clipManager: ClippingManagerMetal?
    var dpGL: DrawParamMetal?

    init(_ model: ALive2DModel) {
        self.model = model
        tmpPivotTableIndices = [Int16](repeating: 0, count: Live2DDEF.PIVOT_TABLE_SIZE)
        tempTArray = [Float](repeating: 0, count: Live2DDEF.MAX_INTERPOLATION)
    }

    // MARK: - Temp arrays (shared scratch space)

    func getTempPivotTableIndices() -> [Int16] { tmpPivotTableIndices }
    func setTempPivotTableIndices(_ v: [Int16]) { tmpPivotTableIndices = v }
    func getTempT() -> [Float] { tempTArray }
    func setTempT(_ v: [Float]) { tempTArray = v }

    // MARK: - Param access

    func getParamIndex(_ paramId: Live2DId) -> Int {
        for i in 0..<paramIdList.count {
            if paramIdList[i] == paramId {
                return i
            }
        }
        return extendAndAddParam(paramId, 0, ModelContext.PARAM_FLOAT_MIN, ModelContext.PARAM_FLOAT_MAX)
    }

    func getParamFloat(_ idx: Int) -> Float { paramValues[idx] }

    func setParamFloat(_ idx: Int, _ value: Float) {
        var v = value
        if v < paramMinValues[idx] { v = paramMinValues[idx] }
        if v > paramMaxValues[idx] { v = paramMaxValues[idx] }
        paramValues[idx] = v
    }

    func getParamMax(_ idx: Int) -> Float { paramMaxValues[idx] }
    func getParamMin(_ idx: Int) -> Float { paramMinValues[idx] }
    func isParamUpdated(_ idx: Int) -> Bool { updatedParamFlags[idx] == ModelContext.PARAM_UPDATED }
    func getInitVersion() -> Int { initVersion }
    func requireSetup() -> Bool { needSetup }

    // MARK: - Deformer access

    func getDeformerIndex(_ id: Live2DId) -> Int {
        for i in stride(from: deformerList.count - 1, through: 0, by: -1) {
            if deformerList[i]?.getId() == id {
                return i
            }
        }
        return -1
    }

    func getDeformer(_ idx: Int) -> Deformer? { deformerList[idx] }
    func getDeformerContext(_ idx: Int) -> DeformerContext { deformerContextList[idx]! }

    // MARK: - Draw data access

    func getDrawDataIndex(_ drawId: Live2DId) -> Int {
        for i in stride(from: drawDataList.count - 1, through: 0, by: -1) {
            if drawDataList[i]?.getId() == drawId {
                return i
            }
        }
        return -1
    }

    func getDrawData(_ idx: Int) -> IDrawData? {
        if idx < drawDataList.count { return drawDataList[idx] }
        return nil
    }

    func getDrawContext(_ idx: Int) -> IDrawContext? { drawContextList[idx] }

    // MARK: - Parts access

    func getPartsDataIndex(_ id: Live2DId) -> Int {
        for i in stride(from: partsDataList.count - 1, through: 0, by: -1) {
            if partsDataList[i]?.getId() == id {
                return i
            }
        }
        return -1
    }

    func getPartsContext(_ idx: Int) -> PartsDataContext { partsContextList[idx]! }

    func setPartsOpacity(_ idx: Int, _ opacity: Float) {
        partsContextList[idx]?.setPartsOpacity(opacity)
    }

    func getPartsOpacity(_ idx: Int) -> Float {
        return partsContextList[idx]?.getPartsOpacity() ?? 0
    }

    func setPartMultiplyColor(_ idx: Int, _ r: Float, _ g: Float, _ b: Float, _ a: Float) {
        partsContextList[idx]?.setPartMultiplyColor(r, g, b, a)
    }

    func getPartMultiplyColor(_ idx: Int) -> [Float] {
        return partsContextList[idx]?.multiplyColor ?? [1, 1, 1, 0]
    }

    func setPartScreenColor(_ idx: Int, _ r: Float, _ g: Float, _ b: Float, _ a: Float) {
        partsContextList[idx]?.setPartScreenColor(r, g, b, a)
    }

    func getPartScreenColor(_ idx: Int) -> [Float] {
        return partsContextList[idx]?.screenColor ?? [0, 0, 0, 0]
    }

    func setDrawParam(_ dp: DrawParamMetal?) { dpGL = dp }
    func getDrawParam() -> DrawParamMetal? { dpGL }

    // MARK: - Param management

    @discardableResult
    func extendAndAddParam(_ paramId: Live2DId, _ defaultVal: Float,
                            _ minVal: Float, _ maxVal: Float) -> Int {
        paramIdList.append(paramId)
        paramValues.append(defaultVal)
        lastParamValues.append(defaultVal)
        paramMinValues.append(minVal)
        paramMaxValues.append(maxVal)
        updatedParamFlags.append(ModelContext.DEFAULT_PARAM_UPDATE_FLAG)
        let ret = nextParamPos
        nextParamPos += 1
        return ret
    }

    func loadParam() {
        for i in 0..<savedParamValues.count {
            paramValues[i] = savedParamValues[i]
        }
    }

    func saveParam() {
        if savedParamValues.count < paramValues.count {
            savedParamValues = paramValues
        } else {
            for i in 0..<paramValues.count {
                savedParamValues[i] = paramValues[i]
            }
        }
    }

    // MARK: - Init

    func release() {
        deformerList.removeAll()
        drawDataList.removeAll()
        partsDataList.removeAll()
        tmpDrawDataList?.removeAll()
        deformerContextList.removeAll()
        drawContextList.removeAll()
        partsContextList.removeAll()
    }

    func initModel() {
        initVersion += 1
        drawFrameCounter = 0
        if !partsDataList.isEmpty {
            release()
        }

        guard let modelImpl = model?.getModelImpl() else { return }
        let partsData = modelImpl.getPartsDataList()

        var allDeformers: [Deformer?] = []
        var allDeformerContexts: [DeformerContext?] = []

        for v in 0..<partsData.count {
            guard let parts = partsData[v] as? PartsData else { continue }
            partsDataList.append(parts)
            partsContextList.append(parts.initContext())

            // Collect deformers
            let deformers = parts.getDeformer()
            for u in 0..<deformers.count {
                if let dfm = deformers[u] as? Deformer {
                    allDeformers.append(dfm)
                }
            }
            for u in 0..<deformers.count {
                if let dfm = deformers[u] as? Deformer {
                    let dctx = dfm.initContext(self)
                    dctx.setPartsIndex(v)
                    allDeformerContexts.append(dctx)
                }
            }

            // Collect draw data
            let draws = parts.getDrawData()
            for u in 0..<draws.count {
                guard let mesh = draws[u] as? Mesh else { continue }
                let mctx = mesh.initContext(self)
                mctx.partsIndex = v
                drawDataList.append(mesh)
                drawContextList.append(mctx)
            }
        }

        // Sort deformers by dependency (parents before children)
        let baseId = Live2DId.DST_BASE_ID()
        let totalDeformers = allDeformers.count
        print("[L2D-DBG] initModel: totalDeformers=\(totalDeformers), drawData=\(drawDataList.count), parts=\(partsDataList.count)")
        while true {
            var added = false
            for v in 0..<totalDeformers {
                guard let dfm = allDeformers[v] else { continue }
                let tid = dfm.getTargetId()
                if tid == nil || tid == baseId || getDeformerIndex(tid!) >= 0 {
                    deformerList.append(dfm)
                    deformerContextList.append(allDeformerContexts[v])
                    allDeformers[v] = nil
                    added = true
                }
            }
            if !added { break }
        }
        // Diagnostic: log deformer chain
        print("[L2D-DBG] Sorted \(deformerList.count)/\(totalDeformers) deformers")
        for i in 0..<deformerList.count {
            let d = deformerList[i]!
            let typeStr = d.getType() == Deformer.TYPE_WARP ? "W" : "R"
            print("[L2D-DBG]  [\(i)]\(typeStr) \(d.getId()?.id ?? "?") -> \(d.getTargetId()?.id ?? "BASE")")
        }
        let orphans = allDeformers.compactMap { $0 }
        if !orphans.isEmpty {
            print("[L2D-DBG] ⚠ \(orphans.count) ORPHAN deformers (parent not found):")
            for d in orphans {
                print("[L2D-DBG]  ORPHAN \(d.getId()?.id ?? "?") -> \(d.getTargetId()?.id ?? "?")")
            }
        }
        for i in 0..<drawDataList.count {
            if let dd = drawDataList[i], dd.needTransform(), let tid = dd.getTargetId() {
                if getDeformerIndex(tid) < 0 {
                    print("[L2D-DBG] ⚠ Mesh[\(i)] \(dd.getId()?.id ?? "?") target=\(tid.id) NOT FOUND")
                }
            }
        }

        // Register parameter definitions
        if let paramDefSet = modelImpl.getParamDefSet(),
           let paramDefs = paramDefSet.getParamDefFloatList() {
            for paramDef in paramDefs {
                if let pid = paramDef.getParamID() {
                    extendAndAddParam(pid, paramDef.getDefaultValue(),
                                      paramDef.getMinValue(), paramDef.getMaxValue())
                }
            }
        }

        // Initialize clipping — uses ClippingManagerMetal which takes ModelContext
        // directly to preserve index alignment between drawDataList and drawContextList
        clipManager = ClippingManagerMetal(dpGL)
        clipManager?.initContext(self)
        needSetup = true
    }

    // MARK: - Update

    func update() {
        // Mark changed params
        for i in 0..<paramValues.count {
            if paramValues[i] != lastParamValues[i] {
                updatedParamFlags[i] = ModelContext.PARAM_UPDATED
                lastParamValues[i] = paramValues[i]
            }
        }

        let deformerCount = deformerList.count
        let drawCount = drawDataList.count

        let minOrder = IDrawData.getTotalMinOrder()
        let maxOrder = IDrawData.getTotalMaxOrder()
        let orderRange = maxOrder - minOrder + 1
        if needSetup {
            print("[L2D-DBG] Draw order range: min=\(minOrder) max=\(maxOrder) buckets=\(orderRange)")
        }

        // Initialize draw order lists
        if orderList_firstDrawIndex == nil || orderList_firstDrawIndex!.count < orderRange {
            orderList_firstDrawIndex = [Int16](repeating: ModelContext.NOT_USED_ORDER, count: orderRange)
            orderList_lastDrawIndex = [Int16](repeating: ModelContext.NOT_USED_ORDER, count: orderRange)
        } else {
            for i in 0..<orderRange {
                orderList_firstDrawIndex![i] = ModelContext.NOT_USED_ORDER
                orderList_lastDrawIndex![i] = ModelContext.NOT_USED_ORDER
            }
        }

        if nextList_drawIndex == nil || nextList_drawIndex!.count < drawCount {
            nextList_drawIndex = [Int16](repeating: ModelContext.NO_NEXT, count: drawCount)
        } else {
            for i in 0..<drawCount {
                nextList_drawIndex![i] = ModelContext.NO_NEXT
            }
        }

        // Setup deformers
        for v in 0..<deformerCount {
            guard let dfm = deformerList[v], let dctx = deformerContextList[v] else { continue }
            dfm.setupInterpolate(self, dctx)
            let _ = dfm.setupTransform(self, dctx)
        }

        // First-frame diagnostic: dump deformer state after setup
        if needSetup {
            print("[L2D-DBG] === FIRST FRAME DEFORMER STATE ===")
            for v in 0..<deformerCount {
                guard let dfm = deformerList[v], let dctx = deformerContextList[v] else { continue }
                let typeStr = dfm.getType() == Deformer.TYPE_WARP ? "W" : "R"
                let avail = dctx.isAvailable() ? "OK" : "UNAVAIL"
                let parentIdx = (dctx as? WarpContext)?.tmpDeformerIndex ?? (dctx as? RotationContext)?.tmpDeformerIndex ?? -99
                if dfm.getType() == Deformer.TYPE_ROTATION, let rctx = dctx as? RotationContext {
                    let ia = rctx.interpolatedAffine
                    let ta = rctx.transformedAffine
                    print("[L2D-DBG]  [\(v)]\(typeStr) \(dfm.getId()?.id ?? "?") \(avail) parent=\(parentIdx) interpOrigin=(\(ia?.originX ?? -1),\(ia?.originY ?? -1)) transOrigin=(\(ta?.originX ?? -1),\(ta?.originY ?? -1)) rot=\(ta?.rotationDeg ?? ia?.rotationDeg ?? 0) scale=\(dctx.getTotalScale())")
                } else if dfm.getType() == Deformer.TYPE_WARP, let wctx = dctx as? WarpContext {
                    let warp = dfm as! WarpDeformer
                    let pts = wctx.transformedPoints ?? wctx.interpolatedPoints
                    let p0x = pts?[0] ?? -1; let p0y = pts?[1] ?? -1
                    print("[L2D-DBG]  [\(v)]\(typeStr) \(dfm.getId()?.id ?? "?") \(avail) parent=\(parentIdx) grid=\(warp.row)x\(warp.col) pt0=(\(p0x),\(p0y))")
                }
            }
        }

        // Setup draw data and build draw order linked list
        for o in 0..<drawCount {
            guard let mesh = drawDataList[o] as? Mesh,
                  let dctx = drawContextList[o] as? MeshContext else { continue }
            mesh.setupInterpolateMesh(self, dctx)
            if dctx.isParamOutside() { continue }
            mesh.setupTransformMesh(self, dctx)

            // First-frame diagnostic: dump mesh vertex positions
            if needSetup {
                let mid = mesh.getId()?.id ?? "?"
                let tid = mesh.getTargetId()?.id ?? "NONE"
                let avail = dctx.isAvailable() ? "OK" : "UNAVAIL"
                let ip = dctx.interpolatedPoints
                let tp = dctx.transformedPoints
                let ip0 = ip != nil && ip!.count >= 2 ? "(\(ip![0]),\(ip![1]))" : "nil"
                let tp0 = tp != nil && tp!.count >= 2 ? "(\(tp![0]),\(tp![1]))" : "nil"
                print("[L2D-DBG]  Mesh[\(o)] \(mid) -> \(tid) \(avail) dfmIdx=\(dctx.tmpDeformerIndex) interp0=\(ip0) trans0=\(tp0)")
            }

            let orderIdx = IDrawData.getDrawOrder(dctx) - minOrder
            let prev = orderList_lastDrawIndex![orderIdx]
            if prev == ModelContext.NOT_USED_ORDER {
                orderList_firstDrawIndex![orderIdx] = Int16(o)
            } else {
                nextList_drawIndex![Int(prev)] = Int16(o)
            }
            orderList_lastDrawIndex![orderIdx] = Int16(o)
        }

        // Clear update flags
        for i in stride(from: updatedParamFlags.count - 1, through: 0, by: -1) {
            updatedParamFlags[i] = ModelContext.DEFAULT_PARAM_UPDATE_FLAG
        }

        needSetup = false
    }

    // MARK: - Draw

    func preDraw(_ dp: DrawParamMetal) {
        if let cm = clipManager {
            dp.setupDraw()
            cm.setupClip(self, dp)
        }
    }

    private var drawFrameCounter: Int = 0

    func draw(_ dp: DrawParamMetal) {
        guard let firstList = orderList_firstDrawIndex else {
            print("call update() before draw()")
            return
        }
        let isFirstFrame = drawFrameCounter == 0
        drawFrameCounter += 1

        dp.setupDraw()
        var drawSeq = 0
        if isFirstFrame {
            print("[L2D-DRAW-ORDER] === FIRST FRAME DRAW ORDER (back to front) ===")
        }
        for k in 0..<firstList.count {
            var idx = Int(firstList[k])
            if idx == Int(ModelContext.NOT_USED_ORDER) { continue }

            while true {
                guard let mesh = drawDataList[idx] as? Mesh,
                      let dctx = drawContextList[idx] as? MeshContext else { break }

                if dctx.isAvailable() {
                    let partsIdx = dctx.partsIndex
                    let pctx = partsContextList[partsIdx]
                    dctx.partsOpacity = pctx?.getPartsOpacity() ?? 0

                    if isFirstFrame {
                        let meshId = mesh.getId()?.id ?? "?"
                        let partsId = partsDataList[partsIdx]?.getId()?.id ?? "?"
                        let interpOp = IDrawData.getOpacity(dctx)
                        let baseOp = dctx.baseOpacity
                        let partsOp = dctx.partsOpacity
                        let finalOp = interpOp * partsOp * baseOp
                        let texNo = mesh.getTextureNo()
                        let pts = dctx.getTransformedPoints()
                        let p0 = pts != nil && pts!.count >= 2 ? String(format: "(%.1f,%.1f)", pts![0], pts![1]) : "nil"
                        let drawOrder = dctx.interpolatedDrawOrder
                        let nPts = mesh.getNumPoints()
                        let comp = mesh.colorCompositionType
                        let compStr = comp == 0 ? "N" : comp == 1 ? "S" : "M"
                        let targetId = mesh.getTargetId()?.id ?? "NONE"
                        print("[L2D-DRAW-ORDER] #\(drawSeq) bucket=\(k) idx=\(idx) order=\(drawOrder) \"\(meshId)\" parts=\"\(partsId)\" tex=\(texNo) \(compStr) pts=\(nPts) p0=\(p0) target=\(targetId) opacity=\(String(format: "%.3f", finalOp))(interp=\(String(format: "%.2f", interpOp))*parts=\(String(format: "%.2f", partsOp))*base=\(String(format: "%.2f", baseOp)))")
                    }

                    mesh.draw(dp, self, dctx)
                    drawSeq += 1
                } else if isFirstFrame {
                    let meshId = mesh.getId()?.id ?? "?"
                    let partsId = partsDataList[dctx.partsIndex]?.getId()?.id ?? "?"
                    let outside = dctx.isParamOutside()
                    print("[L2D-DRAW-ORDER] #-- SKIP idx=\(idx) \"\(meshId)\" parts=\"\(partsId)\" avail=\(dctx.available) outside=\(outside)")
                }

                let next = Int(nextList_drawIndex![idx])
                if next <= idx || next == Int(ModelContext.NO_NEXT) { break }
                idx = next
            }
        }
        if isFirstFrame {
            print("[L2D-DRAW-ORDER] === END: \(drawSeq) meshes drawn ===")
        }
    }
}
