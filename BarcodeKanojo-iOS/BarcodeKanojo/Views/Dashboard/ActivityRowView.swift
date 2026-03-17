import SwiftUI

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Kanojo/User thumbnail
            if let kanojo = activity.kanojo {
                AsyncCachedImage(url: kanojo.profileImageIconURL)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activity ?? activityDescription)
                    .font(.subheadline)
                    .lineLimit(2)

                Text(timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var activityDescription: String {
        let userName = activity.user?.name ?? "Someone"
        let kanojoName = activity.kanojo?.name ?? "a kanojo"
        switch activity.type {
        case .scan:             return "\(userName) scanned \(kanojoName)"
        case .generated:        return "\(userName) generated \(kanojoName)"
        case .approachKanojo:   return "\(userName) approached \(kanojoName)"
        case .married:          return "\(userName) married \(kanojoName)"
        case .becomeNewLevel:   return "\(userName) reached a new level!"
        case .joined:           return "\(userName) joined the game"
        case .breakup:          return "\(userName) broke up with \(kanojoName)"
        default:                return activity.activity ?? "\(userName) did something"
        }
    }

    private var timeAgo: String {
        let date = Date(timeIntervalSince1970: TimeInterval(activity.createdTimestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
