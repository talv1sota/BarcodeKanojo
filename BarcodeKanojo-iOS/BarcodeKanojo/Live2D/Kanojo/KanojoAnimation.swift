// KanojoAnimation.swift — Animation controller for kanojo Live2D model
// Ported from kanojo_app-master/.../live2d/motion/KanojoAnimation.java
// Handles eye blink, idle breathing, parameter-based animation,
// accelerometer response, and shake-triggered dizzy (kurakura) motions.

import Foundation

final class KanojoAnimation {
    // Eye blink
    private var eyeBlinkInterval: Double = 4000  // ms between blinks
    private var lastBlinkTime: Double = 0
    private var blinkState: BlinkState = .open
    private var blinkTimer: Double = 0
    private let blinkCloseDuration: Double = 80
    private let blinkOpenDuration: Double = 120

    // Breathing
    private var breathPhase: Float = 0

    // Param indices (cached)
    private var paramAngleX: Int = -1
    private var paramAngleY: Int = -1
    private var paramAngleZ: Int = -1
    private var paramEyeLOpen: Int = -1
    private var paramEyeROpen: Int = -1
    private var paramBodyAngleX: Int = -1
    private var paramBreath: Int = -1
    private var paramEyeBallX: Int = -1
    private var paramEyeBallY: Int = -1
    private var paramBrowLY: Int = -1
    private var paramBrowRY: Int = -1
    private var paramSmile: Int = -1
    private var paramTere: Int = -1
    private var paramMouthForm: Int = -1
    private var paramMouthOpenY: Int = -1
    private var paramBodyDir: Int = -1

    // Feature offsets (brow only — eye/mouth are set as model params directly)
    var browPositionOffset: Float = 0

    // Accelerometer input (set externally by DeviceMotionManager)
    var accelX: Float = 0
    var accelY: Float = 0
    var accelZ: Float = 0

    // Motion player for kurakura (dizzy), touch, and other .mtn motions
    private let motionPlayer = MotionPlayer()
    private var kurakuraMotions: [MotionPlayer.Motion] = []
    private var touchMotions: [MotionPlayer.Motion] = []
    private var doubleTapMotions: [MotionPlayer.Motion] = []

    /// Which type of motion is currently playing (affects facial expression overlay)
    private enum ActiveMotionType {
        case none, kurakura, touch, doubleTap, kiss, breastTouch
    }
    private var activeMotionType: ActiveMotionType = .none

    /// Whether a kurakura/dizzy motion is active.
    /// When true, accelerometer input should be suppressed to avoid vibration.
    var isMotionPlaying: Bool { motionPlayer.playing }

    private enum BlinkState {
        case open, closing, closed, opening
    }

    // MARK: - Setup

    func cacheParamIndices(_ model: ALive2DModel) {
        paramAngleX = model.getParamIndex("PARAM_ANGLE_X")
        paramAngleY = model.getParamIndex("PARAM_ANGLE_Y")
        paramAngleZ = model.getParamIndex("PARAM_ANGLE_Z")
        paramEyeLOpen = model.getParamIndex("PARAM_EYE_L_OPEN")
        paramEyeROpen = model.getParamIndex("PARAM_EYE_R_OPEN")
        paramBodyAngleX = model.getParamIndex("PARAM_BODY_ANGLE_X")
        paramBreath = model.getParamIndex("PARAM_BREATH")
        paramEyeBallX = model.getParamIndex("PARAM_EYE_BALL_X")
        paramEyeBallY = model.getParamIndex("PARAM_EYE_BALL_Y")
        paramBrowLY = model.getParamIndex("PARAM_BROW_L_Y")
        paramBrowRY = model.getParamIndex("PARAM_BROW_R_Y")
        paramSmile = model.getParamIndex("PARAM_SMILE")
        paramTere = model.getParamIndex("PARAM_TERE")
        paramMouthForm = model.getParamIndex("PARAM_MOUTH_FORM")
        paramMouthOpenY = model.getParamIndex("PARAM_MOUTH_OPEN_Y")
        paramBodyDir = model.getParamIndex("PARAM_BODY_DIR")
    }

