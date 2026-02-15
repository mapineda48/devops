#!/bin/bash
set -euo pipefail

echo "[nginx-init] waiting for /mnt/deploy mount..."
for i in $(seq 1 90); do
  if mountpoint -q /mnt/deploy; then
    break
  fi
  sleep 1
done

if ! mountpoint -q /mnt/deploy; then
  echo "[nginx-init] ERROR: /mnt/deploy is not mounted"
  exit 1
fi

BASE_DIR="/mnt/deploy/vm/agape.js/docker"

echo "[nginx-init] ensuring persistent directories under $BASE_DIR"
mkdir -p "$BASE_DIR/certs" "$BASE_DIR/acme"

echo "[nginx-init] ensuring local pgadmin data dir"
mkdir -p /opt/mapineda48/data/pgadmin
chmod 0777 /opt/mapineda48/data/pgadmin

echo "[nginx-init] done"
