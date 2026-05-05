"""Step 5: Package city data into a versioned zip bundle."""

import argparse
import zipfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Package city data into a zip bundle")
    parser.add_argument("--city", required=True, help="City slug (e.g., 'rome', 'oslo')")
    parser.add_argument("--version", type=int, default=1, help="Pack version number")
    parser.add_argument("--data-dir", default="data", help="Data directory")
    parser.add_argument("--output-dir", default="dist", help="Output directory for zip")
    args = parser.parse_args()

    data_dir = Path(args.data_dir) / args.city
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    output_file = output_dir / f"{args.city}_v{args.version}.zip"

    print(f"Packaging {args.city} v{args.version} -> {output_file}")
    raise NotImplementedError


if __name__ == "__main__":
    main()
