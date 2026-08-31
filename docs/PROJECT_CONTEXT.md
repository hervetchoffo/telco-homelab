I am working on a home Telco Cloud lab project called "telco-homelab".
Please act as a DevOps / Telco Cloud expert throughout this discussion.
All responses, code, and documentation must be in English.

--- PROJECT SUMMARY ---
Goal: Deploy Tvheadend, NFS, Nginx and Gitea on a two-node K3s cluster
      running on Raspberry Pi 2B, managed fully as Infrastructure as Code.

Training path: Telco Cloud Beginner (Linux → Docker → Kubernetes → CI/CD)

Hardware (confirmed on real nodes at v1.3.0):
  - Raspberry Pi 2B × 2 (ARM Cortex-A7, 4-core @ 900 MHz, 1 GB RAM each
    — ~920 MiB usable per `free -h`, GPU/firmware memory split)
  - USB disk × 2 (1 TB each, XFS + prjquota, mounted at /mnt/k3s-storage
    — WD Elements SE on pi-server, Toshiba STOR.E Basics on pi-agent)
  - Sundtek MediaTV Pro III MiniPCIe tuner, USB ID 2659:1212 (confirmed),
    attached to pi-agent — driver install deferred to v1.11.0
  - OS: Raspberry Pi OS Lite 32-bit — Trixie (Debian 13), running kernel
    6.18.34+rpt-rpi-v7 (newer than the 6.6 LTS baseline in ADR-003 —
    expected drift, does not affect the decision)
  - cgroup v2 (unified hierarchy) confirmed active by default on both
    nodes; verify controller availability via
    /sys/fs/cgroup/cgroup.controllers, NOT /proc/cgroups (legacy v1
    interface, unreliable on this kernel — see ADR-003 revision notes)

Key technical choices (documented as ADRs):
  - K8s distribution : K3s (SQLite, no etcd — RAM constraint)     ADR-001
  - Git server       : Gitea (~80 MB RAM; GitLab excluded 2–4 GB)  ADR-002
  - OS               : Raspberry Pi OS Lite Trixie (Debian 13)     ADR-003
  - CI runner        : Woodpecker CI (Gitea OAuth, ~50 MB RAM)     ADR-004
  - Ingress          : Traefik (K3s built-in)                      ADR-005
  - Storage          : local-path PVCs on XFS USB disks            ADR-006
  - HA topology      : 1 server + 1 agent (no HA, Edition 1)       ADR-007
  - Tuner passthrough: Proposed — device-node pre-creation required
    on host before container start; final decision at v1.11.0      ADR-008

Node layout (hostnames confirmed on real hardware — NOT pi-1/pi-2):
  - pi-server (192.168.1.100): K3s server — Nginx, Gitea, Woodpecker server
  - pi-agent  (192.168.1.101): K3s agent  — NFS server, Tvheadend, Woodpecker agent
  - SSH: key-only (password auth disabled), config aliases `pi-server`/
    `pi-agent`, admin user `herve` (not the generic `pi` user)
  - IP addressing: router-side DHCP reservation by MAC, NOT a manually
    configured static IP on the interface — scripts verify, never set, IP

Note on HA: multi-master HA needs ≥3 nodes for quorum. With 2 nodes,
the correct topology is 1 server + 1 agent. HA is out of scope for Edition 1.

Storage:
  - USB disks formatted as XFS with prjquota for hard PVC capacity enforcement
  - Mounted at /mnt/k3s-storage on both nodes (NOT /mnt/usb0)
  - local-path-provisioner with custom quota scripts (ConfigMap setup/teardown)
  - Nightly rsync CronJob: pi-server k3s-storage/ → pi-agent /backup/pi1/

Versioning (SemVer):
  - MAJOR=1  → Edition 1 (Core Infrastructure)
  - MINOR    → one deliverable milestone (v1.4.0 = K3s server on Pi #1)
  - PATCH    → fix or addition after a MINOR
  - -rc.N    → release candidate
  - -final   → last stable of the edition (archive tag)

GitHub workflow:
  Issue → Branch feat/v1.X.0-<desc> or fix/v1.X.Y-<desc>
  → PR (links AI discussion URL) → Squash and merge → git tag → Release
  → Milestone closed → PROJECT_CONTEXT updated
  (Administrative closeout — CHANGELOG/README/PROJECT_CONTEXT updates
  after a tag — also goes through a short-lived branch + PR, same as
  any other change; nothing is pushed directly to main.)

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
v1.3.0  Prepare Raspberry Pi OS (Trixie)   ✅ Done
v1.4.0  K3s server on Pi #1                🔲 Today's goal

--- TODAY'S GOAL ---
Milestone v1.4.0 — K3s server installation on Pi #1

Deliverables expected:
1. scripts/install-k3s-server.sh
   - Full implementation of the procedure documented as a stub in
     scripts/install-k3s.sh at v1.3.0 (see that file for the exact
     command and token-exchange reference)
   - Idempotent: safe to re-run against an already-installed server
   - Installs K3s with INSTALL_K3S_EXEC="--write-kubeconfig-mode 644"
   - Must run on pi-server only — guard against accidental agent run

2. Verification steps
   - `kubectl get nodes -o wide` shows pi-server Ready,
     roles control-plane,master
   - Confirm Traefik, CoreDNS, local-path-provisioner auto-deployed
     (`kubectl get pods -A`)
   - Confirm K3s server RAM usage aligns with the ADR-001 estimate
     (~200–300 MB) against the confirmed ~920 MiB usable baseline
   - Retrieve and safely store the node-token for v1.5.0 (agent join)
     — treat as a credential, do not commit to git, do not paste into
     an issue or PR

3. kubeconfig handling
   - Confirm .gitignore excludes kubeconfig (already true since v1.1.0
     — verify, do not assume)
   - Document how to fetch kubeconfig for local kubectl use without
     copying secrets into the repo

4. Validation checklist (aligned with HLD §11 test & validation section)

5. CHANGELOG.md entry for v1.4.0

6. GitHub workflow: Issue → Branch → PR → Tag → Release

Key constraints to respect:
  - Server-only in this milestone — do NOT join the agent yet (that's
    v1.5.0); this milestone validates a single-node control plane first
  - All scripts must target armv7l (32-bit ARM) Raspberry Pi OS Trixie
  - Follow IaC principles: every action described in a file, no manual steps
  - Reuse the SSH config aliases (`ssh pi-server`) and confirmed hostname/
    IP verification pattern established in setup-node.sh — do not
    reintroduce raw `pi@<ip>` or assume static IP configuration
