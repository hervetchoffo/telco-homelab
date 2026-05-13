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
  - USB disk × 2 (1 TB each, XFS filesystem, Kubernetes persistent storage)
  - Sundtek MediaTV USB tuner (passed through to Tvheadend pod)
  - OS: Raspberry Pi OS Lite 32-bit — Trixie (Debian 13, kernel 6.6 LTS)

Key technical choices (documented as ADRs):
  - K8s distribution : K3s (SQLite, no etcd — RAM constraint)     ADR-001
  - Git server       : Gitea (~80 MB RAM; GitLab excluded 2–4 GB)  ADR-002
  - OS               : Raspberry Pi OS Lite Trixie (Debian 13)     ADR-003
  - CI runner        : Woodpecker CI (Gitea OAuth, ~50 MB RAM)     ADR-004
  - Ingress          : Traefik (K3s built-in)                      ADR-005
  - Storage          : local-path PVCs on XFS USB disks            ADR-006
  - HA topology      : 1 server + 1 agent (no HA, Edition 1)       ADR-007

Node layout:
  - Pi #1 (192.168.1.100): K3s server — Nginx, Gitea, Woodpecker server
  - Pi #2 (192.168.1.101): K3s agent  — NFS server, Tvheadend, Woodpecker agent

Note on HA: multi-master HA needs ≥3 nodes for quorum. With 2 nodes,
the correct topology is 1 server + 1 agent. HA is out of scope for Edition 1.

Storage:
  - USB disks formatted as XFS with prjquota for hard PVC capacity enforcement
  - local-path-provisioner with custom quota scripts (ConfigMap setup/teardown)
  - Nightly rsync CronJob: Pi #1 k3s-storage/ → Pi #2 /backup/pi1/

Versioning (SemVer):
  - MAJOR=1  → Edition 1 (Core Infrastructure)
  - MINOR    → one deliverable milestone (v1.2.0 = HLD document)
  - PATCH    → fix or addition after a MINOR (v1.1.1 = credential guide)
  - -rc.N    → release candidate
  - -final   → last stable of the edition (archive tag)

GitHub workflow:
  Issue → Branch feat/v1.X.0-<desc> or fix/v1.X.Y-<desc>
  → PR (links AI discussion URL) → Squash and merge → git tag → Release
  → Milestone closed → PROJECT_CONTEXT updated

Local credential setup:
  - Two fine-grained PATs, one per repo, stored in libsecret
  - credential.useHttpPath=true isolates tokens by full repo path
  - Both remote URLs embed username: https://hervetchoffo@github.com/...
  - Guide: docs/libsecret-credential-setup.md

Repository: https://github.com/hervetchoffo/telco-homelab

--- CURRENT STATUS ---
v1.1.0  Initialize GitHub repository       ✅ Done
v1.1.1  Credential setup documentation     ✅ Done
v1.2.0  HLD document & network inventory   ✅ Done
v1.3.0  Prepare Raspberry Pi OS (Trixie)   🔲 Next
```

---

## Project status tracker

| Version | Milestone | Status | Notes |
|---|---|---|---|
| `v1.1.0` | Initialize GitHub repository | ✅ Done | README, CHANGELOG, ADR-001/002/003, PROJECT_CONTEXT, init-repo.sh |
| `v1.1.1` | Credential setup documentation | ✅ Done | docs/libsecret-credential-setup.md, CHANGELOG updated |
| `v1.2.0` | HLD document & network inventory | ✅ Done | docs/hld/architecture.md (18 sections, Mermaid diagrams), ADR-004–007 stubs, documentation issue template |
| `v1.3.0` | Prepare Raspberry Pi OS (Trixie) | 🔲 Next | Flash OS, configure static IPs, enable cgroups, zram, XFS USB mount |
| `v1.4.0` | K3s server on Pi #1 | 🔲 | |
| `v1.5.0` | K3s agent on Pi #2 | 🔲 | |
| `v1.6.0` | Validation deployment (smoke test) | 🔲 | |
| `v1.7.0` | USB (XFS) persistent volumes + rsync backup | 🔲 | |
| `v1.8.0` | NFS server in K8s | 🔲 | |
| `v1.9.0` | Gitea deployed (GitOps pivot) | 🔲 | |
| `v1.10.0` | Nginx via Traefik Ingress | 🔲 | |
| `v1.11.0` | Tvheadend + Sundtek USB tuner | 🔲 | |
| `v1.12.0` | Image & manifest versioning | 🔲 | |
| `v1.13.0` | Woodpecker CI runner + trigger strategy | 🔲 | |
| `v1.14.0` | Build → deploy pipeline | 🔲 | |
| `v1.15.0` | Prometheus + Grafana monitoring | 🔲 | |
| `v1.15.0-final` | Edition 1 archive release | 🔲 | |

---

## Open decisions & blockers

| # | Topic | Status |
|---|---|---|
| 1 | Confirm IP plan (192.168.1.x assumed) | ⚠️ Confirm at v1.3.0 |
| 2 | USB disk filesystem confirmed as XFS (prjquota) | ✅ Decided — ADR-006 |
| 3 | Gitea registry vs Docker Hub for ARM images | ⚠️ v1.9.0 |
| 4 | Trixie boot path: `/boot/firmware/cmdline.txt` | ✅ Confirmed |
| 5 | Per-repo PAT isolation via `credential.useHttpPath=true` | ✅ Implemented |
| 6 | PAT expiry: both tokens expire after 90 days — renewal procedure documented | ✅ Documented |
| 7 | CI/CD trigger strategy: push vs tag vs both | ⚠️ v1.13.0 — see HLD §13.3 |

---

## GitHub setup checklist

### Milestones (GitHub → Issues → Milestones)

| Milestone | Status |
|---|---|
| `v1.1.0 — Initialize GitHub repository` | ✅ Closed |
| `v1.2.0 — HLD document & network inventory` | ✅ Closed |
| `v1.3.0 — Prepare Raspberry Pi OS` | 🔲 Create |
| `v1.4.0 — K3s server on Pi #1` | 🔲 Create |
| `v1.5.0 — K3s agent on Pi #2` | 🔲 Create |
| `v1.6.0 — Smoke test` | 🔲 Create |
| `v1.7.0 — USB volumes + rsync backup` | 🔲 Create |
| `v1.8.0 — NFS server` | 🔲 Create |
| `v1.9.0 — Gitea` | 🔲 Create |
| `v1.10.0 — Nginx` | 🔲 Create |
| `v1.11.0 — Tvheadend` | 🔲 Create |
| `v1.12.0 — Versioning` | 🔲 Create |
| `v1.13.0 — Woodpecker CI + trigger strategy` | 🔲 Create |
| `v1.14.0 — Pipeline` | 🔲 Create |
| `v1.15.0 — Monitoring` | 🔲 Create |

