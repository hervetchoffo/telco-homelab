#!/usr/bin/env bash
# =============================================================================
# init-repo.sh — Telco Home Lab — fully self-contained repository initialiser
# =============================================================================
#
# USAGE
#   chmod +x scripts/init-repo.sh
#   ./scripts/init-repo.sh [--git-remote <url>] [--dry-run]
#
# WHAT IT DOES (in order)
#   1.  Verifies prerequisites (git, bash >= 4)
#   2.  Creates the full directory tree
#   3.  Writes every project file (README, CHANGELOG, ADRs, etc.)
#   4.  Writes .gitkeep into empty directories
#   5.  Initialises a local git repo on branch 'main'
#   6.  Stages and commits everything as the v1.1.0 initial commit
#   7.  Creates the annotated tag v1.1.0
#   8.  Optionally adds a git remote named 'origin'
#   9.  Prints next-step instructions
#
# OPTIONS
#   --git-remote <url>   GitHub remote URL to register as 'origin'
#   --dry-run            Print every action without writing any file or git op
#
# REQUIREMENTS
#   bash >= 4, git >= 2.28 (for --initial-branch support)
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERR ]${RESET}  $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}── $* ${RESET}"; }
dryrun()  { echo -e "${YELLOW}[DRY ]${RESET}  $*"; }

# ── Argument parsing ──────────────────────────────────────────────────────────
GIT_REMOTE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --git-remote) GIT_REMOTE="${2:-}"; shift 2 ;;
    --dry-run)    DRY_RUN=true; shift ;;
    -h|--help)
      grep '^#' "$0" | grep -v '#!/' | sed 's/^# \?//'
      exit 0 ;;
    *) error "Unknown argument: $1. Use --help for usage." ;;
  esac
done

# ── Helper: write a file (respects --dry-run) ─────────────────────────────────
write_file() {
  local path="$1"; local content="$2"
  if [[ "$DRY_RUN" == true ]]; then
    dryrun "write  $path"
    return
  fi
  mkdir -p "$(dirname "$path")"
  printf '%s' "$content" > "$path"
  success "write  $path"
}

# ── Helper: create directory ──────────────────────────────────────────────────
make_dir() {
  if [[ "$DRY_RUN" == true ]]; then dryrun "mkdir  $1"; return; fi
  mkdir -p "$1" && success "mkdir  $1"
}

# ── Helper: git command (respects --dry-run) ──────────────────────────────────
run_git() {
  if [[ "$DRY_RUN" == true ]]; then dryrun "git $*"; return; fi
  git "$@"
}

# ── Prerequisites ─────────────────────────────────────────────────────────────
step "Checking prerequisites"

command -v git &>/dev/null || error "git is not installed."
command -v bash &>/dev/null || error "bash is not installed."

BASH_MAJOR="${BASH_VERSINFO[0]}"
[[ "$BASH_MAJOR" -ge 4 ]] || error "bash >= 4 required (found $BASH_VERSION)."

# Must be run from the repo root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"
info "Working directory: $REPO_ROOT"

[[ "$DRY_RUN" == true ]] && warn "DRY-RUN mode — no files or git operations will be performed."

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Telco Home Lab — Repository Initialiser v1.1.0  ║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════╝${RESET}"

# =============================================================================
# STEP 1 — DIRECTORY STRUCTURE
# =============================================================================
step "1/7  Creating directory structure"

make_dir "docs/hld"
make_dir "docs/adr"
make_dir "docker/nginx"
make_dir "docker/gitea"
make_dir "docker/nfs"
make_dir "docker/tvheadend"
make_dir "k8s/base/nginx"
make_dir "k8s/base/gitea"
make_dir "k8s/base/nfs"
make_dir "k8s/base/tvheadend"
make_dir "k8s/overlays/dev"
make_dir "k8s/overlays/prod"
make_dir "monitoring/prometheus"
make_dir "monitoring/grafana"
make_dir "scripts"
make_dir ".github/ISSUE_TEMPLATE"
make_dir ".github/workflows"

