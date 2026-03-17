import Foundation
import CoreLocation

/// Virtual companion character generated from a product barcode.
/// Source: Kanojo.kt + KanojoParser.java
struct Kanojo: Codable, Identifiable, Hashable, Sendable {

    // MARK: - Core Identity

    var id: Int
    var name: String?
    var barcode: String?

    // MARK: - Relationship

    /// 1 = OTHER, 2 = KANOJO, 3 = FRIEND
    var relationStatus: Int
    var loveGauge: Int
    var followerCount: Int
    var likeRate: Int
    var votedLike: Bool
    /// Married flag (0 or 1)
    var mascotEnabled: Int
    var emotionStatus: Int

    // MARK: - State

    var inRoom: Bool
    var onDate: Bool
    var dateLocation: String?

    // MARK: - Birthday

    var birthDay: Int
    var birthMonth: Int
    var birthYear: Int

    // MARK: - Location

    /// Geo coordinates as comma-separated "lat,lng" string.
    /// Server may send as string or as {"lat":..., "lng":...} object.
    var geo: String?
    var location: String?
    /// Location where the kanojo was spawned
    var nationality: String?

    // MARK: - Visual Attributes (14 part types)

    var accessoryType: Int
    var bodyType: Int
    var browType: Int
    var clothesType: Int
    var earType: Int
    var eyeType: Int
    var faceType: Int
    var fringeType: Int
    var glassesType: Int
    var hairType: Int
    var mouthType: Int
    var noseType: Int
    var raceType: Int
    var spotType: Int

    // MARK: - Colors

    var eyeColor: Int
    var hairColor: Int
    var skinColor: Int

    // MARK: - Feature Positions

    var browPosition: Float
    var eyePosition: Float
    var mouthPosition: Float

    // MARK: - Chart Stats (radar chart)

    /// The text label in the chart dropdown
    var status: String?
    var flirtable: Int
    var consumption: Int
    var possession: Int
    var recognition: Int
    var sexual: Int

    // MARK: - Computed Properties

    var profileImageIconURL: String {
        "/profile_images/kanojo/\(id)/icon.png"
    }

    var profileImageBustURL: String {
        "/profile_images/kanojo/\(id)/bust.png"
    }

    var profileImageURL: String {
        "/profile_images/kanojo/\(id)/full.png"
    }

    var relation: RelationStatus? {
        RelationStatus(rawValue: relationStatus)
    }

