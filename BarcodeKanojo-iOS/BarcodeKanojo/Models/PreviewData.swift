import Foundation

// MARK: - Preview / Dummy Data

/// Comprehensive dummy data for SwiftUI previews and testing.
/// All data is wrapped in `#if DEBUG` to exclude from release builds.
#if DEBUG

// swiftlint:disable type_body_length file_length

enum PreviewData {

    // MARK: - Users

    static let currentUser = User(
        id: 1,
        name: "SakuraMaster",
        language: "en",
        level: 12,
        stamina: 78,
        staminaMax: 100,
        money: 5420,
        kanojoCount: 5,
        generateCount: 8,
        scanCount: 42,
        enemyCount: 2,
        wishCount: 3,
        tickets: 15,
        relationStatus: 2,
        birthDay: 15,
        birthMonth: 3,
        birthYear: 1998
    )

    static let friendUser = User(
        id: 2,
        name: "BarcodeBro",
        language: "en",
        level: 18,
        stamina: 45,
        staminaMax: 100,
        money: 12300,
        kanojoCount: 9,
        generateCount: 15,
        scanCount: 87,
        enemyCount: 4,
        wishCount: 6,
        tickets: 42,
        relationStatus: 3,
        birthDay: 22,
        birthMonth: 7,
        birthYear: 1995
    )

    static let rivalUser = User(
        id: 3,
        name: "KanojoThief",
        language: "ja",
        level: 25,
        stamina: 100,
        staminaMax: 100,
        money: 34000,
        kanojoCount: 14,
        generateCount: 20,
        scanCount: 156,
        enemyCount: 8,
        wishCount: 1,
        tickets: 99,
        relationStatus: 1,
        birthDay: 1,
        birthMonth: 1,
        birthYear: 1990
    )

    static let newbieUser = User(
        id: 4,
        name: "NewScanner",
        language: "en",
        level: 1,
        stamina: 100,
        staminaMax: 100,
        money: 200,
        kanojoCount: 1,
        generateCount: 1,
        scanCount: 3,
        enemyCount: 0,
        wishCount: 0,
        tickets: 5,
        relationStatus: 2,
        birthDay: 10,
        birthMonth: 12,
        birthYear: 2002
    )

    static let exhaustedUser = User(
        id: 5,
        name: "TiredPlayer",
        language: "en",
        level: 8,
        stamina: 0,
        staminaMax: 100,
        money: 50,
        kanojoCount: 3,
        generateCount: 5,
        scanCount: 28,
        enemyCount: 1,
        wishCount: 2,
        tickets: 0,
        relationStatus: 2,
        birthDay: 5,
        birthMonth: 9,
        birthYear: 2000
    )

    static let allUsers: [User] = [currentUser, friendUser, rivalUser, newbieUser, exhaustedUser]

    // MARK: - Kanojos

    static let ownKanojo = Kanojo(
        id: 101,
        name: "Hana",
        barcode: "4901234567890",
        relationStatus: 2, // .kanojo
        loveGauge: 72,
        followerCount: 15,
        likeRate: 80,
        votedLike: false,
        mascotEnabled: 0,
        emotionStatus: 1,
        inRoom: true,
        birthDay: 14,
        birthMonth: 2,
        birthYear: 2024,
        geo: "35.6762,139.6503",
        location: "Tokyo",
        nationality: "Japan",
        bodyType: 2,
        browType: 1,
        clothesType: 3,
        eyeType: 4,
        faceType: 1,
        fringeType: 2,
        hairType: 5,
        mouthType: 1,
        noseType: 1,
        eyeColor: 3,
        hairColor: 2,
        skinColor: 1,
        browPosition: 0.45,
        eyePosition: 0.5,
        mouthPosition: 0.7,
        flirtable: 75,
        consumption: 40,
        possession: 60,
        recognition: 85,
        sexual: 30
    )

