// ModelImpl.swift — Top-level model data from .moc file
// Ported from live2d-v2/live2d/core/model/model_impl.py

import Foundation

final class ModelImpl: Live2DSerializable {
    var paramDefSet: ParamDefSet?
    var partsDataList: [Any?]?
    var canvasWidth: Int = 400
    var canvasHeight: Int = 400

    func initDirect() {
        if paramDefSet == nil { paramDefSet = ParamDefSet() }
        if partsDataList == nil { partsDataList = [] }
    }

    func read(_ br: BinaryReader) {
        paramDefSet = br.readObject() as? ParamDefSet
        partsDataList = br.readObject() as? [Any?]
        canvasWidth = Int(br.readInt32())
        canvasHeight = Int(br.readInt32())
    }

    func getCanvasWidth() -> Int { canvasWidth }
    func getCanvasHeight() -> Int { canvasHeight }
    func getPartsDataList() -> [Any?] { partsDataList ?? [] }
    func getParamDefSet() -> ParamDefSet? { paramDefSet }
}
