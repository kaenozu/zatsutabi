"""Build the compact SQLite asset from an OSM-derived normalized POI JSON export.

Usage with the full Japan extract is documented in README.md. The checked-in
sample input keeps local builds deterministic; replace it with the generated
normalized export when the Geofabrik pipeline is run.
"""
import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).parents[1]
input_path = ROOT / "tool" / "sample_pois.json"
output_path = ROOT / "assets" / "poi_osm.sqlite"
rows = json.loads(input_path.read_text(encoding="utf-8"))
output_path.parent.mkdir(parents=True, exist_ok=True)
if output_path.exists():
    output_path.unlink()
connection = sqlite3.connect(output_path)
connection.execute("CREATE TABLE poi (id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL, indoor INTEGER NOT NULL)")
connection.executemany("INSERT INTO poi VALUES (?, ?, ?, ?, ?, ?)", [(r["id"], r["name"], r["category"], r["latitude"], r["longitude"], int(r["indoor"])) for r in rows])
connection.execute("CREATE INDEX idx_poi_lat_lon ON poi(latitude, longitude)")
connection.commit()
connection.close()
print(f"rows={len(rows)} bytes={output_path.stat().st_size} path={output_path}")
