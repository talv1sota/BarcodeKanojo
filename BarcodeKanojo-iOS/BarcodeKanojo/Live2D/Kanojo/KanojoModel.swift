// KanojoModel.swift — High-level kanojo character model manager
// Ported from kanojo_app-master/.../live2d/KanojoModel.java
// Loads .moc base model, assembles .bkparts parts, loads and tints textures.

import Foundation
import UIKit
import Metal
import MetalKit

final class KanojoModel {
    private(set) var live2dModel: Live2DModelMetal?
    private(set) var setting: KanojoSetting
    private var avatarDataDir: URL
    private var isLoaded = false
    private var animation: KanojoAnimation?

    init(avatarDataDir: URL) {
        self.avatarDataDir = avatarDataDir
        self.setting = KanojoSetting()
    }

    // MARK: - Configure from kanojo data

    func configure(from kanojo: [String: Any]) {
        // Map kanojo fields to parts
        let partsMapping: [(String, String)] = [
            ("body_type", KanojoSetting.PARTS_01_BODY),
            ("face_type", KanojoSetting.PARTS_01_FACE),
            ("eye_type", KanojoSetting.PARTS_01_EYE),
            ("brow_type", KanojoSetting.PARTS_01_BROW),
            ("mouth_type", KanojoSetting.PARTS_01_MOUTH),
            ("nose_type", KanojoSetting.PARTS_01_NOSE),
            ("ear_type", KanojoSetting.PARTS_01_EAR),
            ("fringe_type", KanojoSetting.PARTS_01_FRINGE),
            ("hair_type", KanojoSetting.PARTS_01_HAIR),
            ("clothes_type", KanojoSetting.PARTS_01_CLOTHES),
            ("glasses_type", KanojoSetting.PARTS_01_GLASSES),
            ("accessory_type", KanojoSetting.PARTS_01_ACCESSORY),
        ]
        for (key, partsId) in partsMapping {
            if let val = kanojo[key] as? Int {
                setting.setParts(partsId, val)
            }
        }

        // Colors
        if let v = kanojo["skin_color"] as? Int { setting.setColor(KanojoSetting.COLOR_01_SKIN, v) }
        if let v = kanojo["hair_color"] as? Int { setting.setColor(KanojoSetting.COLOR_01_HAIR, v) }
        if let v = kanojo["eye_color"] as? Int { setting.setColor(KanojoSetting.COLOR_01_EYE, v) }
        if let v = kanojo["clothes_color"] as? Int { setting.setColor(KanojoSetting.COLOR_01_CLOTHES_A, v) }

        // Features (server returns these as Float/Double values like 0.17, -0.7, etc.)
        if let v = kanojo["eye_position"] as? Double { setting.setFeature(KanojoSetting.FEATURE_01_EYE_POS, Float(v)) }
        else if let v = kanojo["eye_position"] as? Float { setting.setFeature(KanojoSetting.FEATURE_01_EYE_POS, v) }
        if let v = kanojo["brow_position"] as? Double { setting.setFeature(KanojoSetting.FEATURE_01_BROW_POS, Float(v)) }
        else if let v = kanojo["brow_position"] as? Float { setting.setFeature(KanojoSetting.FEATURE_01_BROW_POS, v) }
        if let v = kanojo["mouth_position"] as? Double { setting.setFeature(KanojoSetting.FEATURE_01_MOUTH_POS, Float(v)) }
        else if let v = kanojo["mouth_position"] as? Float { setting.setFeature(KanojoSetting.FEATURE_01_MOUTH_POS, v) }

        // State
        if let v = kanojo["love_gauge"] as? Int { setting.loveGauge = Double(v) }
        else if let v = kanojo["love_gauge"] as? Double { setting.loveGauge = v }
        if let v = kanojo["relation_status"] as? Int { setting.kanojoState = v }
    }

    // MARK: - Load model

