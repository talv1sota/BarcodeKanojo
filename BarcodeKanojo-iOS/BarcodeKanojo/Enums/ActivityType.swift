import Foundation

/// Activity types for timeline events.
/// Source: ActivityModel.java lines 7-18
enum ActivityType: Int, Codable, Sendable {
    case scan = 1
    case generated = 2
    case meAddFriend = 5
    case approachKanojo = 7
    case meStolenKanojo = 8
    case myKanojoStolen = 9
    case myKanojoAddedToFriends = 10
    case becomeNewLevel = 11
    case married = 15
    case joined = 101
    case breakup = 102
    case addAsEnemy = 103
}
