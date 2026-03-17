// Avatar.swift — Avatar data from .bkparts files
// Ported from live2d-v2/live2d/core/model/avatar.py
//
// An Avatar contains replacement deformers and draw data for a single
// body part (hair, eyes, etc.) loaded from a .bkparts file.

import Foundation

final class Avatar: Live2DSerializable {
    var id: Live2DId?
    var deformerList: [Any?]?
    var drawDataList: [Any?]?

    func read(_ br: BinaryReader) {
        id = br.readObject() as? Live2DId
        drawDataList = br.readObject() as? [Any?]
        deformerList = br.readObject() as? [Any?]
    }

    func getDeformer() -> [Any?]? { deformerList }
    func getDrawDataList() -> [Any?]? { drawDataList }

    /// Replace a PartsData's deformers and draw data with this avatar's data
    func replacePartsData(_ parts: PartsData) {
        parts.setDeformerList(deformerList)
        parts.setDrawDataList(drawDataList)
        deformerList = nil
        drawDataList = nil
    }
}
