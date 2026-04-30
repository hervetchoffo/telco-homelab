# ADR-001 — Kubernetes distribution: K3s vs K0s

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
