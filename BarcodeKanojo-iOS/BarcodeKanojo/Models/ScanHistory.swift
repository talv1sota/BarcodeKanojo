import Foundation

/// Statistics for a scanned barcode.
/// Source: ScanHistory.java + ScanHistoryParser.java
struct ScanHistory: Codable, Hashable, Sendable {

    var barcode: String?
    var totalCount: Int
    var kanojoCount: Int
    var friendCount: Int

    init(
        barcode: String? = nil,
        totalCount: Int = 0,
        kanojoCount: Int = 0,
        friendCount: Int = 0
    ) {
        self.barcode = barcode
        self.totalCount = totalCount
        self.kanojoCount = kanojoCount
        self.friendCount = friendCount
    }

    enum CodingKeys: String, CodingKey {
        case barcode
        case totalCount = "total_count"
        case kanojoCount = "kanojo_count"
        case friendCount = "friend_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount) ?? 0
        kanojoCount = try container.decodeIfPresent(Int.self, forKey: .kanojoCount) ?? 0
        friendCount = try container.decodeIfPresent(Int.self, forKey: .friendCount) ?? 0
    }
}