    static let friendKanojo = Kanojo(
        id: 102,
        name: "Yuki",
        barcode: "0012345678905",
        relationStatus: 3, // .friend
        loveGauge: 55,
        followerCount: 32,
        likeRate: 92,
        votedLike: true,
        mascotEnabled: 0,
        emotionStatus: 0,
        inRoom: true,
        birthDay: 25,
        birthMonth: 12,
        birthYear: 2024,
        geo: "34.6937,135.5023",
        location: "Osaka",
        nationality: "Japan",
        bodyType: 1,
        browType: 2,
        clothesType: 5,
        eyeType: 2,
        faceType: 2,
        fringeType: 4,
        hairType: 3,
        mouthType: 2,
        noseType: 2,
        eyeColor: 1,
        hairColor: 5,
        skinColor: 1,
        browPosition: 0.4,
        eyePosition: 0.52,
        mouthPosition: 0.68,
        flirtable: 90,
        consumption: 55,
        possession: 20,
        recognition: 70,
        sexual: 45
    )

    static let otherKanojo = Kanojo(
        id: 103,
        name: "Miku",
        barcode: "5901234123457",
        relationStatus: 1, // .other
        loveGauge: 88,
        followerCount: 128,
        likeRate: 96,
        votedLike: false,
        mascotEnabled: 1,
        emotionStatus: 2,
        inRoom: true,
        birthDay: 8,
        birthMonth: 8,
        birthYear: 2024,
        geo: "35.0116,135.7681",
        location: "Kyoto",
        nationality: "Japan",
        bodyType: 3,
        browType: 1,
        clothesType: 7,
        eyeType: 6,
        faceType: 3,
        fringeType: 1,
        hairType: 8,
        mouthType: 3,
        noseType: 1,
        eyeColor: 5,
        hairColor: 7,
        skinColor: 1,
        browPosition: 0.42,
        eyePosition: 0.48,
        mouthPosition: 0.72,
        flirtable: 95,
        consumption: 80,
        possession: 90,
        recognition: 95,
        sexual: 70
    )

    static let lowLoveKanojo = Kanojo(
        id: 104,
        name: "Rin",
        barcode: "8801234567893",
        relationStatus: 2,
        loveGauge: 12,
        followerCount: 2,
        likeRate: 45,
        votedLike: false,
        birthDay: 3,
        birthMonth: 5,
        birthYear: 2025,
        geo: "43.0618,141.3545",
        location: "Sapporo",
        nationality: "Japan",
        bodyType: 1,
        eyeType: 3,
        hairType: 2,
        eyeColor: 2,
        hairColor: 1,
        skinColor: 1,
        flirtable: 25,
        consumption: 15,
        possession: 30,
        recognition: 20,
        sexual: 10
    )

    static let maxLoveKanojo = Kanojo(
        id: 105,
        name: "Sakura",
        barcode: "4512345678901",
        relationStatus: 2,
        loveGauge: 100,
        followerCount: 256,
        likeRate: 99,
        votedLike: true,
        mascotEnabled: 1,
        birthDay: 1,
        birthMonth: 4,
        birthYear: 2024,
        geo: "33.5904,130.4017",
        location: "Fukuoka",
        nationality: "Japan",
        bodyType: 2,
        browType: 3,
        clothesType: 10,
        eyeType: 1,
        faceType: 1,
        fringeType: 5,
        hairType: 1,
        mouthType: 1,
        noseType: 1,
        eyeColor: 4,
        hairColor: 3,
        skinColor: 1,
        browPosition: 0.5,
        eyePosition: 0.5,
        mouthPosition: 0.65,
        flirtable: 100,
        consumption: 90,
        possession: 100,
        recognition: 100,
        sexual: 85
    )

    /// Kanojo with no geo data (won't appear on map).
    static let noGeoKanojo = Kanojo(
        id: 106,
        name: "Aoi",
        barcode: "6291234567895",
        relationStatus: 2,
        loveGauge: 45,
        followerCount: 7,
        likeRate: 60,
        birthDay: 20,
        birthMonth: 6,
        birthYear: 2025,
        nationality: "Japan",
        bodyType: 1,
        eyeType: 5,
        hairType: 4,
        eyeColor: 1,
        hairColor: 4,
        skinColor: 1,
        flirtable: 50,
        consumption: 50,
        possession: 50,
        recognition: 50,
        sexual: 50
    )

