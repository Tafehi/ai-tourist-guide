## Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload          # run dev server
python -m pytest tests/                 # run all tests
python -m pytest tests/test_health.py   # single test file
ruff check .                            # lint
bandit -r app/                          # security scan
```

## Pack Builder

```bash
cd pack_builder
pip install -e ".[dev]"
python scripts/03_generate_text.py --city oslo
ruff check scripts/
```

## iOS

```bash
cd ios
xcodegen generate    # regenerate .xcodeproj after adding/removing files
open LocalLore.xcodeproj
```

## Running CI Locally

To mirror what GitHub Actions runs:

```bash
cd backend && ruff check . && bandit -r app/ && python -m pytest tests/
cd ../pack_builder && ruff check scripts/
```
