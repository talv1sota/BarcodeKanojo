# Barcode Kanojo - iOS Port Implementation Plan

## Project Overview
Port the Android "Barcode Kanojo" app to native iOS using Swift + SwiftUI. The app is a social barcode-scanning game where users scan product barcodes to generate/collect anime girl characters ("kanojos") powered by Live2D avatars, connect to an existing community server, and interact through dating/gift systems.

**Target:** iOS 16+ | Swift 5.9+ | SwiftUI | Xcode 15+

---

## Key Technical Decisions

| Android | iOS Replacement |
|---------|----------------|
| Kotlin/Java | Swift |
| XML Layouts | SwiftUI |
| HttpURLConnection | URLSession + async/await |
| SharedPreferences | UserDefaults + @AppStorage |
| ZXing barcode scanner | AVFoundation + VisionKit (native) |
| Live2D Android SDK (Cubism 2.x) | Live2D Cubism SDK for Native (C++ via bridging header) |
| OpenGL ES 1.0 | OpenGL ES via GLKit (for Live2D 2.x compat) or Metal |
| OSMDroid (OpenStreetMap) | MapKit (Apple Maps) |
| Google Play Billing | StoreKit 2 |
| AsyncTask / Coroutines | Swift Concurrency (async/await, Task) |
| SensorManager (Accelerometer) | CoreMotion |
| TabActivity | SwiftUI TabView |
| JSON manual parsing (15+ parsers) | Codable protocol (auto-decode) |
| CookieManager | HTTPCookieStorage |

---

## Critical Risk: Live2D SDK Version

**Problem:** The Android app uses **Live2D Cubism 2.x SDK** (`live2d_android.jar`), which uses the legacy `.moc` format. The current Live2D SDK (Cubism 5) **only supports `.moc3`** format and is NOT backward compatible.

