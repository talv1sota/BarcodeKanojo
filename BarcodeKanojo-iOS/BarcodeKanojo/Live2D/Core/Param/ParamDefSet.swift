// ParamDefSet.swift — Set of parameter definitions
// Ported from live2d-v2/live2d/core/param/param_def_set.py

import Foundation

final class ParamDefSet: Live2DSerializable {
    var paramDefList: [ParamDefFloat]?

    func read(_ br: BinaryReader) {
        if let rawArray = br.readObject() as? [Any?] {
            paramDefList = rawArray.compactMap { $0 as? ParamDefFloat }
        }
    }

    func getParamDefFloatList() -> [ParamDefFloat]? {
        return paramDefList
    }
}
