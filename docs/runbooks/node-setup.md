# Runbook — Node Setup (v1.3.0)

| Field | Value |
|---|---|
| Milestone | [v1.3.0 — Prepare Raspberry Pi OS (Trixie)](../../CHANGELOG.md) |
| Applies to | Pi #1 (`pi-server`, 192.168.1.100), Pi #2 (`pi-agent`, 192.168.1.101) |
| Related ADRs | ADR-001 (K3s/SQLite), ADR-003 (Trixie), ADR-006 (XFS+prjquota) |

This runbook is the human-readable companion to `scripts/inventory-node.sh`,
`scripts/setup-node.sh`, and `scripts/setup-zram.sh`. Follow it once per
node, in order. All steps are idempotent — re-running a step after a
partial failure is safe.

---

## 0. Prerequisites (local machine, once)

### 0.1 Generate the project SSH key pair

```bash
ssh-keygen -t ed25519 -C "herve@telco-homelab" -f ~/.ssh/telco_homelab_ed25519
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/telco_homelab_ed25519
```

Add to `~/.ssh/config`:

```
Host pi-server
    HostName 192.168.1.100
    User herve
    IdentityFile ~/.ssh/telco_homelab_ed25519

Host pi-agent
    HostName 192.168.1.101
    User herve
    IdentityFile ~/.ssh/telco_homelab_ed25519
```

### 0.2 Configure router DHCP reservations

This project uses **DHCP reservation by MAC address**, not a manually
configured static IP on each Pi. Rationale: survives SD card re-flashes
automatically, single source of truth at the router, no IP-conflict risk.

In your router's admin UI, find "DHCP reservation" / "static lease" /
"address reservation" and reserve:

| Hostname | MAC address | Reserved IP |
|---|---|---|
| `pi-server` | *(from RPi Imager advanced settings, or read after first boot)* | 192.168.1.100 |
| `pi-agent` | *(same)* | 192.168.1.101 |

> If the MAC isn't known yet, flash and boot the Pi once on DHCP first,
> read the MAC from the router's client list or `ip link show`, then set
> the reservation and reboot the Pi to pick up the reserved address.

---

## 1. Flash the SD card (RPi Imager)

Follow the official Raspberry Pi Foundation guide:
<https://www.raspberrypi.com/documentation/computers/getting-started.html>

Image: **Raspberry Pi OS Lite (32-bit) — Trixie**

In the Imager's advanced options (⚙️ gear icon), set:

| Setting | Pi #1 | Pi #2 |
|---|---|---|
| Hostname | `pi-server` | `pi-agent` |
| Username | `herve` | `herve` |
| Password | Set a strong password (recovery fallback only — see §1.1) | Same |
| Enable SSH | ✅ | ✅ |
| Allow public-key authentication only | ✅ — paste contents of `~/.ssh/telco_homelab_ed25519.pub` | ✅ — same key |

### 1.1 Why set a password if we're using key auth?

The password is a **recovery fallback**, not the primary login method.
If the SSH key is ever lost, corrupted, or misconfigured, the password
is the only way back in without re-flashing. `setup-node.sh` disables
password authentication over SSH once key-based login is confirmed
working (§4 below) — the password then only matters for local console
access in an emergency.

---

## 2. First boot and SSH verification

```bash
ssh pi-server   # or: ssh pi-agent
```

Confirm you land in a shell **without** being prompted for a password
(key auth working). If prompted for a password, key auth is not yet
configured correctly — do not proceed until this works.

---

## 3. Hardware inventory (read-only, run once)

```bash
scp scripts/inventory-node.sh pi-server:~/
ssh pi-server './inventory-node.sh | tee ~/inventory-pi-server.txt'
scp pi-server:~/inventory-pi-server.txt docs/hardware/
```

Repeat for `pi-agent`. This script makes **no changes** — it only reads
and reports. Review the output for:

- Confirm `/proc/cgroups` shows a `memory` line **not yet enabled**
  (expected pre-setup)
