import Foundation

/// Activity feed entry (scan, generation, friend addition, etc.).
/// Source: ActivityModel.java + ActivityParser.java
struct Activity: Codable, Identifiable, Hashable, Sendable {

    var id: Int
    var activityType: Int
    var createdTimestamp: Int
    var activity: String?
    var user: User?
    var otherUser: User?
    var kanojo: Kanojo?
    var product: Product?

    // MARK: - Computed Properties

    var type: ActivityType? {
        ActivityType(rawValue: activityType)
    }

    // MARK: - Default Initializer

    init(
        id: Int = 0,
        activityType: Int = 0,
        createdTimestamp: Int = 0,
        activity: String? = nil,
        user: User? = nil,
        otherUser: User? = nil,
        kanojo: Kanojo? = nil,
        product: Product? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.createdTimestamp = createdTimestamp
        self.activity = activity
        self.user = user
        self.otherUser = otherUser
        self.kanojo = kanojo
        self.product = product
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, activity, user, kanojo, product
        case activityType = "activity_type"
        case createdTimestamp = "created_timestamp"
        case otherUser = "other_user"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        activityType = try container.decodeIfPresent(Int.self, forKey: .activityType) ?? 0
        createdTimestamp = try container.decodeIfPresent(Int.self, forKey: .createdTimestamp) ?? 0
        activity = try container.decodeIfPresent(String.self, forKey: .activity)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        otherUser = try container.decodeIfPresent(User.self, forKey: .otherUser)
        kanojo = try container.decodeIfPresent(Kanojo.self, forKey: .kanojo)
        product = try container.decodeIfPresent(Product.self, forKey: .product)
    }
}
