# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────┐
│                    iOS App                          │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌─────────────────┐   │
│  │ Camera   │  │ GPS/CL   │  │ Chat UI         │   │
│  │ Capture  │  │ Monitor  │  │                 │   │
│  └─────┬────┘  └─────┬────┘  └────────┬────────┘   │
│        │             │                │            │
│        ▼             ▼                ▼            │
│  ┌────────────────────────────────────────────┐    │
│  │   Local Matcher                            │    │
│  │   - GPS → nearest POI in city pack         │    │
│  │   - Image → embedding similarity vs pack   │    │
│  │   - Returns POI + cached explanation       │    │
│  └────────────┬───────────────────────────────┘    │
│               │                                    │
│               ▼ (on miss or follow-up Q)           │
└───────────────┼────────────────────────────────────┘
                │ HTTPS (JSON)
                ▼
┌─────────────────────────────────────────────────────┐
│              FastAPI Backend                        │
│                                                     │
│  /identify  → Claude Sonnet (vision)                │
│              + pgvector lookup for hints            │
│                                                     │
│  /chat      → Claude Haiku                          │
│              with POI context as system prompt      │
│                                                     │
│  /pack      → signed URL to R2 city pack zip        │
│                                                     │
│  /usage     → rate limiting (free tier)             │
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

## Key Flows

### Camera in a Museum

1. User snaps photo of painting
2. App computes image embedding on-device (CoreML CLIP)
3. App searches loaded city pack's local embeddings — if cosine similarity > 0.85, it's a hit
4. **Hit:** show pre-generated explanation, offer chat (zero backend cost)
5. **Miss:** upload photo to `/identify`. Backend runs pgvector search; if no match, calls Claude Sonnet vision. Result is cached.

### Walking Past a Building

1. CoreLocation reports user position via geofence enter event
2. App queries local city pack: any POI within radius and not yet seen this session?
3. If yes — notification with title; tap to hear narration (no backend call)
4. Follow-up questions go to `/chat` with the POI as context

## City Pack Format

A city pack is a versioned zip bundle containing:
- `manifest.json` — metadata
- `pois.json` — all POIs with pre-generated explanations
- `embeddings.bin` — binary float32 array [N x 512] for CLIP matching
- `images/` — reference images for each POI
- `audio/` — (optional) pre-generated TTS for top POIs
