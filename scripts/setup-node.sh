#!/usr/bin/env bash
#
# setup-node.sh — Prepare a Raspberry Pi OS Trixie node for K3s (v1.3.0)
#
# Idempotent — safe to run multiple times. Targets Raspberry Pi OS Lite
# 32-bit (Trixie / Debian 13), ARMv7l. Boot config path is Trixie's
# /boot/firmware/ (not the pre-Trixie /boot/). See ADR-003.
#
# What this script does NOT do (by design):
#   - Does NOT set a static IP on the interface. IP addressing is
#     handled by a router-side DHCP reservation (MAC → IP), verified
#     here, not configured here. See project decision log, v1.3.0.
#   - Does NOT install K3s. See install-k3s.sh (stub) and v1.4.0/v1.5.0.
#   - Does NOT install the Sundtek driver. See v1.11.0.
#
# Usage:
#   ./setup-node.sh                    # auto-detect role from hostname
#   ./setup-node.sh --role server      # force role (server|agent)
#   ./setup-node.sh --wipe-disk        # confirm destructive disk format
#   ./setup-node.sh --skip-disk        # skip disk setup entirely
#
set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────
declare -A NODE_IP=(
  [server]="192.168.1.100"
  [agent]="192.168.1.101"
)
declare -A NODE_HOSTNAME=(
  [server]="pi-server"
  [agent]="pi-agent"
)

CMDLINE_FILE="/boot/firmware/cmdline.txt"
CGROUP_FLAGS="cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1"
MOUNT_POINT="/mnt/k3s-storage"
FSTAB_LABEL="k3sstorage"
ADMIN_USER="${SUDO_USER:-$(whoami)}"

WIPE_DISK=false
SKIP_DISK=false
FORCE_ROLE=""
REBOOT_REQUIRED=false

# ── Argument parsing ─────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)      FORCE_ROLE="$2"; shift 2 ;;
    --wipe-disk) WIPE_DISK=true; shift ;;
    --skip-disk) SKIP_DISK=true; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "[ERROR] Unknown argument: $1" >&2; exit 1 ;;
  esac
done

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
warn() { echo "[$(date '+%H:%M:%S')] [WARN] $*" >&2; }
die()  { echo "[$(date '+%H:%M:%S')] [ERROR] $*" >&2; exit 1; }

# ── Role detection ───────────────────────────────────────────────────
detect_role() {
  if [[ -n "$FORCE_ROLE" ]]; then
    echo "$FORCE_ROLE"
    return
  fi
  local h
  h=$(hostname)
  for role in "${!NODE_HOSTNAME[@]}"; do
    if [[ "${NODE_HOSTNAME[$role]}" == "$h" ]]; then
      echo "$role"
      return
    fi
  done
  die "Cannot detect role from hostname '$h'. Use --role server|agent."
}

ROLE=$(detect_role)
[[ -n "${NODE_IP[$ROLE]:-}" ]] || die "Unknown role '$ROLE'. Expected: server|agent."
EXPECTED_IP="${NODE_IP[$ROLE]}"
EXPECTED_HOSTNAME="${NODE_HOSTNAME[$ROLE]}"

# ── 1. Verify hostname ───────────────────────────────────────────────
verify_hostname() {
  local current
  current=$(hostname)
  [[ "$current" == "$EXPECTED_HOSTNAME" ]] || \
    die "Hostname mismatch: expected '$EXPECTED_HOSTNAME', got '$current'. Fix via hostnamectl before proceeding."
  log "[OK] Hostname matches: $current"
}

# ── 2. Verify IP (DHCP reservation, not manually configured) ─────────
verify_expected_ip() {
  local current_ip
  current_ip=$(hostname -I | awk '{print $1}')
  if [[ "$current_ip" != "$EXPECTED_IP" ]]; then
    warn "Expected IP ${EXPECTED_IP}, got '${current_ip}'."
    warn "This project relies on a router-side DHCP reservation (MAC → IP),"
    warn "not a manually configured static IP. Current MAC address(es):"
    ip -o link show | awk '/ether/{print "  " $2}'
    die "Configure a DHCP reservation for this MAC on your router, then re-run."
  fi
  log "[OK] IP matches expected: $current_ip"
}

# ── 3. Enable cgroups for K3s (Trixie boot path) ─────────────────────
configure_cgroups() {
  [[ -f "$CMDLINE_FILE" ]] || die "cmdline.txt not found at $CMDLINE_FILE (unexpected on Trixie — check /boot/cmdline.txt for pre-Trixie layout)"

  if grep -q "cgroup_memory=1" "$CMDLINE_FILE"; then
    log "[OK] cgroup flags already present in $CMDLINE_FILE"
    return
  fi

  log "Appending cgroup flags to $CMDLINE_FILE"
  sudo cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak.$(date +%s)"
  sudo sed -i "\$ s/\$/ ${CGROUP_FLAGS}/" "$CMDLINE_FILE"
  log "[OK] cgroup flags appended. A reboot is required for them to take effect."
  REBOOT_REQUIRED=true
}

