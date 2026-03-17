// ALive2DModel.swift — Abstract base class for Live2D models
// Ported from live2d-v2/live2d/core/alive2d_model.py

import Foundation

class ALive2DModel {
    var modelImpl: ModelImpl?
    var modelContext: ModelContext!

    init() {
        modelContext = ModelContext(self)
    }

    func setModelImpl(_ moc: ModelImpl) {
        modelImpl = moc
    }

    func getModelImpl() -> ModelImpl {
        if modelImpl == nil {
            modelImpl = ModelImpl()
            modelImpl!.initDirect()
        }
        return modelImpl!
    }

    func getCanvasWidth() -> Int {
        return modelImpl?.getCanvasWidth() ?? 0
    }

    func getCanvasHeight() -> Int {
        return modelImpl?.getCanvasHeight() ?? 0
    }

    // MARK: - Parameter access

    func getParamFloat(_ x: Any) -> Float {
        var idx: Int
        if let intVal = x as? Int {
            idx = intVal
        } else if let strVal = x as? String {
            idx = modelContext.getParamIndex(Live2DId.getID(strVal))
        } else {
            return 0
        }
        return modelContext.getParamFloat(idx)
    }

    func setParamFloat(_ x: Any, _ value: Float, weight: Float = 1.0) {
        var idx: Int
        if let intVal = x as? Int {
            idx = intVal
        } else if let strVal = x as? String {
            idx = modelContext.getParamIndex(Live2DId.getID(strVal))
        } else { return }

        let v = value
        let current = modelContext.getParamFloat(idx)
        modelContext.setParamFloat(idx, current * (1 - weight) + v * weight)
    }

    func addToParamFloat(_ x: Any, _ value: Float, weight: Float = 1.0) {
        var idx: Int
        if let intVal = x as? Int {
            idx = intVal
        } else if let strVal = x as? String {
            idx = modelContext.getParamIndex(Live2DId.getID(strVal))
        } else { return }

        modelContext.setParamFloat(idx, modelContext.getParamFloat(idx) + value * weight)
    }

    func multParamFloat(_ x: Any, _ value: Float, weight: Float = 1.0) {
        var idx: Int
        if let intVal = x as? Int {
            idx = intVal
        } else if let strVal = x as? String {
            idx = modelContext.getParamIndex(Live2DId.getID(strVal))
        } else { return }

        modelContext.setParamFloat(idx, modelContext.getParamFloat(idx) * (1 + (value - 1) * weight))
    }

    func getParamIndex(_ idStr: String) -> Int {
        return modelContext.getParamIndex(Live2DId.getID(idStr))
    }

    // MARK: - State management

    func loadParam() { modelContext.loadParam() }
    func saveParam() { modelContext.saveParam() }

    func initModel() {
        modelContext.initModel()
    }

    func update() {
        modelContext.update()
    }

    func draw() {
        fatalError("subclass must override")
    }

    func getModelContext() -> ModelContext { modelContext }

    // MARK: - Parts

    func setPartsOpacity(_ x: Any, _ opacity: Float) {
        var idx: Int
        if let intVal = x as? Int {
            idx = intVal
        } else if let strVal = x as? String {
            idx = modelContext.getPartsDataIndex(Live2DId.getID(strVal))
        } else { return }
        modelContext.setPartsOpacity(idx, opacity)
    }

    func getPartsDataIndex(_ x: Any) -> Int {
        if let idObj = x as? Live2DId {
            return modelContext.getPartsDataIndex(idObj)
        } else if let strVal = x as? String {
            return modelContext.getPartsDataIndex(Live2DId.getID(strVal))
        }
        return -1
    }

    func getPartsOpacity(_ x: Any) -> Float {
        var idx: Int
        if let intVal = x as? Int {
            idx = intVal
        } else if let strVal = x as? String {
            idx = modelContext.getPartsDataIndex(Live2DId.getID(strVal))
        } else { return 0 }

        if idx < 0 { return 0 }
        return modelContext.getPartsOpacity(idx)
    }

    // MARK: - Draw data access

    func getDrawParam() -> DrawParamMetal? {
        fatalError("subclass must override")
    }

    func getDrawDataIndex(_ drawId: String) -> Int {
        return modelContext.getDrawDataIndex(Live2DId.getID(drawId))
    }

    func getTransformedPoints(_ idx: Int) -> [Float]? {
        if let dctx = modelContext.getDrawContext(idx) as? MeshContext {
            return dctx.getTransformedPoints()
        }
        return nil
    }

    func getIndexArray(_ idx: Int) -> [Int16]? {
        if idx < 0 || idx >= modelContext.drawDataList.count { return nil }
        if let mesh = modelContext.drawDataList[idx] as? Mesh,
           mesh.getType() == IDrawData.TYPE_MESH {
            return mesh.getIndexArray()
        }
        return nil
    }

    // MARK: - Load model

    static func loadModel(_ model: ALive2DModel, _ data: Data) {
        let br = BinaryReader(data)
        let magic1 = br.readByte()  // 'm'
        let magic2 = br.readByte()  // 'o'
        let magic3 = br.readByte()  // 'c'

        guard magic1 == 109 && magic2 == 111 && magic3 == 99 else {
            fatalError("Invalid MOC file.")
        }

        let version = Int(br.readByte())
        br.setFormatVersion(version)

        guard version <= Live2DDEF.LIVE2D_FORMAT_VERSION_AVAILABLE else {
            fatalError("Unsupported version \(version)")
        }

        guard let modelImpl = br.readObject() as? ModelImpl else {
            fatalError("Failed to read ModelImpl")
        }

        if version >= Live2DDEF.LIVE2D_FORMAT_VERSION_V2_8_TEX_OPTION {
            let eof1 = br.readUShort()
            let eof2 = br.readUShort()
            if eof1 != -30584 || eof2 != -30584 {
                fatalError("Invalid load EOF")
            }
        }

        model.setModelImpl(modelImpl)
        let mc = model.getModelContext()
        mc.setDrawParam(model.getDrawParam())
        mc.initModel()
    }
}