    /// Parse geo "lat,lng" string into a CLLocationCoordinate2D.
    var geoCoordinate: CLLocationCoordinate2D? {
        guard let geo else { return nil }
        let parts = geo.split(separator: ",")
        guard parts.count == 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lng = Double(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    // MARK: - Default Initializer

    init(
        id: Int = 0,
        name: String? = nil,
        barcode: String? = nil,
        relationStatus: Int = 0,
        loveGauge: Int = 0,
        followerCount: Int = 0,
        likeRate: Int = 0,
        votedLike: Bool = false,
        mascotEnabled: Int = 0,
        emotionStatus: Int = 0,
        inRoom: Bool = true,
        onDate: Bool = false,
        dateLocation: String? = nil,
        birthDay: Int = 0,
        birthMonth: Int = 0,
        birthYear: Int = 0,
        geo: String? = nil,
        location: String? = nil,
        nationality: String? = nil,
        accessoryType: Int = 0,
        bodyType: Int = 0,
        browType: Int = 0,
        clothesType: Int = 0,
        earType: Int = 0,
        eyeType: Int = 0,
        faceType: Int = 0,
        fringeType: Int = 0,
        glassesType: Int = 0,
        hairType: Int = 0,
        mouthType: Int = 0,
        noseType: Int = 0,
        raceType: Int = 0,
        spotType: Int = 0,
        eyeColor: Int = 0,
        hairColor: Int = 0,
        skinColor: Int = 0,
        browPosition: Float = 0,
        eyePosition: Float = 0,
        mouthPosition: Float = 0,
        status: String? = nil,
        flirtable: Int = 0,
        consumption: Int = 0,
        possession: Int = 0,
        recognition: Int = 0,
        sexual: Int = 0
    ) {
        self.id = id
        self.name = name
        self.barcode = barcode
        self.relationStatus = relationStatus
        self.loveGauge = loveGauge
        self.followerCount = followerCount
        self.likeRate = likeRate
        self.votedLike = votedLike
        self.mascotEnabled = mascotEnabled
        self.emotionStatus = emotionStatus
        self.inRoom = inRoom
        self.onDate = onDate
        self.dateLocation = dateLocation
        self.birthDay = birthDay
        self.birthMonth = birthMonth
        self.birthYear = birthYear
        self.geo = geo
        self.location = location
        self.nationality = nationality
        self.accessoryType = accessoryType
        self.bodyType = bodyType
        self.browType = browType
        self.clothesType = clothesType
        self.earType = earType
        self.eyeType = eyeType
        self.faceType = faceType
        self.fringeType = fringeType
        self.glassesType = glassesType
        self.hairType = hairType
        self.mouthType = mouthType
        self.noseType = noseType
        self.raceType = raceType
        self.spotType = spotType
        self.eyeColor = eyeColor
        self.hairColor = hairColor
        self.skinColor = skinColor
        self.browPosition = browPosition
        self.eyePosition = eyePosition
        self.mouthPosition = mouthPosition
        self.status = status
        self.flirtable = flirtable
        self.consumption = consumption
        self.possession = possession
        self.recognition = recognition
        self.sexual = sexual
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, name, barcode
        case relationStatus = "relation_status"
        case loveGauge = "love_gauge"
        case followerCount = "follower_count"
        case likeRate = "like_rate"
        case votedLike = "voted_like"
        case mascotEnabled = "mascot_enabled"
        case emotionStatus = "emotion_status"
        case inRoom = "in_room"
        case onDate = "on_date"
        case dateLocation = "date_location"
        case birthDay = "birth_day"
        case birthMonth = "birth_month"
        case birthYear = "birth_year"
        case geo, location, nationality
        case accessoryType = "accessory_type"
        case bodyType = "body_type"
        case browType = "brow_type"
        case clothesType = "clothes_type"
        case earType = "ear_type"
        case eyeType = "eye_type"
        case faceType = "face_type"
        case fringeType = "fringe_type"
        case glassesType = "glasses_type"
        case hairType = "hair_type"
        case mouthType = "mouth_type"
        case noseType = "nose_type"
        case raceType = "race_type"
        case spotType = "spot_type"
        case eyeColor = "eye_color"
        case hairColor = "hair_color"
        case skinColor = "skin_color"
        case browPosition = "brow_position"
        case eyePosition = "eye_position"
        case mouthPosition = "mouth_position"
        case status, flirtable, consumption, possession, recognition, sexual
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)

        relationStatus = try container.decodeIfPresent(Int.self, forKey: .relationStatus) ?? 0
        loveGauge = try container.decodeIfPresent(Int.self, forKey: .loveGauge) ?? 0
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        likeRate = try container.decodeIfPresent(Int.self, forKey: .likeRate) ?? 0
        votedLike = try container.decodeIfPresent(Bool.self, forKey: .votedLike) ?? false
        mascotEnabled = try container.decodeIfPresent(Int.self, forKey: .mascotEnabled) ?? 0
        emotionStatus = try container.decodeIfPresent(Int.self, forKey: .emotionStatus) ?? 0

        inRoom = try container.decodeIfPresent(Bool.self, forKey: .inRoom) ?? true
        onDate = try container.decodeIfPresent(Bool.self, forKey: .onDate) ?? false
        dateLocation = try container.decodeIfPresent(String.self, forKey: .dateLocation)

        birthDay = try container.decodeIfPresent(Int.self, forKey: .birthDay) ?? 0
        birthMonth = try container.decodeIfPresent(Int.self, forKey: .birthMonth) ?? 0
        birthYear = try container.decodeIfPresent(Int.self, forKey: .birthYear) ?? 0

        // Geo field: handle both string "lat,lng" and object {"lat":..., "lng":...} formats
        if let geoString = try? container.decodeIfPresent(String.self, forKey: .geo) {
            geo = geoString
        } else if let geoObject = try? container.decodeIfPresent(GeoObject.self, forKey: .geo) {
            geo = "\(geoObject.lat),\(geoObject.lng)"
        } else {
            geo = nil
        }

        location = try container.decodeIfPresent(String.self, forKey: .location)
        nationality = try container.decodeIfPresent(String.self, forKey: .nationality)

        // Visual attributes
        accessoryType = try container.decodeIfPresent(Int.self, forKey: .accessoryType) ?? 0
        bodyType = try container.decodeIfPresent(Int.self, forKey: .bodyType) ?? 0
        browType = try container.decodeIfPresent(Int.self, forKey: .browType) ?? 0
        clothesType = try container.decodeIfPresent(Int.self, forKey: .clothesType) ?? 0
        earType = try container.decodeIfPresent(Int.self, forKey: .earType) ?? 0
        eyeType = try container.decodeIfPresent(Int.self, forKey: .eyeType) ?? 0
        faceType = try container.decodeIfPresent(Int.self, forKey: .faceType) ?? 0
        fringeType = try container.decodeIfPresent(Int.self, forKey: .fringeType) ?? 0
        glassesType = try container.decodeIfPresent(Int.self, forKey: .glassesType) ?? 0
        hairType = try container.decodeIfPresent(Int.self, forKey: .hairType) ?? 0
        mouthType = try container.decodeIfPresent(Int.self, forKey: .mouthType) ?? 0
        noseType = try container.decodeIfPresent(Int.self, forKey: .noseType) ?? 0
        raceType = try container.decodeIfPresent(Int.self, forKey: .raceType) ?? 0
        spotType = try container.decodeIfPresent(Int.self, forKey: .spotType) ?? 0

        // Colors
        eyeColor = try container.decodeIfPresent(Int.self, forKey: .eyeColor) ?? 0
        hairColor = try container.decodeIfPresent(Int.self, forKey: .hairColor) ?? 0
        skinColor = try container.decodeIfPresent(Int.self, forKey: .skinColor) ?? 0

        // Positions (server sends as Double, store as Float)
        browPosition = try container.decodeIfPresent(Float.self, forKey: .browPosition) ?? 0
        eyePosition = try container.decodeIfPresent(Float.self, forKey: .eyePosition) ?? 0
        mouthPosition = try container.decodeIfPresent(Float.self, forKey: .mouthPosition) ?? 0

        // Chart stats
        status = try container.decodeIfPresent(String.self, forKey: .status)
        flirtable = try container.decodeIfPresent(Int.self, forKey: .flirtable) ?? 0
        consumption = try container.decodeIfPresent(Int.self, forKey: .consumption) ?? 0
        possession = try container.decodeIfPresent(Int.self, forKey: .possession) ?? 0
        recognition = try container.decodeIfPresent(Int.self, forKey: .recognition) ?? 0
        sexual = try container.decodeIfPresent(Int.self, forKey: .sexual) ?? 0
    }
}

// MARK: - Geo Object Helper

/// Helper for decoding geo as a JSON object {"lat": ..., "lng": ...}
/// Used when the server sends geo coordinates as an object instead of a comma-separated string.
private struct GeoObject: Codable {
    let lat: Double
    let lng: Double
}
