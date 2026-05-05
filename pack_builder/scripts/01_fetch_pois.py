"""Step 1: Fetch POI data from Wikidata/OpenStreetMap for a given city."""

import argparse


def main():
    parser = argparse.ArgumentParser(description="Fetch POIs for a city")
    parser.add_argument("--city", required=True, help="City slug (e.g., 'rome', 'oslo')")
    parser.add_argument("--output", default="data", help="Output directory")
    args = parser.parse_args()

    print(f"Fetching POIs for {args.city}...")
    raise NotImplementedError


if __name__ == "__main__":
    main()
