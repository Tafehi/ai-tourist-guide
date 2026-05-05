LocalLore — an AI-powered tour guide app.

Point camera at art/objects for identification, walk near buildings for GPS-triggered stories. Cities are downloadable packs with pre-generated content.

## Monorepo Structure

- `ios/` — SwiftUI iOS app (iOS 17+, Swift 5.9). Uses XcodeGen (`project.yml`) to generate the Xcode project.
- `backend/` — Python 3.11+ FastAPI server (AI endpoints, auth, city pack distribution).
- `pack_builder/` — Python pipeline scripts to build city pack bundles.
- `docs/` — Architecture and API documentation.

## Tech Stack

- **AI:** Anthropic Claude API — Sonnet for vision (image identification), Haiku for chat
- **Database:** PostgreSQL + pgvector (hosted on Neon)
- **Hosting:** Fly.io or Railway
- **Storage:** Cloudflare R2 (city pack zips)
- **Auth:** Sign in with Apple
