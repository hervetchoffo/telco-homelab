# ADR-003 — Raspberry Pi OS version: Bookworm vs Trixie

| Field | Value |
|---|---|
| **Date** | 2025-04-29 |
| **Status** | Accepted |
| **Decider** | Project team |
| **Milestone** | v1.1.0 |

## Context

Raspberry Pi OS is available as Bookworm (Debian 12) and Trixie (Debian 13, stable since
October 1 2025). Both exist as Lite 32-bit images for ARMv7 (Raspberry Pi 2B).

## Decision

**Raspberry Pi OS Lite 32-bit (Trixie / Debian 13) is selected.**

## Evaluation

| Criterion | Trixie (Debian 13) | Bookworm (Debian 12) |
|---|---|---|
| Release status | Current stable (Oct 2025) | Previous stable |
| Kernel | 6.6 LTS | 6.1 |
| cgroup v2 support | Improved — positive for K3s | Good |
| K3s ARMv7 compatibility | Community-validated on Pi 2B | Well-documented |
| Boot config path | `/boot/firmware/cmdline.txt` | `/boot/cmdline.txt` |
| Recommendation | Fresh image install | N/A |

Trixie is the current official Raspberry Pi OS. Community members have confirmed K3s
running correctly on Trixie ARMv7 (including Pi 2B). The Raspberry Pi team explicitly
recommends a clean image install rather than an in-place upgrade from Bookworm.

⚠️ **Important:** on Trixie, boot configuration files moved to `/boot/firmware/`.
All setup scripts in this project use the Trixie path.

## Consequences

- Both nodes flashed from a clean Trixie Lite image
- cgroup flag: `sudo sed -i '$ s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/firmware/cmdline.txt`
- All docs target Trixie (Debian 13)
- If K3s issues specific to Trixie ARMv7 arise, they are patched and this ADR updated

## Rejected alternatives

| Option | Reason |
|---|---|
| Bookworm (Debian 12) | Previous stable — superseded by Trixie |
| Ubuntu Server 24.04 LTS ARMv7 | Heavier footprint, less Pi-optimised |
| DietPi | Non-standard package management, narrower community support |