    static let allKanojos: [Kanojo] = [ownKanojo, friendKanojo, otherKanojo, lowLoveKanojo, maxLoveKanojo, noGeoKanojo]
    static let ownKanojos: [Kanojo] = [ownKanojo, lowLoveKanojo, maxLoveKanojo, noGeoKanojo]
    static let friendKanojos: [Kanojo] = [friendKanojo]
    static let rankingKanojos: [Kanojo] = [otherKanojo, maxLoveKanojo, friendKanojo, ownKanojo]

    // MARK: - Products

    static let cocaCola = Product(
        barcode: "4901234567890",
        name: "Coca-Cola 500ml",
        categoryId: 3,
        category: "Beverages",
        comment: "Classic cola drink",
        location: "Tokyo, Japan",
        geo: "35.6762,139.6503",
        scanCount: 142,
        companyName: "The Coca-Cola Company",
        country: "Japan",
        price: "150"
    )

    static let kitKat = Product(
        barcode: "0012345678905",
        name: "Kit Kat Matcha",
        categoryId: 5,
        category: "Snacks",
        comment: "Green tea flavored Kit Kat",
        location: "Osaka, Japan",
        geo: "34.6937,135.5023",
        scanCount: 87,
        companyName: "Nestle Japan",
        country: "Japan",
        price: "200"
    )

    static let pocky = Product(
        barcode: "5901234123457",
        name: "Pocky Chocolate",
        categoryId: 5,
        category: "Snacks",
        comment: "Chocolate-coated biscuit sticks",
        location: "Kyoto, Japan",
        geo: "35.0116,135.7681",
        scanCount: 203,
        companyName: "Glico",
        country: "Japan",
        price: "120"
    )

    static let onigiri = Product(
        barcode: "8801234567893",
        name: "Salmon Onigiri",
        categoryId: 7,
        category: "Prepared Food",
        comment: "Rice ball with salmon filling",
        location: "Sapporo, Japan",
        geo: "43.0618,141.3545",
        scanCount: 56,
        companyName: "7-Eleven Japan",
        country: "Japan",
        price: "130"
    )

    static let ramune = Product(
        barcode: "4512345678901",
        name: "Ramune Soda",
        categoryId: 3,
        category: "Beverages",
        comment: "Classic marble soda",
        location: "Fukuoka, Japan",
        geo: "33.5904,130.4017",
        scanCount: 312,
        companyName: "Sangaria",
        country: "Japan",
        price: "180"
    )

    static let allProducts: [Product] = [cocaCola, kitKat, pocky, onigiri, ramune]

    // MARK: - Scan History

    static let popularScanHistory = ScanHistory(
        barcode: "4901234567890",
        totalCount: 142,
        kanojoCount: 42,
        friendCount: 15
    )

    static let freshScanHistory = ScanHistory(
        barcode: "0012345678905",
        totalCount: 3,
        kanojoCount: 1,
        friendCount: 0
    )

    static let viralScanHistory = ScanHistory(
        barcode: "5901234123457",
        totalCount: 999,
        kanojoCount: 203,
        friendCount: 88
    )

    // MARK: - Scan Results (for ScanResultView)

    static let ownScanResult = ScanViewModel.ScanResult(
        kanojo: ownKanojo,
        product: cocaCola,
        ownerUser: currentUser,
        scanHistory: popularScanHistory
    )

    static let friendScanResult = ScanViewModel.ScanResult(
        kanojo: friendKanojo,
        product: kitKat,
        ownerUser: friendUser,
        scanHistory: freshScanHistory
    )

    static let otherScanResult = ScanViewModel.ScanResult(
        kanojo: otherKanojo,
        product: pocky,
        ownerUser: rivalUser,
        scanHistory: viralScanHistory
    )

    // MARK: - Love Increments

    static let smallLoveUp = LoveIncrement(increaseLove: "3", decrementLove: "0", alertShow: "0")
    static let bigLoveUp = LoveIncrement(increaseLove: "15", decrementLove: "0", alertShow: "0")
    static let loveDown = LoveIncrement(increaseLove: "0", decrementLove: "5", alertShow: "1")
    static let noLoveChange = LoveIncrement(increaseLove: "0", decrementLove: "0", alertShow: "0")

    // MARK: - Kanojo Messages

