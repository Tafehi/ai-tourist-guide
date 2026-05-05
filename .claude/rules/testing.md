## What to Test

- All API endpoints: success path + error cases
- Input validation: malformed requests return 422
- Auth: unauthorized requests return 401
- Rate limiting: requests beyond quota return 429
- Database queries: use test fixtures, not mocks (integration tests)

## CI Pipeline

GitHub Actions runs on every push to `main` and all PRs:
1. `backend-test` — pytest with coverage
2. `backend-lint` — ruff check
3. `security-scan` — bandit on all Python code
4. `pack-builder-lint` — ruff check

## Running Tests Locally

```bash
cd backend
python -m pytest tests/ -v              # verbose
python -m pytest tests/ --cov=app       # with coverage
python -m pytest tests/test_health.py   # single file
```

## Adding New Tests

- Place tests in `backend/tests/` matching the module structure (e.g., `test_chat.py` for `routers/chat.py`)
- Use `fastapi.testclient.TestClient` for endpoint tests
- Use fixtures for reusable test data