- Confirm exactly one USB disk under "Block Devices"
- Confirm the tuner appears under "TV Tuner — USB-level detection"
  (Pi #2 / `pi-agent` only — the tuner is not expected on `pi-server`)

> **Note on the Sundtek tuner:** only USB-level identification (vendor
> ID, product string, negotiated speed) is possible at this stage. The
> Sundtek driver is intentionally not installed on the host — it will
> be installed inside the Tvheadend container at milestone v1.11.0.
> Seeing the tuner in `lsusb` output is sufficient confirmation for now.

Commit both inventory files:

```bash
git add docs/hardware/inventory-pi-server.txt docs/hardware/inventory-pi-agent.txt
git commit -m "docs(hardware): add v1.3.0 hardware inventory for both nodes"
```

---

## 4. Run setup-node.sh

```bash
scp scripts/setup-node.sh pi-server:~/
ssh pi-server
```

On the Pi:

```bash
chmod +x setup-node.sh

# First run — will refuse to touch the USB disk if it's not blank/XFS.
# Confirm from the inventory output that it's safe to erase, then:
./setup-node.sh --wipe-disk
```

The script will:
1. Verify hostname matches the expected role (`pi-server`/`pi-agent`)
2. Verify the current IP matches the DHCP reservation from §0.2
3. Append cgroup flags to `/boot/firmware/cmdline.txt` (Trixie path)
4. Format the USB disk as XFS with `prjquota`, mount it at
   `/mnt/k3s-storage`, and add the `/etc/fstab` entry
5. Disable SSH password authentication (guarded — only if a working
   `authorized_keys` is already present)

If a reboot is required (cgroup flags just added), the script tells you:

```bash
sudo reboot
```

Reconnect and re-run `./setup-node.sh` — it will report every step as
already satisfied (`[OK]`) and exit cleanly. This is the idempotency
check.

Repeat for `pi-agent`.

---

## 5. Run setup-zram.sh

```bash
scp scripts/setup-zram.sh pi-server:~/
ssh pi-server './setup-zram.sh'
```

Repeat for `pi-agent`.

---

## 6. Validation checklist (aligned with HLD §11)

Run on **both** nodes:

```bash
# 1. cgroups active
cat /proc/cgroups | grep memory
# Expect: memory  <hierarchy>  <num_cgroups>  1   (last column = enabled)

# 2. XFS mount with prjquota
mount | grep prjquota
# Expect: /dev/sda1 on /mnt/k3s-storage type xfs (...,prjquota)

# 3. zram active
zramctl
# Expect: one zram device, ~512M, algorithm lz4

# 4. Hostname and IP
hostnamectl
ip addr show | grep "inet "
# Expect: hostname and IP match the table in §0.2

# 5. SSH hardened
sudo grep PasswordAuthentication /etc/ssh/sshd_config
# Expect: PasswordAuthentication no
```

If every check passes on both nodes, v1.3.0 is complete.

---

## 7. K3s install reference (not run yet)

```bash
./install-k3s.sh --show
```

This prints the full server/agent install procedure and token exchange
steps that will be **automated** at v1.4.0 (server) and v1.5.0 (agent).
Running this now is informational only.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `setup-node.sh` dies on IP check | DHCP reservation not yet configured or not yet renewed | Check router UI, reboot the Pi to renew the lease |
| `setup-node.sh` refuses disk setup without `--wipe-disk` | Disk isn't blank/XFS — safety guard | Confirm from inventory it's safe to erase, then re-run with the flag |
| `setup-node.sh` reports "Multiple USB disks detected" | Unexpected second USB storage device plugged in | Unplug the extra device, or use `--skip-disk` and configure manually |
| SSH locks you out after hardening | `authorized_keys` was empty or malformed when the script ran | Use the recovery password from RPi Imager via local console (HDMI + keyboard) to fix `~/.ssh/authorized_keys`, then re-run |
| Tuner missing from `lsusb` in inventory | Not plugged in, or USB hub power issue | Reseat the tuner directly into a Pi USB port (not through the hub) and re-run inventory |
