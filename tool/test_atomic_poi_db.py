import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from tool.generate_poi_db import build_database


class AtomicPoiDatabaseTests(unittest.TestCase):
    def test_failed_generation_preserves_existing_database(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            output = root / "poi.sqlite"
            output.write_bytes(b"known-good-database")
            source = root / "pois.json"
            source.write_text(
                json.dumps(
                    [
                        {
                            "id": "duplicate",
                            "name": "A",
                            "category": "test",
                            "latitude": 35.0,
                            "longitude": 139.0,
                            "indoor": 1,
                        },
                        {
                            "id": "duplicate",
                            "name": "B",
                            "category": "test",
                            "latitude": 36.0,
                            "longitude": 140.0,
                            "indoor": 0,
                        },
                    ]
                ),
                encoding="utf-8",
            )

            with self.assertRaises(sqlite3.IntegrityError):
                build_database(source, output)

            self.assertEqual(output.read_bytes(), b"known-good-database")
            self.assertEqual(list(root.glob(".poi.sqlite.*.tmp")), [])

    def test_successful_generation_replaces_destination_with_valid_database(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            output = root / "poi.sqlite"
            output.write_bytes(b"old")
            source = root / "pois.json"
            source.write_text(
                json.dumps(
                    [
                        {
                            "id": "one",
                            "name": "One",
                            "category": "test",
                            "latitude": 35.0,
                            "longitude": 139.0,
                            "indoor": 1,
                        }
                    ]
                ),
                encoding="utf-8",
            )

            self.assertEqual(build_database(source, output), 1)
            connection = sqlite3.connect(output)
            try:
                self.assertEqual(connection.execute("PRAGMA integrity_check").fetchone()[0], "ok")
                self.assertEqual(connection.execute("SELECT COUNT(*) FROM poi").fetchone()[0], 1)
            finally:
                connection.close()


if __name__ == "__main__":
    unittest.main()
