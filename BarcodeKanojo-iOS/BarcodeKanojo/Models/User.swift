import Foundation

/// Player profile model.
/// Source: User.kt + UserParser.java
struct User: Codable, Identifiable, Hashable, Sendable {

    var id: Int
    var name: String?
    var language: String?
    var level: Int
    var stamina: Int
    var staminaMax: Int
    var money: Int
    var kanojoCount: Int
    var generateCount: Int
    var scanCount: Int
    var enemyCount: Int
    /// Number of friends/wishes.
    /// IMPORTANT: JSON key is "friend_count" but semantically this is the wish count.
    /// This mapping comes from UserParser.java line 48.
    var wishCount: Int
    var tickets: Int
    var relationStatus: Int

    var birthDay: Int
    var birthMonth: Int
    var birthYear: Int

    // MARK: - Computed Properties

    var profileImageURL: String {
        "/profile_images/user/\(id).jpg"
    }

    /// Returns birth date as "M.D.YYYY" or empty string if any component is 0.
    var birthText: String {
        if birthMonth == 0 || birthDay == 0 || birthYear == 0 {
            return ""
        }
        return "\(birthMonth).\(birthDay).\(birthYear)"
    }

    var relation: RelationStatus? {
        RelationStatus(rawValue: relationStatus)
    }

    // MARK: - Methods

    /// Parse birth date from "M.D.YYYY" format string.
    mutating func setBirthFromText(_ birthdate: String) {
        guard !birthdate.isEmpty else { return }
        let components = birthdate.split(separator: ".")
        guard components.count == 3,
              let month = Int(components[0]),
              let day = Int(components[1]),
              let year = Int(components[2]) else { return }
        birthMonth = month
        birthDay = day
        birthYear = year
    }

    mutating func setBirth(month: Int, day: Int, year: Int) {
        birthMonth = month
        birthDay = day
        birthYear = year
    }

    // MARK: - Default Initializer

    init(
        id: Int = 0,
        name: String? = nil,
        language: String? = nil,
        level: Int = 0,
        stamina: Int = 0,
        staminaMax: Int = 100,
        money: Int = 0,
        kanojoCount: Int = 0,
        generateCount: Int = 0,
        scanCount: Int = 0,
        enemyCount: Int = 0,
        wishCount: Int = 0,
        tickets: Int = 0,
        relationStatus: Int = 0,
        birthDay: Int = 1,
        birthMonth: Int = 1,
        birthYear: Int = 2000
    ) {
        self.id = id
        self.name = name
        self.language = language
        self.level = level
        self.stamina = stamina
        self.staminaMax = staminaMax
        self.money = money
        self.kanojoCount = kanojoCount
        self.generateCount = generateCount
        self.scanCount = scanCount
        self.enemyCount = enemyCount
        self.wishCount = wishCount
        self.tickets = tickets
        self.relationStatus = relationStatus
        self.birthDay = birthDay
        self.birthMonth = birthMonth
        self.birthYear = birthYear
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, name, language, level, stamina, money, tickets
        case staminaMax = "stamina_max"
        case kanojoCount = "kanojo_count"
        case generateCount = "generate_count"
        case scanCount = "scan_count"
        case enemyCount = "enemy_count"
        // IMPORTANT: Server sends "friend_count" but we store as wishCount
        case wishCount = "friend_count"
        case relationStatus = "relation_status"
        case birthDay = "birth_day"
        case birthMonth = "birth_month"
        case birthYear = "birth_year"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 0
        stamina = try container.decodeIfPresent(Int.self, forKey: .stamina) ?? 0
        staminaMax = try container.decodeIfPresent(Int.self, forKey: .staminaMax) ?? 100
        money = try container.decodeIfPresent(Int.self, forKey: .money) ?? 0
        kanojoCount = try container.decodeIfPresent(Int.self, forKey: .kanojoCount) ?? 0
        generateCount = try container.decodeIfPresent(Int.self, forKey: .generateCount) ?? 0
        scanCount = try container.decodeIfPresent(Int.self, forKey: .scanCount) ?? 0
        enemyCount = try container.decodeIfPresent(Int.self, forKey: .enemyCount) ?? 0
        wishCount = try container.decodeIfPresent(Int.self, forKey: .wishCount) ?? 0
        tickets = try container.decodeIfPresent(Int.self, forKey: .tickets) ?? 0
        relationStatus = try container.decodeIfPresent(Int.self, forKey: .relationStatus) ?? 0
        birthDay = try container.decodeIfPresent(Int.self, forKey: .birthDay) ?? 1
        birthMonth = try container.decodeIfPresent(Int.self, forKey: .birthMonth) ?? 1
        birthYear = try container.decodeIfPresent(Int.self, forKey: .birthYear) ?? 2000
    }
}
