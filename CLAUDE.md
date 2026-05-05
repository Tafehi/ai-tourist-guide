# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

LocalLore — an AI-powered tour guide app. Point camera at art/objects for identification, walk near buildings for GPS-triggered stories. Cities are downloadable packs with pre-generated content.

## Monorepo Structure

- `ios/` — SwiftUI iOS app (iOS 17+, Swift 5.9). Uses XcodeGen (`project.yml`) to generate the Xcode project.
- `backend/` — Python 3.11+ FastAPI server (AI endpoints, auth, city pack distribution).
- `pack_builder/` — Python pipeline scripts to build city pack bundles.
- `docs/` — Architecture and API documentation.
- `.claude/rules/` — Authoritative project rules (loaded automatically by Claude Code).

## Commands

### Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload          # run dev server
python -m pytest tests/                 # run tests
python -m pytest tests/test_health.py   # single test file
ruff check .                            # lint
bandit -r app/                          # security scan
```

### Pack Builder

```bash
cd pack_builder
pip install -e ".[dev]"
python scripts/03_generate_text.py --city oslo
ruff check scripts/
```

### iOS

```bash
cd ios
xcodegen generate    # regenerate .xcodeproj after adding/removing files
open LocalLore.xcodeproj
```

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`) runs on push to `main` and all PRs:
- **backend-test** — pytest
- **backend-lint** — ruff
- **security-scan** — bandit on all Python code (backend + pack_builder)
- **pack-builder-lint** — ruff

Run locally to mirror CI: `cd backend && ruff check . && bandit -r app/ && python -m pytest tests/`

## Key Conventions

- Backend uses pydantic-settings for configuration via `.env` file
- AI calls use Anthropic SDK: Claude Sonnet for vision, Claude Haiku for chat
- City pack format: versioned zip with `pois.json`, `embeddings.bin`, `images/`
- Pack builder scripts are numbered and run sequentially (01 through 05)
- Linting: Ruff (line-length 100, target Python 3.11)

## Security

- PostgreSQL connections use SSL (`sslmode=verify-full`) with connection pooling (`pool_pre_ping=True`, `pool_recycle=300`)
- All database queries use SQLAlchemy ORM/Core with bound parameters — never string interpolation
- API input validated via Pydantic models at every endpoint
- File uploads: validate content type and enforce size limits
- No secrets in code — all via `.env` loaded by pydantic-settings
- `bandit` security scan must pass with no high-severity issues before merge
