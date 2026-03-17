import Foundation

/// Item class types for kanojo items.
/// Source: KanojoItem.java lines 17-19
enum ItemClass: Int, Codable, Sendable {
    case gift = 1
    case date = 2
    case ticket = 3
}
