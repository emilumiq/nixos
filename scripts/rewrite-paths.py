#!/usr/bin/env python3
"""Rewrite container paths to macOS paths in configs and databases.

Examples:
  python3 rewrite-paths.py --configs /path/to/restored --dry-run
  python3 rewrite-paths.py --configs /path/to/restored --apply \
      --media-from /media --media-to /Volumes/HDD/Media \
      --downloads-from /downloads --downloads-to /Volumes/HDD/Download

Handles:
  * SQLite databases (Sonarr, Radarr, Jellyfin, Shoko, AniBridge)
  * bencoded qBittorrent .fastresume files (length-prefixed -> safe rewrite)
  * text configs (.conf .ini .xml .json .yaml .yml .txt .mblink .collection)

Never touches media files or .torrent files. Always make a backup first.
"""

from __future__ import annotations

import argparse
import os
import sqlite3
import sys
from pathlib import Path

DB_SUFFIXES = {".db", ".db3", ".sqlite", ".sqlite3"}
TEXT_SUFFIXES = {
    ".conf", ".ini", ".cfg", ".xml", ".json", ".yaml", ".yml",
    ".txt", ".mblink", ".collection", ".properties",
}


def replace_bytes(data: bytes, pairs: list[tuple[bytes, bytes]]) -> bytes:
    for old, new in pairs:
        data = data.replace(old, new)
    return data


# --------------------------------------------------------------------------
# bencode (minimal, preserves types)
# --------------------------------------------------------------------------
def bdecode(data: bytes):
    def parse(i: int):
        c = data[i:i + 1]
        if c == b"i":
            end = data.index(b"e", i)
            return int(data[i + 1:end]), end + 1
        if c == b"l":
            i += 1
            items = []
            while data[i:i + 1] != b"e":
                v, i = parse(i)
                items.append(v)
            return items, i + 1
        if c == b"d":
            i += 1
            d = {}
            while data[i:i + 1] != b"e":
                k, i = parse(i)
                v, i = parse(i)
                d[k] = v
            return d, i + 1
        if c.isdigit():
            colon = data.index(b":", i)
            n = int(data[i:colon])
            start = colon + 1
            return data[start:start + n], start + n
        raise ValueError(f"bad bencode at {i}: {c!r}")

    value, _ = parse(0)
    return value


def bencode(value) -> bytes:
    if isinstance(value, int):
        return b"i" + str(value).encode() + b"e"
    if isinstance(value, bytes):
        return str(len(value)).encode() + b":" + value
    if isinstance(value, list):
        return b"l" + b"".join(bencode(v) for v in value) + b"e"
    if isinstance(value, dict):
        out = b"d"
        for k in sorted(value):
            out += bencode(k) + bencode(value[k])
        return out + b"e"
    raise TypeError(type(value))


def rewrite_bencoded(data: bytes, pairs: list[tuple[bytes, bytes]]) -> bytes:
    tree = bdecode(data)

    def walk(v):
        if isinstance(v, bytes):
            return replace_bytes(v, pairs)
        if isinstance(v, list):
            return [walk(x) for x in v]
        if isinstance(v, dict):
            return {k: walk(x) for k, x in v.items()}
        return v

    return bencode(walk(tree))


# --------------------------------------------------------------------------
# SQLite
# --------------------------------------------------------------------------
def rewrite_sqlite(path: Path, pairs: list[tuple[bytes, bytes]], apply: bool) -> int:
    str_pairs = [(o.decode(), n.decode()) for o, n in pairs]
    conn = sqlite3.connect(path)
    total = 0
    try:
        tables = [
            r[0] for r in conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table' "
                "AND name NOT LIKE 'sqlite_%'"
            )
        ]
        for table in tables:
            cols = [r[1] for r in conn.execute(f'PRAGMA table_info("{table}")')]
            for col in cols:
                where = " OR ".join(f'"{col}" LIKE ?' for _ in str_pairs)
                likes = [f"%{old}%" for old, _ in str_pairs]
                try:
                    n = conn.execute(
                        f'SELECT COUNT(*) FROM "{table}" WHERE {where}', likes
                    ).fetchone()[0]
                except sqlite3.Error:
                    continue
                if not n:
                    continue
                total += n
                print(f"  {path.name}: {table}.{col}: {n} row(s)")
                if apply:
                    expr = f'"{col}"'
                    params: list[str] = []
                    for old, new in str_pairs:
                        expr = f'REPLACE({expr}, ?, ?)'
                        params += [old, new]
                    conn.execute(
                        f'UPDATE "{table}" SET "{col}" = {expr} WHERE {where}',
                        params + likes,
                    )
        if apply:
            conn.commit()
            conn.execute("VACUUM")
            conn.commit()
    finally:
        conn.close()
    return total


# --------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--configs", required=True, type=Path)
    ap.add_argument("--media-from", default="/media")
    ap.add_argument("--media-to", default="/Volumes/HDD/Media")
    ap.add_argument("--downloads-from", default="/downloads")
    ap.add_argument("--downloads-to", default="/Volumes/HDD/Download")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not args.configs.exists():
        print(f"not found: {args.configs}", file=sys.stderr)
        return 1

    pairs = [
        (args.media_from.encode(), args.media_to.encode()),
        (args.downloads_from.encode(), args.downloads_to.encode()),
    ]
    apply = args.apply and not args.dry_run
    print(f"mode: {'APPLY' if apply else 'DRY-RUN'}")
    print(f"  {args.media_from} -> {args.media_to}")
    print(f"  {args.downloads_from} -> {args.downloads_to}")

    changed = 0
    for path in sorted(args.configs.rglob("*")):
        if not path.is_file():
            continue
        suffix = path.suffix.lower()
        rel = path.relative_to(args.configs)
        try:
            if suffix in DB_SUFFIXES:
                n = rewrite_sqlite(path, pairs, apply)
                if n:
                    changed += n
            elif suffix == ".fastresume":
                raw = path.read_bytes()
                new = rewrite_bencoded(raw, pairs)
                if new != raw:
                    print(f"  fastresume: {rel}")
                    changed += 1
                    if apply:
                        path.write_bytes(new)
            elif suffix in TEXT_SUFFIXES:
                raw = path.read_bytes()
                new = replace_bytes(raw, pairs)
                if new != raw:
                    print(f"  text: {rel}")
                    changed += 1
                    if apply:
                        path.write_bytes(new)
        except Exception as exc:  # noqa: BLE001
            print(f"  SKIP {rel}: {exc}", file=sys.stderr)

    print(f"\n{'updated' if apply else 'would update'}: {changed} item(s)")
    if not apply:
        print("re-run with --apply to write changes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
