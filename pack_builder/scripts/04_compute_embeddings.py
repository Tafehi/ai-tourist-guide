"""Step 4: Compute CLIP image embeddings for each POI's reference image."""

import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Compute image embeddings")
    parser.add_argument("--city", required=True, help="City slug (e.g., 'rome', 'oslo')")
    parser.add_argument("--data-dir", default="data", help="Data directory")
    args = parser.parse_args()

    data_dir = Path(args.data_dir) / args.city
    images_dir = data_dir / "images"

    if not images_dir.exists():
        print(f"Error: {images_dir} not found. Run 02_fetch_images.py first.")
        return

    print(f"Computing embeddings for {args.city}...")
    raise NotImplementedError


if __name__ == "__main__":
    main()
