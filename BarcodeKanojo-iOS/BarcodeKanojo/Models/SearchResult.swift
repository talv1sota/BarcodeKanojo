import Foundation

/// Search result metadata.
/// Source: SearchResult.java + SearchResultParser.java
struct SearchResult: Codable, Hashable, Sendable {

    var hitCount: Int

    init(hitCount: Int = 0) {
        self.hitCount = hitCount
    }

    enum CodingKeys: String, CodingKey {
        case hitCount = "hit_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hitCount = try container.decodeIfPresent(Int.self, forKey: .hitCount) ?? 0
    }
}
