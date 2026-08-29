# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org) with project-specific
conventions described in [README.md](README.md#versioning-semver).

---

## [Unreleased]

### Added

- `scripts/inventory-node.sh` — read-only hardware inventory: OS/kernel,
  Pi model, RAM, micro SD card, USB block devices, network interfaces,
  Sundtek tuner (USB-level detection only — driver deferred to v1.11.0),
  and pre-K3s cgroup status
- `scripts/setup-node.sh` — idempotent node preparation: hostname and
  DHCP-reservation IP verification, cgroup flags on
  `/boot/firmware/cmdline.txt` (Trixie path), USB disk detection with
  destructive-operation guard, XFS format with `prjquota`, `/etc/fstab`
  entry, SSH password-authentication hardening
- `scripts/setup-zram.sh` — idempotent 512 MB (target) zram swap
  configuration via `zram-tools`, with pre-flight teardown of any
  conflicting default zram provider
- `scripts/install-k3s.sh` — stub documenting the K3s server/agent
  install commands and node-token exchange procedure; full automation
  deferred to v1.4.0 (server) and v1.5.0 (agent)
- `docs/runbooks/node-setup.md` — end-to-end operator guide: SSH key
  generation, router DHCP reservation, RPi Imager settings, script
  execution order, validation checklist aligned with HLD §11,
  troubleshooting table
- `docs/hardware/inventory-pi-server.txt`, `docs/hardware/inventory-pi-agent.txt`
  — committed hardware baselines from `inventory-node.sh`
- `docs/adr/ADR-008-sundtek-device-passthrough.md` — research findings
  on Sundtek tuner device passthrough (Docker host device-node
  requirement, translated to K3s `hostPath`/`privileged` pattern).
  Status: Proposed — implementation deferred to v1.11.0

### Fixed

- `inventory-node.sh`: MAC address extraction was splitting on `': '`,
  unsafe since MAC addresses themselves contain colons — was printing
  the interface name twice instead of the MAC. Switched to whitespace
  field-splitting, scanning for the `link/ether` token.
- `setup-node.sh`: `xfsprogs` is not part of the Raspberry Pi OS Lite
  base image — `mkfs.xfs` failed on first on-hardware run. Added
  `ensure_disk_tools()` to install `xfsprogs`/`parted` lazily, only on
  the disk-format path.
- `setup-node.sh`: reboot-required detection initially only checked
  `/proc/cgroups`, a legacy cgroup v1 interface that does not reliably
  list controllers on a cgroup v2 (unified hierarchy) system — the
  default on this project's kernel (6.18). Added `memory_cgroup_active()`,
  which checks `/sys/fs/cgroup/cgroup.controllers` on v2 systems and
  falls back to `/proc/cgroups` on v1 systems. Runbook validation
  checklist updated to match.
- `setup-zram.sh`: hardware inventory revealed an already-active
  ~920 MB zram0 swap device present by default on Raspberry Pi OS
  Trixie, before this script ever ran. Added a pre-flight check that
  tears down any zram swap not managed by `zram-tools` first.

### Notes

- Confirmed running kernel is `6.18.34+rpt-rpi-v7`, newer than the
  `6.6 LTS` referenced in ADR-003 at time of writing — expected drift,
  does not affect the ADR's decision.
- Confirmed Sundtek MediaTV Pro III MiniPCIe (EU) USB ID: `2659:1212`
- cgroup v2 (unified hierarchy) confirmed active by default on both
  nodes; `memory` controller present in `cgroup.controllers`
- Actual zram size settled at ~460 MB rather than the 512 MB target
  (installed `zram-tools` version reads the `PERCENT` key over `SIZE`;
  50% of ~920 MiB usable RAM = 460 MiB) — close enough to target,
  not adjusted further

---

## [1.2.0] — 2026-05-11

### Added

- `docs/hld/architecture.md` — High-Level Design for Edition 1 (18 sections):
  use cases, K8s primer, network architecture (Flannel VXLAN, Traefik,
  cert-manager, HostPort vs NodePort), node layout, Mermaid sequence diagrams
  for all five call flows, test & validation procedures (smoke tests,
  tcpdump/Wireshark/tshark), storage design (XFS quotas, rsync backup),
  RAM budget with sourced estimates, security considerations, risks register,
  general reading references (Linux, Docker, Kubernetes, CI/CD)
- `docs/adr/ADR-004-woodpecker-vs-others.md` — Woodpecker CI selection rationale
- `docs/adr/ADR-005-traefik-ingress.md` — Traefik as K3s built-in ingress
- `docs/adr/ADR-006-local-path-storage.md` — local-path-provisioner + XFS quotas
- `docs/adr/ADR-007-no-ha-edition1.md` — single server + agent, no HA in Edition 1
- `.github/ISSUE_TEMPLATE/documentation.md` — documentation issue template with
  AI session URL field

---

## [1.1.1] — 2025-04-30

### Added
- `docs/libsecret-credential-setup.md`: guide for storing per-repo GitHub PATs
  using libsecret and `credential.useHttpPath=true` on Linux Mint

---

## [1.1.0] — 2025-04-29

### Added
- `README.md`: project overview, hardware architecture diagram, full roadmap table,
  SemVer conventions (MAJOR / MINOR / PATCH / -rc.N / -final)
- `CHANGELOG.md`: version history (this file), Keep a Changelog format
- `LICENSE`: MIT licence
- `.gitignore`: excludes kubeconfig, secrets, `.env` files, build artefacts
- Full repository directory structure:
  `docs/`, `k8s/`, `docker/`, `monitoring/`, `scripts/`, `.github/`
- `docs/adr/ADR-001-k3s-vs-k0s.md`: K3s selected over K0s
- `docs/adr/ADR-002-gitea-vs-gitlab.md`: Gitea selected over GitLab
- `docs/adr/ADR-003-bookworm-vs-trixie.md`: Raspberry Pi OS Trixie selected
- `docs/hld/architecture.md`: HLD stub (to be completed in v1.2.0)
- `docs/PROJECT_CONTEXT.md`: AI session briefing block + project status tracker
- `scripts/init-repo.sh`: self-contained repository initialisation script
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- README stubs for all service directories
- `.gitkeep` placeholders in all empty directories

---

[Unreleased]: https://github.com/hervetchoffo/telco-homelab/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/hervetchoffo/telco-homelab/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/hervetchoffo/telco-homelab/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/hervetchoffo/telco-homelab/releases/tag/v1.1.0
