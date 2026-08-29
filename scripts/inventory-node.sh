#!/usr/bin/env bash
#
# inventory-node.sh — Hardware inventory for telco-homelab nodes (v1.3.0)
#
# Run ONCE per node, right after first SSH login, BEFORE setup-node.sh.
# Read-only: makes no changes to the system.
#
# Captures: OS/kernel, Pi model, RAM, micro SD card, USB block devices,
# network interfaces, Sundtek tuner (USB-level only — see note below),
# and current cgroup status ahead of K3s install.
#
# IMPORTANT — Sundtek tuner detection:
#   The Sundtek driver is intentionally NOT installed on the host OS.
#   It will be installed inside the Tvheadend container at milestone
#   v1.11.0, keeping host state minimal (immutable infrastructure
#   principle — the driver becomes part of a versioned image, not
#   host-level package state).
#   This means only USB-level identification is possible here:
#   vendor/product ID, descriptors, negotiated speed. Tuner capability
#   details (DVB standards, signal lock) require the driver and are
#   out of scope for this script.
#
# Usage:
#   ./inventory-node.sh | tee ~/inventory-$(hostname).txt
#
set -euo pipefail

SEP="────────────────────────────────────────────────────────────"
section() { echo; echo "## $1"; echo "$SEP"; }

# Known Sundtek USB vendor:product IDs seen in this project.
# Extend this list if a different Sundtek model is used later.
KNOWN_TUNER_IDS=("2659:1212")  # Sundtek MediaTV Pro III MiniPCIe (EU)

echo "# telco-homelab — hardware inventory"
echo "# Host: $(hostname)  |  Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# ── OS & Kernel ─────────────────────────────────────────────────────
section "OS & Kernel"
uname -a
grep -E "^(NAME|VERSION|VERSION_CODENAME)=" /etc/os-release

# ── Raspberry Pi hardware ───────────────────────────────────────────
section "Raspberry Pi Hardware"
grep -E "^(Hardware|Revision|Serial|Model)" /proc/cpuinfo || true
echo "CPU cores : $(nproc)"
echo "CPU arch  : $(uname -m)"
if command -v vcgencmd &>/dev/null; then
  echo "CPU temp  : $(vcgencmd measure_temp 2>/dev/null || echo 'n/a')"
fi

# ── Memory ───────────────────────────────────────────────────────────
section "Memory"
free -h

# ── Micro SD card ────────────────────────────────────────────────────
section "Micro SD Card (/dev/mmcblk0)"
if [[ -e /dev/mmcblk0 ]]; then
  lsblk /dev/mmcblk0 --output NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
  [[ -e /sys/block/mmcblk0/device/name ]] && \
    echo "Card model: $(cat /sys/block/mmcblk0/device/name)"
else
  echo "Not found at /dev/mmcblk0"
fi

# ── USB devices (raw) ─────────────────────────────────────────────────
section "USB Devices (lsusb)"
lsusb

# ── Block devices (all disks, USB HDDs included) ───────────────────────
section "Block Devices"
lsblk --output NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,TRAN,MODEL

section "Disk Details (fdisk -l per disk)"
for disk in $(lsblk -dnp -o NAME,TYPE | awk '$2=="disk"{print $1}'); do
  echo "--- $disk ---"
  sudo fdisk -l "$disk" 2>/dev/null || echo "(no readable partition table)"
  echo
done

# ── Network interfaces ───────────────────────────────────────────────
section "Network Interfaces"
ip -brief addr show
echo
echo "MAC addresses:"
ip -o link show | awk -F': ' '!/lo/{iface=$2} /ether/{print "  " iface ": " $2}' \
  || ip link show | awk '/ether/{print "  " $2}'

# ── TV Tuner — USB-level detection only (see header note) ──────────────
section "TV Tuner — USB-level detection"
echo "Note: Sundtek driver is deliberately NOT installed on this host."
echo "      Only USB enumeration is available here. Driver + DVB-level"
echo "      detail (frontend, supported standards) comes at v1.11.0."
echo

found_known=false
for id in "${KNOWN_TUNER_IDS[@]}"; do
  if lsusb -d "$id" &>/dev/null; then
    echo "Matched known tuner ID: $id"
    lsusb -d "$id"
    echo
    echo "Full descriptor (informational — driver not loaded, some fields absent):"
    lsusb -v -d "$id" 2>/dev/null | head -25
    found_known=true
    break
  fi
done

if ! $found_known; then
  echo "No match against known IDs (${KNOWN_TUNER_IDS[*]})."
  echo "Loose match attempt (sundtek/media/tuner in description):"
  lsusb | grep -iE "sundtek|media|tuner" || echo "  (none found — is the tuner plugged in?)"
fi

echo
echo "Recent USB kernel messages (dmesg, filtered):"
dmesg | grep -iE "usb.*(new|device found)" | tail -15 || echo "  (dmesg not readable — try with sudo)"

# ── cgroup status (K3s prerequisite check) ─────────────────────────────
section "cgroup Status (pre-K3s check)"
echo "/proc/cgroups (memory row is what K3s needs):"
awk 'NR==1 || /memory|cpu/' /proc/cgroups
echo
CMDLINE_FILE="/boot/firmware/cmdline.txt"
if [[ -f "$CMDLINE_FILE" ]]; then
  echo "$CMDLINE_FILE:"
  cat "$CMDLINE_FILE"
  if grep -q "cgroup_memory=1" "$CMDLINE_FILE"; then
    echo "  → cgroup_memory=1 already present"
  else
    echo "  → cgroup_memory=1 NOT yet present (setup-node.sh will add it)"
  fi
else
  echo "[WARNING] $CMDLINE_FILE not found — unexpected on Trixie. Check /boot/cmdline.txt (pre-Trixie path)."
fi

section "Inventory Complete"
echo "Hostname : $(hostname)"
echo "IP(s)    : $(hostname -I)"
echo "Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo
echo "Next step: commit this output to docs/hardware/inventory-\$(hostname).txt"
echo "Then run: ./setup-node.sh"