    /// Load all motions from the avatar_data bundle.
    /// Kurakura (dizzy): kurakura/kurakura1-3.mtn
    /// Touch (single tap): touch/touch1-4.mtn
    /// Double tap (head pat): double_tap/double_tap1-4.mtn
    func loadMotions(avatarDataDir: URL) {
        let motionDir = avatarDataDir.appendingPathComponent("live2d_motion")

        // Kurakura (dizzy) motions
        let kurakuraDir = motionDir.appendingPathComponent("kurakura")
        for i in 1...3 {
            let file = kurakuraDir.appendingPathComponent("kurakura\(i).mtn")
            if let motion = MotionPlayer.loadMotion(from: file) {
                kurakuraMotions.append(motion)
                print("[KanojoAnim] Loaded kurakura\(i).mtn (\(motion.frameCount) frames)")
            }
        }

        // Touch motions (single tap reactions)
        let touchDir = motionDir.appendingPathComponent("touch")
        for i in 1...4 {
            let file = touchDir.appendingPathComponent("touch\(i).mtn")
            if let motion = MotionPlayer.loadMotion(from: file) {
                touchMotions.append(motion)
                print("[KanojoAnim] Loaded touch\(i).mtn (\(motion.frameCount) frames)")
            }
        }

        // Double-tap motions (head pat)
        let doubleTapDir = motionDir.appendingPathComponent("double_tap")
        for i in 1...4 {
            let file = doubleTapDir.appendingPathComponent("double_tap\(i).mtn")
            if let motion = MotionPlayer.loadMotion(from: file) {
                doubleTapMotions.append(motion)
                print("[KanojoAnim] Loaded double_tap\(i).mtn (\(motion.frameCount) frames)")
            }
        }
    }

    /// Set initial parameter values matching Android KanojoAnimation.initParam().
    /// Must be called after cacheParamIndices. Saves params so the loadParam/saveParam
    /// cycle in update() works correctly from the first frame.
    func initParam(_ model: ALive2DModel) {
        model.setParamFloat(paramBodyDir, 15.0)
        model.setParamFloat(paramAngleX, -15.0)
        model.setParamFloat(paramAngleY, -3.0)
        model.setParamFloat(paramAngleZ, -15.0)
        model.setParamFloat(paramEyeBallX, 0.0)
        model.setParamFloat(paramEyeBallY, 0.0)
        model.setParamFloat(paramEyeLOpen, 1.0)
        model.setParamFloat(paramEyeROpen, 1.0)
        model.setParamFloat(paramSmile, 0.5)
        model.setParamFloat(paramTere, 0.2)
        model.setParamFloat(paramMouthForm, 0.5)
        model.setParamFloat(paramMouthOpenY, 0.0)
        model.setParamFloat(paramBrowLY, 0.5)
        model.setParamFloat(paramBrowRY, 0.5)
        model.saveParam()
    }

    // MARK: - Update

    func update(_ model: ALive2DModel, deltaMs: Double) {
        // If a motion is playing, it takes priority over idle animation.
        // The motion controls the sway (PARAM_BASE_X/Y, PARAM_ANGLE_Z, etc.).
        // Accelerometer is NOT applied during motion to prevent vibration.
        if motionPlayer.playing {
            model.loadParam()
            // Motion sets sway params on top of loaded base state
            _ = motionPlayer.update(model, deltaMs: deltaMs)
            // Dampen head tilt side-to-side — the .mtn files swing ±28° which
            // looks awkward; scale down to ~60% for a gentler sway
            let angleZ = model.getParamFloat(paramAngleZ)
            model.setParamFloat(paramAngleZ, angleZ * 0.6)
            // Still do breathing during motion
            updateBreathing(model, deltaMs: deltaMs)
            // Apply appropriate facial expression based on motion type
            switch activeMotionType {
            case .kurakura:
                applyDizzyFace(model, weight: 1.0)
            case .touch:
                applyTouchFace(model)
            case .doubleTap:
                applyHeadPatFace(model)
            case .kiss:
                applyKissFace(model)
            case .breastTouch:
                applyBreastTouchFace(model)
            case .none:
                break
            }
            // Do NOT saveParam here — face values must not persist into base state.
            return
        }
        // Motion finished — clear type
        if activeMotionType != .none {
            activeMotionType = .none
        }

        model.loadParam()

        // Eye blink
        updateEyeBlink(model, deltaMs: deltaMs)

        // Breathing
        updateBreathing(model, deltaMs: deltaMs)

        // Idle head sway (subtle)
        let time = UtSystem.getTimeMSec() / 1000.0
        let swayX = Float(sin(time * 2.0 * .pi / 6.0)) * 5.0  // 6 second cycle
        let swayY = Float(sin(time * 2.0 * .pi / 8.0)) * 3.0  // 8 second cycle
        model.setParamFloat(paramAngleX, swayX, weight: 0.5)
        model.setParamFloat(paramAngleY, swayY, weight: 0.5)

        model.saveParam()
    }

