"""SQLite database setup and connection helper."""

import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path

_DEFAULT_DB = str(Path(__file__).parent.parent / "veritas.db")


def _db_path() -> Path:
    return Path(os.environ.get("VERITAS_DB_PATH", _DEFAULT_DB))


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(_db_path())
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


@contextmanager
def db():
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db() -> None:
    with db() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS users (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                name          TEXT    NOT NULL,
                email         TEXT    UNIQUE NOT NULL,
                password_hash TEXT    NOT NULL,
                is_nerd       INTEGER NOT NULL DEFAULT 0,
                created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS daily_usage (
                user_id         INTEGER NOT NULL,
                date            TEXT    NOT NULL,
                analyses_count  INTEGER NOT NULL DEFAULT 0,
                questions_count INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (user_id, date),
                FOREIGN KEY (user_id) REFERENCES users(id)
            );
        """)
