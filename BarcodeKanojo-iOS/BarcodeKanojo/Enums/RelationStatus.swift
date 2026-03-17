import Foundation

/// Relationship status between user and kanojo.
/// Source: Kanojo.kt lines 239-241
enum RelationStatus: Int, Codable, CaseIterable, Sendable {
    case other = 1
    case kanojo = 2
    case friend = 3
}