    func load(device: MTLDevice) {
        print("[KanojoModel] Loading from \(avatarDataDir.path)")
        // Dump configuration for debugging
        print("[KanojoModel] Config: body=\(setting.partsSetList.first { $0.partsID == KanojoSetting.PARTS_01_BODY }?.partsItemNo ?? -1) face=\(setting.partsSetList.first { $0.partsID == KanojoSetting.PARTS_01_FACE }?.partsItemNo ?? -1) eye=\(setting.partsSetList.first { $0.partsID == KanojoSetting.PARTS_01_EYE }?.partsItemNo ?? -1) brow=\(setting.partsSetList.first { $0.partsID == KanojoSetting.PARTS_01_BROW }?.partsItemNo ?? -1) mouth=\(setting.partsSetList.first { $0.partsID == KanojoSetting.PARTS_01_MOUTH }?.partsItemNo ?? -1)")
        print("[KanojoModel] Config: hair=\(setting.partsSetList.first { $0.partsID == KanojoSetting.PARTS_01_HAIR }?.partsItemNo ?? -1) fringe=\(setting.partsSetList.first { $0.partsID == KanojoSetting.PARTS_01_FRINGE }?.partsItemNo ?? -1) clothes=\(setting.partsSetList.first { $0.partsID == KanojoSetting.PARTS_01_CLOTHES }?.partsItemNo ?? -1)")
        print("[KanojoModel] Features: eyePos=\(setting.getFeature(KanojoSetting.FEATURE_01_EYE_POS)) browPos=\(setting.getFeature(KanojoSetting.FEATURE_01_BROW_POS)) mouthPos=\(setting.getFeature(KanojoSetting.FEATURE_01_MOUTH_POS))")

        // 1. Load base .moc model
        let mocURL = avatarDataDir.appendingPathComponent("kanojoBaseModel.moc")
        guard let mocData = try? Data(contentsOf: mocURL) else {
            print("[KanojoModel] Failed to load .moc file from \(mocURL.path)")
            return
        }
        print("[KanojoModel] Loaded .moc (\(mocData.count) bytes)")

        let model = Live2DModelMetal.loadModel(from: mocData)
        model.setupMetal(device: device)
        self.live2dModel = model
        print("[KanojoModel] Base model loaded: \(model.getCanvasWidth())x\(model.getCanvasHeight()), parts=\(model.getModelContext().partsDataList.count)")

        // 2. Load .bkparts for each part and replace parts data
        // Matches Android KanojoModel.setupModel_process1:
        //   - Items with itemNo <= 0 are forced to 1
        //   - If the requested item's .bkparts doesn't exist, falls back to item 001
        var loadedParts = 0
        var fallbackParts: [String] = []
        var missingParts: [String] = []
        for ps in setting.partsSetList {
            var effectiveItemNo = ps.partsItemNo
            if effectiveItemNo < 1 { effectiveItemNo = 1 }

            let itemStr = String(format: "%03d", effectiveItemNo)
            var partsFolder = avatarDataDir
                .appendingPathComponent(ps.partsID)
                .appendingPathComponent("\(ps.partsID)_\(itemStr)")
            var bkpartsFile = partsFolder.appendingPathComponent("data.bkparts")
            var bkpartsData = try? Data(contentsOf: bkpartsFile)

            // Fallback to item 001 if requested item doesn't exist (matching Android)
            if bkpartsData == nil && effectiveItemNo != 1 {
                let fallbackFolder = avatarDataDir
                    .appendingPathComponent(ps.partsID)
                    .appendingPathComponent("\(ps.partsID)_001")
                let fallbackFile = fallbackFolder.appendingPathComponent("data.bkparts")
                bkpartsData = try? Data(contentsOf: fallbackFile)
                if bkpartsData != nil {
                    partsFolder = fallbackFolder
                    fallbackParts.append("\(ps.partsID)_\(itemStr)→001")
                    print("[KanojoModel] ⚠ Fallback: \(ps.partsID)_\(itemStr) → \(ps.partsID)_001")
                }
            }

            guard let data = bkpartsData else {
                missingParts.append("\(ps.partsID)_\(itemStr)")
                print("[KanojoModel] ⚠ MISSING .bkparts for \(ps.partsID)_\(itemStr) (no fallback)")
                continue
            }

            print("[KanojoModel] Loading \(ps.partsID)_\(itemStr) (\(data.count) bytes)")
            loadBkparts(data, partsID: ps.partsID, partsFolder: partsFolder, device: device)
            loadedParts += 1
        }
        print("[KanojoModel] Loaded \(loadedParts) parts, fallbacks=\(fallbackParts), missing=\(missingParts)")

        // 3. Re-initialize model context after replacing parts
        model.initModel()
        print("[KanojoModel] Model re-initialized after parts replacement")

        // 4. Set feature position params on the model (matches Android lines 100-101)
        // These params control deformer positions for eyes/mouth and must be set
        // AFTER init() but BEFORE animation starts.
        model.setParamFloat("PARAM_EYE_POS", setting.getFeature(KanojoSetting.FEATURE_01_EYE_POS))
        model.setParamFloat("PARAM_MOUTH_POS", setting.getFeature(KanojoSetting.FEATURE_01_MOUTH_POS))

        // 5. Setup animation controller
        let anim = KanojoAnimation()
        anim.cacheParamIndices(model)
        anim.browPositionOffset = setting.getFeature(KanojoSetting.FEATURE_01_BROW_POS)
        // Load kurakura (dizzy) motions for shake response
        anim.loadMotions(avatarDataDir: avatarDataDir)
        // Initialize all default params (matches Android KanojoAnimation.initParam)
        anim.initParam(model)
        self.animation = anim

        isLoaded = true
        print("[KanojoModel] ✓ Model fully loaded and ready")
    }

