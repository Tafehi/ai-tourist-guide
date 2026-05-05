# AI Tour Guide iOS App — Development Plan

> **Working title:** *LocalLore* (placeholder — pick whatever you like)
> **Target platforms:** iOS 17+ (start), Android later
> **Pilot cities:** Rome, Oslo
> **Core idea:** Point camera at art/object → AI explains it. Walk near a registered building → AI explains it via GPS. Cities are downloadable "packs" so most explanations are cached and cheap.

---

## 1. Product Vision (One Paragraph)

A pocket tour guide that turns sightseeing into a conversation. For **artworks and museum objects**, the user opens the camera and the app identifies the piece and tells its story. For **outdoor buildings, monuments, and squares**, GPS triggers a story when the user is within range of a registered location. Each city is a downloadable pack with a curated list of points of interest (POIs), pre-generated narratives, and visual fingerprints — so 95% of interactions are answered locally for free, and the AI backend is only called for follow-up questions or unknown items. Users can chat with the guide for deeper context.

---

## 2. MVP Scope (Be Strict — Cut Everything Else)

**In scope for v1:**
- iOS native app (SwiftUI, iOS 17+)
- Two pilot city packs: **Rome** (~150 POIs) and **Oslo** (~80 POIs)
- Camera mode: snap a photo of a painting/sculpture/object → identification + explanation
- GPS mode: walk near a registered building → notification + explanation
- Text-to-speech playback of explanations
- Follow-up chat with the AI guide ("tell me more about the architect", "what year was this?")
- Offline use of pre-generated content after city pack is downloaded
- Simple paywall: free tier with one city + 10 free AI follow-up questions/day; one-time $2.99 per additional city pack

