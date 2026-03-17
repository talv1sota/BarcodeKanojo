// ParamPivots.swift — Parameter pivot point data
// Ported from live2d-v2/live2d/core/param/param_pivots.py

import Foundation

final class ParamPivots: Live2DSerializable {
    static let PARAM_INDEX_NOT_INIT: Int = -2

    var pivotCount: Int = 0
    var paramId: Live2DId?
    var pivotValues: [Float]?
    var paramIndex: Int = PARAM_INDEX_NOT_INIT
    var initVersion: Int = -1
    var tmpPivotIndex: Int = 0
    var tmpT: Float = 0

    func read(_ br: BinaryReader) {
        paramId = br.readObject() as? Live2DId
        pivotCount = Int(br.readInt32())
        pivotValues = br.readObject() as? [Float]
    }

    func getParamIndex(_ initVer: Int) -> Int {
        if self.initVersion != initVer {
            paramIndex = ParamPivots.PARAM_INDEX_NOT_INIT
        }
        return paramIndex
    }

    func setParamIndex(_ index: Int, _ initVer: Int) {
        paramIndex = index
        initVersion = initVer
    }

    func getParamID() -> Live2DId? { paramId }
    func getPivotCount() -> Int { pivotCount }
    func getPivotValues() -> [Float]? { pivotValues }
    func getTmpPivotIndex() -> Int { tmpPivotIndex }
    func setTmpPivotIndex(_ index: Int) { tmpPivotIndex = index }
    func getTmpT() -> Float { tmpT }
    func setTmpT(_ value: Float) { tmpT = value }
}
