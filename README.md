# LocalLore

A pocket tour guide that turns sightseeing into a conversation. Point your camera at art or objects and the AI explains them. Walk near a registered building and GPS triggers a story. Cities are downloadable packs with pre-generated content so most interactions are answered locally.

## Architecture

- **iOS App** (`ios/`) — SwiftUI, iOS 17+. Camera identification via on-device CLIP embeddings, GPS geofencing for outdoor POIs, chat with AI guide.
- **Backend** (`backend/`) — Python/FastAPI. Handles image identification (Claude Sonnet vision), follow-up chat (Claude Haiku), city pack distribution, auth.
- **Pack Builder** (`pack_builder/`) — Python scripts to curate POIs, generate explanations, compute embeddings, and package city bundles.

## Quick Start

### Backend

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # fill in ANTHROPIC_API_KEY
uvicorn app.main:app --reload
```

### Pack Builder

```bash
cd pack_builder
pip install -e ".[dev]"
python scripts/01_fetch_pois.py --city oslo
```

### iOS

Requires Xcode 16+ and macOS.

```bash
cd ios
brew install xcodegen  # if not already installed
xcodegen generate
open LocalLore.xcodeproj
```

## Pilot Cities

- **Oslo** (~80 POIs) — free
- **Rome** (~150 POIs) — $2.99

## Documentation

- [Architecture](docs/architecture.md)
- [API Reference](docs/api.md)
- [Pack Builder Guide](pack_builder/README.md)
