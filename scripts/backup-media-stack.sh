#!/usr/bin/env bash
# Backup the whole media stack (configs + databases) before moving to macOS.
#
#   ./backup-media-stack.sh [OUT_DIR]
#
# Default OUT_DIR: ~/backups
# Output: media-stack-YYYYmmdd-HHMMSS.tar.zst (+ .sha256)
#
# Notes:
#  - SQLite databases are copied with "sqlite3 .backup" (consistent even while
#    the service is running). H2 (Suwayomi) is copied as-is: stop it first if
#    you want a guaranteed-consistent copy.
#  - Caches, logs, transcodes and cover art are excluded.
#  - gluetun.env (WireGuard keys!) is included with mode 600.

set -euo pipefail

SRC="${SRC:-/home/emily/containers}"
OUT="${1:-$HOME/backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"
STAGE="$(mktemp -d)"
TARBALL="$OUT/media-stack-$STAMP.tar.zst"
trap 'rm -rf "$STAGE"' EXIT

APPS=(jellyfin qbittorrent jackett radarr sonarr anibridge suwayomi shoko)

mkdir -p "$OUT" "$STAGE/configs"
chmod 700 "$STAGE"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 not found. Run: nix shell nixpkgs#sqlite -c $0" >&2
  exit 1
fi

echo "==> copying configs (without caches/logs/covers)"
for app in "${APPS[@]}"; do
  [[ -d "$SRC/$app" ]] || continue
  rsync -a \
    --exclude='log/' --exclude='logs/' --exclude='cache/' \
    --exclude='transcodes/' --exclude='MediaCover/' --exclude='Sentry/' \
    --exclude='downloads/thumbnails/' \
    "$SRC/$app" "$STAGE/configs/"
done

echo "==> consistent SQLite copies"
sqlite_backup() {
  local db="$1" rel="$2"
  [[ -f "$db" ]] || return 0
  mkdir -p "$STAGE/configs/$(dirname "$rel")"
  sqlite3 "$db" ".backup '$STAGE/configs/$rel'"
  rm -f "$STAGE/configs/$rel-wal" "$STAGE/configs/$rel-shm"
  echo "    $rel"
}
sqlite_backup "$SRC/sonarr/sonarr.db"                "sonarr/sonarr.db"
sqlite_backup "$SRC/radarr/radarr.db"                "radarr/radarr.db"
sqlite_backup "$SRC/anibridge/anibridge.db"          "anibridge/anibridge.db"
sqlite_backup "$SRC/jellyfin/data/data/jellyfin.db"  "jellyfin/data/data/jellyfin.db"
sqlite_backup "$SRC/shoko/SQLite/JMMServer.db3"      "shoko/SQLite/JMMServer.db3"
sqlite_backup "$SRC/shoko/SQLite/Quartz.db3"         "shoko/SQLite/Quartz.db3"

if [[ -f "$SRC/gluetun.env" ]]; then
  echo "==> WireGuard / gluetun env"
  install -m 600 "$SRC/gluetun.env" "$STAGE/configs/gluetun.env"
fi

cat > "$STAGE/README-MIGRATION.txt" <<'EOF'
Media stack backup
==================
Restore target paths on macOS:

  container path   ->  native macOS path
  /media           ->  /Volumes/HDD/Media
  /downloads       ->  /Volumes/HDD/Download
  /config          ->  ~/Library/Application Support/<app>   (per app, see below)

Suggested native config locations:
  sonarr      ~/Library/Application Support/Sonarr
  radarr      ~/Library/Application Support/Radarr
  prowlarr    ~/Library/Application Support/Prowlarr
  qbittorrent ~/Library/Application Support/qBittorrent
  jellyfin    ~/Library/Application Support/jellyfin
  shoko       ~/Library/Application Support/ShokoServer   (if run natively)
  suwayomi    ~/Library/Application Support/Tachidesk
  anibridge   ~/Library/Application Support/anibridge      (config.yaml + DB)
  jackett     ~/Library/Application Support/Jackett

After restoring, run scripts/rewrite-paths.py against the restored tree:
  python3 rewrite-paths.py --configs <restored-tree> --apply

The disk label is already "HDD", so macOS mounts it at /Volumes/HDD.
EOF

echo "==> packing $TARBALL"
tar -C "$STAGE" --zstd -cf "$TARBALL" .
(cd "$OUT" && sha256sum "$(basename "$TARBALL")" > "$(basename "$TARBALL").sha256")

echo
echo "done: $TARBALL"
du -h "$TARBALL"
cat "$TARBALL.sha256"
