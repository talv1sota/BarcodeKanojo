import Foundation

/// Dialogue messages from a kanojo after dates/gifts.
/// Source: KanojoMessage.java + server response kanojo_message field
struct KanojoMessage: Codable, Hashable, Sendable {

    var messages: [String]

    init(messages: [String] = []) {
        self.messages = messages
    }
}
