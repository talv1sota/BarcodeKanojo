import Foundation

/// Game notification/alert message from the server.
/// Source: Alert.java + AlertParser.java
struct Alert: Codable, Hashable, Sendable {

    var title: String
    var body: String

    init(title: String = "", body: String = "") {
        self.title = title
        self.body = body
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case title, body
    }
}
