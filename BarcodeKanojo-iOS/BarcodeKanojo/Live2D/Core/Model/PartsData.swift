// PartsData.swift — A named part containing deformers and draw data
// Ported from live2d-v2/live2d/core/model/part.py

import Foundation

final class PartsData: Live2DSerializable {
    var visible: Bool = true
    var locked: Bool = false
    var id: Live2DId?
    var deformerList: [Any?]?
    var drawDataList: [Any?]?

    func initDirect() {
        deformerList = []
        drawDataList = []
    }

    func read(_ br: BinaryReader) {
        locked = br.readBit()
        visible = br.readBit()
        id = br.readObject() as? Live2DId
        deformerList = br.readObject() as? [Any?]
        drawDataList = br.readObject() as? [Any?]
    }

    func initContext() -> PartsDataContext {
        let ctx = PartsDataContext(self)
        ctx.setPartsOpacity(isVisible() ? 1 : 0)
        return ctx
    }

    func setDeformerList(_ list: [Any?]?) {
        deformerList = list
    }

    func setDrawDataList(_ list: [Any?]?) {
        drawDataList = list
    }

    func isVisible() -> Bool { visible }
    func isLocked() -> Bool { locked }
    func setVisible(_ v: Bool) { visible = v }
    func setLocked(_ v: Bool) { locked = v }

    func getDeformer() -> [Any?] { deformerList ?? [] }
    func getDrawData() -> [Any?] { drawDataList ?? [] }
    func getId() -> Live2DId? { id }
    func setId(_ newId: Live2DId) { id = newId }
}
