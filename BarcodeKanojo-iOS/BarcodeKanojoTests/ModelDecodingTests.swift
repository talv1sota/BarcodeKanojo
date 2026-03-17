import XCTest
@testable import BarcodeKanojo

final class ModelDecodingTests: XCTestCase {

    // MARK: - Kanojo Decoding

    func testKanojoDecoding() throws {
        let json = """
        {
            "id": 42,
            "name": "Test Kanojo",
            "barcode": "4901234567890",
            "relation_status": 2,
            "birth_year": 2020,
            "birth_month": 6,
            "birth_day": 15,
            "love_gauge": 75,
            "follower_count": 10,
            "like_rate": 50,
            "in_room": true,
            "on_date": false,
            "voted_like": false,
            "mascot_enabled": 0,
            "emotion_status": 0,
            "eye_type": 3,
            "hair_type": 5,
            "hair_color": 12,
            "skin_color": 2,
            "eye_position": 0.5,
            "brow_position": 0.3,
            "mouth_position": -0.2,
            "flirtable": 60,
            "consumption": 40,
            "possession": 30,
            "recognition": 80,
            "sexual": 20,
            "nationality": "Japan",
            "status": "Happy",
            "geo": "35.6762,139.6503"
        }
        """.data(using: .utf8)!

        let kanojo = try JSONDecoder().decode(Kanojo.self, from: json)

        XCTAssertEqual(kanojo.id, 42)
        XCTAssertEqual(kanojo.name, "Test Kanojo")
        XCTAssertEqual(kanojo.barcode, "4901234567890")
        XCTAssertEqual(kanojo.relationStatus, 2)
        XCTAssertEqual(kanojo.loveGauge, 75)
        XCTAssertEqual(kanojo.followerCount, 10)
        XCTAssertEqual(kanojo.likeRate, 50)
        XCTAssertEqual(kanojo.inRoom, true)
        XCTAssertEqual(kanojo.onDate, false)
        XCTAssertEqual(kanojo.votedLike, false)
        XCTAssertEqual(kanojo.mascotEnabled, 0)
        XCTAssertEqual(kanojo.eyeType, 3)
        XCTAssertEqual(kanojo.hairType, 5)
        XCTAssertEqual(kanojo.hairColor, 12)
        XCTAssertEqual(kanojo.eyePosition, 0.5)
        XCTAssertEqual(kanojo.browPosition, 0.3, accuracy: 0.001)
        XCTAssertEqual(kanojo.mouthPosition, -0.2, accuracy: 0.001)
        XCTAssertEqual(kanojo.flirtable, 60)
        XCTAssertEqual(kanojo.nationality, "Japan")
        XCTAssertEqual(kanojo.geo, "35.6762,139.6503")
        XCTAssertEqual(kanojo.relation, .kanojo)
    }

    func testKanojoGeoObjectDecoding() throws {
        let json = """
        {
            "id": 1,
            "geo": {"lat": 35.6762, "lng": 139.6503}
        }
        """.data(using: .utf8)!

        let kanojo = try JSONDecoder().decode(Kanojo.self, from: json)
        XCTAssertEqual(kanojo.geo, "35.6762,139.6503")
    }

    func testKanojoMissingFieldsUseDefaults() throws {
        let json = """
        {
            "id": 1
        }
        """.data(using: .utf8)!

        let kanojo = try JSONDecoder().decode(Kanojo.self, from: json)
        XCTAssertEqual(kanojo.id, 1)
        XCTAssertNil(kanojo.name)
        XCTAssertEqual(kanojo.relationStatus, 0)
        XCTAssertEqual(kanojo.loveGauge, 0)
        XCTAssertEqual(kanojo.inRoom, true)  // default true
        XCTAssertEqual(kanojo.onDate, false)
        XCTAssertEqual(kanojo.votedLike, false)
        XCTAssertEqual(kanojo.eyeType, 0)
        XCTAssertEqual(kanojo.eyePosition, 0)
    }

    func testKanojoComputedURLs() {
        let kanojo = Kanojo(id: 42)
        XCTAssertEqual(kanojo.profileImageIconURL, "/profile_images/kanojo/42/icon.png")
        XCTAssertEqual(kanojo.profileImageBustURL, "/profile_images/kanojo/42/bust.png")
        XCTAssertEqual(kanojo.profileImageURL, "/profile_images/kanojo/42/full.png")
    }

    // MARK: - User Decoding