### Projects board columns

`📋 Backlog` | `🔄 In Progress` | `👀 In Review` | `✅ Done`

---

## Discussion naming convention

Format: `[v1.X.0] <Imperative verb> <object>`

| Title | Milestone | AI session link |
|---|---|---|
| `[v1.1.0] Initialize GitHub repository` | ✅ Done | Not shared — contains revoked credential |
| `[v1.2.0] Write HLD document` | ✅ Done | [[v1.2.0] Write HLD document](https://claude.ai/share/de9ca4a5-e346-4a66-9014-f0db0747a2c3) |
| `[v1.3.0] Prepare Raspberry Pi OS` | 🔲 | |
| `[v1.4.0] Install K3s server node` | 🔲 | |
| `[v1.5.0] Join K3s worker node` | 🔲 | |
| `[v1.6.0] Validate cluster with smoke test` | 🔲 | |
| `[v1.7.0] Configure USB persistent volumes` | 🔲 | |
| `[v1.8.0] Deploy NFS server` | 🔲 | |
| `[v1.9.0] Deploy Gitea as GitOps source` | 🔲 | |
| `[v1.10.0] Deploy Nginx with Traefik` | 🔲 | |
| `[v1.11.0] Deploy Tvheadend with USB tuner` | 🔲 | |
| `[v1.12.0] Version images and manifests` | 🔲 | |
| `[v1.13.0] Set up Woodpecker CI runner` | 🔲 | |
| `[v1.14.0] Build and deploy CI pipeline` | 🔲 | |
| `[v1.15.0] Add Prometheus and Grafana` | 🔲 | |

---

## Session workflow

### Start of session

**Prepare before opening Claude:**

1. Update the `CURRENT STATUS` block in the briefing block above:
   - Mark completed milestones ✅
   - Set the active milestone as 🔲 Next (or 🔵 In progress if resuming)
2. Append `"Today's goal: milestone v1.X.0 — [title]"` at the end of
   the briefing block
3. Identify which files to attach to the session:
   - `docs/PROJECT_CONTEXT.md` — **always**
   - `docs/hld/architecture.md` — for any milestone involving network,
     services, storage, or infrastructure decisions
   - Relevant ADR files if the milestone implements or revises a decision
   - Relevant manifests or scripts if iterating on existing files

**In Claude:**

4. Paste the full briefing block as your first message
5. Attach the files identified in step 3
6. State the milestone title and its expected deliverables explicitly

---

### End of session (intermediate — milestone not yet closed)

Run at the end of every Claude conversation, even if no milestone closes.

1. Note in the status table any partial progress made (e.g. rc.1 → rc.3)
2. Update the open decisions table with any decisions made or newly raised
3. Note any deviations from the HLD — flag for a future HLD revision
4. Note any new architecture choices that should become ADR stubs
5. Get the Claude share link (top-right of the conversation) and save it
   — you will add it to the discussion table when the milestone closes
6. Commit any in-progress files:

```bash
git add <files>
git commit -m "wip: v1.X.0 — <short description of progress>"
git push origin feat/v1.X.0-<desc>
```

---

### End of milestone (final session — MINOR version v1.X.0 closes)

Run only when the milestone deliverables are complete and reviewed.

**In the PR (before merge):**

- [ ] All deliverable files committed on the feature branch
- [ ] PR description Changes table complete and accurate
- [ ] AI session URL added to PR description
- [ ] All checklist items verified
- [ ] Squash and merge

**After merge — on local machine:**

```bash
git checkout main && git pull origin main
git log --oneline -3          # confirm merge commit is HEAD
git tag -a v1.X.0 -m "v1.X.0 — <milestone title>"
git push origin v1.X.0
```

**On GitHub.com:**

- [ ] Releases → Draft new release → tag `v1.X.0`
      → paste `CHANGELOG.md [v1.X.0]` block as description → Publish
- [ ] Issues → Milestones → close `v1.X.0`

**Project context update (separate branch, no tag):**

```bash
git checkout -b fix/v1.X.0-update-project-context
```

Edit `docs/PROJECT_CONTEXT.md`:
- Mark `v1.X.0` ✅ Done in the status table
- Add the Claude session URL to the discussion table
- Promote `v1.(X+1).0` as next in the `CURRENT STATUS` block
- Update any open decisions resolved during the milestone

```bash
git add docs/PROJECT_CONTEXT.md
git commit -m "docs: update PROJECT_CONTEXT after v1.X.0 — milestone closed"
git push -u origin fix/v1.X.0-update-project-context
# PR → Squash and merge (no tag needed)
git branch -d fix/v1.X.0-update-project-context
git push origin --delete fix/v1.X.0-update-project-context
```