    private func loadBkparts(_ data: Data, partsID: String, partsFolder: URL, device: MTLDevice) {
        guard let model = live2dModel else { return }

        let br = BinaryReader(data)

        // Read & verify header: 'b' 'k' 'p' <version>
        let bByte = br.readByte()
        let kByte = br.readByte()
        let pByte = br.readByte()
        let version = Int(br.readByte())
        br.setFormatVersion(version)

        guard bByte == 0x62 && kByte == 0x6B && pByte == 0x70 else {
            print("[KanojoModel] Invalid .bkparts header for \(partsID)")
            return
        }

        let partsVersion = br.readInt32()
        _ = partsVersion

        guard let avatar = br.readObject() as? Avatar else {
            print("[KanojoModel] Failed to read Avatar from .bkparts for \(partsID)")
            return
        }

        let clippedImageCount = Int(br.readInt32())

        let eofMarker = br.readInt32()
        if eofMarker != Int32(bitPattern: 0x88888888) {
            print("[KanojoModel] EOF check failed for \(partsID): 0x\(String(UInt32(bitPattern: eofMarker), radix: 16))")
        }
        print("[KanojoModel]   Avatar loaded for \(partsID), textures=\(clippedImageCount)")

        // 1. Preload texture images from tex512/ folder to get dimensions for UV scaling.
        //    Matches Android flow: textures loaded first, then dimensions used for UV scale.
        let texFolder = partsFolder.appendingPathComponent("tex512")
        let textureImages = preloadTextureImages(from: texFolder)
        print("[KanojoModel]   Preloaded \(textureImages.count) texture images for \(partsID)")

        // 2. Replace parts data and remap texture indices.
        // This matches Android's KanojoPartsItem.bindTextures_process1():
        //   a. Replace draw data on the target PartsData
        //   b. Collect per-texture bkOptionColor from mesh draw data
        //   c. Scale UVs by 512/textureWidth if texture != 512x512
        //   d. Remap each mesh's textureNo from local (0,1,2...) to global namespace
        var textureColorMap: [Int: Int32] = [:]  // localTexIdx → bkOptionColor
        let partsIdx = model.getPartsDataIndex(partsID)
        if partsIdx >= 0, let parts = model.getModelContext().partsDataList[partsIdx] {
            avatar.replacePartsData(parts)

            // After replacement, parts.drawDataList has the avatar's draw data.
            // Iterate meshes to remap textureNo, scale UVs, and collect color info.
            for dd in parts.getDrawData() {
                if let mesh = dd as? Mesh {
                    let localTexNo = mesh.getTextureNo()
                    if localTexNo >= 0 {
                        // Collect per-texture bkOptionColor (matches Android switch on colorType)
                        if mesh.bkOptionColor != 0 {
                            textureColorMap[localTexNo] = mesh.bkOptionColor
                        }

                        // UV scaling: scale UVs if texture is not 512x512
                        // Matches Android: scalex = 512.0 / tex.getTextureWidth()
                        if localTexNo < textureImages.count, let cgImg = textureImages[localTexNo] {
                            let texW = cgImg.width
                            let texH = cgImg.height
                            if texW != 512 || texH != 512, var uvsArr = mesh.uvs {
                                let scaleX = 512.0 / Float(texW)
                                let scaleY = 512.0 / Float(texH)
                                for pti in 0..<mesh.pointCount {
                                    let oi = pti << 1
                                    uvsArr[oi] *= scaleX
                                    uvsArr[oi + 1] *= scaleY
                                }
                                mesh.uvs = uvsArr
                                print("[KanojoModel]   UV scaled for \(partsID) tex \(localTexNo): \(texW)x\(texH)")
                            }
                        }

                        // Remap local → global texture index
                        let globalTexNo = computeTextureIndex(partsID: partsID, localIndex: localTexNo)
                        mesh.setTextureNo(globalTexNo)
                    }
                }
            }
            print("[KanojoModel]   Remapped \(parts.getDrawData().compactMap { $0 as? Mesh }.count) meshes for \(partsID), colorMap=\(textureColorMap)")
        } else {
            print("[KanojoModel]   Warning: PartsData '\(partsID)' not found in model (index=\(partsIdx))")
        }

        // Workaround: For BODY parts, propagate SKIN color to ALL textures.
        // Some body variants (e.g. BODY_002) have meshes on textures 4-5 that lack
        // bkOptionColor=2 in the .bkparts data, causing untinted arms when skin_color != default.
        // Since all body textures should logically share the same skin tone, we fill in the gaps.
        if partsID == KanojoSetting.PARTS_01_BODY {
            let hasSkinColor = textureColorMap.values.contains(2)
            if hasSkinColor {
                let totalTex = textureImages.count
                for i in 0..<totalTex {
                    if textureColorMap[i] == nil {
                        textureColorMap[i] = 2  // SKIN
                        print("[KanojoModel]   ⚠ Body tex \(i) missing bkOptionColor, propagating SKIN color")
                    }
                }
            }
        }

        // 3. Upload textures to Metal, applying color tinting per bkOptionColor
        for (idx, cgImageOpt) in textureImages.enumerated() {
            guard var cgImage = cgImageOpt else { continue }

            // Apply color tinting using per-mesh bkOptionColor
            // (matches Android's KanojoPartsItem.bindTextures_process1 switch statement)
            var colorDesc = "none"
            if let colorType = textureColorMap[idx], colorType != 0 {
                let colorID = colorIDForBkOptionColor(colorType)
                if let colorID = colorID, let cc = setting.getColorConvert(colorID, colorType) {
                    cgImage = ColorConvertUtil.convertColor(cgImage, cc)
                    colorDesc = "\(colorID)(type=\(colorType),h=\(cc.hue),s=\(cc.sat),l=\(cc.lum))"
                } else {
                    colorDesc = "type=\(colorType) no-convert"
                }
            }

            // Load texture at global index matching the remapped mesh textureNo
            let texIndex = computeTextureIndex(partsID: partsID, localIndex: idx)
            model.loadTexture(texIndex, from: UIImage(cgImage: cgImage))
            print("[KanojoModel]   Loaded texture idx \(idx) → slot \(texIndex) (\(cgImage.width)x\(cgImage.height)) color=\(colorDesc)")
        }
    }