# =============================================================================
# STEP 2 — ROOT FILES
# =============================================================================
step "2/7  Writing root files"

# ── .gitignore ────────────────────────────────────────────────────────────────
write_file ".gitignore" '# Kubernetes credentials — never commit
kubeconfig
*.kubeconfig
.kube/

# Secrets & environment files
secrets/
*.secret
*.env
.env
.env.*
!.env.example

# K3s runtime data
/k3s-data/
k3s-token

# Docker build artefacts
docker/*/build/
*.tar

# Monitoring persistent data
monitoring/grafana/data/
monitoring/prometheus/data/

# Editors
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Build output
dist/
build/
'

# ── LICENSE ───────────────────────────────────────────────────────────────────
write_file "LICENSE" 'MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'

# ── CHANGELOG.md ──────────────────────────────────────────────────────────────
write_file "CHANGELOG.md" '# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org) with project-specific
conventions described in [README.md](README.md#versioning-semver).

---

## [Unreleased]

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

[Unreleased]: https://github.com/hervetchoffo/telco-homelab/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/hervetchoffo/telco-homelab/releases/tag/v1.1.0
'

# ── README.md ─────────────────────────────────────────────────────────────────
write_file "README.md" '# 🏠 Telco Home Lab — K3s on Raspberry Pi 2B

[![Version](https://img.shields.io/badge/version-v1.1.0-blue?style=flat-square)](CHANGELOG.md)
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
│  ┌───────────────────────┐     ┌───────────────────────┐    │
│  │   Raspberry Pi #1     │     │   Raspberry Pi #2     │    │
│  │   192.168.1.100       │     │   192.168.1.101       │    │
│  │                       │     │                       │    │
│  │   K3s server          │◄───►│   K3s agent           │    │
│  │   (control plane)     │     │   (worker)            │    │
│  │                       │     │                       │    │
│  │   • Nginx             │     │   • NFS server        │    │
│  │   • Gitea             │     │   • Tvheadend         │    │
│  │                       │     │   • Sundtek USB tuner │    │
│  │   [USB disk #1 — 1TB] │     │   [USB disk #2 — 1TB] │    │
│  └───────────────────────┘     └───────────────────────┘    │
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
│   ├── hld/architecture.md          # High Level Design
│   └── adr/
│       ├── ADR-001-k3s-vs-k0s.md
│       ├── ADR-002-gitea-vs-gitlab.md
│       └── ADR-003-bookworm-vs-trixie.md
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
sudo sed -i '\''$ s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/'\'' \
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
| `v1.1.0` | Preparation | Initialize GitHub repository | ✅ Current |
| `v1.2.0` | Preparation | HLD document & network inventory | 🔲 |
| `v1.3.0` | Preparation | Prepare Raspberry Pi OS (Trixie) | 🔲 |
| `v1.4.0` | K3s | K3s server on Pi #1 | 🔲 |
| `v1.5.0` | K3s | K3s agent on Pi #2 | 🔲 |
| `v1.6.0` | K3s | Validation deployment (smoke test) | 🔲 |
| `v1.7.0` | Storage | USB persistent volumes | 🔲 |
| `v1.8.0` | Storage | NFS server in K8s | 🔲 |
| `v1.9.0` | Storage | Gitea deployed (GitOps pivot) | 🔲 |
| `v1.10.0` | Services | Nginx via Traefik Ingress | 🔲 |
| `v1.11.0` | Services | Tvheadend + Sundtek USB tuner | 🔲 |
| `v1.12.0` | Services | Image & manifest versioning | 🔲 |
| `v1.13.0` | CI/CD | Woodpecker CI runner | 🔲 |
| `v1.14.0` | CI/CD | Build → deploy pipeline | 🔲 |
| `v1.15.0` | CI/CD | Prometheus + Grafana monitoring | 🔲 |
| `v1.15.0-final` | — | Edition 1 archive release | 🔲 |

---

## Architecture decisions

| ADR | Decision | Status |
|---|---|---|
| [ADR-001](docs/adr/ADR-001-k3s-vs-k0s.md) | K3s over K0s | Accepted |
| [ADR-002](docs/adr/ADR-002-gitea-vs-gitlab.md) | Gitea over GitLab | Accepted |
| [ADR-003](docs/adr/ADR-003-bookworm-vs-trixie.md) | Raspberry Pi OS Trixie | Accepted |

---

## Licence

[MIT](LICENSE) — free to use, modify and distribute.

*Built as part of the **Telco Cloud Beginner** training path.*
'

# =============================================================================
# STEP 3 — DOCUMENTATION FILES
# =============================================================================
step "3/7  Writing documentation files"

# ── docs/hld/architecture.md ──────────────────────────────────────────────────
write_file "docs/hld/architecture.md" '# High Level Design — Telco Home Lab

> **Version:** v1.2.0 (to be completed)
> **Status:** Draft

This document will be completed as part of milestone `v1.2.0`.

It will cover:
- Detailed network diagram (IP plan, subnets, traffic flows)
- Full hardware and OS inventory
- OS choice — Raspberry Pi OS Lite Trixie (Debian 13, kernel 6.6 LTS)
- Technical stack justification (K3s, Gitea, Woodpecker CI, Traefik)
- Node role assignment and memory budget per node
- Persistent storage design (USB disks, local-path PVCs)
- Security considerations
- PVC backup strategy
'

# ── ADR-001 ───────────────────────────────────────────────────────────────────
write_file "docs/adr/ADR-001-k3s-vs-k0s.md" '# ADR-001 — Kubernetes distribution: K3s vs K0s

| Field | Value |
|---|---|
| **Date** | 2025-04-29 |
| **Status** | Accepted |
| **Decider** | Project team |
| **Milestone** | v1.1.0 |

## Context

The project requires a lightweight Kubernetes distribution running on two Raspberry Pi 2B nodes
(ARM Cortex-A7, 1 GB RAM each) running Raspberry Pi OS Lite 32-bit (Trixie / Debian 13).
The two candidates evaluated are **K3s** (Rancher / SUSE) and **K0s** (Mirantis).

## Decision

**K3s is selected.**

## Evaluation

| Criterion | K3s | K0s |
|---|---|---|
| Minimum RAM at idle | ~300 MB | ~400 MB |
| Binary size | ~70 MB (all-in-one) | ~200 MB (static) |
| Default datastore | SQLite (embedded) | kine / etcd (separate process) |
| ARM v7 support | Official, production-tested | Experimental |
| Ingress controller | Traefik (pre-configured) | Manual install |
| Helm controller | Built-in | External tool |
| Local storage provisioner | local-path (built-in) | Manual install |
| Community & documentation | Very large | Smaller |

K3s saves ~100 MB RAM vs K0s and replaces etcd with SQLite, avoiding an extra ~200 MB
process. ARM v7 is officially supported and production-tested on Raspberry Pi hardware.

### Note on multi-master HA

HA Kubernetes requires **at least 3 control-plane nodes** so the distributed consensus
datastore can maintain quorum. With only 2 nodes, any partition leaves each side with
exactly half the votes — neither side can form a majority (split-brain). Three nodes mean
a failure leaves 2/3 surviving, quorum holds, and the cluster continues. With our 2-node
hardware, the correct and stable topology is 1 K3s server + 1 K3s agent. HA is out of
scope for Edition 1.

## Consequences

- Cluster uses SQLite — single control-plane node, no HA (acceptable for a home lab)
- Traefik available out of the box
- All Docker images must target `linux/arm/v7`

## Rejected alternatives

| Distribution | Reason |
|---|---|
| MicroK8s | Too heavy for ARMv7 (Snap + etcd) |
| Kind / Minikube | Development-only |
| Upstream K8s | Exceeds 1 GB RAM budget |
| K0s | ARMv7 experimental, heavier, no built-in Ingress |
'

# ── ADR-002 ───────────────────────────────────────────────────────────────────
write_file "docs/adr/ADR-002-gitea-vs-gitlab.md" '# ADR-002 — Git server: Gitea vs GitLab

| Field | Value |
|---|---|
| **Date** | 2025-04-29 |
| **Status** | Accepted |
| **Decider** | Project team |
| **Milestone** | v1.1.0 |

## Context

The project needs a self-hosted Git server that is also the GitOps source of truth and
hosts CI/CD pipelines. GitLab is the most widely known self-hosted Git platform, but its
hardware requirements must be evaluated honestly against the available infrastructure
(2 × Raspberry Pi 2B, 1 GB RAM each).

## Decision

**Gitea is selected.** GitLab is excluded — its memory requirement exceeds the total
cluster RAM.

## Evaluation

| Component | RAM |
|---|---|
| GitLab all-in-one | 2–4 GB minimum |
| Total cluster RAM | 2 GB (2 × 1 GB) |
| Gitea process | ~80 MB |
| Gitea + SQLite | ~80 MB |

GitLab requires more RAM than the entire cluster. Gitea covers every required feature:
repository hosting, webhooks, OAuth2 (used by Woodpecker CI), container registry,
and official `linux/arm/v7` Docker images.

CI/CD skills from the training path (YAML pipelines, Docker build, push, deploy) transfer
directly — `.woodpecker.yml` is the functional equivalent of `.gitlab-ci.yml`.

## Consequences

- Gitea is the GitOps source of truth from v1.9.0 onwards
- Woodpecker CI is the runner (Gitea OAuth integration, ~50 MB RAM)
- If reproduced on x86 with adequate RAM, migration to GitLab CE is straightforward

## Rejected alternatives

| Platform | Reason |
|---|---|
| GitLab CE | 2–4 GB RAM — exceeds total cluster RAM |
| Forgejo | Gitea fork, functionally equivalent — Gitea has wider documentation |
| Gogs | Predecessor of Gitea, less actively maintained |
| GitHub hosted | Defeats the self-hosted IaC goal |
'

# ── ADR-003 ───────────────────────────────────────────────────────────────────
write_file "docs/adr/ADR-003-bookworm-vs-trixie.md" '# ADR-003 — Raspberry Pi OS version: Bookworm vs Trixie

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
- cgroup flag: `sudo sed -i '\''$ s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/'\'' /boot/firmware/cmdline.txt`
- All docs target Trixie (Debian 13)
- If K3s issues specific to Trixie ARMv7 arise, they are patched and this ADR updated

## Rejected alternatives

| Option | Reason |
|---|---|
| Bookworm (Debian 12) | Previous stable — superseded by Trixie |
| Ubuntu Server 24.04 LTS ARMv7 | Heavier footprint, less Pi-optimised |
| DietPi | Non-standard package management, narrower community support |
'

# ── PROJECT_CONTEXT.md ────────────────────────────────────────────────────────
write_file "docs/PROJECT_CONTEXT.md" '# Project Context — Telco Home Lab

> **Purpose:**
> 1. **AI session briefing** — paste the block below at the start of every new discussion
> 2. **Project status tracker** — update the table after each milestone delivery

---

## Briefing block (copy-paste into every new AI session)

```
I am working on a home Telco Cloud lab project called "telco-homelab".
Please act as a DevOps / Telco Cloud expert throughout this discussion.
All responses, code, and documentation must be in English.

--- PROJECT SUMMARY ---
Goal: Deploy Tvheadend, NFS, Nginx and Gitea on a two-node K3s cluster
      running on Raspberry Pi 2B, managed fully as Infrastructure as Code.

Training path: Telco Cloud Beginner (Linux → Docker → Kubernetes → CI/CD)

Hardware:
  - Raspberry Pi 2B × 2 (ARM Cortex-A7, 1 GB RAM each)
  - USB disk × 2 (1 TB each, Kubernetes persistent storage)
  - Sundtek MediaTV USB tuner (passed through to Tvheadend pod)
  - OS: Raspberry Pi OS Lite 32-bit — Trixie (Debian 13, kernel 6.6 LTS)

Key technical choices (documented as ADRs):
  - K8s distribution : K3s (SQLite, no etcd — RAM constraint)     ADR-001
  - Git server       : Gitea (~80 MB RAM; GitLab excluded 2–4 GB)  ADR-002
  - OS               : Raspberry Pi OS Lite Trixie (Debian 13)     ADR-003
  - CI runner        : Woodpecker CI (Gitea OAuth, ~50 MB RAM)
  - Ingress          : Traefik (K3s built-in)
  - Storage          : local-path PVCs on USB disks

Node layout:
  - Pi #1 (192.168.1.100): K3s server — Nginx, Gitea
  - Pi #2 (192.168.1.101): K3s agent  — NFS server, Tvheadend

Note on HA: multi-master HA needs ≥3 nodes for quorum. With 2 nodes,
the correct topology is 1 server + 1 agent. HA is out of scope for Edition 1.

Versioning (SemVer):
  - MAJOR=1  → Edition 1 (Core Infrastructure)
  - MINOR    → one deliverable milestone (v1.2.0 = HLD document)
  - PATCH    → fix after a MINOR (v1.2.1)
  - -rc.N    → release candidate
  - -final   → last stable of the edition (archive tag)

GitHub workflow:
  Milestone v1.X.0 → Issues → Branch feat/v1.X.0-<desc>
  → PR (links AI discussion) → merge → git tag → Release → Milestone closed

Repository: https://github.com/hervetchoffo/telco-homelab

--- CURRENT STATUS ---
[Copy the rows you need from the table below]
```

---

## Project status tracker

| Version | Milestone | Status | Notes |
|---|---|---|---|
| `v1.1.0` | Initialize GitHub repository | ✅ Done | README, CHANGELOG, 3 ADRs, PROJECT_CONTEXT, init-repo.sh |
| `v1.2.0` | HLD document & network inventory | 🔲 | |
| `v1.3.0` | Prepare Raspberry Pi OS (Trixie) | 🔲 | |
| `v1.4.0` | K3s server on Pi #1 | 🔲 | |
| `v1.5.0` | K3s agent on Pi #2 | 🔲 | |
| `v1.6.0` | Validation deployment (smoke test) | 🔲 | |
| `v1.7.0` | USB persistent volumes | 🔲 | |
| `v1.8.0` | NFS server in K8s | 🔲 | |
| `v1.9.0` | Gitea deployed (GitOps pivot) | 🔲 | |
| `v1.10.0` | Nginx via Traefik Ingress | 🔲 | |
| `v1.11.0` | Tvheadend + Sundtek USB tuner | 🔲 | |
| `v1.12.0` | Image & manifest versioning | 🔲 | |
| `v1.13.0` | Woodpecker CI runner | 🔲 | |
| `v1.14.0` | Build → deploy pipeline | 🔲 | |
| `v1.15.0` | Prometheus + Grafana monitoring | 🔲 | |
| `v1.15.0-final` | Edition 1 archive release | 🔲 | |

---

## Open decisions & blockers

| # | Topic | Status |
|---|---|---|
| 1 | Confirm IP plan (192.168.1.x assumed) | ⚠️ v1.2.0 |
| 2 | Confirm USB disk filesystem (ext4 recommended) | ⚠️ v1.3.0 |
| 3 | Gitea registry vs Docker Hub for ARM images | ⚠️ v1.9.0 |
| 4 | Trixie boot path: `/boot/firmware/cmdline.txt` | ✅ Confirmed |

---

## GitHub setup checklist

### Milestones (GitHub → Issues → Milestones)

Create one milestone per MINOR version:
`v1.2.0 — HLD document` · `v1.3.0 — Prepare OS` · `v1.4.0 — K3s server`
`v1.5.0 — K3s agent` · `v1.6.0 — Smoke test` · `v1.7.0 — USB volumes`
`v1.8.0 — NFS server` · `v1.9.0 — Gitea` · `v1.10.0 — Nginx`
`v1.11.0 — Tvheadend` · `v1.12.0 — Versioning` · `v1.13.0 — Woodpecker`
`v1.14.0 — Pipeline` · `v1.15.0 — Monitoring`

### Projects board columns

`📋 Backlog` | `🔄 In Progress` | `👀 In Review` | `✅ Done`

---

## Discussion naming convention

Format: `[v1.X.0] <Imperative verb> <object>`

| Title | Milestone |
|---|---|
| `[v1.1.0] Initialize GitHub repository` | ✅ Done |
| `[v1.2.0] Write HLD document` | next |
| `[v1.3.0] Prepare Raspberry Pi OS` | |
| `[v1.4.0] Install K3s server node` | |
| `[v1.5.0] Join K3s worker node` | |
| `[v1.6.0] Validate cluster with smoke test` | |
| `[v1.7.0] Configure USB persistent volumes` | |
| `[v1.8.0] Deploy NFS server` | |
| `[v1.9.0] Deploy Gitea as GitOps source` | |
| `[v1.10.0] Deploy Nginx with Traefik` | |
| `[v1.11.0] Deploy Tvheadend with USB tuner` | |
| `[v1.12.0] Version images and manifests` | |
| `[v1.13.0] Set up Woodpecker CI runner` | |
| `[v1.14.0] Build and deploy CI pipeline` | |
| `[v1.15.0] Add Prometheus and Grafana` | |

---

## Session workflow

**End of session:** mark milestone ✅, note decisions, commit `docs: update PROJECT_CONTEXT after v1.X.0`

**Start of session:** paste briefing block + updated status rows + `"Today'\''s goal: v1.X.0 — [title]"`
'

# =============================================================================
# STEP 4 — GITHUB TEMPLATES
# =============================================================================
step "4/7  Writing GitHub templates"

write_file ".github/ISSUE_TEMPLATE/bug_report.md" '---
name: 🐛 Bug report
about: Report unexpected behaviour
labels: bug
---

## Description

<!-- Clear and concise description of the problem -->

## Steps to reproduce

1. ...
2. ...
3. ...

## Expected behaviour

## Actual behaviour

## Environment

- Project version: `v1.X.Y`
- Node: Pi #1 / Pi #2
- Service: nginx / gitea / nfs / tvheadend
- K3s version: `kubectl version`
- OS: Raspberry Pi OS Trixie 32-bit

## Logs

```
# kubectl logs <pod> -n <namespace>
# journalctl -u k3s -n 50
```
'

write_file ".github/ISSUE_TEMPLATE/feature_request.md" '---
name: ✨ Feature request
about: Propose a new feature or improvement
labels: enhancement
---

## Summary

## Problem to solve

## Proposed solution

## Architecture impact

- [ ] New service / pod
- [ ] Change to existing K8s manifest
- [ ] New Dockerfile
- [ ] CI/CD pipeline change
- [ ] RAM impact (estimate: ___ MB)
- [ ] New ADR required

## Target milestone

<!-- e.g. v1.10.0 -->
'

# =============================================================================
# STEP 5 — SERVICE STUBS
# =============================================================================
step "5/7  Writing service README stubs"

for svc in nginx gitea nfs tvheadend; do
  write_file "docker/$svc/README.md" "# docker/$svc

Dockerfile and build resources for the **$svc** service.

> To be completed at the corresponding milestone.
"
  write_file "k8s/base/$svc/README.md" "# k8s/base/$svc

Kubernetes base manifests for **$svc** (Kustomize layer).

> To be completed at the corresponding milestone.
"
done

# ── .gitkeep files ────────────────────────────────────────────────────────────
for dir in k8s/overlays/dev k8s/overlays/prod monitoring/prometheus \
           monitoring/grafana .github/workflows; do
  if [[ "$DRY_RUN" == true ]]; then
    dryrun "touch  $dir/.gitkeep"
  else
    touch "$dir/.gitkeep"
    success "touch  $dir/.gitkeep"
  fi
done

# =============================================================================
# STEP 6 — GIT INITIALISATION
# =============================================================================
step "6/7  Git initialisation"

if git rev-parse --git-dir &>/dev/null 2>&1; then
  warn "Git repository already exists — skipping 'git init'."
else
  run_git init -b main
  success "git init (branch: main)"
fi

if [[ -n "$GIT_REMOTE" ]]; then
  if git remote get-url origin &>/dev/null 2>&1; then
    run_git remote set-url origin "$GIT_REMOTE"
    success "git remote updated → $GIT_REMOTE"
  else
    run_git remote add origin "$GIT_REMOTE"
    success "git remote added  → $GIT_REMOTE"
  fi
fi

run_git add .

if [[ "$DRY_RUN" == false ]] && git diff --cached --quiet; then
  warn "Nothing to commit — repository may already be initialised."
else
  run_git commit -m "chore: initialize repository structure — v1.1.0

- Add full directory tree (docs, docker, k8s, monitoring, scripts)
- Add README.md with overview, hardware diagram, SemVer roadmap, GitHub workflow
- Add CHANGELOG.md (Keep a Changelog)
- Add LICENSE (MIT)
- Add .gitignore
- Add ADR-001 (K3s vs K0s), ADR-002 (Gitea vs GitLab), ADR-003 (Trixie vs Bookworm)
- Add docs/PROJECT_CONTEXT.md (AI briefing block + status tracker)
- Add GitHub Issue templates
- Add scripts/init-repo.sh (this script)
- Add README stubs for all service directories

Milestone: v1.1.0 — Initialize GitHub repository
Edition:   1 — Core Infrastructure"
  success "Initial commit created"

  run_git tag -a v1.1.0 -m "v1.1.0 — Initialize GitHub repository

First milestone of Edition 1 (Core Infrastructure).
Establishes repository structure, documentation skeleton, ADRs, and SemVer conventions."
  success "Tag v1.1.0 created"
fi

# =============================================================================
# STEP 7 — SUMMARY & NEXT STEPS
# =============================================================================
step "7/7  Done"

FILE_COUNT=0
[[ "$DRY_RUN" == false ]] && FILE_COUNT=$(find . -not -path './.git/*' -type f | wc -l | tr -d ' ')

echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Initialisation complete ✓                       ║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════╝${RESET}"
echo ""
[[ "$DRY_RUN" == false ]] && echo -e "  ${BOLD}Files written:${RESET}   $FILE_COUNT"
echo -e "  ${BOLD}Git tag:${RESET}        v1.1.0"
[[ -n "$GIT_REMOTE" ]] && echo -e "  ${BOLD}Remote:${RESET}         $GIT_REMOTE"
echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo ""
if [[ -n "$GIT_REMOTE" ]]; then
  echo -e "  ${CYAN}1.${RESET} Push to GitHub:"
  echo -e "       git push -u origin main --tags"
  echo ""
  echo -e "  ${CYAN}2.${RESET} On GitHub — create the v1.1.0 Release:"
  echo -e "       Releases → Draft a new release → Tag: v1.1.0"
  echo -e "       Title: 'v1.1.0 — Initialize GitHub repository'"
  echo -e "       Paste the CHANGELOG [1.1.0] section as release notes"
  echo ""
  echo -e "  ${CYAN}3.${RESET} On GitHub — set up project management:"
  echo -e "       a) Issues → Milestones → create one per v1.X.0"
  echo -e "       b) Projects → New project → Board view"
  echo -e "          Columns: Backlog | In Progress | In Review | Done"
  echo ""
  echo -e "  ${CYAN}4.${RESET} Open next AI discussion:"
  echo -e "       Title: [v1.2.0] Write HLD document"
  echo -e "       Start with the briefing block from docs/PROJECT_CONTEXT.md"
else
  echo -e "  ${CYAN}1.${RESET} Add your GitHub remote and push:"
  echo -e "       git remote add origin https://github.com/hervetchoffo/telco-homelab.git"
  echo -e "       git push -u origin main --tags"
  echo ""
  echo -e "  ${CYAN}2–4.${RESET} See steps above once remote is configured."
fi
echo ""