    /// Apply accelerometer tilt to Live2D params, matching Android
    /// KanojoModel.drawModel_core() lines 164-170.
    /// Called from KanojoModel.update() AFTER animation update.
    func applyAcceleration(_ model: ALive2DModel) {
        // Matches Android exactly:
        //   addToParamFloat("PARAM_ANGLE_X", 60.0f * 1.5f * accel[0], 0.5f)
        //   addToParamFloat("PARAM_ANGLE_Y", 60.0f * 1.5f * accel[1], 0.5f)
        //   addToParamFloat("PARAM_BODY_ANGLE_X", 20.0f * 1.5f * accel[0], 0.5f)
        //   addToParamFloat("PARAM_BASE_X", -200.0f * accel[0], 0.5f)
        //   addToParamFloat("PARAM_BASE_Y", -100.0f * accel[1], 0.5f)
        model.addToParamFloat(paramAngleX, 90.0 * accelX, weight: 0.5)
        model.addToParamFloat(paramAngleY, 90.0 * accelY, weight: 0.5)
        model.addToParamFloat(paramBodyAngleX, 30.0 * accelX, weight: 0.5)
        model.addToParamFloat("PARAM_BASE_X", -200.0 * accelX, weight: 0.5)
        model.addToParamFloat("PARAM_BASE_Y", -100.0 * accelY, weight: 0.5)
    }

    /// Apply brow position offset AFTER animation update, matching Android
    /// KanojoModel.drawModel_core() lines 173-179. Called from KanojoModel.update().
    func applyBrowOffset(_ model: ALive2DModel) {
        let srcBrowLY = model.getParamFloat(paramBrowLY)
        let srcBrowRY = model.getParamFloat(paramBrowRY)
        let browCenter: Float = 0.5 + (browPositionOffset * 0.4 * 0.5)
        let dstBrowLY = clamp(browCenter + (srcBrowLY - 0.5) * 0.8, min: 0, max: 1)
        let dstBrowRY = clamp(browCenter + (srcBrowRY - 0.5) * 0.8, min: 0, max: 1)
        model.setParamFloat(paramBrowLY, dstBrowLY)
        model.setParamFloat(paramBrowRY, dstBrowRY)
    }

    // MARK: - Shake Event

    /// Trigger dizzy (kurakura) animation on shake.
    /// Matches Android KanojoAnimation.shakeEvent(): picks random kurakura motion.
    func shakeEvent() {
        guard !kurakuraMotions.isEmpty else { return }
        let motion = kurakuraMotions[Int.random(in: 0..<kurakuraMotions.count)]
        activeMotionType = .kurakura
        motionPlayer.startMotion(motion)
        print("[KanojoAnim] Shake! Playing kurakura motion (\(motion.frameCount) frames)")
    }

    // MARK: - Touch Events

    /// Trigger a single-tap reaction animation.
    /// In the original game: single tap on the body triggers a surprised/embarrassed reaction.
    func touchEvent() {
        guard !touchMotions.isEmpty else { return }
        let motion = touchMotions[Int.random(in: 0..<touchMotions.count)]
        activeMotionType = .touch
        motionPlayer.startMotion(motion)
        print("[KanojoAnim] Touch! Playing touch motion (\(motion.frameCount) frames)")
    }

    /// Trigger a double-tap (head pat) reaction animation.
    /// In the original game: double tap on the head triggers a happy/pleased reaction.
    func doubleTapEvent() {
        guard !doubleTapMotions.isEmpty else { return }
        let motion = doubleTapMotions[Int.random(in: 0..<doubleTapMotions.count)]
        activeMotionType = .doubleTap
        motionPlayer.startMotion(motion)
        print("[KanojoAnim] DoubleTap! Playing head pat motion (\(motion.frameCount) frames)")
    }

    /// Trigger a kiss reaction (tap on face area).
    /// Reuses touch motions with a special blush+closed-eyes face overlay.
    func kissEvent() {
        guard !touchMotions.isEmpty else { return }
        let motion = touchMotions[Int.random(in: 0..<touchMotions.count)]
        activeMotionType = .kiss
        motionPlayer.startMotion(motion)
        print("[KanojoAnim] Kiss! Playing kiss reaction (\(motion.frameCount) frames)")
    }

    /// Trigger a breast touch reaction (tap on chest area).
    /// Reuses touch motions with a surprised/angry face overlay.
    func breastTouchEvent() {
        guard !touchMotions.isEmpty else { return }
        let motion = touchMotions[Int.random(in: 0..<touchMotions.count)]
        activeMotionType = .breastTouch
        motionPlayer.startMotion(motion)
        print("[KanojoAnim] BreastTouch! Playing surprised reaction (\(motion.frameCount) frames)")
    }

    // MARK: - Facial Expressions for Motion Types

    /// Apply dizzy facial expression with the given intensity weight (0 = none, 1 = full).
    private func applyDizzyFace(_ model: ALive2DModel, weight: Float) {
        model.setParamFloat(paramEyeLOpen, 0.0)
        model.setParamFloat(paramEyeROpen, 0.0)
        model.setParamFloat(paramMouthOpenY, 0.15 * weight)
        model.setParamFloat(paramMouthForm, -0.5 * weight)  // frown
        model.setParamFloat(paramTere, 0.8 * weight)  // blush
        model.setParamFloat(paramSmile, 0.0)
        model.setParamFloat(paramBrowLY, 0.0)  // upset brows
        model.setParamFloat(paramBrowRY, 0.0)
    }