    static let happyMessages = KanojoMessage(messages: [
        "I'm so happy you came to visit!",
        "Let's spend more time together today~",
        "You always know how to make me smile!"
    ])

    static let shyMessages = KanojoMessage(messages: [
        "Oh... you're here again...",
        "I-It's not like I was waiting for you or anything!"
    ])

    static let greetingMessages = KanojoMessage(messages: [
        "Good morning! Did you sleep well?"
    ])

    static let dateMessages = KanojoMessage(messages: [
        "That was such a wonderful date!",
        "Can we go again sometime?",
        "I had so much fun with you~"
    ])

    static let giftMessages = KanojoMessage(messages: [
        "A present? For me?!",
        "Thank you so much! I love it!"
    ])

    // MARK: - Items (Date)

    static let dateItems: [KanojoItem] = [
        KanojoItem(
            itemId: 201,
            itemCategoryId: 1,
            itemClass: 2,
            title: "Walk in the Park",
            description: "A relaxing stroll through the cherry blossom park.",
            imageThumbnailURL: "/items/thumbnails/date_park.png",
            imageURL: "/items/date_park.png",
            price: "100"
        ),
        KanojoItem(
            itemId: 202,
            itemCategoryId: 1,
            itemClass: 2,
            title: "Movie Date",
            description: "Watch the latest blockbuster together.",
            imageThumbnailURL: "/items/thumbnails/date_movie.png",
            imageURL: "/items/date_movie.png",
            price: "200"
        ),
        KanojoItem(
            itemId: 203,
            itemCategoryId: 1,
            itemClass: 2,
            title: "Fancy Dinner",
            description: "A candlelit dinner at an upscale restaurant.",
            imageThumbnailURL: "/items/thumbnails/date_dinner.png",
            imageURL: "/items/date_dinner.png",
            price: "500"
        ),
        KanojoItem(
            itemId: 204,
            itemCategoryId: 1,
            itemClass: 2,
            title: "Beach Trip",
            description: "Spend the day at the beach together.",
            imageThumbnailURL: "/items/thumbnails/date_beach.png",
            imageURL: "/items/date_beach.png",
            price: "350"
        ),
        KanojoItem(
            itemId: 205,
            itemCategoryId: 2,
            itemClass: 2,
            title: "Amusement Park",
            description: "Ride roller coasters and eat cotton candy!",
            imageThumbnailURL: "/items/thumbnails/date_amusement.png",
            imageURL: "/items/date_amusement.png",
            price: "800"
        )
    ]

    // MARK: - Items (Gift)

    static let giftItems: [KanojoItem] = [
        KanojoItem(
            itemId: 301,
            itemCategoryId: 10,
            itemClass: 1,
            title: "Red Rose",
            description: "A single beautiful red rose.",
            imageThumbnailURL: "/items/thumbnails/gift_rose.png",
            imageURL: "/items/gift_rose.png",
            price: "50",
            confirmUseMessage: "Give the rose to your kanojo?"
        ),
        KanojoItem(
            itemId: 302,
            itemCategoryId: 10,
            itemClass: 1,
            title: "Teddy Bear",
            description: "A cute and cuddly teddy bear.",
            imageThumbnailURL: "/items/thumbnails/gift_teddy.png",
            imageURL: "/items/gift_teddy.png",
            price: "150",
            confirmUseMessage: "Give the teddy bear?"
        ),
        KanojoItem(
            itemId: 303,
            itemCategoryId: 10,
            itemClass: 1,
            title: "Necklace",
            description: "An elegant silver necklace with a heart pendant.",
            imageThumbnailURL: "/items/thumbnails/gift_necklace.png",
            imageURL: "/items/gift_necklace.png",
            price: "400",
            confirmUseMessage: "Give the necklace?"
        ),
        KanojoItem(
            itemId: 304,
            itemCategoryId: 11,
            itemClass: 1,
            title: "Chocolate Box",
            description: "A box of premium Belgian chocolates.",
            imageThumbnailURL: "/items/thumbnails/gift_chocolate.png",
            imageURL: "/items/gift_chocolate.png",
            price: "200"
        ),
        KanojoItem(
            itemId: 305,
            itemCategoryId: 11,
            itemClass: 1,
            title: "Perfume",
            description: "A luxurious French perfume with floral notes.",
            imageThumbnailURL: "/items/thumbnails/gift_perfume.png",
            imageURL: "/items/gift_perfume.png",
            price: "600"
        ),
        KanojoItem(
            itemId: 306,
            itemCategoryId: 11,
            itemClass: 1,
            title: "Diamond Ring",
            description: "A dazzling diamond engagement ring.",
            imageThumbnailURL: "/items/thumbnails/gift_ring.png",
            imageURL: "/items/gift_ring.png",
            price: "2000",
            purchasableLevel: "10"
        )
    ]