# ── 4. USB disk: detect, format XFS+prjquota, mount, fstab ───────────
ensure_disk_tools() {
  # xfsprogs (mkfs.xfs) is NOT part of the Raspberry Pi OS Lite base
  # image — discovered during v1.3.0 on-hardware testing. parted is
  # checked defensively too, though it was present on tested nodes.
  local missing_pkgs=()
  command -v parted   &>/dev/null || missing_pkgs+=("parted")
  command -v mkfs.xfs &>/dev/null || missing_pkgs+=("xfsprogs")

  if [[ ${#missing_pkgs[@]} -eq 0 ]]; then
    log "[OK] Required disk tools already present (parted, xfsprogs)"
    return
  fi

  log "Installing missing disk tools: ${missing_pkgs[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing_pkgs[@]}"

  command -v parted   &>/dev/null || die "parted still not found after installing 'parted' package"
  command -v mkfs.xfs &>/dev/null || die "mkfs.xfs still not found after installing 'xfsprogs' package"
  log "[OK] Disk tools installed: ${missing_pkgs[*]}"
}

setup_usb_disk() {
  if $SKIP_DISK; then
    log "[SKIP] Disk setup skipped (--skip-disk)"
    return
  fi

  mapfile -t candidates < <(lsblk -dnp -o NAME,TYPE,TRAN | awk '$2=="disk" && $3=="usb"{print $1}')

  if [[ ${#candidates[@]} -eq 0 ]]; then
    die "No USB disk detected (lsblk TRAN=usb). Check 'lsusb' and 'lsblk' — is the disk plugged in and powered?"
  fi
  if [[ ${#candidates[@]} -gt 1 ]]; then
    die "Multiple USB disks detected (${candidates[*]}). This script expects exactly one per node. Aborting for safety — use --skip-disk and configure manually if intentional."
  fi

  local disk="${candidates[0]}"
  local part="${disk}1"
  log "Target USB disk: $disk"

  local current_fstype
  current_fstype=$(lsblk -no FSTYPE "$part" 2>/dev/null || true)

  if [[ "$current_fstype" == "xfs" ]] && grep -qF "$MOUNT_POINT" /etc/fstab; then
    log "[OK] $part already XFS and present in /etc/fstab — skipping format"
  else
    if ! $WIPE_DISK; then
      die "$part is not XFS (found: '${current_fstype:-none}'), or fstab entry missing. This disk may contain existing data. This is a DESTRUCTIVE operation — re-run with --wipe-disk once you have confirmed it is safe to erase $disk."
    fi

    ensure_disk_tools

    log "[WIPE] Formatting $disk as a single XFS partition (this destroys all existing data on $disk)"
    sudo wipefs -a "$disk"
    sudo parted -s "$disk" mklabel gpt
    sudo parted -s "$disk" mkpart primary xfs 0% 100%
    sleep 2  # allow the kernel to re-read the new partition table
    sudo mkfs.xfs -f -L "$FSTAB_LABEL" "$part"
    log "[OK] $part formatted as XFS (label: $FSTAB_LABEL)"
  fi

  sudo mkdir -p "$MOUNT_POINT"

  local uuid
  uuid=$(sudo blkid -s UUID -o value "$part")
  [[ -n "$uuid" ]] || die "Could not read UUID for $part after formatting"
  local fstab_line="UUID=${uuid} ${MOUNT_POINT} xfs defaults,prjquota 0 2"

  if ! grep -qF "$MOUNT_POINT" /etc/fstab; then
    log "Adding fstab entry for $MOUNT_POINT"
    echo "$fstab_line" | sudo tee -a /etc/fstab > /dev/null
  else
    log "[OK] fstab entry for $MOUNT_POINT already present"
  fi

  if ! mountpoint -q "$MOUNT_POINT"; then
    sudo mount "$MOUNT_POINT"
    log "[OK] Mounted $MOUNT_POINT"
  else
    log "[OK] $MOUNT_POINT already mounted"
  fi

  if mount | grep "$MOUNT_POINT " | grep -q prjquota; then
    log "[OK] prjquota active on $MOUNT_POINT"
  else
    warn "prjquota not visible in mount output — verify manually: mount | grep $MOUNT_POINT"
  fi
}

# ── 5. SSH hardening: disable password auth (key-only) ───────────────
harden_ssh() {
  local authorized_keys="/home/${ADMIN_USER}/.ssh/authorized_keys"

  if [[ ! -s "$authorized_keys" ]]; then
    warn "No authorized_keys found for '${ADMIN_USER}' at $authorized_keys — skipping SSH hardening."
    warn "Confirm key-based login works (ssh -i <key> ${ADMIN_USER}@${EXPECTED_IP}), then re-run this script."
    return
  fi

  if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
    log "[OK] Password authentication already disabled"
    return
  fi

  log "Disabling SSH password authentication (key-only from now on)"
  sudo cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%s)"
  sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
  sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo systemctl restart ssh
  log "[OK] SSH hardened: password authentication disabled, key-only login enforced."
}

# ── Main ────────────────────────────────────────────────────────────
log "═══════════════════════════════════════════════════"
log " telco-homelab — setup-node.sh — role: $ROLE"
log "═══════════════════════════════════════════════════"

verify_hostname
verify_expected_ip
configure_cgroups
setup_usb_disk
harden_ssh

log "═══════════════════════════════════════════════════"
log " setup-node.sh complete for $ROLE ($EXPECTED_HOSTNAME)"

# Reboot is required if either (a) this run just edited cmdline.txt, or
# (b) cmdline.txt already has the flags but the *running* kernel's
# cgroup memory controller isn't actually active yet — e.g. a prior run
# was interrupted after editing cmdline.txt but before a reboot happened.
if ! awk '$1=="memory"{print $4}' /proc/cgroups | grep -q '^1$'; then
  REBOOT_REQUIRED=true
fi

if $REBOOT_REQUIRED; then
  log " ⚠  Reboot required for cgroup flags to take effect: sudo reboot"
fi
log "═══════════════════════════════════════════════════"
