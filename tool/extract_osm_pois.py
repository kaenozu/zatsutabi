"""Extract destination-like POIs from a Geofabrik OSM PBF into SQLite.

Usage:
  python tool/extract_osm_pois.py tool/japan-260810.osm.pbf assets/poi_osm.sqlite

The PBF is a build-time input and is never copied into the Flutter asset set.
Requires the ``osmium`` Python package (``python -m pip install osmium``).
"""
from __future__ import annotations

import argparse
import math
import sqlite3
from pathlib import Path

import osmium

TAG_TO_CATEGORY = {
    "museum": "博物館",
    "gallery": "美術館・ギャラリー",
    "aquarium": "水族館",
    "zoo": "動物園",
    "theme_park": "テーマパーク",
    "attraction": "観光施設",
    "viewpoint": "展望地点",
    "park": "公園・散歩",
    "water_park": "ウォーターパーク",
    "nature_reserve": "自然保護区",
    "castle": "城・史跡",
    "ruins": "城・史跡",
    "archaeological_site": "城・史跡",
    "beach": "海岸",
    "arts_centre": "文化施設",
    "public_bath": "日帰り温泉",
    "swimming_pool": "プール",
}
INDOOR_CATEGORIES = {"museum", "gallery", "aquarium", "arts_centre", "public_bath", "swimming_pool"}


def classify(tags: dict[str, str]) -> tuple[str, bool] | None:
    for key in ("tourism", "leisure", "historic", "natural", "amenity"):
        value = tags.get(key)
        if value in TAG_TO_CATEGORY:
            return TAG_TO_CATEGORY[value], value in INDOOR_CATEGORIES
    return None


class PoiHandler(osmium.SimpleHandler):
    def __init__(self, include_ways: bool = False) -> None:
        super().__init__()
        self.include_ways = include_ways
        self.rows: dict[str, tuple[str, str, float, float, int]] = {}

    def _add(self, element_id: int, tags: dict[str, str], latitude: float, longitude: float, classified: tuple[str, bool] | None = None) -> None:
        name = (tags.get("name:ja") or tags.get("name") or "").strip()
        if not name or not math.isfinite(latitude) or not math.isfinite(longitude):
            return
        classified = classified or classify(tags)
        if classified is None:
            return
        category, indoor = classified
        stable_id = f"osm-{element_id}"
        self.rows[stable_id] = (name, category, latitude, longitude, int(indoor))

    def node(self, node: osmium.osm.Node) -> None:
        tags = dict(node.tags)
        classified = classify(tags)
        if classified is not None:
            self._add(node.id, tags, node.location.lat, node.location.lon, classified)

    def way(self, way: osmium.osm.Way) -> None:
        if not self.include_ways:
            return
        tags = dict(way.tags)
        classified = classify(tags)
        if classified is None or not (tags.get("name:ja") or tags.get("name")) or not way.nodes:
            return
        points = [(node.lat, node.lon) for node in way.nodes if node.location.valid()]
        if not points:
            return
        latitude = sum(point[0] for point in points) / len(points)
        longitude = sum(point[1] for point in points) / len(points)
        self._add(way.id, dict(way.tags), latitude, longitude)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pbf", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--include-ways", action="store_true", help="also extract named POI ways; slower and optional")
    args = parser.parse_args()
    if not args.pbf.exists():
        raise SystemExit(f"PBF not found: {args.pbf}")
    handler = PoiHandler(include_ways=args.include_ways)
    handler.apply_file(str(args.pbf), locations=args.include_ways)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.output.exists():
        args.output.unlink()
    connection = sqlite3.connect(args.output)
    connection.execute("CREATE TABLE poi (id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL, indoor INTEGER NOT NULL)")
    connection.executemany("INSERT INTO poi VALUES (?, ?, ?, ?, ?, ?)", [(key, *row) for key, row in handler.rows.items()])
    connection.execute("CREATE INDEX idx_poi_lat_lon ON poi(latitude, longitude)")
    connection.commit()
    count = connection.execute("SELECT COUNT(*) FROM poi").fetchone()[0]
    connection.close()
    print(f"source_bytes={args.pbf.stat().st_size} rows={count} db_bytes={args.output.stat().st_size} output={args.output}")


if __name__ == "__main__":
    main()
