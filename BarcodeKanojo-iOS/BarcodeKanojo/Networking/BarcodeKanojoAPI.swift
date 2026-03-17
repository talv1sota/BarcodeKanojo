import Foundation

/// High-level API client — all 46+ server endpoints.
/// Each method fetches raw data via HTTPClient and decodes into APIResponse.
/// Source: BarcodeKanojoHttpApi.kt
@MainActor
final class BarcodeKanojoAPI: ObservableObject {

    static let shared = BarcodeKanojoAPI()

    private let http: HTTPClient

    init(http: HTTPClient = HTTPClient()) {
        self.http = http
    }

    // MARK: - Decode Helper

    private func fetch(_ path: String, params: [String: String?] = [:]) async throws -> APIResponse {
        let data = try await http.get(path: path, params: params)
        return try http.decode(APIResponse.self, from: data)
    }

    private func submit(_ path: String, params: [String: String?] = [:]) async throws -> APIResponse {
        let data = try await http.post(path: path, params: params)
        return try http.decode(APIResponse.self, from: data)
    }

    private func upload(_ path: String, fields: [String: String?] = [:], files: [String: Data] = [:]) async throws -> APIResponse {
        let data = try await http.multipart(path: path, fields: fields, files: files)
        return try http.decode(APIResponse.self, from: data)
    }

    // MARK: - Account

    /// Sign up new account with profile image.
    func signup(
        uuid: String,
        name: String?,
        passwordHash: String,
        email: String,
        birthYear: Int?,
        birthMonth: Int?,
        birthDay: Int?,
        sex: String?,
        profileImageData: Data? = nil
    ) async throws -> APIResponse {
        var files: [String: Data] = [:]
        if let img = profileImageData { files["profile_image_data"] = img }
        return try await upload(
            Constants.API.accountSignup,
            fields: [
                "uuid": uuid,
                "name": name,
                "password": passwordHash,
                "email": email,
                "birth_year": birthYear.map(String.init),
                "birth_month": birthMonth.map(String.init),
                "birth_day": birthDay.map(String.init),
                "sex": sex
            ],
            files: files
        )
    }

    /// Login with email + hashed password.
    func verify(uuid: String, email: String, passwordHash: String) async throws -> APIResponse {
        return try await submit(
            Constants.API.accountVerify,
            params: [
                "uuid": uuid,
                "email": email,
                "password": passwordHash,
                "language": Locale.current.identifier
            ]
        )
    }

    /// UUID-only auto-login (used on launch if no email/password saved).
    func uuidVerify(uuid: String) async throws -> APIResponse {
        return try await submit(
            Constants.API.accountUUIDVerify,
            params: ["uuid": uuid]
        )
    }

    /// Fetch current user account info.
    func accountShow() async throws -> APIResponse {
        return try await fetch(Constants.API.accountShow)
    }

    /// Update account profile.
    func accountUpdate(
        name: String?,
        currentPasswordHash: String?,
        newPasswordHash: String?,
        email: String?,
        birthYear: Int,
        birthMonth: Int,
        birthDay: Int,
        sex: String?,
        profileImageData: Data? = nil
    ) async throws -> APIResponse {
        var files: [String: Data] = [:]
        if let img = profileImageData { files["profile_image_data"] = img }
        return try await upload(
            Constants.API.accountUpdate,
            fields: [
                "name": name,
                "current_password": currentPasswordHash,
                "new_password": newPasswordHash,
                "email": email,
                "birth_year": String(birthYear),
                "birth_month": String(birthMonth),
                "birth_day": String(birthDay),
                "sex": sex
            ],
            files: files
        )
    }

    /// Delete account.
    func accountDelete(userId: Int) async throws -> APIResponse {
        return try await submit(Constants.API.accountDelete, params: ["user_id": String(userId)])
    }

    // MARK: - Kanojos

    /// Fetch user's kanojos with optional search and pagination.
    func currentKanojos(userId: Int, index: Int = 0, limit: Int = 20, search: String? = nil) async throws -> APIResponse {
        return try await fetch(
            Constants.API.userCurrentKanojos,
            params: [
                "user_id": String(userId),
                "index": String(index),
                "limit": String(limit),
                "search": search
            ]
        )
    }

    /// Fetch friend's kanojos.
    func friendKanojos(userId: Int, index: Int = 0, limit: Int = 20, search: String? = nil) async throws -> APIResponse {
        return try await fetch(
            Constants.API.userFriendKanojos,
            params: [
                "user_id": String(userId),
                "index": String(index),
                "limit": String(limit),
                "search": search
            ]
        )
    }

    /// Fetch like ranking kanojos.
    func likeRanking(index: Int = 0, limit: Int = 20) async throws -> APIResponse {
        return try await fetch(
            Constants.API.kanojoLikeRanking,
            params: ["index": String(index), "limit": String(limit)]
        )
    }

    /// Fetch individual kanojo details.
    /// - Parameter screen: Pass true to include Live2D data.
    func kanojoShow(kanojoId: Int, screen: Bool = false) async throws -> APIResponse {
        return try await fetch(
            Constants.API.kanojoShow,
            params: [
                "kanojo_id": String(kanojoId),
                "screen": screen ? "live2d" : nil
            ]
        )
    }

