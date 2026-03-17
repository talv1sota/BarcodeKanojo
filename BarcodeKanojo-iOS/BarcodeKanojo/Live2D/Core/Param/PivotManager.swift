// PivotManager.swift — Manages parameter pivot tables for interpolation
// Ported from live2d-v2/live2d/core/param/pivot_manager.py

import Foundation

final class PivotManager: Live2DSerializable {
    var paramPivotTable: [ParamPivots]?

    func read(_ br: BinaryReader) {
        if let rawArray = br.readObject() as? [Any?] {
            paramPivotTable = rawArray.compactMap { $0 as? ParamPivots }
        }
    }

    func checkParamUpdated(_ mc: ModelContext) -> Bool {
        guard let table = paramPivotTable else { return false }

        if mc.requireSetup() {
            return true
        }

        let initVer = mc.getInitVersion()
        for i in stride(from: table.count - 1, through: 0, by: -1) {
            var idx = table[i].getParamIndex(initVer)
            if idx == ParamPivots.PARAM_INDEX_NOT_INIT {
                if let pid = table[i].getParamID() {
                    idx = mc.getParamIndex(pid)
                }
            }
            if mc.isParamUpdated(idx) {
                return true
            }
        }
        return false
    }

    func calcPivotValues(_ mdc: ModelContext, _ ret: inout [Bool]) -> Int {
        guard let table = paramPivotTable else { return 0 }
        let count = table.count
        let initVer = mdc.getInitVersion()
        var numInterp = 0

        for k in 0..<count {
            let pp = table[k]
            var idx = pp.getParamIndex(initVer)
            if idx == ParamPivots.PARAM_INDEX_NOT_INIT {
                if let pid = pp.getParamID() {
                    idx = mdc.getParamIndex(pid)
                    pp.setParamIndex(idx, initVer)
                }
            }

            let paramVal = idx < 0 ? Float(0) : mdc.getParamFloat(idx)
            let pivotCount = pp.getPivotCount()
            guard let pivotVals = pp.getPivotValues() else { continue }

            var pivotIdx: Int = -1
            var t: Float = 0

            if pivotCount < 1 {
                // skip
            } else if pivotCount == 1 {
                let s = pivotVals[0]
                if s - Live2DDEF.GOSA < paramVal && paramVal < s + Live2DDEF.GOSA {
                    pivotIdx = 0
                    t = 0
                } else {
                    pivotIdx = 0
                    ret[0] = true
                }
            } else {
                var s = pivotVals[0]
                if paramVal < s - Live2DDEF.GOSA {
                    pivotIdx = 0
                    ret[0] = true
                } else if paramVal < s + Live2DDEF.GOSA {
                    pivotIdx = 0
                } else {
                    var found = false
                    for o in 1..<pivotCount {
                        let r = pivotVals[o]
                        if paramVal < r + Live2DDEF.GOSA {
                            if r - Live2DDEF.GOSA < paramVal {
                                pivotIdx = o
                            } else {
                                pivotIdx = o - 1
                                t = (paramVal - s) / (r - s)
                                numInterp += 1
                            }
                            found = true
                            break
                        }
                        s = r
                    }
                    if !found {
                        pivotIdx = pivotCount - 1
                        t = 0
                        ret[0] = true
                    }
                }
            }

            pp.setTmpPivotIndex(pivotIdx)
            pp.setTmpT(t)
        }

        return numInterp
    }

    func calcPivotIndices(_ indices: inout [Int16], _ tArray: inout [Float], _ numInterp: Int) {
        guard let table = paramPivotTable else { return }
        let totalCombinations = 1 << numInterp
        if totalCombinations + 1 > Live2DDEF.PIVOT_TABLE_SIZE {
            print("err 23245")
        }

        let paramCount = table.count
        var stride = 1
        var interpBit = 1
        var tIdx = 0

        for q in 0..<totalCombinations {
            indices[q] = 0
        }

        for l in 0..<paramCount {
            let pp = table[l]
            if pp.getTmpT() == 0 {
                let ofs = Int16(pp.getTmpPivotIndex() * stride)
                if ofs < 0 {
                    fatalError("err 23246")
                }
                for q in 0..<totalCombinations {
                    indices[q] += ofs
                }
            } else {
                let ofs = Int16(stride * pp.getTmpPivotIndex())
                let ofsNext = Int16(stride * (pp.getTmpPivotIndex() + 1))
                for q in 0..<totalCombinations {
                    indices[q] += (Int(q / interpBit) % 2 == 0) ? ofs : ofsNext
                }
                tArray[tIdx] = pp.getTmpT()
                tIdx += 1
                interpBit *= 2
            }
            stride *= pp.getPivotCount()
        }

        indices[totalCombinations] = Int16(bitPattern: 0xFFFF) // 65535
        tArray[tIdx] = -1
    }

    func getParamCount() -> Int {
        return paramPivotTable?.count ?? 0
    }
}
