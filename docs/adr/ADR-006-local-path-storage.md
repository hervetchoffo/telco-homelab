# ADR-006 — local-path-provisioner with XFS project quotas for storage

| Field     | Value      |
|-----------|------------|
| Status    | Accepted   |
| Date      | 2026-05-11 |
| Milestone | v1.2.0     |

## Decision

Use K3s built-in `local-path-provisioner` backed by XFS-formatted USB disks
with project quotas for all PersistentVolumeClaims in Edition 1.

## Rationale

- No additional RAM overhead — provisioner is bundled with K3s
- XFS `prjquota` mount option enables hard per-directory quota enforcement,
  compensating for local-path-provisioner's lack of native capacity enforcement
- USB disks provide sufficient capacity for all Edition 1 workloads (1 TB each)
- Avoids high resource cost of distributed storage solutions

## Alternatives considered

| Alternative | Reason excluded |
|---|---|
| Longhorn | ~500 MB RAM per node — incompatible with 1 GB RAM constraint |
| Ceph | Requires minimum 3 nodes and significant RAM |
| NFS-backed PVCs | Circular dependency — NFS server is itself a cluster workload |
| ext4 | Supports project quotas but XFS is recommended in local-path-provisioner examples |

## Consequences

- USB disks formatted as XFS with `prjquota` option in `/etc/fstab`
- Custom setup/teardown scripts provided via `local-path-provisioner` ConfigMap
- Helper container requires `xfsprogs` package
- PVCs are node-local — no cross-node replication
- Data loss risk mitigated by nightly rsync CronJob: Pi #1 → Pi #2 `/backup/pi1/`
- XFS quota scripts must be retested after any `local-path-provisioner` upgrade
- Full storage configuration in milestone v1.7.0