    /// Vote like/unlike for a kanojo.
    func voteLike(kanojoId: Int, like: Bool) async throws -> APIResponse {
        return try await submit(
            Constants.API.kanojoVoteLike,
            params: ["kanojo_id": String(kanojoId), "like": String(like)]
        )
    }

    // MARK: - Barcode / Scanning

    /// Query if a barcode already has a kanojo.
    func barcodeQuery(barcode: String, format: String, extension ext: String) async throws -> APIResponse {
        return try await fetch(
            Constants.API.barcodeQuery,
            params: ["barcode": barcode, "format": format, "extension": ext]
        )
    }

    /// Record a scan (for an existing barcode).
    func barcodeScan(
        barcode: String,
        companyName: String?,
        productName: String?,
        productCategoryId: Int,
        productComment: String?,
        productImageData: Data? = nil,
        productGeo: String? = nil
    ) async throws -> APIResponse {
        var files: [String: Data] = [:]
        if let img = productImageData { files["product_image_data"] = img }
        return try await upload(
            Constants.API.barcodeScan,
            fields: [
                "barcode": barcode,
                "company_name": companyName,
                "product_name": productName,
                "product_category_id": String(productCategoryId),
                "product_comment": productComment,
                "product_geo": productGeo
            ],
            files: files
        )
    }

    /// Scan and generate a new kanojo for a new barcode.
    func barcodeScanAndGenerate(
        barcode: String?,
        companyName: String?,
        kanojoName: String?,
        kanojoProfileImageData: Data? = nil,
        productName: String?,
        productCategoryId: Int,
        productComment: String?,
        productImageData: Data? = nil,
        productGeo: String? = nil
    ) async throws -> APIResponse {
        var files: [String: Data] = [:]
        if let img = kanojoProfileImageData { files["kanojo_profile_image_data"] = img }
        if let img = productImageData { files["product_image_data"] = img }
        return try await upload(
            Constants.API.barcodeScanAndGenerate,
            fields: [
                "barcode": barcode,
                "company_name": companyName,
                "kanojo_name": kanojoName,
                "product_name": productName,
                "product_category_id": String(productCategoryId),
                "product_comment": productComment,
                "product_geo": productGeo
            ],
            files: files
        )
    }

    /// Decrease the remaining generation count for a barcode.
    func decreaseGenerating(barcode: String?) async throws -> APIResponse {
        return try await fetch(Constants.API.barcodeDecreaseGenerating, params: ["barcode": barcode])
    }

    /// Update product info for a barcode.
    func barcodeUpdate(
        barcode: String?,
        companyName: String?,
        productName: String?,
        productCategoryId: Int,
        productComment: String?,
        productImageData: Data? = nil,
        productGeo: String? = nil
    ) async throws -> APIResponse {
        var files: [String: Data] = [:]
        if let img = productImageData { files["product_image_data"] = img }
        return try await upload(
            Constants.API.barcodeUpdate,
            fields: [
                "barcode": barcode,
                "company_name": companyName,
                "product_name": productName,
                "product_category_id": String(productCategoryId),
                "product_comment": productComment,
                "product_geo": productGeo
            ],
            files: files
        )
    }

    // MARK: - Communication (Dating / Gifting)

    /// Fetch gift menu for a kanojo.
    func giftMenu(kanojoId: Int, typeId: Int = 0) async throws -> APIResponse {
        return try await fetch(
            Constants.API.communicationGiftMenu,
            params: ["kanojo_id": String(kanojoId), "type_id": String(typeId)]
        )
    }

    /// Fetch date menu for a kanojo.
    func dateMenu(kanojoId: Int, typeId: Int = 0) async throws -> APIResponse {
        return try await fetch(
            Constants.API.communicationDateMenu,
            params: ["kanojo_id": String(kanojoId), "type_id": String(typeId)]
        )
    }

    /// Fetch permanent items menu.
    func permanentItems(itemClass: Int, itemCategoryId: Int) async throws -> APIResponse {
        return try await fetch(
            Constants.API.communicationPermanentItems,
            params: ["item_class": String(itemClass), "item_category_id": String(itemCategoryId)]
        )
    }

    /// Fetch permanent sub-items.
    func permanentSubItem(itemClass: Int, itemCategoryId: Int) async throws -> APIResponse {
        return try await fetch(
            Constants.API.communicationPermanentSubItem,
            params: ["item_class": String(itemClass), "item_category_id": String(itemCategoryId)]
        )
    }

    /// Check if user has items in a category.
    func hasItems(itemClass: Int, itemCategoryId: Int) async throws -> APIResponse {
        return try await fetch(
            Constants.API.communicationHasItems,
            params: ["item_class": String(itemClass), "item_category_id": String(itemCategoryId)]
        )
    }