**Out of scope for v1 (note these as TODO/v2):**
- Android
- Augmented reality overlays
- Multi-day itinerary planning
- User-generated content / reviews
- Social sharing
- Voice input ("ask a question by speaking")
- Indoor museum positioning (we'll rely on camera for indoors, GPS for outdoors)

---

## 3. Tech Stack

### iOS App
- **Language/UI:** Swift 5.9+, SwiftUI
- **Min iOS:** 17.0
- **Camera:** AVFoundation
- **Location:** CoreLocation (significant location changes + region monitoring for battery efficiency)
- **Local DB:** SwiftData (city packs, cached explanations, chat history)
- **On-device ML (optional optimization):** Apple Vision framework + a small CLIP-style image embedding model converted to CoreML, for fast local matching against city pack artworks
- **Networking:** URLSession + async/await
- **TTS:** AVSpeechSynthesizer (free, on-device)
- **Payments:** StoreKit 2 (one-time in-app purchases per city pack)

### Backend
- **Language/Framework:** Python 3.11+ with FastAPI
- **AI provider:** Anthropic Claude API
  - **Claude Haiku** for follow-up text chat (cheap)
  - **Claude Sonnet** for vision (image identification of unknown items)
- **Vector search:** PostgreSQL + `pgvector` extension (for matching uploaded photos against known artworks in a city pack)
- **Object storage:** Cloudflare R2 or AWS S3 (city pack assets, reference images)
- **Hosting:** Fly.io or Railway (cheap, auto-scaling, fits a side project budget)
- **Auth:** Sign in with Apple (no password infra to manage)

### City Pack Build Pipeline (offline tooling — Python scripts)
- Scrape/curate POI list per city (Wikipedia, Wikidata, OpenStreetMap, museum open data)
- For each POI: collect reference images, generate explanation text via Claude, generate image embeddings, package as a versioned bundle
- Output: `rome_v1.zip` and `oslo_v1.zip` containing JSON + images + embeddings, hosted on R2

---

## 4. System Architecture

```
┌─────────────────────────────────────────────────────┐
│                    iOS App                          │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌─────────────────┐    │
│  │ Camera   │  │ GPS/CL   │  │ Chat UI         │    │
│  │ Capture  │  │ Monitor  │  │                 │    │
│  └─────┬────┘  └─────┬────┘  └────────┬────────┘    │
│        │             │                │             │
│        ▼             ▼                ▼             │
│  ┌────────────────────────────────────────────┐     │
│  │   Local Matcher                            │     │
│  │   - GPS → nearest POI in city pack         │     │
│  │   - Image → embedding similarity vs pack   │     │
│  │   - Returns POI + cached explanation       │     │
│  └────────────┬───────────────────────────────┘     │
│               │                                     │
│               ▼ (on miss or follow-up Q)            │
└───────────────┼─────────────────────────────────────┘
                │ HTTPS (JSON)
                ▼
┌─────────────────────────────────────────────────────┐
│              FastAPI Backend                        │
│                                                     │
│  /identify  ─→ Claude Sonnet (vision)               │
│               + pgvector lookup for hints           │
│                                                     │
│  /chat      ─→ Claude Haiku                         │
│               with POI context as system prompt     │
│                                                     │
│  /pack      ─→ signed URL to R2 city pack zip       │
│                                                     │
│  /usage     ─→ rate limiting (free tier)            │
└─────────────────────────────────────────────────────┘
                │
                ▼
        ┌──────────────────┐
        │ Postgres +       │
        │ pgvector         │
        │  - users         │
        │  - usage_log     │
        │  - poi_metadata  │
        │  - embeddings    │
        └──────────────────┘
```

**Key flow — camera in a museum:**
1. User snaps photo of painting.
2. App computes image embedding **on-device** (CoreML CLIP).
3. App searches the loaded city pack's local embeddings → if cosine similarity > 0.85, it's a hit.
4. **Hit:** show pre-generated explanation, offer chat. Zero backend cost.
5. **Miss:** upload photo to `/identify`. Backend runs pgvector search across full DB; if still no match, calls Claude Sonnet vision to describe the artwork. Result is cached and (optionally) added to the city pack for future users.

**Key flow — walking past a building:**
1. CoreLocation reports user position every ~20 meters or via geofence enter event.
2. App queries local city pack: any POI within 50m and not yet seen this session?
3. If yes → notification with title; tap to hear narration. No backend call needed.
4. Follow-up questions go to `/chat` with the POI as context.

---

## 5. City Pack Data Model

A city pack is a versioned zip bundle. Format:

```
rome_v1/
  manifest.json
  pois.json
  embeddings.bin          # binary float32 array, [N x 512]
  images/
    poi_001.jpg
    poi_002.jpg
    ...
  audio/                  # optional, pre-generated TTS for top POIs
    poi_001.mp3
    ...
```

**`pois.json` schema:**

```json
{
  "city": "rome",
  "version": 1,
  "language": "en",
  "pois": [
    {
      "id": "poi_001",
      "type": "building",            // building | artwork | monument | square
      "name": "Colosseum",
      "aliases": ["Flavian Amphitheatre", "Colosseo"],
      "lat": 41.8902,
      "lng": 12.4922,
      "trigger_radius_m": 80,
      "short_summary": "...",        // 1-2 sentences for notification
      "full_explanation": "...",     // 200-400 words narrative
      "fun_facts": ["...", "..."],
      "year_built": "70-80 AD",
      "tags": ["roman", "ancient", "amphitheatre", "unesco"],
      "image_ref": "images/poi_001.jpg",
      "embedding_index": 0
    }
  ]
}
```

`type: "artwork"` POIs use camera matching only (no GPS triggers).
`type: "building" | "monument" | "square"` use GPS triggers and can also be matched by camera.

---

## 6. Backend API (Endpoints)

```
GET  /v1/cities                           → list available city packs + versions
GET  /v1/cities/{city}/pack               → returns signed download URL
POST /v1/identify                         → multipart: image; returns {poi_id?, explanation, confidence}
POST /v1/chat                             → {poi_id, history[], user_message} → {assistant_message}
GET  /v1/usage                            → returns remaining free quota
POST /v1/auth/apple                       → Sign in with Apple token exchange
```

All endpoints require an auth token except `/v1/cities`.

---

## 7. Cost Strategy (Keep it Cheap)

This is critical — it's what determines whether you can charge $2.99 or have to charge $20.

| Lever | Mechanism |
|---|---|
| **Pre-generate everything possible** | Top 150 Rome POIs and 80 Oslo POIs get full Claude-generated explanations once, baked into the pack. Zero per-user inference cost. |
| **On-device matching first** | CLIP embeddings on iPhone are free; only call backend on miss. Target: 90%+ of camera taps hit the local pack. |
| **Cheap model for chat** | Claude Haiku for follow-up Q&A; only escalate to Sonnet for vision. |
| **Aggressive caching** | Cache `/identify` results by image hash. Cache `/chat` responses by `(poi_id, message_hash)` for FAQ-style questions. |
| **Free tier limits** | 10 backend chat questions/day for free users. Camera matches against the local pack are unlimited. |
| **One city free, rest paid** | First city pack is free; additional packs $2.99 one-time each via StoreKit. |
| **No always-on infra** | Fly.io scale-to-zero or Railway hobby tier. Postgres on Neon free tier to start. |

**Rough back-of-envelope (per paying user/month):**
- ~30 follow-up chat messages × Haiku ≈ $0.02
- ~3 unknown-image identifications × Sonnet vision ≈ $0.04
- Hosting amortized ≈ $0.05
- **≈ $0.11/user/month operating cost** → comfortable margin on a one-time $2.99 pack.

---

## 8. Project Structure

```
locallore/
├── ios/
│   └── LocalLore.xcodeproj
│       └── LocalLore/
│           ├── App/
│           │   ├── LocalLoreApp.swift
│           │   └── AppRouter.swift
│           ├── Features/
│           │   ├── Camera/
│           │   ├── Map/
│           │   ├── Chat/
│           │   ├── PackStore/
│           │   └── Onboarding/
│           ├── Core/
│           │   ├── LocationService.swift
│           │   ├── CameraService.swift
│           │   ├── EmbeddingService.swift   # CoreML CLIP
│           │   ├── PackManager.swift
│           │   ├── BackendClient.swift
│           │   └── TTSService.swift
│           ├── Models/
│           │   ├── POI.swift
│           │   ├── CityPack.swift
│           │   └── ChatMessage.swift
│           ├── Resources/
│           │   └── CLIPModel.mlmodel
│           └── Tests/
│
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── routers/
│   │   │   ├── identify.py
│   │   │   ├── chat.py
│   │   │   ├── cities.py
│   │   │   └── auth.py
│   │   ├── services/
│   │   │   ├── claude_client.py
│   │   │   ├── embeddings.py
│   │   │   └── cache.py
│   │   ├── db/
│   │   │   ├── models.py
│   │   │   └── migrations/
│   │   └── config.py
│   ├── tests/
│   ├── requirements.txt
│   └── Dockerfile
│
├── pack_builder/
│   ├── scripts/
│   │   ├── 01_fetch_pois.py            # Wikidata/OSM scraper
│   │   ├── 02_fetch_images.py          # Wikipedia/Commons
│   │   ├── 03_generate_text.py         # Claude calls
│   │   ├── 04_compute_embeddings.py    # CLIP
│   │   └── 05_package.py
│   ├── data/
│   │   ├── rome/
│   │   └── oslo/
│   └── README.md
│
└── docs/
    ├── architecture.md
    └── api.md
```

---

## 9. Development Milestones

### Milestone 0 — Foundation (Week 1)
- [ ] Set up monorepo, basic CI
- [ ] Apple Developer enrollment
- [ ] Anthropic API key, Fly.io account, Neon Postgres
- [ ] Empty SwiftUI app with tab nav (Camera / Map / Library / Settings)
- [ ] Empty FastAPI app with `/health`

### Milestone 1 — Pack Builder for Oslo (Week 2)
- [ ] Curate ~30 Oslo POIs by hand for v0 (Vigeland Park sculptures, Royal Palace, Akershus Fortress, Opera House, Munch Museum exterior, etc.)
- [ ] Write `03_generate_text.py` that calls Claude to write each explanation
- [ ] Write `04_compute_embeddings.py` using OpenCLIP (Python)
- [ ] Output `oslo_v0.zip`, upload to R2

### Milestone 2 — GPS Mode in App (Week 3)
- [ ] `PackManager` downloads + unzips Oslo pack on first launch
- [ ] `LocationService` with permission flow + region monitoring
- [ ] When user enters POI radius → local notification + detail view
- [ ] TTS playback of `full_explanation`
- [ ] **Manual test:** walk around Oslo, verify triggers fire correctly

### Milestone 3 — Camera Mode (Week 4)
- [ ] Convert OpenCLIP image encoder to CoreML, bundle in app
- [ ] Camera capture → embedding → cosine search vs pack embeddings
- [ ] Show match + explanation, or "no match" state
- [ ] **Manual test:** point at images of Oslo landmarks; confirm matches

### Milestone 4 — Backend AI Fallback (Week 5)
- [ ] `/identify` endpoint: accepts image, calls Claude Sonnet vision with prompt "identify this artwork or building, return JSON with name, era, summary"
- [ ] iOS calls backend on local match miss
- [ ] Result cached locally and optionally appended to pack
- [ ] Sign in with Apple

### Milestone 5 — Chat (Week 6)
- [ ] `/chat` endpoint with Claude Haiku, system prompt includes the POI's metadata
- [ ] iOS chat UI with streaming responses
- [ ] Conversation history persisted per POI

### Milestone 6 — Rome Pack + Paywall (Week 7)
- [ ] Build `rome_v1` pack with ~150 POIs
- [ ] StoreKit 2 integration: Oslo free, Rome $2.99
- [ ] Pack store UI

### Milestone 7 — Polish & Submit (Week 8)
- [ ] Onboarding screens, permissions priming
- [ ] Empty states, error states
- [ ] App Store screenshots, description, privacy nutrition labels
- [ ] TestFlight beta, then submission

---

## 10. First Tasks for Claude Code (Copy-Paste Ready)

When you start a Claude Code session, hand it tasks in this order. Each is sized for one focused session.

**Task 1 — Repo scaffold:**
> Create the monorepo structure shown in section 8. Initialize the Xcode project with SwiftUI, iOS 17 minimum target, and a tab-based root view (Camera, Map, Library, Settings — placeholder views for now). Initialize the FastAPI backend with `/health` returning `{"ok": true}` and a Dockerfile. Initialize the `pack_builder` Python project with `pyproject.toml` and stub scripts. Add a top-level `README.md` summarizing the architecture.

**Task 2 — Pack format & loader:**
> Implement the `CityPack`, `POI`, and `ChatMessage` Swift models matching section 5. Implement `PackManager` with: `availablePacks()`, `downloadPack(city:)`, `loadedPack(city:) -> CityPack?`, `unload()`. Use SwiftData for persistence. Use `URLSession` to download zips from a configurable base URL. Include unit tests using a fixture pack.

**Task 3 — Pack builder skeleton:**
> Implement `pack_builder/scripts/03_generate_text.py` and `05_package.py`. Script 03 takes a CSV of POIs (`id,name,type,lat,lng,wikipedia_slug`) and uses the Anthropic Python SDK (Claude Sonnet) to generate `short_summary`, `full_explanation`, `fun_facts`, and `tags` for each, writing to `pois.json`. Script 05 zips the output directory into `<city>_v<version>.zip`. Use `python-dotenv` for `ANTHROPIC_API_KEY`.

**Task 4 — Location service & GPS triggers:**
> Implement `LocationService` in iOS using CoreLocation. On app launch (after permission), build geofence regions for every POI in the loaded pack with `type` in [`building`, `monument`, `square`]. On region entry, post a local notification and broadcast a `POITriggered` event the UI can subscribe to. Handle "always" vs "when in use" permission gracefully.

**Task 5 — Backend `/identify` and `/chat`:**
> Implement the two FastAPI endpoints in section 6. `/identify` accepts a multipart image, calls Claude Sonnet vision with a structured-output prompt to return `{name, type, era, summary, confidence}`, and returns it as JSON. `/chat` accepts `{poi_id, history, message}`, loads the POI from Postgres, builds a system prompt including the POI's metadata, calls Claude Haiku, and returns the assistant message. Add a simple per-user daily rate limit (Redis-free: in-memory dict for now, swap to Postgres counter later).

You do not need to give Claude Code all five tasks at once — feed them one at a time and review the diffs.

---

## 11. Open Decisions Before You Start

These are choices only you can make. Decide them now so they don't block development:

1. **App name** — "LocalLore" is a placeholder. Pick before App Store submission.
2. **Voice for TTS** — default Apple voice is fine for v1, but premium voices (ElevenLabs) are a tempting v2 upgrade.
3. **Languages** — start English-only? Or launch with English + Norwegian + Italian for the pilot cities? Each language ~2x the pack-build cost but big UX win locally.
4. **Pricing model alternative** — instead of per-city packs, a $1.99/month subscription unlocks all cities. Simpler conceptually but worse for casual one-trip users. Worth A/B-ing later.
5. **Image rights** — Wikipedia/Commons reference images are fine, but verify license for any museum collection imagery before bundling.
6. **GDPR / privacy** — you'll need a privacy policy before submission. Sign in with Apple keeps PII minimal, but document image-upload behavior clearly.

---

## 12. What's Deliberately Missing From V1 (Track in Backlog)

- AR overlays (point camera at building → see info pinned in space)
- Offline TTS in non-English languages (Apple TTS quality varies)
- User accounts / sync across devices
- Crowd-sourced POI submissions
- Indoor positioning for big museums (BLE beacons or visual SLAM)
- Apple Watch companion ("Tap when you hear a chime nearby")
- Itinerary planner integrating multiple POIs into a walking route
- Social features (share discoveries, follow friends' tours)

---

**End of plan.** Hand sections 1–10 to Claude Code, keep section 11 open in a notes file, and revisit section 12 once v1 ships.