**Solution Options (in order of preference):**
1. **Find Cubism 2.x iOS Framework** - The original game DID have an iOS version (IPA files exist per README). The Cubism 2.x SDK had an iOS framework. We need to locate `live2d_ios.framework` from archives or the Live2D community.
2. **Use Cubism SDK for Native (C++)** - The modern SDK is C++ and works on iOS, but requires converting `.moc` -> `.moc3` (needs original editor source files `.cmox`/`.canx` which we likely don't have).
3. **Java-to-Swift bridge for .bkparts** - Write a pre-conversion tool (Java CLI) that deserializes the `.bkparts` files (which use Java ObjectInputStream) into a portable JSON/binary format that Swift can read. Then use whichever Live2D SDK is available on iOS.
4. **Custom 2D renderer** - As a last resort, bypass Live2D entirely and render the avatar using SpriteKit or Metal with the texture PNGs directly. Lose animation but keep visuals.

**Recommendation:** Option 1 first (check archives), fallback to Option 3 (pre-conversion tool + modern SDK).

---

## Phase 1: Project Setup & Data Models
**Goal:** Xcode project with all data models, configuration, and assets bundled.
**Complexity:** Low | **Duration:** ~1 week

### Tasks:
1. Create Xcode project `BarcodeKanojo` with SwiftUI lifecycle
2. Configure project settings (iOS 16+, portrait only, camera permissions, location permissions)
3. Copy all reusable assets from Android:
   - `avatar_data/` folder (all .bkparts, .moc, motion files, textures)
   - Background images (back*.png, class_*.png, shrine.png, etc.)
   - App icons and drawable resources
4. Create Swift data models with Codable:

### Files to Create:
```
BarcodeKanojo/
  BarcodeKanojoApp.swift              (App entry point)
  Info.plist                           (Permissions: Camera, Location, etc.)
  Models/
    User.swift                         (User model - Codable)
    Kanojo.swift                       (Kanojo model - 20+ appearance attrs - Codable)
    Product.swift                      (Product/barcode model - Codable)
    KanojoItem.swift                   (Gift/date items - Codable)
    Activity.swift                     (Timeline entries - Codable)
    KanojoMessage.swift                (Dialogue messages - Codable)
    LoveIncrement.swift                (Love gain response - Codable)
    ScanHistory.swift                  (Scan records - Codable)
    SearchResult.swift                 (Search metadata - Codable)
    Alert.swift                        (Server alerts - Codable)
    Category.swift                     (Product categories - Codable)
    PurchaseItem.swift                 (IAP items - Codable)
    APIResponse.swift                  (Generic response wrapper with code/message)
    Enums/
      RelationStatus.swift             (OTHER=1, KANOJO=2, FRIEND=3)
      ResponseCode.swift               (200, 400, 401, etc.)
      ItemClass.swift                  (GIFT, DATE, PERMANENT, etc.)
  Config/
    AppSettings.swift                  (UserDefaults wrapper - server URL, UUID, credentials)
    Constants.swift                    (API paths, user agent, defaults)
  Assets.xcassets/                     (App icons, colors)
  Resources/
    avatar_data/                       (Copied from Android assets)
    backgrounds/                       (Background images)
```

### Milestone: App launches, all models compile, assets load from bundle.

---

## Phase 2: Networking Layer & Authentication
**Goal:** Full API client that can authenticate and make all 46+ API calls.
**Complexity:** Medium | **Duration:** ~2 weeks

### Tasks:
1. Build URLSession-based HTTP client with GET/POST/Multipart support
2. Implement cookie-based session management
3. Implement all 46+ API endpoints
4. Build authentication flow (login, signup, verify)
5. Handle error responses and map to Swift errors
6. Password hashing (match Android's implementation)

### Files to Create:
```
  Networking/
    HTTPClient.swift                   (URLSession wrapper - GET/POST/Multipart)
    MultipartFormData.swift            (Multipart body builder, boundary: "0xKhTmLbOuNdArY")
    APIEndpoints.swift                 (All endpoint path constants)
    BarcodeKanojoAPI.swift             (High-level API - 46+ methods, returns Codable models)
    APIError.swift                     (Custom error types matching response codes)
    ImageCache.swift                   (NSCache + disk cache for downloaded images)
    ImageDownloader.swift              (Async image loading with caching)
  Utils/
    PasswordHasher.swift               (SHA hash matching Android Password class)
    DeviceUUID.swift                   (UUID generation/persistence)
```

### Key Implementation Details:
- Base URL: configurable, default `https://kanojo.goujer.com:443`
- User-Agent: `BarcodeKanojo/2.4.2 CFNetwork/...` (match Android format)
- Accept-Language: from `Locale.current`
- Cookie jar: `HTTPCookieStorage.shared`
- All API methods return `async throws -> APIResponse<T>`

### Milestone: Can login to server, fetch user profile, list kanojos via API.

---

## Phase 3: Core UI Screens (No Live2D)
**Goal:** All navigable screens with real server data, using placeholder for Live2D avatar.
**Complexity:** Medium-High | **Duration:** ~3 weeks

### Tasks:
1. Build tab-based navigation (Dashboard, Kanojos, Scan, Enemy Book, Map)
2. Implement all screens as SwiftUI views
3. Build barcode scanner using AVFoundation / VisionKit
4. Integrate MapKit for kanojo locations
5. Build image loading with async caching
6. Implement pull-to-refresh, pagination, search

### Files to Create:
```
  Views/
    MainTabView.swift                  (TabView: Dashboard, Kanojos, Scan, Enemies, Map)

    Auth/
      LaunchView.swift                 (Boot screen, server check)
      LoginView.swift                  (Login form)
      SignupView.swift                 (Registration form)
      ServerConfigView.swift           (Server URL/port/HTTPS config)

    Dashboard/
      DashboardView.swift              (Main hub with user profile header)
      DashboardHeaderView.swift        (User stats: level, stamina, money, tickets)
      ActivityTimelineView.swift       (Activity feed)
      ActivityRowView.swift            (Individual timeline entry)

    Kanojos/
      KanojosListView.swift            (Grid/list of user's kanojos with search)
      KanojoRowView.swift              (Kanojo list item with thumbnail)
      KanojoRoomView.swift             (Live2D display + interaction buttons)
      KanojoInfoView.swift             (Kanojo details, stats radar chart)
      KanojoEditView.swift             (Edit kanojo name/appearance)

    Scan/
      BarcodeScannerView.swift         (AVFoundation camera + barcode detection)
      ScanResultView.swift             (Post-scan: existing kanojo or new)
      ScanGenerateView.swift           (Generate new kanojo from barcode)
      ScanOthersEditView.swift         (Edit product info for scanned barcode)

    Items/
      KanojoItemsView.swift            (Shop: gifts, dates, permanent items)
      KanojoItemDetailView.swift       (Item detail + purchase)
      KanojoPaymentView.swift          (StoreKit payment flow)

    Enemies/
      EnemyBookView.swift              (List of encountered kanojos)
      EnemyView.swift                  (Enemy kanojo detail)

    Map/
      MapKanojosView.swift             (MapKit view with kanojo pins)

    Settings/
      OptionsView.swift                (Options menu)
      SettingsView.swift               (App settings)
      UserModifyView.swift             (Edit user profile)
      CreditsView.swift                (Credits screen)

    Common/
      LoadingView.swift                (Custom loading indicator)
      CustomDialogView.swift           (Alert/dialog component)
      ProfileHeaderView.swift          (Reusable user profile header)
      RadarChartView.swift             (5-axis stats chart using SwiftUI Canvas)
      AsyncCachedImage.swift           (Image loader with cache)
      WebContentView.swift             (WKWebView wrapper)

  ViewModels/
    AuthViewModel.swift                (Login/signup state)
    DashboardViewModel.swift           (Dashboard data loading)
    KanojosViewModel.swift             (Kanojo list + search + pagination)
    KanojoRoomViewModel.swift          (Kanojo detail + interactions)
    ScanViewModel.swift                (Barcode scanning + API calls)
    ItemsViewModel.swift               (Shop data)
    MapViewModel.swift                 (Location-based kanojos)
    EnemyBookViewModel.swift           (Enemy list)
    SettingsViewModel.swift            (Settings management)
```

### Milestone: Full app navigation works. Can scan barcodes, view kanojos (with placeholder avatar image), browse shop items, see map. All powered by live server data.

---

## Phase 4: Live2D Integration - Foundation
**Goal:** Load and render a static Live2D kanojo avatar on screen.
**Complexity:** HIGH (Critical Path) | **Duration:** ~3-4 weeks

### Tasks:
1. **Obtain Live2D iOS SDK** - Locate Cubism 2.x iOS framework (check community archives, original IPA, Live2D GitHub)
2. **Create .bkparts parser** - The `.bkparts` format uses Live2D's `BReader` (a custom binary reader, NOT Java ObjectInputStream based on the code). Parse the binary format:
   - Header: 3 bytes `0x62 0x6B 0x70` ("bkp")
   - Format version: 1 byte
   - Parts version: int32
   - AvatarPartsItem: serialized Live2D object (via BReader.readObject())
   - Clipped image count: int32
   - EOF marker: `0x88888888`
3. **Build C++/ObjC bridge** - Create bridging header to expose Live2D C++ API to Swift
4. **Implement KanojoModel equivalent** - Load base model (`kanojoBaseModel.moc`), assemble parts, bind textures
5. **Implement color conversion** - Port `ColorConvertUtil.convertColor_exe1()` HSL algorithm pixel-by-pixel
6. **Create GLKView renderer** - OpenGL ES rendering surface for Live2D (or Metal if using modern SDK)
7. **Implement KanojoSetting** - 14 part types, 5 color channels (with all lookup tables), 3 feature positions

### Files to Create:
```
  Live2D/
    BridgingHeader.h                   (C/ObjC bridge for Live2D framework)
    Live2DWrapper.mm                   (ObjC++ wrapper around Live2D C++ API)
    Live2DWrapper.h                    (Header for Swift access)

    KanojoModel.swift                  (Main model manager - load .moc, assemble parts)
    KanojoPartsItem.swift              (Individual part loader - parse .bkparts)
    KanojoPartsItemTexture.swift       (Texture loading, color conversion, GL binding)
    KanojoSetting.swift                (14 parts + 5 colors + 3 features config)
    KanojoFileManager.swift            (Asset/cache file access)
    KanojoResource.swift               (Resource path constants)

    ColorConvert.swift                 (HSL color shift values: hue, sat, lum)
    ColorConvertUtil.swift             (Pixel-level HSL conversion algorithm)
    ColorTables.swift                  (All color lookup tables: SKIN[12], HAIR[24], EYE[12], CLOTHES[5x6])

    BKPartsReader.swift                (Binary reader for .bkparts format)

    KanojoGLView.swift                 (UIViewRepresentable wrapping GLKView)
    KanojoRenderer.swift               (OpenGL ES renderer - 60fps, 1280x1280 canvas)
```

### Key Algorithm to Port (ColorConvertUtil):
- For each pixel with alpha >= 26 and non-gray (r!=g or r!=b):
  - Convert RGB to HSL (custom formula with "shusendo" blending factor)
  - Apply hue/sat/lum offsets from ColorConvert tables
  - Convert back to RGB
  - Blend based on luminance threshold

### Milestone: A kanojo avatar renders on screen with correct parts, colors, and positioning. Static (no animation yet).

---

## Phase 5: Live2D Animation & Interaction
**Goal:** Fully animated, interactive Live2D kanojos matching Android behavior.
**Complexity:** HIGH | **Duration:** ~2-3 weeks

### Tasks:
1. Port KanojoAnimation state machine (motion selection per category)
2. Port motion file loading (.mtn format) from assets
3. Implement gesture recognition (tap, double-tap, drag with region detection)
4. Implement accelerometer-based physics (CoreMotion)
5. Implement touch region detection (head pat, kiss, body touch zones)
6. Implement background selection based on kanojo state (classroom, shrine, etc.)
7. Integrate with KanojoRoomView (replace placeholder)

### Files to Create:
```
  Live2D/
    KanojoAnimation.swift              (Animation state machine)
    KanojoMotion.swift                 (Motion file loader for .mtn)
    KanojoTouchHandler.swift           (Gesture detection + region mapping)
    AccelerometerManager.swift         (CoreMotion wrapper for physics)

    MotionCategories.swift             (double_tap, touch, shake, love_a/b/c)
    BackgroundManager.swift            (Time-of-day + state-based BG selection)
```

### Motion Categories:
- `double_tap` - Double tap on character
- `touch` - Single touch interactions
- `shake` - Device shake
- `love_a`, `love_b`, `love_c` - Love level animations (based on love_gauge)

### Milestone: Kanojo animates idle, responds to taps/touches, moves with device tilt, plays correct motions. Full KanojoRoom experience matches Android.

---

## Phase 6: Communication System & Shop
**Goal:** Full dating, gifting, and shop system working end-to-end.
**Complexity:** Medium | **Duration:** ~2 weeks

### Tasks:
1. Implement date flow (select item → API call → love increment → kanojo reaction)
2. Implement gift flow (same pattern)
3. Implement Live2D reaction to date/gift (play_on_live2d API)
4. Build item shop with categories (time-of-day filtering)
5. Implement permanent items (clothes, accessories that change avatar)
6. Build kanojo message/dialogue display
7. Implement love gauge UI + animations
8. Implement StoreKit 2 for in-app purchases (tickets)

### Files to Create:
```
  ViewModels/
    DateViewModel.swift                (Date flow state machine)
    GiftViewModel.swift                (Gift flow state machine)
    ShopViewModel.swift                (Store items, categories, time-of-day)
    PurchaseManager.swift              (StoreKit 2 integration)

  Views/
    Interaction/
      DateMenuView.swift               (Date item selection)
      GiftMenuView.swift               (Gift item selection)
      InteractionResultView.swift      (Love increment + message display)
      LoveGaugeView.swift              (Animated love meter)
      KanojoDialogueView.swift         (Character speech bubble)
```

### Server Note:
iOS payment verification will need server-side endpoints. The Android app uses `/api/google/confirm_purchase_item.json` and `/api/google/verify_purchased_item.json`. iOS will need equivalent `/api/apple/*` endpoints. Contact the server maintainer (Goujer) about this.

### Milestone: Can go on dates, give gifts, see love increase, kanojo reacts with animation and dialogue. Shop works with ticket-based purchases.

---

## Phase 7: Polish, Push Notifications & Final Integration
**Goal:** Production-ready iOS app matching Android feature parity.
**Complexity:** Medium | **Duration:** ~1-2 weeks

### Tasks:
1. Push notifications (APNs registration, server token endpoint)
2. Deep link support (`app://com.goujer.barcodekanojo` scheme)
3. Like/voting system for kanojos
4. Rankings view (top liked kanojos)
5. Friend kanojos view
6. User profile editing with image upload
7. Image editing for profile pictures (crop/resize)
8. Error handling polish (network errors, server down, etc.)
9. Loading states and empty states for all screens
10. App icon, launch screen, app metadata
11. TestFlight setup

### Files to Create:
```
  Services/
    PushNotificationManager.swift      (APNs registration + handling)
    DeepLinkHandler.swift              (URL scheme routing)

  Views/
    Social/
      RankingsView.swift               (Top liked kanojos)
      FriendKanojosView.swift          (Friend's kanojos list)

    Profile/
      ImageEditView.swift              (Crop/resize profile image)
```

### Milestone: Feature-complete iOS app. Ready for TestFlight / App Store submission.

---

## Summary

| Phase | Description | Duration | Risk |
|-------|-------------|----------|------|
| 1 | Project Setup & Models | ~1 week | Low |
| 2 | Networking & Auth | ~2 weeks | Low-Med |
| 3 | Core UI Screens | ~3 weeks | Medium |
| 4 | Live2D Foundation | ~3-4 weeks | **HIGH** |
| 5 | Live2D Animation | ~2-3 weeks | **HIGH** |
| 6 | Communication & Shop | ~2 weeks | Medium |
| 7 | Polish & Final | ~1-2 weeks | Low |
| **Total** | | **~14-17 weeks** | |

### Critical Path: Phases 4-5 (Live2D)
The Live2D integration is the hardest part. The `.bkparts` binary format and Cubism 2.x SDK compatibility are the biggest unknowns. **Recommended approach:**
1. Start Phase 4 research immediately (find SDK) while building Phases 1-3
2. If Cubism 2.x iOS framework cannot be found, build a Java CLI tool to pre-convert `.bkparts` → JSON + raw texture data, then use whatever renderer is available on iOS
3. Worst case: render static avatar images using the texture PNGs with SpriteKit (lose animation but keep visual identity)

### What Can Be Reused Directly:
- All `.bkparts` files (with parser/converter)
- All PNG textures (512x512 avatar parts)
- All background images
- All motion files (.mtn)
- Base model (`kanojoBaseModel.moc`)
- Server API (same endpoints, same JSON format)
- Color conversion tables (all HSL values)
- All game logic/rules (just need to rewrite in Swift)