    /// Fetch store items (time-of-day filtered).
    func storeItems(itemClass: Int, itemCategoryId: Int) async throws -> APIResponse {
        return try await fetch(
            Constants.API.communicationStoreItems,
            params: [
                "item_class": String(itemClass),
                "item_category_id": String(itemCategoryId),
                "pod": String(partOfDay())
            ]
        )
    }

    /// Go on a date.
    func doDate(kanojoId: Int, basicItemId: Int) async throws -> APIResponse {
        return try await submit(
            Constants.API.communicationDoDate,
            params: [
                "kanojo_id": String(kanojoId),
                "basic_item_id": String(basicItemId),
                "pod": String(partOfDay())
            ]
        )
    }

    /// Extend a date.
    func doExtendDate(kanojoId: Int, extendItemId: Int) async throws -> APIResponse {
        return try await submit(
            Constants.API.communicationDoExtendDate,
            params: [
                "kanojo_id": String(kanojoId),
                "extend_item_id": String(extendItemId),
                "pod": String(partOfDay())
            ]
        )
    }

    /// Give a gift.
    func doGift(kanojoId: Int, basicItemId: Int) async throws -> APIResponse {
        return try await submit(
            Constants.API.communicationDoGift,
            params: [
                "kanojo_id": String(kanojoId),
                "basic_item_id": String(basicItemId),
                "pod": String(partOfDay())
            ]
        )
    }

    /// Extend a gift interaction.
    func doExtendGift(kanojoId: Int, extendItemId: Int) async throws -> APIResponse {
        return try await submit(
            Constants.API.communicationDoExtendGift,
            params: [
                "kanojo_id": String(kanojoId),
                "extend_item_id": String(extendItemId),
                "pod": String(partOfDay())
            ]
        )
    }

    /// Trigger Live2D reaction.
    func playOnLive2d(kanojoId: Int, actions: String?) async throws -> APIResponse {
        return try await submit(
            Constants.API.communicationPlayOnLive2d,
            params: [
                "kanojo_id": String(kanojoId),
                "actions": actions,
                "pod": String(partOfDay())
            ]
        )
    }

    // MARK: - Activity / Timeline

    /// Fetch user activity timeline.
    func userTimeline(userId: Int, sinceId: Int = 0, index: Int = 0, limit: Int = 20) async throws -> APIResponse {
        return try await fetch(
            Constants.API.activityUserTimeline,
            params: [
                "user_id": String(userId),
                "since_id": String(sinceId),
                "index": String(index),
                "limit": String(limit)
            ]
        )
    }

    /// Fetch scanned barcode timeline.
    func scannedTimeline(barcode: String?, sinceId: Int = 0, index: Int = 0, limit: Int = 20) async throws -> APIResponse {
        return try await fetch(
            Constants.API.activityScannedTimeline,
            params: [
                "barcode": barcode,
                "since_id": String(sinceId),
                "index": String(index),
                "limit": String(limit)
            ]
        )
    }

    /// Fetch kanojo activity timeline.
    func kanojoTimeline(kanojoId: Int, index: Int = 0, limit: Int = 20) async throws -> APIResponse {
        return try await fetch(
            Constants.API.activityKanojoTimeline,
            params: [
                "kanojo_id": String(kanojoId),
                "index": String(index),
                "limit": String(limit)
            ]
        )
    }

    // MARK: - Messages

    /// Fetch kanojo dialogue message.
    func showDialog(action: Int, pod: Int? = nil) async throws -> APIResponse {
        return try await fetch(
            Constants.API.messageDialog,
            params: ["a": String(action), "pod": String(pod ?? partOfDay())]
        )
    }

    // MARK: - Resources

    /// Fetch product category list.
    func productCategoryList() async throws -> APIResponse {
        return try await fetch(Constants.API.resourceProductCategoryList)
    }

    // MARK: - Push Notifications

    /// Register device push token.
    func registerDeviceToken(uuid: String, deviceToken: String) async throws -> APIResponse {
        return try await upload(
            Constants.API.registerToken,
            fields: ["uuid": uuid, "device_token": deviceToken]
        )
    }

    // MARK: - Shopping / Tickets

    /// Compare ticket price for a store item.
    func comparePrice(price: Int, storeItemId: Int) async throws -> APIResponse {
        return try await submit(
            Constants.API.shoppingComparePrice,
            params: ["price": String(price), "store_item_id": String(storeItemId)]
        )
    }

    /// Use tickets to purchase a store item.
    func doTicket(storeItemId: Int, useTickets: Int) async throws -> APIResponse {
        return try await submit(
            Constants.API.shoppingVerifyTickets,
            params: ["store_item_id": String(storeItemId), "use_tickets": String(useTickets)]
        )
    }

    // MARK: - Helpers

    /// Part-of-day value matching Android getPartOfDay() utility.
    /// 0 = Morning (5-11), 1 = Afternoon (12-17), 2 = Evening (18-23), 3 = Night (0-4)
    func partOfDay() -> Int {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return 0
        case 12..<18: return 1
        case 18..<24: return 2
        default: return 3
        }
    }

    /// Build a full image URL from a relative path.
    func imageURL(for path: String) -> URL? {
        URL(string: AppSettings.shared.baseURL + path)
    }
}
