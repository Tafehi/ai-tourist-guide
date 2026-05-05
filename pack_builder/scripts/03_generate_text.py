"""Step 3: Generate explanation text for each POI using Claude."""

import argparse
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()


def main():
    parser = argparse.ArgumentParser(description="Generate text for POIs using Claude")
    parser.add_argument("--city", required=True, help="City slug (e.g., 'rome', 'oslo')")
    parser.add_argument("--data-dir", default="data", help="Data directory")
    args = parser.parse_args()

    data_dir = Path(args.data_dir) / args.city
    pois_csv = data_dir / "pois.csv"

    if not pois_csv.exists():
        print(f"Error: {pois_csv} not found. Run 01_fetch_pois.py first.")
        return

    print(f"Generating text for {args.city} POIs...")
    raise NotImplementedError


if __name__ == "__main__":
    main()
