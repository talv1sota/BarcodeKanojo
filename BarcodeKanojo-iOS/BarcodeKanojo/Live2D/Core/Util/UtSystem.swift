// UtSystem.swift — System utilities
// Ported from live2d-v2/live2d/core/util/ut_system.py

import Foundation

final class UtSystem {
    static let USER_TIME_AUTO: Double = -1
    static var userTimeMSec: Double = USER_TIME_AUTO

    static func getUserTimeMSec() -> Double {
        return userTimeMSec == USER_TIME_AUTO ? getSystemTimeMSec() : userTimeMSec
    }

    static func setUserTimeMSec(_ t: Double) {
        userTimeMSec = t
    }

    static func updateUserTimeMSec() -> Double {
        userTimeMSec = getSystemTimeMSec()
        return userTimeMSec
    }

    static func getTimeMSec() -> Double {
        return Date().timeIntervalSince1970 * 1000.0
    }

    static func getSystemTimeMSec() -> Double {
        return Date().timeIntervalSince1970 * 1000.0
    }

    /// Equivalent of Python's list slice copy: dst[dstOff..<dstOff+len] = src[srcOff..<srcOff+len]
    static func arraycopy<T>(_ src: [T], _ srcOff: Int, _ dst: inout [T], _ dstOff: Int, _ length: Int) {
        for i in 0..<length {
            dst[dstOff + i] = src[srcOff + i]
        }
    }
}
