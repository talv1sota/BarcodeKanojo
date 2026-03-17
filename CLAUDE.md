# Barcode Kanojo - Project Memory

## Overview
Android mobile game that generates virtual companion characters (kanojos) from scanned product barcodes. Originally by Cybird, this is a reconstructed/modernized version by Goujer.

- **Version:** 0.5.2
- **Language:** Kotlin + Java (legacy)
- **Build System:** Gradle 8.2.2
- **Min SDK:** 14 | **Target SDK:** 29 | **Compile SDK:** 35
- **Default Server:** `kanojo.goujer.com:443` (HTTPS, configurable)

## Directory Structure
```
kanojo_app-master/
├── app/
│   ├── build.gradle                    # App-level gradle config
│   ├── libs/live2d_android.jar         # Live2D rendering library
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── java/
│       │   ├── com/goujer/barcodekanojo/       # Modern Kotlin code
│       │   ├── jp/co/cybird/barcodekanojoForGAM/ # Legacy Java code
│       │   └── jp/co/cybird/app/               # Utility libraries
│       ├── assets/                     # Live2D models, backgrounds, HTML
│       └── res/                        # Layouts (73), drawables (154), values
├── build.gradle                        # Root gradle config
├── settings.gradle
├── gradle.properties                   # Keystore passwords
└── release.jks                         # Release signing keystore
```

## Architecture

**Pattern:** MVC + Repository with a facade class

### Key Kotlin Classes (`com.goujer.barcodekanojo`)
- `BarcodeKanojoApp.kt` — Application class, initializes Conscrypt TLS, LRU image cache, global state
- `BarcodeKanojo.kt` — Main API facade (~417 lines): auth, kanojo CRUD, items, dates, Live2D
- `BarcodeKanojoHttpApi.kt` — HTTP API wrapper (REST endpoints, multipart uploads, auth tokens)
- `HttpApi.kt` — Low-level OkHttp3 client (TLS 1.2+, cookies, timeouts)
- `Kanojo.kt` — Character model (Parcelable, 15+ visual attributes, love_gauge, relationship status)
- `User.kt` — Player profile (level, stamina, money, tickets, counters)
- `ApplicationSetting.kt` — SharedPreferences wrapper (server config, UUID, credentials)

### Activities (Entry Flow)
1. `LaunchActivity.kt` → Splash/auto-login
2. `LoginActivity.kt` → Auth UI
3. `DashboardActivity.kt` → Home screen
4. `ScanActivity.kt` → Barcode scanner
5. `ScanKanojoGenerateActivity.kt` → Barcode → kanojo generation
6. `KanojoRoomActivity.kt` → Character interaction
7. `ServerConfigurationActivity.kt` → Server settings

### Legacy Java Code (`jp.co.cybird`)
- ~337 files: models, JSON parsers, Live2D rendering, billing, push notifications
- Core parsers: `ResponseParser`, `KanojoParser`, `UserParser`, etc.
- Live2D: `KanojoLive2D`, `KanojoGLSurfaceView`, `AndroidES1Renderer`
- Billing: `GooglePlayBillingHelper` (in-app purchases)

## Key Dependencies
- **AndroidX:** core-ktx, constraintlayout, swiperefreshlayout, exifinterface
- **Maps:** osmdroid 6.1.20
- **Charts:** MPAndroidChart v3.1.0
- **Barcode:** ZXing core 3.5.3
- **Security:** Conscrypt 2.5.3, Google Play Services Basement 18.3.0
- **HTTP:** OkHttp3 3.12.13
- **Kotlin:** Coroutines 1.6.4
- **Live2D:** Custom JAR (app/libs/)

## Features
1. **Barcode Scanning** — ZXing-based, generates characters from product barcodes
2. **Live2D Characters** — Animated 2D models with 17 part categories (hair, eyes, clothes, etc.)
3. **Relationship System** — Friend/Kanojo/Other status, love gauge, follower count
4. **Item/Gift System** — Ticket-based purchases, gift giving, date mechanics
5. **Geolocation** — OSMDroid map, location-based kanojo discovery
6. **Social** — Friends, leaderboards, timeline/activity feed, enemy book
7. **Localization** — EN, JA, ZH, ES, RU, FR

## Networking
- JSON request/response, multipart form uploads for images
- Session-based auth via cookies
- TLS enforced for production; cleartext allowed for localhost/LAN dev
- Network security config: `res/xml/network_security_config.xml`
- ISRG Root X1 & X2 certificates pinned

## Build & Run
```bash
# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease
```

## Version Code Scheme
Format: `ABBBBBBCC` where A=1, B=version (BB.BB.BB), C=minSDK
Current: `100050214` = v0.5.2, minSDK 14

## Notes
- View Binding enabled, BuildConfig enabled
- ProGuard configured for release builds
- Passwords hashed with SHA-512 + salt (`Password.kt`)
- Image caching: in-memory LRU (1/6 max memory) + disk cache
- Threading: Kotlin coroutines (Main + IO dispatchers)

---

