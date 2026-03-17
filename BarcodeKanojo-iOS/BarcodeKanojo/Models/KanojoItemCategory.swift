import Foundation

/// Container for a category of kanojo items (e.g., Wardrobe, Gifts).
/// Source: KanojoItemCategory.java
struct KanojoItemCategory: Codable, Identifiable, Hashable, Sendable {

    var categoryId: Int
    var title: String?
    var items: [KanojoItem]?
    var flag: String?
    var level: String?

    var id: Int { categoryId }

    init(
        categoryId: Int = 0,
        title: String? = nil,
        items: [KanojoItem]? = nil,
        flag: String? = nil,
        level: String? = nil
    ) {
        self.categoryId = categoryId
        self.title = title
        self.items = items
        self.flag = flag
        self.level = level
    }

    enum CodingKeys: String, CodingKey {
        case categoryId = "item_category_id"
        case title, items, flag, level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        categoryId = try container.decodeIfPresent(Int.self, forKey: .categoryId) ?? 0
        title = try container.decodeIfPresent(String.self, forKey: .title)
        items = try container.decodeIfPresent([KanojoItem].self, forKey: .items)
        flag = try container.decodeIfPresent(String.self, forKey: .flag)
        level = try container.decodeIfPresent(String.self, forKey: .level)
    }
}
