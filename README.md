# 🏠 Telco Home Lab — K3s on Raspberry Pi 2B

[![Version](https://img.shields.io/badge/version-v1.2.0-blue?style=flat-square)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![K3s](https://img.shields.io/badge/k3s-v1.29-orange?style=flat-square)](https://k3s.io)
[![OS](https://img.shields.io/badge/OS-RPi%20OS%20Trixie-c51a4a?style=flat-square)](docs/adr/ADR-003-bookworm-vs-trixie.md)
[![Platform](https://img.shields.io/badge/platform-ARM%20v7-lightgrey?style=flat-square)](docs/hld/architecture.md)
[![Edition](https://img.shields.io/badge/edition-1%20—%20Core%20Infrastructure-purple?style=flat-square)](CHANGELOG.md)

> A home Telco Cloud lab deploying network services on a two-node K3s cluster
> running on Raspberry Pi 2B, managed entirely as Infrastructure as Code (IaC).

---

## Overview

This project implements a domestic Telco Cloud lab following **immutable infrastructure** principles:
every service is defined in code (Dockerfiles + Kubernetes manifests), version-controlled with Git,
and deployed reproducibly through a GitOps CI/CD pipeline.

It is built around the **Telco Cloud Beginner** training path:
Linux → Docker → Kubernetes → CI/CD.

### Deployed services

| Service | Image | Role | Node |
|---|---|---|---|
| **Nginx** | `nginx:alpine` | Web server / reverse proxy | Pi #1 |
| **Gitea** | `gitea/gitea` | Git server + CI/CD source of truth | Pi #1 |
| **NFS Server** | custom | Network file sharing | Pi #2 |
| **Tvheadend** | custom ARM | TV streaming & recording | Pi #2 |

---

## Hardware architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       Local Network (LAN)                    │
│                                                              │
│  ┌───────────────────────┐     ┌───────────────────────┐     │
│  │   Raspberry Pi #1     │     │   Raspberry Pi #2     │     │
│  │   192.168.1.100       │     │   192.168.1.101       │     │
│  │                       │     │                       │     │
│  │   K3s server          │◄───►│   K3s agent           │     │
│  │   (control plane)     │     │   (worker)            │     │
│  │                       │     │                       │     │
│  │   • Nginx             │     │   • NFS server        │     │
│  │   • Gitea             │     │   • Tvheadend         │     │
│  │                       │     │   • Sundtek USB tuner │     │
│  │   [USB disk #1 — 1TB] │     │   [USB disk #2 — 1TB] │     │
│  └───────────────────────┘     └───────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

| Component | Details |
|---|---|
| Raspberry Pi 2B × 2 | ARM Cortex-A7 quad-core 900 MHz, 1 GB RAM each |
| USB disks × 2 | 1 TB each — Kubernetes persistent storage |
| TV tuner | Sundtek MediaTV (USB passthrough to Tvheadend pod) |
| OS | Raspberry Pi OS Lite 32-bit — Trixie (Debian 13) — [ADR-003](docs/adr/ADR-003-bookworm-vs-trixie.md) |
| K8s distribution | K3s — SQLite, no etcd, RAM-optimised — [ADR-001](docs/adr/ADR-001-k3s-vs-k0s.md) |

---

## Repository structure

```
telco-homelab/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── PROJECT_CONTEXT.md           # AI session briefing + status tracker
│   ├── architecture.md              # High-Level Design — Edition 1 (v1.2.0)
│   └── adr/
│       ├── ADR-001-k3s-vs-k0s.md
│       ├── ADR-002-gitea-vs-gitlab.md
│       ├── ADR-003-bookworm-vs-trixie.md
│       ├── ADR-004-woodpecker-vs-others.md
│       ├── ADR-005-traefik-ingress.md
│       ├── ADR-006-local-path-storage.md
│       └── ADR-007-no-ha-edition1.md
├── docker/                          # Dockerfiles per service
│   ├── nginx/ │ gitea/ │ nfs/ │ tvheadend/
├── k8s/
│   ├── base/                        # Kustomize base manifests
│   │   ├── nginx/ │ gitea/ │ nfs/ │ tvheadend/
│   └── overlays/dev/ overlays/prod/
├── monitoring/prometheus/ │ grafana/
├── scripts/
│   └── init-repo.sh                 # This script
└── .github/
    ├── ISSUE_TEMPLATE/
    └── workflows/
```

---

## Getting started

### Prerequisites

- Two Raspberry Pi 2B flashed with **Raspberry Pi OS Lite 32-bit (Trixie)**
- SSH enabled, static IPs configured
- This repository cloned locally

### Initialise the repository (first time only)

```bash
chmod +x scripts/init-repo.sh
./scripts/init-repo.sh --git-remote https://github.com/hervetchoffo/telco-homelab.git
git push -u origin main --tags
```

### Enable cgroups on each Pi (required by K3s)

```bash
# Trixie — boot files are under /boot/firmware/ (not /boot/)
sudo sed -i '$ s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' \
  /boot/firmware/cmdline.txt
sudo reboot
```

### Install K3s

```bash
# Pi #1 — server (control plane)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
sudo cat /var/lib/rancher/k3s/server/node-token   # copy token for agent

# Pi #2 — agent (worker)
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.100:6443 K3S_TOKEN=<token> sh -

# Verify
kubectl get nodes
```

---

## GitHub workflow

```
Milestone v1.X.0
  └── Issues (atomic tasks)
        └── Branch: feat/v1.X.0-<description>
              └── Pull Request  ←  links AI discussion URL in description
                    └── merge → git tag v1.X.0 → GitHub Release
                                  └── Milestone closed → PROJECT_CONTEXT updated
```

| GitHub feature | Role |
|---|---|
| **Milestones** | One per `v1.X.0` MINOR version |
| **Issues** | Atomic tasks; closed via `Closes #N` in PR commits |
| **Pull Requests** | One per milestone; description links the AI session |
| **Projects (Board)** | Kanban: Backlog → In Progress → In Review → Done |
| **Releases** | Created from each tag with CHANGELOG excerpt as notes |

**Branch naming:** `feat/v1.X.0-<short-title>` · `fix/v1.X.Y-<short-title>`

---

## Versioning

| Segment | Meaning | Example |
|---|---|---|
| `MAJOR=1` | Edition 1 — Core Infrastructure | `v1.x.y` |
| `MINOR` | One deliverable milestone | `v1.2.0` |
| `PATCH` | Fix after a MINOR | `v1.2.1` |
| `-rc.N` | Release candidate | `v1.2.0-rc.1` |
| `-final` | Last stable of the edition (archive) | `v1.15.0-final` |

### Roadmap — Edition 1

| Version | Phase | Milestone | Status |
|---|---|---|---|
| `v1.1.0` | Preparation | Initialize GitHub repository | ✅ Done |
| `v1.1.1` | Preparation | Credential setup documentation | ✅ Done |
| `v1.2.0` | Preparation | HLD document & network inventory | ✅ Done |
| `v1.3.0` | Preparation | Prepare Raspberry Pi OS (Trixie) | 🔲 |
| `v1.4.0` | K3s | K3s server on Pi #1 | 🔲 |
| `v1.5.0` | K3s | K3s agent on Pi #2 | 🔲 |
| `v1.6.0` | K3s | Validation deployment (smoke test) | 🔲 |
| `v1.7.0` | Storage | USB (XFS) persistent volumes + rsync backup | 🔲 |
| `v1.8.0` | Storage | NFS server in K8s | 🔲 |
| `v1.9.0` | Services | Gitea deployed (GitOps pivot) | 🔲 |
| `v1.10.0` | Services | Nginx via Traefik Ingress | 🔲 |
| `v1.11.0` | Services | Tvheadend + Sundtek USB tuner | 🔲 |
| `v1.12.0` | Services | Image & manifest versioning | 🔲 |
| `v1.13.0` | CI/CD | Woodpecker CI runner + trigger strategy | 🔲 |
| `v1.14.0` | CI/CD | Build → deploy pipeline | 🔲 |
| `v1.15.0` | CI/CD | Prometheus + Grafana monitoring | 🔲 |
| `v1.15.0-final` | — | Edition 1 archive release | 🔲 |

---

## Architecture decisions

| ADR | Decision | Status |
|---|---|---|
| [ADR-001](docs/adr/ADR-001-k3s-vs-k0s.md) | K3s over K0s | ✅ Accepted |
| [ADR-002](docs/adr/ADR-002-gitea-vs-gitlab.md) | Gitea over GitLab | ✅ Accepted |
| [ADR-003](docs/adr/ADR-003-bookworm-vs-trixie.md) | Raspberry Pi OS Trixie | ✅ Accepted |
| [ADR-004](docs/adr/ADR-004-woodpecker-vs-others.md) | Woodpecker CI over Jenkins / Drone / GitHub Actions | ✅ Accepted |
| [ADR-005](docs/adr/ADR-005-traefik-ingress.md) | Traefik as K3s built-in ingress controller | ✅ Accepted |
| [ADR-006](docs/adr/ADR-006-local-path-storage.md) | local-path-provisioner with XFS project quotas | ✅ Accepted |
| [ADR-007](docs/adr/ADR-007-no-ha-edition1.md) | Single server + agent topology (no HA, Edition 1) | ✅ Accepted |

---

## Licence

[MIT](LICENSE) — free to use, modify and distribute.

*Built as part of the **Telco Cloud Beginner** training path.*