    // MARK: - Items (Owned)

    static let ownedItems: [KanojoItem] = [
        KanojoItem(
            itemId: 301,
            itemCategoryId: 10,
            itemClass: 1,
            title: "Red Rose",
            description: "A single beautiful red rose.",
            imageThumbnailURL: "/items/thumbnails/gift_rose.png",
            price: "50",
            hasUnits: "3"
        ),
        KanojoItem(
            itemId: 304,
            itemCategoryId: 11,
            itemClass: 1,
            title: "Chocolate Box",
            description: "A box of premium Belgian chocolates.",
            imageThumbnailURL: "/items/thumbnails/gift_chocolate.png",
            price: "200",
            hasUnits: "1"
        )
    ]

    // MARK: - Items (Ticket Shop)

    static let ticketItems: [KanojoItem] = [
        KanojoItem(
            itemId: 401,
            itemCategoryId: 20,
            itemClass: 3,
            title: "Stamina Refill",
            description: "Fully restore your stamina.",
            imageThumbnailURL: "/items/thumbnails/ticket_stamina.png",
            price: "5",
            confirmPurchaseMessage: "Spend 5 tickets to restore stamina?"
        ),
        KanojoItem(
            itemId: 402,
            itemCategoryId: 20,
            itemClass: 3,
            title: "Love Booster",
            description: "Double love gain from dates for 1 hour.",
            imageThumbnailURL: "/items/thumbnails/ticket_love.png",
            price: "10",
            confirmPurchaseMessage: "Spend 10 tickets for a love booster?"
        ),
        KanojoItem(
            itemId: 403,
            itemCategoryId: 21,
            itemClass: 3,
            title: "Extra Scan Slot",
            description: "Increase your maximum kanojo count by 1.",
            imageThumbnailURL: "/items/thumbnails/ticket_slot.png",
            price: "25",
            confirmPurchaseMessage: "Spend 25 tickets for an extra slot?"
        ),
        KanojoItem(
            itemId: 404,
            itemCategoryId: 21,
            itemClass: 3,
            title: "Name Change Token",
            description: "Change your kanojo's name once.",
            imageThumbnailURL: "/items/thumbnails/ticket_rename.png",
            price: "15",
            confirmPurchaseMessage: "Spend 15 tickets?"
        )
    ]

    // MARK: - Item Categories

    static let dateCategories: [KanojoItemCategory] = [
        KanojoItemCategory(categoryId: 1, title: "Casual Dates", items: Array(dateItems.prefix(4))),
        KanojoItemCategory(categoryId: 2, title: "Premium Dates", items: Array(dateItems.suffix(1)))
    ]

    static let giftCategories: [KanojoItemCategory] = [
        KanojoItemCategory(categoryId: 10, title: "Romantic", items: Array(giftItems.prefix(3))),
        KanojoItemCategory(categoryId: 11, title: "Luxury", items: Array(giftItems.suffix(3)))
    ]

    static let ownedCategories: [KanojoItemCategory] = [
        KanojoItemCategory(categoryId: 10, title: "Romantic", items: [ownedItems[0]]),
        KanojoItemCategory(categoryId: 11, title: "Luxury", items: [ownedItems[1]])
    ]

    static let ticketCategories: [KanojoItemCategory] = [
        KanojoItemCategory(categoryId: 20, title: "Consumables", items: Array(ticketItems.prefix(2))),
        KanojoItemCategory(categoryId: 21, title: "Permanent", items: Array(ticketItems.suffix(2)))
    ]

    // MARK: - Activities

    /// Current Unix timestamp (approximately).
    private static let now = Int(Date().timeIntervalSince1970)

