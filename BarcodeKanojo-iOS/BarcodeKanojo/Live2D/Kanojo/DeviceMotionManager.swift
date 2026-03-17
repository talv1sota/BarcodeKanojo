// DeviceMotionManager.swift — Accelerometer input for Live2D character response
// Ported from kanojo_app-master/.../live2d/util/AccelHelper.java
// and shake detection + smoothing from AndroidES1Renderer.java

import CoreMotion
import Foundation

final class DeviceMotionManager {
    private let motionManager = CMMotionManager()

    // Smoothed acceleration output (rate-limited, matching Android updateAccel())
    private(set) var accelerationX: Float = 0
    private(set) var accelerationY: Float = 0
    private(set) var accelerationZ: Float = 0

    // Raw destination values from sensor (matching Android dst_acceleration_*)
    private var dstAccelX: Float = 0
    private var dstAccelY: Float = 0
    private var dstAccelZ: Float = 0

    // Rate limiter: max acceleration change per frame
    // Matches Android MAX_ACCEL_D = 0.04f
    private let maxAccelDelta: Float = 0.04

    // Shake detection (matches Android: threshold 1.5, cooldown 3s)
    private var lastMove: Float = 0
    private var prevDstAccelX: Float = 0
    private var prevDstAccelY: Float = 0
    private var prevDstAccelZ: Float = 0
    private var lastShakeTime: Double = 0
    private let shakeThreshold: Float = 1.5
    private let shakeCooldown: Double = 3.0  // seconds

    var onShake: (() -> Void)?

    func start() {
        guard motionManager.isAccelerometerAvailable else {
            print("[Motion] Accelerometer not available")
            return
        }
        motionManager.accelerometerUpdateInterval = 1.0 / 30.0  // 30 Hz
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }

            // CMAccelerometerData gives values in g-force already
            // Android negates x and y, so we do too
            let ax = Float(-data.acceleration.x)
            let ay = Float(-data.acceleration.y)
            let az = Float(-data.acceleration.z)

            // Store raw destination (matching Android setCurAccel)
            self.dstAccelX = ax
            self.dstAccelY = ay
            self.dstAccelZ = az

            // Shake detection (matches AndroidES1Renderer.setCurAccel)
            let delta = abs(ax - self.prevDstAccelX) + abs(ay - self.prevDstAccelY) + abs(az - self.prevDstAccelZ)
            self.lastMove = self.lastMove * 0.7 + 0.3 * delta

            if self.lastMove > self.shakeThreshold {
                let now = UtSystem.getTimeMSec() / 1000.0
                if now - self.lastShakeTime >= self.shakeCooldown {
                    self.lastShakeTime = now
                    self.lastMove = 0
                    self.onShake?()
                }
            }

            self.prevDstAccelX = ax
            self.prevDstAccelY = ay
            self.prevDstAccelZ = az

            // Rate-limited smoothing (matches Android updateAccel())
            // Acceleration can only change by ±maxAccelDelta per frame
            self.accelerationX = Self.smoothStep(self.accelerationX, toward: self.dstAccelX, maxDelta: self.maxAccelDelta)
            self.accelerationY = Self.smoothStep(self.accelerationY, toward: self.dstAccelY, maxDelta: self.maxAccelDelta)
            self.accelerationZ = Self.smoothStep(self.accelerationZ, toward: self.dstAccelZ, maxDelta: self.maxAccelDelta)
        }
        print("[Motion] Accelerometer started")
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
        print("[Motion] Accelerometer stopped")
    }

    /// Rate-limited step: move current toward target by at most maxDelta per call.
    private static func smoothStep(_ current: Float, toward target: Float, maxDelta: Float) -> Float {
        let diff = target - current
        if diff > maxDelta {
            return current + maxDelta
        } else if diff < -maxDelta {
            return current - maxDelta
        }
        return current + diff
    }
}