    func testUserDecoding() throws {
        let json = """
        {
            "id": 7,
            "name": "TestPlayer",
            "language": "en",
            "level": 5,
            "stamina": 80,
            "stamina_max": 100,
            "money": 1500,
            "kanojo_count": 3,
            "generate_count": 10,
            "scan_count": 25,
            "enemy_count": 2,
            "friend_count": 8,
            "tickets": 50,
            "relation_status": 0,
            "birth_month": 3,
            "birth_day": 14,
            "birth_year": 1995
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)

        XCTAssertEqual(user.id, 7)
        XCTAssertEqual(user.name, "TestPlayer")
        XCTAssertEqual(user.language, "en")
        XCTAssertEqual(user.level, 5)
        XCTAssertEqual(user.stamina, 80)
        XCTAssertEqual(user.staminaMax, 100)
        XCTAssertEqual(user.money, 1500)
        XCTAssertEqual(user.kanojoCount, 3)
        XCTAssertEqual(user.generateCount, 10)
        XCTAssertEqual(user.scanCount, 25)
        XCTAssertEqual(user.enemyCount, 2)
        // CRITICAL: JSON key "friend_count" maps to wishCount
        XCTAssertEqual(user.wishCount, 8)
        XCTAssertEqual(user.tickets, 50)
        XCTAssertEqual(user.birthMonth, 3)
        XCTAssertEqual(user.birthDay, 14)
        XCTAssertEqual(user.birthYear, 1995)
    }

    func testUserDefaults() throws {
        let json = """
        {"id": 1}
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        XCTAssertEqual(user.staminaMax, 100)
        XCTAssertEqual(user.birthDay, 1)
        XCTAssertEqual(user.birthMonth, 1)
        XCTAssertEqual(user.birthYear, 2000)
    }

    func testUserBirthText() {
        var user = User(birthDay: 14, birthMonth: 3, birthYear: 1995)
        XCTAssertEqual(user.birthText, "3.14.1995")

        user.birthMonth = 0
        XCTAssertEqual(user.birthText, "")
    }

    func testUserSetBirthFromText() {
        var user = User()
        user.setBirthFromText("6.15.2000")
        XCTAssertEqual(user.birthMonth, 6)
        XCTAssertEqual(user.birthDay, 15)
        XCTAssertEqual(user.birthYear, 2000)
    }

    func testUserComputedURL() {
        let user = User(id: 7)
        XCTAssertEqual(user.profileImageURL, "/profile_images/user/7.jpg")
    }

    // MARK: - Product Decoding

    func testProductDecoding() throws {
        let json = """
        {
            "barcode": "4901234567890",
            "name": "Test Product",
            "category_id": 5,
            "category": "Electronics",
            "scan_count": 42,
            "company_name": "TestCorp",
            "country": "Japan",
            "price": "500"
        }
        """.data(using: .utf8)!

        let product = try JSONDecoder().decode(Product.self, from: json)

        XCTAssertEqual(product.barcode, "4901234567890")
        XCTAssertEqual(product.name, "Test Product")
        XCTAssertEqual(product.categoryId, 5)
        XCTAssertEqual(product.scanCount, 42)
        XCTAssertEqual(product.companyName, "TestCorp")
    }

    // MARK: - KanojoItem Decoding

