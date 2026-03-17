import Foundation

/// Application-wide constants.
/// Source: Defs.java, HttpApi.kt, BarcodeKanojoHttpApi.kt
enum Constants {

    // MARK: - Server Defaults

    static let defaultServerHost = "localhost"
    static let defaultServerPort = 8000
    static let defaultUseHTTPS = false

    // MARK: - HTTP

    /// User agent prefix matching Android client (Defs.java line 43)
    static let userAgentPrefix = "BarcodeKanojo/2.4.2 "

    /// Multipart form boundary (HttpApi.kt line 306)
    static let multipartBoundary = "0xKhTmLbOuNdArY"

    /// Default accept charset
    static let acceptCharset = "utf-8"

    // MARK: - App Info

    static let bundleIdentifier = "com.goujer.barcodekanojo.ios"
    static let appVersion = "0.5.2"

    // MARK: - Image URL Patterns

    static let kanojoProfileIconPattern = "/profile_images/kanojo/%d/icon.png"
    static let kanojoProfileBustPattern = "/profile_images/kanojo/%d/bust.png"
    static let kanojoProfileFullPattern = "/profile_images/kanojo/%d/full.png"
    static let userProfilePattern = "/profile_images/user/%d.jpg"
    static let productImagePattern = "/product_images/barcode/%@/%@.png"

    // MARK: - API Endpoints (from BarcodeKanojoHttpApi.kt lines 457-520)

    enum API {
        // Account
        static let accountSignup = "/api/account/signup.json"
        static let accountVerify = "/api/account/verify.json"
        static let accountUUIDVerify = "/api/account/uuidverify.json"
        static let accountUpdate = "/api/account/update.json"
        static let accountShow = "/api/account/show.json"
        static let accountDelete = "/api/account/delete.json"
        static let facebookConnect = "/api/account/connect_facebook.json"
        static let facebookDisconnect = "/api/account/disconnect_facebook.json"
        static let twitterConnect = "/api/account/connect_twitter.json"
        static let twitterDisconnect = "/api/account/disconnect_twitter.json"
        static let sukiyaConnect = "/api/account/connect_sukiya.json"
        static let sukiyaDisconnect = "/api/account/disconnect_sukiya.json"

        // Activity / Timeline
        static let activityUserTimeline = "/activity/user_timeline.json"
        static let activityScannedTimeline = "/api/activity/scanned_timeline.json"
        static let activityKanojoTimeline = "/api/activity/kanojo_timeline.json"

        // Barcode Scanning
        static let barcodeQuery = "/api/barcode/query.json"
        static let barcodeScan = "/api/barcode/scan.json"
        static let barcodeScanAndGenerate = "/api/barcode/scan_and_generate.json"
        static let barcodeDecreaseGenerating = "/api/barcode/decrease_generating.json"
        static let barcodeUpdate = "/api/barcode/update.json"

        // Communication (Dating / Gifting)
        static let communicationDateAndGiftMenu = "/api/communication/date_and_gift_menu.json"
        static let communicationDateMenu = "/api/communication/date_list.json"
        static let communicationGiftMenu = "/api/communication/item_list.json"
        static let communicationDoDate = "/api/communication/do_date.json"
        static let communicationDoExtendDate = "/api/communication/do_extend_date.json"
        static let communicationDoGift = "/api/communication/do_gift.json"
        static let communicationDoExtendGift = "/api/communication/do_extend_gift.json"
        static let communicationHasItems = "/api/communication/has_items.json"
        static let communicationStoreItems = "/api/communication/store_items.json"
        static let communicationPermanentItems = "/api/communication/permanent_items.json"
        static let communicationPermanentSubItem = "/api/communication/permanent_sub_item.json"
        static let communicationPlayOnLive2d = "/api/communication/play_on_live2d.json"

        // In-App Purchases (Google Play - will need Apple equivalent)
        static let confirmPurchaseItem = "/api/google/confirm_purchase_item.json"
        static let verifyPurchasedItem = "/api/google/verify_purchased_item.json"

        // Kanojo
        static let kanojoShow = "/api/kanojo/show.json"
        static let kanojoVoteLike = "/api/kanojo/vote_like.json"
        static let kanojoLikeRanking = "/api/kanojo/like_rankings.json"

        // Messages / Dialogue
        static let messageDialog = "/api/message/dialog.json"

        // Payment
        static let paymentItemDetail = "/api/payment/item_detail.html"
        static let paymentVerify = "/api/payment/verify.json"

        // Push Notifications
        static let registerToken = "/api/notification/register_token.json"

        // Resources
        static let resourceProductCategoryList = "/api/resource/product_category_list.json"

        // Shopping
        static let shoppingComparePrice = "/api/shopping/compare_price.json"
        static let shoppingGoodsList = "/api/shopping/goods_list.json"
        static let shoppingVerifyTickets = "/api/shopping/verify_tickets.json"

        // User Kanojos
        static let userCurrentKanojos = "/user/current_kanojos.json"
        static let userFriendKanojos = "/api/user/friend_kanojos.json"

        // WebView
        static let webviewChart = "/api/webview/chart.json"
        static let webviewShow = "/api/webview/show.json"
    }
}
