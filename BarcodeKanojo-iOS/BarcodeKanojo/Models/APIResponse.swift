import Foundation

/// Generic API response wrapper.
/// Server returns flat JSON: {"code": 200, "message": "OK", "user": {...}, "kanojo": {...}, ...}
/// Source: Response.java + ResponseParser.java + schemas/common.py
struct APIResponse: Codable, Sendable {

    // MARK: - Status

    var code: Int
    var message: String?

    // MARK: - Single Objects

    var user: User?
    var selfUser: User?
    var ownerUser: User?
    var kanojo: Kanojo?
    var product: Product?
    var scanHistory: ScanHistory?
    var searchResult: SearchResult?
    var loveIncrement: LoveIncrement?
    var kanojoMessage: KanojoMessage?

    // MARK: - Collections

    var currentKanojos: [Kanojo]?
    var friendKanojos: [Kanojo]?
    var likeRankingKanojos: [Kanojo]?
    var activities: [Activity]?
    var itemCategories: [KanojoItemCategory]?
    var alerts: [Alert]?
    var categories: [Category]?

    // MARK: - Computed Properties

    var responseCode: ResponseCode? {
        ResponseCode(rawValue: code)
    }

    var isSuccess: Bool {
        code == ResponseCode.success.rawValue
    }

    // MARK: - Default Initializer

    init(
        code: Int = 200,
        message: String? = nil,
        user: User? = nil,
        selfUser: User? = nil,
        ownerUser: User? = nil,
        kanojo: Kanojo? = nil,
        product: Product? = nil,
        scanHistory: ScanHistory? = nil,
        searchResult: SearchResult? = nil,
        loveIncrement: LoveIncrement? = nil,
        kanojoMessage: KanojoMessage? = nil,
        currentKanojos: [Kanojo]? = nil,
        friendKanojos: [Kanojo]? = nil,
        likeRankingKanojos: [Kanojo]? = nil,
        activities: [Activity]? = nil,
        itemCategories: [KanojoItemCategory]? = nil,
        alerts: [Alert]? = nil,
        categories: [Category]? = nil
    ) {
        self.code = code
        self.message = message
        self.user = user
        self.selfUser = selfUser
        self.ownerUser = ownerUser
        self.kanojo = kanojo
        self.product = product
        self.scanHistory = scanHistory
        self.searchResult = searchResult
        self.loveIncrement = loveIncrement
        self.kanojoMessage = kanojoMessage
        self.currentKanojos = currentKanojos
        self.friendKanojos = friendKanojos
        self.likeRankingKanojos = likeRankingKanojos
        self.activities = activities
        self.itemCategories = itemCategories
        self.alerts = alerts
        self.categories = categories
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case code, message, user, kanojo, product, activities, alerts, categories
        case selfUser = "self_user"
        case ownerUser = "owner_user"
        case scanHistory = "scan_history"
        case searchResult = "search_result"
        case loveIncrement = "love_increment"
        case kanojoMessage = "kanojo_message"
        case currentKanojos = "current_kanojos"
        case friendKanojos = "friend_kanojos"
        case likeRankingKanojos = "like_ranking_kanojos"
        case itemCategories = "item_categories"
    }
}
