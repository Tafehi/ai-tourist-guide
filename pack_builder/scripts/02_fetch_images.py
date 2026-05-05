"""Step 2: Fetch reference images from Wikipedia/Commons for each POI."""

import argparse


def main():
    parser = argparse.ArgumentParser(description="Fetch images for POIs")
    parser.add_argument("--city", required=True, help="City slug (e.g., 'rome', 'oslo')")
    parser.add_argument("--data-dir", default="data", help="Data directory")
    args = parser.parse_args()

    print(f"Fetching images for {args.city}...")
    raise NotImplementedError


if __name__ == "__main__":
    main()
