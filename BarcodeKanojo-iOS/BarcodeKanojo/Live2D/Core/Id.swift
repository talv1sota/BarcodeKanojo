// Id.swift — Live2D flyweight ID singleton
// Ported from live2d-v2/live2d/core/id/id.py
//
// IDs are interned strings used throughout the engine for parameter names,
// parts IDs, deformer IDs, etc. Using reference equality for fast comparison.

import Foundation

final class Live2DId: Equatable, Hashable, CustomStringConvertible {

    // MARK: - Singleton registry
    private static var instances: [String: Live2DId] = [:]

    // MARK: - Properties
    let id: String

    // MARK: - Init (private — use getID)
    private init(_ idStr: String) {
        self.id = idStr
    }

    // MARK: - Factory
    static func getID(_ idStr: String) -> Live2DId {
        if let existing = instances[idStr] {
            return existing
        }
        let newId = Live2DId(idStr)
        instances[idStr] = newId
        return newId
    }

    // MARK: - Well-known IDs
    static func DST_BASE_ID() -> Live2DId {
        return getID("DST_BASE")
    }

    // MARK: - Cleanup
    static func releaseStored() {
        instances.removeAll()
    }

    // MARK: - Equatable
    static func == (lhs: Live2DId, rhs: Live2DId) -> Bool {
        return lhs === rhs || lhs.id == rhs.id
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - CustomStringConvertible
    var description: String {
        return id
    }
}
