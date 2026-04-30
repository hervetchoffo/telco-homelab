# Project Context — Telco Home Lab

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

**Start of session:** paste briefing block + updated status rows + `"Today's goal: v1.X.0 — [title]"`
