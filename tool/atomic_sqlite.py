"""Failure-atomic helpers for generated SQLite assets."""

from __future__ import annotations

import os
import sqlite3
import uuid
from collections.abc import Callable
from pathlib import Path


def build_sqlite_atomically(
    output_path: Path,
    writer: Callable[[sqlite3.Connection], int],
) -> int:
    """Build and validate a SQLite DB beside the destination, then replace it.

    The existing destination is never removed before the replacement DB is
    fully committed, closed, integrity-checked, and fsynced.
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = output_path.with_name(
        f".{output_path.name}.{uuid.uuid4().hex}.tmp",
    )

    try:
        connection = sqlite3.connect(temp_path)
        try:
            row_count = writer(connection)
            connection.commit()
            integrity = connection.execute("PRAGMA integrity_check").fetchone()
            if integrity is None or integrity[0] != "ok":
                raise RuntimeError(f"SQLite integrity_check failed: {integrity!r}")
        finally:
            connection.close()

        with temp_path.open("rb") as database_file:
            os.fsync(database_file.fileno())

        os.replace(temp_path, output_path)
        return row_count
    except BaseException:
        temp_path.unlink(missing_ok=True)
        raise