    static let scanActivity = Activity(
        id: 1001,
        activityType: ActivityType.scan.rawValue,
        createdTimestamp: now - 300, // 5 min ago
        activity: "scanned a barcode",
        user: currentUser,
        kanojo: ownKanojo,
        product: cocaCola
    )

    static let generateActivity = Activity(
        id: 1002,
        activityType: ActivityType.generated.rawValue,
        createdTimestamp: now - 3600, // 1 hour ago
        activity: "generated a new kanojo",
        user: currentUser,
        kanojo: lowLoveKanojo,
        product: onigiri
    )

    static let friendAddActivity = Activity(
        id: 1003,
        activityType: ActivityType.meAddFriend.rawValue,
        createdTimestamp: now - 7200, // 2 hours ago
        activity: "added as a friend",
        user: currentUser,
        otherUser: friendUser,
        kanojo: friendKanojo
    )

    static let stolenByMeActivity = Activity(
        id: 1004,
        activityType: ActivityType.meStolenKanojo.rawValue,
        createdTimestamp: now - 14400, // 4 hours ago
        activity: "stole a kanojo",
        user: currentUser,
        otherUser: rivalUser,
        kanojo: otherKanojo
    )

    static let myStolenActivity = Activity(
        id: 1005,
        activityType: ActivityType.myKanojoStolen.rawValue,
        createdTimestamp: now - 28800, // 8 hours ago
        activity: "had their kanojo stolen",
        user: rivalUser,
        otherUser: currentUser,
        kanojo: lowLoveKanojo
    )

    static let levelUpActivity = Activity(
        id: 1006,
        activityType: ActivityType.becomeNewLevel.rawValue,
        createdTimestamp: now - 43200, // 12 hours ago
        activity: "reached level 12",
        user: currentUser
    )

    static let marriedActivity = Activity(
        id: 1007,
        activityType: ActivityType.married.rawValue,
        createdTimestamp: now - 86400, // 1 day ago
        activity: "married a kanojo",
        user: currentUser,
        kanojo: maxLoveKanojo
    )

    static let joinedActivity = Activity(
        id: 1008,
        activityType: ActivityType.joined.rawValue,
        createdTimestamp: now - 172800, // 2 days ago
        activity: "joined Barcode Kanojo",
        user: newbieUser
    )

    static let approachActivity = Activity(
        id: 1009,
        activityType: ActivityType.approachKanojo.rawValue,
        createdTimestamp: now - 1800, // 30 min ago
        activity: "approached a kanojo",
        user: friendUser,
        kanojo: ownKanojo
    )

    static let breakupActivity = Activity(
        id: 1010,
        activityType: ActivityType.breakup.rawValue,
        createdTimestamp: now - 259200, // 3 days ago
        activity: "broke up with a kanojo",
        user: rivalUser,
        kanojo: noGeoKanojo
    )

    static let enemyActivity = Activity(
        id: 1011,
        activityType: ActivityType.addAsEnemy.rawValue,
        createdTimestamp: now - 10800, // 3 hours ago
        activity: "added as an enemy",
        user: currentUser,
        otherUser: rivalUser
    )

    static let friendKanojoAddedActivity = Activity(
        id: 1012,
        activityType: ActivityType.myKanojoAddedToFriends.rawValue,
        createdTimestamp: now - 21600, // 6 hours ago
        activity: "kanojo was added to friends",
        user: friendUser,
        kanojo: friendKanojo
    )

    static let allActivities: [Activity] = [
        scanActivity,
        approachActivity,
        generateActivity,
        friendAddActivity,
        enemyActivity,
        stolenByMeActivity,
        myStolenActivity,
        friendKanojoAddedActivity,
        levelUpActivity,
        marriedActivity,
        joinedActivity,
        breakupActivity
    ]

    /// Just the enemy-related activities (for EnemyBookView previews).
    static let enemyActivities: [Activity] = [
        stolenByMeActivity,
        myStolenActivity,
        enemyActivity
    ]

    /// Timeline suitable for the dashboard (mixed activity types).
    static let dashboardTimeline: [Activity] = Array(allActivities.prefix(8))
}

// swiftlint:enable type_body_length file_length

#endif