    /// Apply surprised/embarrassed face for single-tap touch reaction.
    private func applyTouchFace(_ model: ALive2DModel) {
        // The .mtn motion files already animate many params (mouth, eyes, brows, tere).
        // We only add a light blush overlay; let the motion handle the rest.
        let currentTere = model.getParamFloat(paramTere)
        model.setParamFloat(paramTere, max(currentTere, 0.4))  // ensure at least mild blush
    }

    /// Apply happy/pleased face for double-tap head pat reaction.
    private func applyHeadPatFace(_ model: ALive2DModel) {
        // The .mtn motion files already animate the reaction.
        // We add a smile and slight blush overlay for warmth.
        let currentSmile = model.getParamFloat(paramSmile)
        model.setParamFloat(paramSmile, max(currentSmile, 0.6))  // ensure smile
        let currentTere = model.getParamFloat(paramTere)
        model.setParamFloat(paramTere, max(currentTere, 0.3))  // light blush
    }

    /// Apply kiss facial expression — closed eyes, blush, slight smile.
    private func applyKissFace(_ model: ALive2DModel) {
        model.setParamFloat(paramEyeLOpen, 0.0)       // eyes closed
        model.setParamFloat(paramEyeROpen, 0.0)
        model.setParamFloat(paramTere, 0.9)            // heavy blush
        model.setParamFloat(paramSmile, 0.7)            // pleased smile
        model.setParamFloat(paramMouthForm, 0.3)        // slight pout
        model.setParamFloat(paramMouthOpenY, 0.05)
    }

    /// Apply breast touch facial expression — wide eyes, angry/surprised, blush.
    private func applyBreastTouchFace(_ model: ALive2DModel) {
        model.setParamFloat(paramEyeLOpen, 1.0)        // eyes wide open
        model.setParamFloat(paramEyeROpen, 1.0)
        model.setParamFloat(paramTere, 0.7)            // blush
        model.setParamFloat(paramSmile, 0.0)            // no smile
        model.setParamFloat(paramMouthForm, -0.8)       // frown/angry
        model.setParamFloat(paramMouthOpenY, 0.5)       // mouth open (shocked)
        model.setParamFloat(paramBrowLY, 0.9)          // angry brows
        model.setParamFloat(paramBrowRY, 0.9)
    }

    private func clamp(_ v: Float, min minV: Float, max maxV: Float) -> Float {
        if v < minV { return minV }
        return v > maxV ? maxV : v
    }

    // MARK: - Eye Blink

    private func updateEyeBlink(_ model: ALive2DModel, deltaMs: Double) {
        blinkTimer += deltaMs

        switch blinkState {
        case .open:
            let now = UtSystem.getTimeMSec()
            if now - lastBlinkTime > eyeBlinkInterval {
                blinkState = .closing
                blinkTimer = 0
                // Randomize next interval (3-5 seconds)
                eyeBlinkInterval = Double.random(in: 3000...5000)
            }
            model.setParamFloat(paramEyeLOpen, 1.0)
            model.setParamFloat(paramEyeROpen, 1.0)

        case .closing:
            let t = Float(min(blinkTimer / blinkCloseDuration, 1.0))
            model.setParamFloat(paramEyeLOpen, 1.0 - t)
            model.setParamFloat(paramEyeROpen, 1.0 - t)
            if blinkTimer >= blinkCloseDuration {
                blinkState = .closed
                blinkTimer = 0
            }

        case .closed:
            model.setParamFloat(paramEyeLOpen, 0.0)
            model.setParamFloat(paramEyeROpen, 0.0)
            if blinkTimer >= 50 { // Brief closed pause
                blinkState = .opening
                blinkTimer = 0
            }

        case .opening:
            let t = Float(min(blinkTimer / blinkOpenDuration, 1.0))
            model.setParamFloat(paramEyeLOpen, t)
            model.setParamFloat(paramEyeROpen, t)
            if blinkTimer >= blinkOpenDuration {
                blinkState = .open
                lastBlinkTime = UtSystem.getTimeMSec()
            }
        }
    }

    // MARK: - Breathing

    private func updateBreathing(_ model: ALive2DModel, deltaMs: Double) {
        breathPhase += Float(deltaMs) / 3500.0 * 2.0 * .pi
        if breathPhase > .pi * 2 { breathPhase -= .pi * 2 }
        let breathVal = (sin(breathPhase) + 1.0) / 2.0  // 0..1
        model.setParamFloat(paramBreath, breathVal)
    }
}
