import Foundation

/// Love gauge changes from dates/gifts.
/// Source: LoveIncrement.java + LoveIncrementParser.java
struct LoveIncrement: Codable, Hashable, Sendable {

    var increaseLove: String
    var decrementLove: String
    /// NOTE: This JSON key is camelCase ("alertShow"), unlike other snake_case keys.
    var alertShow: String

    init(
        increaseLove: String = "0",
        decrementLove: String = "0",
        alertShow: String = "0"
    ) {
        self.increaseLove = increaseLove
        self.decrementLove = decrementLove
        self.alertShow = alertShow
    }

    mutating func clearAll() {
        increaseLove = "0"
        decrementLove = "0"
        alertShow = "0"
    }

    enum CodingKeys: String, CodingKey {
        case increaseLove = "increase_love"
        case decrementLove = "decrement_love"
        // NOTE: camelCase key from server, not snake_case
        case alertShow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        increaseLove = try container.decodeIfPresent(String.self, forKey: .increaseLove) ?? "0"
        decrementLove = try container.decodeIfPresent(String.self, forKey: .decrementLove) ?? "0"
        alertShow = try container.decodeIfPresent(String.self, forKey: .alertShow) ?? "0"
    }
}
