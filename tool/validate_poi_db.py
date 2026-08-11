"""Validate the production POI database that ships in assets/.

Checks, in order:
  1. The file exists and is a readable SQLite database.
  2. PRAGMA integrity_check returns 'ok'.
  3. The expected schema (poi table + idx_poi_lat_lon index) is present.
  4. The row count is within [min_rows, max_rows].
  5. A few known regions NOT covered by the in-app fallback return rows, so a
     regression to the 7-entry sample cannot pass silently.

Exit code 0 on success, 1 on any failure. Run in CI after a production DB is
checked in.
"""
from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path

# The in-app fallback covers Tokyo/Saitama/Osaka/Kyoto/Fukuoka/Sapporo area
# POIs only. Probe far-flung prefectures so a 7-row sample cannot satisfy this.
PROBE_QUERIES: list[tuple[str, float, float, float]] = [
    ("Okinawa (Naha)", 26.2124, 127.6809, 60.0),
    ("Kagoshima (city)", 31.5966, 130.5571, 60.0),
    ("Aomori (city)", 40.8223, 140.7474, 60.0),
    ("Niigata (city)", 37.9161, 139.0364, 60.0),
    ("Kochi (city)", 33.5597, 133.5311, 60.0),
]


def validate(db_path: Path, min_rows: int, max_rows: int) -> int:
    failures: list[str] = []

    if not db_path.exists():
        failures.append(f"database not found: {db_path}")
        return 1
    if db_path.stat().st_size < 1024:
        failures.append(f"database suspiciously small: {db_path.stat().st_size} bytes")

    connection: sqlite3.Connection | None = None
    try:
        connection = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    except sqlite3.Error as exc:  # pragma: no cover - sqlite rarely throws here
        failures.append(f"cannot open database: {exc}")
        return 1

    try:
        row = connection.execute("PRAGMA integrity_check").fetchone()
        if not row or row[0] != "ok":
            failures.append(f"integrity_check failed: {row}")

        tables = {
            r[0] for r in connection.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            )
        }
        if "poi" not in tables:
            failures.append("schema: missing table 'poi'")
        else:
            columns = {
                r[1] for r in connection.execute("PRAGMA table_info(poi)")
            }
            expected = {"id", "name", "category", "latitude", "longitude", "indoor"}
            missing = expected - columns
            if missing:
                failures.append(f"schema: poi missing columns {sorted(missing)}")
            row_count = connection.execute("SELECT COUNT(*) FROM poi").fetchone()[0]
            if not (min_rows <= row_count <= max_rows):
                failures.append(
                    f"row count {row_count} outside expected range "
                    f"[{min_rows}, {max_rows}]"
                )

        indexes = {
            r[0] for r in connection.execute(
                "SELECT name FROM sqlite_master WHERE type='index'"
            )
        }
        if "idx_poi_lat_lon" not in indexes:
            failures.append("schema: missing index 'idx_poi_lat_lon'")

        for label, lat, lon, radius in PROBE_QUERIES:
            dlat = radius / 111.0
            dlon = radius / (111.0 * 0.75)
            count = connection.execute(
                "SELECT COUNT(*) FROM poi WHERE latitude BETWEEN ? AND ? "
                "AND longitude BETWEEN ? AND ?",
                (lat - dlat, lat + dlat, lon - dlon, lon + dlon),
            ).fetchone()[0]
            if count == 0:
                failures.append(f"region probe '{label}' returned 0 rows")

    except sqlite3.Error as exc:
        failures.append(f"query failed: {exc}")
    finally:
        connection.close()

    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    if failures:
        print(f"validation failed with {len(failures)} issue(s)", file=sys.stderr)
        return 1
    print(
        f"OK: {db_path.name} integrity ok, schema ok, rows in range, "
        f"{len(PROBE_QUERIES)} region probes passed"
    )
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("db", type=Path, help="Path to the SQLite database")
    parser.add_argument(
        "--min-rows",
        type=int,
        default=10000,
        help="Minimum expected row count (default 10000)",
    )
    parser.add_argument(
        "--max-rows",
        type=int,
        default=100000,
        help="Maximum expected row count (default 100000)",
    )
    args = parser.parse_args()
    raise SystemExit(validate(args.db, args.min_rows, args.max_rows))


if __name__ == "__main__":
    main()
