import Foundation

/// Product category (e.g., Foods, Electronics).
/// Source: Category.java + CategoryParser.java
struct Category: Codable, Identifiable, Hashable, Sendable {

    var id: Int
    var name: String

    init(id: Int = 0, name: String = "") {
        self.id = id
        self.name = name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, name
    }
}
