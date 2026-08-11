"""Build the compact SQLite asset from an OSM-derived normalized POI JSON export.

Usage with the full Japan extract is documented in README.md. The checked-in
sample input keeps local builds deterministic; replace it with the generated
normalized export when the Geofabrik pipeline is run.

Safety: by default the output is written to a build/ staging directory, never
over the production asset. Pass --output assets/poi_osm.sqlite explicitly only
when you intend to replace the bundled production database (e.g. after running
the full Geofabrik pipeline).
"""
import argparse
import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).parents[1]
DEFAULT_INPUT = ROOT / "tool" / "sample_pois.json"
DEFAULT_OUTPUT = ROOT / "build" / "poi_db" / "poi_osm.sqlite"
PRODUCTION_OUTPUT = ROOT / "assets" / "poi_osm.sqlite"


def build_database(input_path: Path, output_path: Path) -> int:
    """Create a compact poi table from the normalized JSON. Returns row count."""
    rows = json.loads(input_path.read_text(encoding="utf-8"))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()
    connection = sqlite3.connect(output_path)
    try:
        connection.execute(
            "CREATE TABLE poi (id TEXT PRIMARY KEY, name TEXT NOT NULL, "
            "category TEXT NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL, "
            "indoor INTEGER NOT NULL)"
        )
        connection.executemany(
            "INSERT INTO poi VALUES (?, ?, ?, ?, ?, ?)",
            [
                (
                    r["id"],
                    r["name"],
                    r["category"],
                    r["latitude"],
                    r["longitude"],
                    int(r["indoor"]),
                )
                for r in rows
            ],
        )
        connection.execute("CREATE INDEX idx_poi_lat_lon ON poi(latitude, longitude)")
        connection.commit()
    finally:
        connection.close()
    print(f"rows={len(rows)} bytes={output_path.stat().st_size} path={output_path}")
    return len(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=DEFAULT_INPUT,
        help="Normalized POI JSON export (default: tool/sample_pois.json)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=(
            "Output SQLite path. Defaults to build/poi_db/poi_osm.sqlite so a "
            "sample run can never overwrite the production asset. Pass "
            "assets/poi_osm.sqlite explicitly to publish a production database."
        ),
    )
    args = parser.parse_args()

    if args.output.resolve() == PRODUCTION_OUTPUT.resolve():
        answer = input(
            "WARNING: this overwrites the production asset assets/poi_osm.sqlite. "
            "Type 'publish' to continue: "
        )
        if answer.strip().lower() != "publish":
            print("aborted: production asset left untouched")
            raise SystemExit(1)

    build_database(args.input, args.output)


if __name__ == "__main__":
    main()
