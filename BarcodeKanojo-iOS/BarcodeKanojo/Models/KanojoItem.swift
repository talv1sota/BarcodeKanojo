import Foundation

/// Gift, date, or ticket item for kanojo interactions.
/// Source: KanojoItem.java + KanojoItemParser.java
struct KanojoItem: Codable, Identifiable, Hashable, Sendable {

    var itemId: Int
    var itemCategoryId: Int
    /// 1 = GIFT, 2 = DATE, 3 = TICKET
    var itemClass: Int
    var category: Bool
    /// Server sends as Int (0/1), stored as Bool.
    var expandFlag: Bool
    var title: String?
    var description: String?
    var imageThumbnailURL: String?
    var imageURL: String?
    var price: String?
    var confirmPurchaseMessage: String?
    var confirmUseMessage: String?
    var hasUnits: String?
    /// Google Play / App Store product ID for in-app purchases
    var purchaseProductId: String?
    var purchasableLevel: String?

    // MARK: - Identifiable

    var id: Int { itemId }

    // MARK: - Computed Properties

    var hasItem: Bool {
        guard let hasUnits, !hasUnits.isEmpty else { return false }
        return true
    }

    var itemClassType: ItemClass? {
        ItemClass(rawValue: itemClass)
    }

    // MARK: - Default Initializer

    init(
        itemId: Int = 0,
        itemCategoryId: Int = 0,
        itemClass: Int = 1,
        category: Bool = false,
        expandFlag: Bool = false,
        title: String? = nil,
        description: String? = nil,
        imageThumbnailURL: String? = nil,
        imageURL: String? = nil,
        price: String? = nil,
        confirmPurchaseMessage: String? = nil,
        confirmUseMessage: String? = nil,
        hasUnits: String? = nil,
        purchaseProductId: String? = nil,
        purchasableLevel: String? = nil
    ) {
        self.itemId = itemId
        self.itemCategoryId = itemCategoryId
        self.itemClass = itemClass
        self.category = category
        self.expandFlag = expandFlag
        self.title = title
        self.description = description
        self.imageThumbnailURL = imageThumbnailURL
        self.imageURL = imageURL
        self.price = price
        self.confirmPurchaseMessage = confirmPurchaseMessage
        self.confirmUseMessage = confirmUseMessage
        self.hasUnits = hasUnits
        self.purchaseProductId = purchaseProductId
        self.purchasableLevel = purchasableLevel
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case title, description, price, category
        case itemId = "item_id"
        case itemCategoryId = "item_category_id"
        case itemClass = "item_class"
        case expandFlag = "expand_flag"
        case imageThumbnailURL = "image_thumbnail_url"
        case imageURL = "image_url"
        case confirmPurchaseMessage = "confirm_purchase_message"
        case confirmUseMessage = "confirm_use_message"
        case hasUnits = "has_units"
        case purchaseProductId = "purchase_product_id"
        case purchasableLevel = "purchasable_level"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        itemId = try container.decodeIfPresent(Int.self, forKey: .itemId) ?? 0
        itemCategoryId = try container.decodeIfPresent(Int.self, forKey: .itemCategoryId) ?? 0
        itemClass = try container.decodeIfPresent(Int.self, forKey: .itemClass) ?? 1
        category = try container.decodeIfPresent(Bool.self, forKey: .category) ?? false

        // expand_flag comes from server as Int (0 or 1), convert to Bool
        if let expandInt = try? container.decodeIfPresent(Int.self, forKey: .expandFlag) {
            expandFlag = expandInt != 0
        } else {
            expandFlag = try container.decodeIfPresent(Bool.self, forKey: .expandFlag) ?? false
        }

        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageThumbnailURL = try container.decodeIfPresent(String.self, forKey: .imageThumbnailURL)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        confirmPurchaseMessage = try container.decodeIfPresent(String.self, forKey: .confirmPurchaseMessage)
        confirmUseMessage = try container.decodeIfPresent(String.self, forKey: .confirmUseMessage)
        hasUnits = try container.decodeIfPresent(String.self, forKey: .hasUnits)
        purchaseProductId = try container.decodeIfPresent(String.self, forKey: .purchaseProductId)
        purchasableLevel = try container.decodeIfPresent(String.self, forKey: .purchasableLevel)
    }
}
