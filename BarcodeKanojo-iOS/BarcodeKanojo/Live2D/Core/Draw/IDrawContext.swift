// IDrawContext.swift — Base context for drawable data
// Ported from live2d-v2/live2d/core/draw/idraw_context.py

import Foundation

class IDrawContext {
    var interpolatedDrawOrder: Int = 500
    var paramOutside: [Bool] = [false]
    var partsOpacity: Float = 0
    var available: Bool = true
    var baseOpacity: Float = 1.0
    var clipBufPre_clipContext: ClipContext?
    var drawData: IDrawData
    var partsIndex: Int = -1
    var interpolatedOpacity: Float = 1.0

    init(_ dd: IDrawData) {
        self.drawData = dd
    }

    func isParamOutside() -> Bool { paramOutside[0] }

    func isAvailable() -> Bool { available && !paramOutside[0] }

    func getDrawData() -> IDrawData { drawData }
}
