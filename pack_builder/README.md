# Pack Builder

Pipeline for building city packs for the LocalLore app.

## Steps

1. `01_fetch_pois.py` — Scrape POI data from Wikidata/OpenStreetMap
2. `02_fetch_images.py` — Fetch reference images from Wikipedia/Commons
3. `03_generate_text.py` — Generate explanation text using Claude
4. `04_compute_embeddings.py` — Compute CLIP image embeddings
5. `05_package.py` — Bundle everything into a versioned zip

## Usage

```bash
cd pack_builder
pip install -e .

python scripts/01_fetch_pois.py --city oslo
python scripts/02_fetch_images.py --city oslo
python scripts/03_generate_text.py --city oslo
python scripts/04_compute_embeddings.py --city oslo
python scripts/05_package.py --city oslo --version 1
```

Requires `ANTHROPIC_API_KEY` in a `.env` file for step 3.
