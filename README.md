# LocalLore

An AI-powered tour guide app that turns sightseeing into a conversation. Point your camera at art or objects for instant identification. Walk near a building and GPS triggers its story. Cities are downloadable packs with pre-generated content so most interactions work offline.

## How It Works

1. **Camera identification** — Snap a photo of a painting, sculpture, or landmark. The app matches it locally via CLIP embeddings; on miss, the backend calls Claude Sonnet vision.
2. **GPS stories** — Walk within range of a POI and get a notification with its history. No network required for pre-cached content.
3. **Follow-up chat** — Ask questions about any POI. Claude Haiku answers with the POI context loaded as system prompt.

## Monorepo Structure

```
ios/           SwiftUI app (iOS 17+, Swift 5.9) — XcodeGen managed
backend/       Python 3.11+ FastAPI server — AI, auth, city pack distribution
pack_builder/  Pipeline scripts to build city pack bundles
docs/          Architecture diagrams and API reference
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | SwiftUI, CoreML (CLIP), CoreLocation |
| Backend | FastAPI, SQLAlchemy (async), Anthropic SDK |
| AI | Claude Sonnet (vision), Claude Haiku (chat) |
| Database | PostgreSQL + pgvector (Neon) |
| Storage | Cloudflare R2 (city pack zips) |
| Auth | Sign in with Apple |
| CI | GitHub Actions (pytest, ruff, bandit) |

## Quick Start

### Backend

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # fill in ANTHROPIC_API_KEY, DATABASE_URL, R2_BUCKET_URL
uvicorn app.main:app --reload
```

### Pack Builder

```bash
cd pack_builder
pip install -e ".[dev]"
python scripts/01_fetch_pois.py --city oslo
python scripts/02_fetch_images.py --city oslo
python scripts/03_generate_text.py --city oslo
python scripts/04_compute_embeddings.py --city oslo
python scripts/05_package.py --city oslo --version 1
```

Requires `ANTHROPIC_API_KEY` in a `.env` file for text generation (step 3).

### iOS

Requires Xcode 16+ and macOS.

```bash
cd ios
brew install xcodegen  # if not already installed
xcodegen generate
open LocalLore.xcodeproj
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/v1/cities` | List available city packs |
| GET | `/v1/cities/{city}/pack` | Signed download URL for a city pack |
| POST | `/v1/identify` | Identify artwork/landmark from image |
| POST | `/v1/chat` | Follow-up conversation about a POI |
| GET | `/v1/usage` | Free-tier quota status |
| POST | `/v1/auth/apple` | Exchange Apple identity token for API token |

Full reference: [docs/api.md](docs/api.md)

## City Pack Format

A versioned zip containing:
- `manifest.json` — metadata (city, version, POI count)
- `pois.json` — all POIs with pre-generated explanations
- `embeddings.bin` — float32 array [N x 512] for CLIP matching
- `images/` — reference images per POI
- `audio/` — (optional) pre-generated TTS narration

## Pilot Cities

- **Oslo** (~80 POIs) — free
- **Rome** (~150 POIs) — $2.99

## CI/CD

GitHub Actions runs on push to `main`/`dev`/`test` and all PRs:
- **backend-test** — pytest
- **backend-lint** — ruff
- **security-scan** — bandit on all Python code
- **pack-builder-lint** — ruff

Run locally to mirror CI:

```bash
cd backend && ruff check . && bandit -r app/ && python -m pytest tests/
cd ../pack_builder && ruff check scripts/
```

## Documentation

- [Architecture](docs/architecture.md)
- [API Reference](docs/api.md)
- [Pack Builder Guide](pack_builder/README.md)