    func testKanojoItemExpandFlagAsInt() throws {
        let json = """
        {
            "item_id": 10,
            "item_category_id": 2,
            "item_class": 1,
            "expand_flag": 1,
            "title": "Rose Bouquet",
            "price": "100"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(KanojoItem.self, from: json)
        XCTAssertEqual(item.itemId, 10)
        XCTAssertEqual(item.itemClass, 1)
        XCTAssertTrue(item.expandFlag)
        XCTAssertEqual(item.title, "Rose Bouquet")
        XCTAssertEqual(item.id, 10)
    }

    // MARK: - Activity Decoding

    func testActivityWithNestedObjects() throws {
        let json = """
        {
            "id": 100,
            "activity_type": 2,
            "created_timestamp": 1700000000,
            "activity": "Generated a new kanojo",
            "user": {"id": 7, "name": "TestPlayer"},
            "kanojo": {"id": 42, "name": "TestKanojo"}
        }
        """.data(using: .utf8)!

        let activity = try JSONDecoder().decode(Activity.self, from: json)
        XCTAssertEqual(activity.id, 100)
        XCTAssertEqual(activity.activityType, 2)
        XCTAssertEqual(activity.type, .generated)
        XCTAssertEqual(activity.user?.id, 7)
        XCTAssertEqual(activity.kanojo?.id, 42)
        XCTAssertNil(activity.otherUser)
        XCTAssertNil(activity.product)
    }

    // MARK: - APIResponse Decoding

    func testAPIResponseVerify() throws {
        let json = """
        {
            "code": 200,
            "message": "OK",
            "user": {
                "id": 7,
                "name": "TestPlayer",
                "level": 5,
                "stamina": 80,
                "stamina_max": 100,
                "money": 1500,
                "tickets": 50,
                "friend_count": 8
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(APIResponse.self, from: json)

        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.responseCode, .success)
        XCTAssertEqual(response.message, "OK")
        XCTAssertNotNil(response.user)
        XCTAssertEqual(response.user?.id, 7)
        XCTAssertEqual(response.user?.name, "TestPlayer")
        XCTAssertEqual(response.user?.wishCount, 8)
        XCTAssertNil(response.kanojo)
    }

    func testAPIResponseError() throws {
        let json = """
        {
            "code": 401,
            "message": "Unauthorized"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(APIResponse.self, from: json)
        XCTAssertFalse(response.isSuccess)
        XCTAssertEqual(response.responseCode, .unauthorized)
    }

    // MARK: - LoveIncrement Decoding

    func testLoveIncrementDecoding() throws {
        let json = """
        {
            "increase_love": "15",
            "decrement_love": "0",
            "alertShow": "1"
        }
        """.data(using: .utf8)!

        let love = try JSONDecoder().decode(LoveIncrement.self, from: json)
        XCTAssertEqual(love.increaseLove, "15")
        XCTAssertEqual(love.decrementLove, "0")
        XCTAssertEqual(love.alertShow, "1")
    }

    // MARK: - Password Hashing

    func testPasswordHasherProducesUppercaseHex() {
        let hash = PasswordHasher.hash(password: "test", salt: "")
        // SHA-512 of "test" should be 128 hex characters (64 bytes)
        XCTAssertEqual(hash.count, 128)
        // Ensure it's all uppercase hex
        XCTAssertTrue(hash.allSatisfy { $0.isHexDigit && ($0.isUppercase || $0.isNumber) })
    }

    func testPasswordHasherConsistency() {
        let hash1 = PasswordHasher.hash(password: "myPassword", salt: "mySalt")
        let hash2 = PasswordHasher.hash(password: "myPassword", salt: "mySalt")
        XCTAssertEqual(hash1, hash2)
    }

    func testPasswordHasherDifferentSalts() {
        let hash1 = PasswordHasher.hash(password: "test", salt: "salt1")
        let hash2 = PasswordHasher.hash(password: "test", salt: "salt2")
        XCTAssertNotEqual(hash1, hash2)
    }

    func testPasswordHasherEmptySalt() {
        // Empty salt is used for login (matching Android behavior)
        let hash = PasswordHasher.hash(password: "password123")
        XCTAssertEqual(hash.count, 128)
        XCTAssertFalse(hash.isEmpty)
    }

    // MARK: - Enum Tests

    func testRelationStatus() {
        XCTAssertEqual(RelationStatus.other.rawValue, 1)
        XCTAssertEqual(RelationStatus.kanojo.rawValue, 2)
        XCTAssertEqual(RelationStatus.friend.rawValue, 3)
    }

    func testResponseCode() {
        XCTAssertEqual(ResponseCode.success.rawValue, 200)
        XCTAssertEqual(ResponseCode.unauthorized.rawValue, 401)
        XCTAssertEqual(ResponseCode.finishedConsumeTicket.rawValue, 600)
    }

    func testItemClass() {
        XCTAssertEqual(ItemClass.gift.rawValue, 1)
        XCTAssertEqual(ItemClass.date.rawValue, 2)
        XCTAssertEqual(ItemClass.ticket.rawValue, 3)
    }

    func testActivityType() {
        XCTAssertEqual(ActivityType.scan.rawValue, 1)
        XCTAssertEqual(ActivityType.generated.rawValue, 2)
        XCTAssertEqual(ActivityType.married.rawValue, 15)
        XCTAssertEqual(ActivityType.joined.rawValue, 101)
    }

    // MARK: - JSON Round-Trip

    func testKanojoRoundTrip() throws {
        let original = Kanojo(
            id: 42,
            name: "Test",
            barcode: "123456",
            relationStatus: 2,
            loveGauge: 75,
            inRoom: true,
            eyeType: 5,
            hairColor: 12,
            eyePosition: 0.5,
            flirtable: 60
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Kanojo.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testUserRoundTrip() throws {
        let original = User(
            id: 7,
            name: "TestPlayer",
            level: 5,
            stamina: 80,
            money: 1500,
            wishCount: 8,
            tickets: 50
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(User.self, from: data)

        XCTAssertEqual(original, decoded)
    }
}