    /// Preload texture PNG images from a tex512/ folder.
    /// Returns CGImage? array sorted by filename (tex_0.png, tex_1.png, ...).
    private func preloadTextureImages(from folder: URL) -> [CGImage?] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
            return []
        }
        let pngFiles = files.filter { $0.pathExtension == "png" }
        // Sort numerically by texture index (tex_0, tex_1, ..., tex_10, tex_11, ...)
        // NOT lexicographically, which would put tex_10 before tex_2!
        let texFiles = pngFiles.sorted { (a: URL, b: URL) -> Bool in
            let aName = a.deletingPathExtension().lastPathComponent
            let bName = b.deletingPathExtension().lastPathComponent
            let aNum = Int(aName.replacingOccurrences(of: "tex_", with: "")) ?? 0
            let bNum = Int(bName.replacingOccurrences(of: "tex_", with: "")) ?? 0
            return aNum < bNum
        }

        return texFiles.map { url in
            guard let image = UIImage(contentsOfFile: url.path) else {
                print("[KanojoModel]   Failed to load texture image: \(url.lastPathComponent)")
                return nil
            }
            return image.cgImage
        }
    }

    /// Map bkOptionColor value to the color setting ID.
    /// Matches Android KanojoPartsItem.bindTextures_process1 switch (colorType).
    private func colorIDForBkOptionColor(_ colorType: Int32) -> String? {
        switch colorType {
        case 1:     return KanojoSetting.COLOR_01_HAIR
        case 2:     return KanojoSetting.COLOR_01_SKIN
        case 3:     return KanojoSetting.COLOR_01_EYE
        case 4, 5, 6, 7, 9: return KanojoSetting.COLOR_01_CLOTHES_A
        default:    return nil
        }
    }

    private func computeTextureIndex(partsID: String, localIndex: Int) -> Int {
        // Map parts to unique texture namespace to avoid collisions
        // Each part gets a range of 16 texture slots
        let partsOrder = [
            KanojoSetting.PARTS_01_BODY, KanojoSetting.PARTS_01_FACE,
            KanojoSetting.PARTS_01_EYE, KanojoSetting.PARTS_01_BROW,
            KanojoSetting.PARTS_01_MOUTH, KanojoSetting.PARTS_01_NOSE,
            KanojoSetting.PARTS_01_EAR, KanojoSetting.PARTS_01_FRINGE,
            KanojoSetting.PARTS_01_HAIR, KanojoSetting.PARTS_01_CLOTHES,
            KanojoSetting.PARTS_01_GLASSES, KanojoSetting.PARTS_01_ACCESSORY,
            KanojoSetting.PARTS_01_SPOT, KanojoSetting.PARTS_01_OPTION,
        ]
        let base = (partsOrder.firstIndex(of: partsID) ?? 0) * 16
        return base + localIndex
    }

    // MARK: - Accelerometer & Shake

    /// Set device acceleration values for tilt response.
    /// Matches Android KanojoModel.setAccelarationValue().
    func setAcceleration(_ x: Float, _ y: Float, _ z: Float) {
        animation?.accelX = x
        animation?.accelY = y
        animation?.accelZ = z
    }

    /// Trigger dizzy (kurakura) animation on shake.
    func triggerShake() {
        animation?.shakeEvent()
    }

    /// Trigger single-tap touch reaction animation.
    func triggerTouch() {
        animation?.touchEvent()
    }

    /// Trigger double-tap head pat reaction animation.
    func triggerDoubleTap() {
        animation?.doubleTapEvent()
    }

    /// Trigger kiss reaction animation (face touch).
    func triggerKiss() {
        animation?.kissEvent()
    }

    /// Trigger breast touch reaction animation (chest touch).
    func triggerBreastTouch() {
        animation?.breastTouchEvent()
    }

    /// Trigger appropriate reaction for a detected touch region.
    func triggerRegionTouch(_ region: TouchRegion) {
        switch region {
        case .head: triggerDoubleTap()
        case .face: triggerKiss()
        case .chest: triggerBreastTouch()
        case .body: triggerTouch()
        }
    }

    // MARK: - Update & Draw

    func update(deltaTime: Float) {
        guard let model = live2dModel, isLoaded else { return }

        // Run animation (eye blink, breathing, idle sway) before model update
        let deltaMsDouble = Double(deltaTime) * 1000.0
        animation?.update(model, deltaMs: deltaMsDouble)

        // Apply brow position offset AFTER animation, matching Android
        // KanojoModel.drawModel_core() lines 173-179
        animation?.applyBrowOffset(model)

        // Apply accelerometer tilt AFTER animation, matching Android
        // KanojoModel.drawModel_core() lines 164-170.
        // Skip during kurakura motion to prevent vibration — the motion
        // file handles the sway and the accelerometer would fight it.
        if animation?.isMotionPlaying != true {
            animation?.applyAcceleration(model)
        }

        model.update()
    }

    func draw(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor,
              viewWidth: Float, viewHeight: Float) {
        guard let model = live2dModel, isLoaded else { return }
        model.setProjection(viewWidth, viewHeight)
        model.draw(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
    }
}
