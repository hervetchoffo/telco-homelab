#!/usr/bin/env bash
#
# install-k3s.sh — STUB — K3s install reference (v1.3.0)
#
# This script does NOT install K3s. It documents the exact commands and
# token exchange procedure that will be automated in later milestones:
#   - v1.4.0 : scripts/install-k3s-server.sh (Pi #1)
#   - v1.5.0 : scripts/install-k3s-agent.sh  (Pi #2)
#
# Usage:
#   ./install-k3s.sh --show
#
set -euo pipefail

show_procedure() {
cat <<'EOF'
════════════════════════════════════════════════════════════════
 K3s install reference — telco-homelab (Edition 1, ADR-001/007)
════════════════════════════════════════════════════════════════

STEP 1 — Install K3s server on Pi #1 (pi-server, 192.168.1.100)
------------------------------------------------------------------
  curl -sfL https://get.k3s.io | \
    INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

  This deploys, as a single binary:
    - kube-apiserver, scheduler, controller-manager
    - SQLite datastore          (ADR-001 — no etcd, RAM constraint)
    - Traefik ingress           (ADR-005)
    - local-path-provisioner    (ADR-006)
    - CoreDNS

STEP 2 — Retrieve the join token (on Pi #1)
------------------------------------------------------------------
  sudo cat /var/lib/rancher/k3s/server/node-token

  Treat this token like a credential:
    - Do not commit it to git
    - Do not paste it into a GitHub issue or PR
    - Copy it over SSH directly to Pi #2, or type it manually

STEP 3 — Install K3s agent on Pi #2 (pi-agent, 192.168.1.101)
------------------------------------------------------------------
  curl -sfL https://get.k3s.io | \
    K3S_URL=https://192.168.1.100:6443 \
    K3S_TOKEN=<paste-token-from-step-2> \
    sh -

STEP 4 — Verify cluster from Pi #1
------------------------------------------------------------------
  kubectl get nodes -o wide

  Expected:
    NAME         STATUS   ROLES                  AGE   VERSION
    pi-server    Ready    control-plane,master   ..    v1.x
    pi-agent     Ready    <none>                 ..    v1.x

STEP 5 — Label nodes for workload placement (HLD §9.1)
------------------------------------------------------------------
  kubectl label node pi-server node-role.telco-homelab/services=true
  kubectl label node pi-agent  node-role.telco-homelab/media=true

════════════════════════════════════════════════════════════════
 Prerequisites (must be complete before Step 1):
   - setup-node.sh has run successfully on BOTH nodes
   - cgroup flags active (reboot done, verify: cat /proc/cgroups)
   - XFS storage mounted with prjquota on BOTH nodes
   - zram swap active (verify: zramctl)

 Full automation of Steps 1–5 is deferred to v1.4.0 / v1.5.0.
════════════════════════════════════════════════════════════════
EOF
}

case "${1:-}" in
  --show)
    show_procedure
    ;;
  *)
    echo "Usage: $0 --show"
    echo "This is a v1.3.0 STUB — it documents commands only, it does not install K3s."
    exit 1
    ;;
esac
