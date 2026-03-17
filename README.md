# Barcode Kanojo

> **Work in Progress** — An iOS revival of Cybird's Barcode Kanojo.

Scan real-world barcodes to generate unique kanojos with distinct personalities, stats, and fully animated Live2D avatars.

![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue) ![Swift](https://img.shields.io/badge/swift-5.9-orange) ![Status](https://img.shields.io/badge/status-WIP-yellow)

---

## Features

- **Barcode Scanning** — Scan any product barcode to generate or discover a kanojo
- **Live2D Avatars** — Fully animated characters with customizable hair, eyes, clothes, accessories
- **Touch Interaction** — Tap, double-tap, and shake to interact with your kanojo
- **Dating & Gifts** — Take your kanojo on dates, give gifts, raise the love gauge
- **Resource Management** — Stamina, money, and tickets govern what actions you can take
- **Social** — Visit other players' kanojos, like them, check rankings
- **Enemy Book** — Track rival players who've interacted with your kanojos
- **Map View** — Discover nearby kanojos on an interactive map

---

## Project Structure

```
barcodekanojo/
├── BarcodeKanojo-iOS/       # SwiftUI iOS client (MVVM)
├── barcode-kanojo-server/   # Python/FastAPI backend + SQLite
└── live2d-v2/               # Live2D v2 rendering engine (Swift/Metal)
```

---

## Tech Stack

**iOS** — SwiftUI, AVFoundation, Metal, async/await, UserDefaults

**Server** — FastAPI, SQLAlchemy (async), SQLite, Pydantic

**Live2D** — Custom Swift/Metal port of Live2D v2 SDK

---

## Getting Started

### Server

```bash
cd barcode-kanojo-server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python main.py
```

Runs on `http://localhost:8000` by default.

### iOS

1. Open `BarcodeKanojo-iOS/BarcodeKanojo.xcodeproj` in Xcode
2. Build & Run on a simulator or device (iOS 16+)
3. Configure the server URL in **Settings**

---

## Game Mechanics

| Action | Stamina Cost | Effect |
|--------|-------------|--------|
| Touch | 1 | +1 love, triggers animation |
| Date | 10 + item price | Large love boost, timed state |
| Gift | 5 + item price | Medium love boost, dialogue |
| Like | Free | Toggle heart on any kanojo |

---

## Credits

Based on the original **Barcode Kanojo** by Cybird. Android reference implementation by Goujer.

## License

For **educational and preservation purposes**. All original Barcode Kanojo assets and trademarks belong to their respective owners.
