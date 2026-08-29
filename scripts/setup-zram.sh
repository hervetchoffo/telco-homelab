#!/usr/bin/env bash
#
# setup-zram.sh — Configure 512 MB zram swap on Raspberry Pi OS Trixie (v1.3.0)
#
# Idempotent — safe to run multiple times. Uses the standard Debian/RPi
# OS 'zram-tools' package (zramswap.service).
#
# Note: zram-tools versions differ in which key they read for sizing
# (SIZE in MB on newer versions, PERCENT of RAM on older ones). This
# script sets both keys so it works either way — the unused key is
# simply ignored by whichever version is installed. PERCENT=50 of a
# 1 GB Pi equals the same 512 MB target as SIZE=512.
#
# Usage:
#   ./setup-zram.sh
#
set -euo pipefail

ZRAM_SIZE_MB=512
ZRAM_PERCENT=50
ZRAM_PRIORITY=100
ZRAM_ALGO=lz4
DEFAULTS_FILE="/etc/default/zramswap"

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
die()  { echo "[$(date '+%H:%M:%S')] [ERROR] $*" >&2; exit 1; }

# ── 1. Install zram-tools if missing ─────────────────────────────────
if ! dpkg -s zram-tools &>/dev/null; then
  log "Installing zram-tools..."
  sudo apt-get update -qq
  sudo apt-get install -y zram-tools
else
  log "[OK] zram-tools already installed"
fi

[[ -f "$DEFAULTS_FILE" ]] || die "$DEFAULTS_FILE not found after zram-tools install — unexpected package layout, check 'dpkg -L zram-tools'"

# ── 2. Configure size (idempotent — rewrite or append each key) ──────
sudo cp "$DEFAULTS_FILE" "${DEFAULTS_FILE}.bak.$(date +%s)"

set_kv() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "$DEFAULTS_FILE"; then
    sudo sed -i "s/^${key}=.*/${key}=${value}/" "$DEFAULTS_FILE"
  elif grep -q "^#${key}=" "$DEFAULTS_FILE"; then
    sudo sed -i "s/^#${key}=.*/${key}=${value}/" "$DEFAULTS_FILE"
  else
    echo "${key}=${value}" | sudo tee -a "$DEFAULTS_FILE" > /dev/null
  fi
}

set_kv "ALGO"     "$ZRAM_ALGO"
set_kv "SIZE"     "$ZRAM_SIZE_MB"
set_kv "PERCENT"  "$ZRAM_PERCENT"
set_kv "PRIORITY" "$ZRAM_PRIORITY"

log "[OK] $DEFAULTS_FILE configured: ALGO=$ZRAM_ALGO SIZE=${ZRAM_SIZE_MB}MB PERCENT=${ZRAM_PERCENT}% PRIORITY=$ZRAM_PRIORITY"

# ── 3. Enable and (re)start the service ───────────────────────────────
sudo systemctl enable zramswap.service &>/dev/null || true
sudo systemctl restart zramswap.service
sleep 1

# ── 4. Validate ─────────────────────────────────────────────────────
log "Current zram devices:"
zramctl || die "zramctl reported no active zram devices — check 'systemctl status zramswap'"

log "Current swap summary:"
swapon --show

log "[OK] setup-zram.sh complete"