## iOS Port (`BarcodeKanojo-iOS/`)

### Overview
Native SwiftUI iOS port targeting iOS 16+. Uses MVVM architecture with async/await. Custom Live2D engine ported to Metal (no third-party Live2D SDK).

- **Language:** Swift 5
- **UI:** SwiftUI
- **Live2D:** Custom Metal renderer (ported from Java/OpenGL ES)
- **Build:** Xcode project (`BarcodeKanojo.xcodeproj`)
- **Build command:** `xcodebuild -project BarcodeKanojo.xcodeproj -scheme BarcodeKanojo -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build`

### iOS Directory Structure
```
BarcodeKanojo-iOS/BarcodeKanojo/
├── App/                          # BarcodeKanojoApp.swift, ContentView.swift
├── Configuration/                # AppSettings.swift, Constants.swift
├── Enums/                        # ActivityType, ItemClass, RelationStatus, ResponseCode
├── Live2D/
│   ├── Core/                     # Metal-based Live2D engine (ALive2DModel, BinaryReader, etc.)
│   └── Kanojo/                   # KanojoModel, KanojoAnimation, KanojoLive2DView, etc.
├── Models/                       # Kanojo, User, KanojoItem, Activity, APIResponse, etc.
├── Networking/                   # BarcodeKanojoAPI (46+ endpoints), HTTPClient, ImageCache
├── Security/                     # PasswordHasher
├── ViewModels/                   # AuthVM, DashboardVM, KanojosVM, KanojoRoomVM, ScanVM
└── Views/
    ├── Auth/                     # Launch, Login, Signup, ServerConfig
    ├── Common/                   # ErrorBanner, LoadingView, LoveGaugeView
    ├── Dashboard/                # DashboardView, DashboardHeaderView, ActivityRowView
    ├── EnemyBook/                # EnemyBookView (placeholder)
    ├── Kanojos/                  # KanojosListView, KanojoRoomView
    ├── Map/                      # MapKanojosView (placeholder)
    ├── Scan/                     # BarcodeScannerView
    ├── Settings/                 # SettingsView
    └── MainTabView.swift         # 5-tab root (Home, Kanojos, Scan, Enemies, Map)
```

### What's Implemented (iOS)
- ✅ Auth (login, signup, UUID auto-login, server config)
- ✅ Barcode scanning (AVFoundation) → kanojo generation form
- ✅ Live2D rendering (Metal): model loading, animation, tap/double-tap/shake reactions
- ✅ Kanojo roster with Live2D thumbnail renderer + server icon fallback
- ✅ Kanojo room: Live2D avatar, love gauge, date/gift system (store/owned tabs, category drill-down, item detail, dialogue overlay, user balance)
- ✅ Dashboard with activity timeline + pagination
- ✅ Image caching (memory LRU + disk)
- ✅ 5-tab navigation: Home, Kanojos, Scan, Enemies, Map
- ✅ Kanojo list: Mine / Friends / Ranking tabs with independent pagination

### Implementation Phases (iOS) — ALL COMPLETE
- ✅ Phase 2: Kanojo info screen + radar chart + product editing
- ✅ Phase 3: Profile editing + account management
- ✅ Phase 4: Advanced Live2D (body-part touch, kiss/breast reactions, playOnLive2d API)
- ✅ Phase 5: Differentiated scan results (own/friend/other kanojo, product info, scan stats)
- ✅ Phase 6: Time-of-day greeting + stamina enforcement
- ✅ Phase 7: Map / geolocation (MapKit, kanojo pins, nav to room)
- ✅ Phase 8: Enemy book (rivalry tracking from timeline activities)
- ✅ Phase 9: Ticket shop (store items, compare price, doTicket purchase flow)
- ✅ Phase 10: Tutorial overlay + visit mode (friend/other kanojo distinction, vacation deferred)
- ✅ Phase 11: Push notifications (AppDelegate, UNUserNotificationCenter, device token registration)

### Implementation Plan
Full 11-phase plan at: `.claude/plans/goofy-riding-abelson.md`

**All 11 phases COMPLETE.** The iOS port is now feature-complete relative to the original plan.

### Key Architecture Notes (iOS)
- **Dating system:** Dates are instant (no on-date state). Server adds love points immediately + returns dialogue message. No extend date/gift needed in UI.
- **KanojosViewModel:** Three parallel data arrays (`kanojos`, `friendKanojos`, `rankingKanojos`) with independent pagination. Concurrent initial fetch via `async let`.
- **KanojoThumbnailView:** Tries Live2D offscreen render first (KanojoThumbnailRenderer), falls back to server icon download.
- **DateGiftMenuView:** Modes: `.date`, `.gift`. Gift mode has Store/Owned segmented picker. Category items navigate via NavigationPath drill-down.
- **API:** 46+ endpoints in BarcodeKanojoAPI.swift. Many already defined but unused (friendKanojos, likeRanking, kanojoTimeline, accountUpdate, accountDelete, playOnLive2d, showDialog, comparePrice, doTicket).
