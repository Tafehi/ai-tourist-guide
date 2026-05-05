# API Reference

Base URL: `https://api.locallore.app`

All endpoints require an auth token (Bearer) except `GET /v1/cities`.

## Endpoints

### `GET /health`

Health check.

**Response:** `{"ok": true}`

---

### `GET /v1/cities`

List available city packs and their current versions.

**Response:**
```json
{
  "cities": [
    {"slug": "rome", "name": "Rome", "version": 1, "poi_count": 150, "price_usd": 2.99},
    {"slug": "oslo", "name": "Oslo", "version": 1, "poi_count": 80, "price_usd": 0}
  ]
}
```

---

### `GET /v1/cities/{city}/pack`

Get a signed download URL for a city pack zip.

**Response:** `{"url": "https://r2.example.com/rome_v1.zip?sig=..."}`

---

### `POST /v1/identify`

Identify artwork/landmark from an uploaded image.

**Request:** `multipart/form-data` with `image` field

**Response:**
```json
{
  "poi_id": "poi_001",
  "name": "Colosseum",
  "type": "building",
  "era": "70-80 AD",
  "summary": "...",
  "confidence": 0.92
}
```

---

### `POST /v1/chat`

Follow-up conversation about a POI.

**Request:**
```json
{
  "poi_id": "poi_001",
  "history": [
    {"role": "user", "content": "Who built it?"},
    {"role": "assistant", "content": "..."}
  ],
  "message": "Tell me more about the architect"
}
```

**Response:**
```json
{
  "message": "The Colosseum was commissioned by Emperor Vespasian..."
}
```

---

### `GET /v1/usage`

Get remaining free-tier quota for the current user.

**Response:** `{"remaining": 7, "daily_limit": 10, "resets_at": "2024-01-02T00:00:00Z"}`

---

### `POST /v1/auth/apple`

Exchange Sign in with Apple identity token for an API token.

**Request:** `{"identity_token": "..."}`

**Response:** `{"token": "...", "user_id": "..."}`
