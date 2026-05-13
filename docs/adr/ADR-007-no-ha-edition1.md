# ADR-007 — Single server + single agent topology (no HA) for Edition 1

| Field     | Value      |
|-----------|------------|
| Status    | Accepted   |
| Date      | 2026-05-11 |
| Milestone | v1.2.0     |

## Decision

Deploy a 1 server + 1 agent topology for Edition 1. No high availability.

## Rationale

Multi-master HA in K3s requires a minimum of 3 nodes for Raft quorum.
With only 2 Raspberry Pi 2B nodes available, HA is not achievable.
Pi #1 is accepted as a Single Point of Failure for Edition 1.

## Alternatives considered

| Alternative | Reason excluded |
|---|---|
| 2-node HA with embedded etcd | Not supported — etcd Raft requires ≥ 3 nodes for quorum |
| External database HA (MySQL/PostgreSQL) | Adds operational complexity incompatible with the beginner training path scope |
| 3-node cluster with a third Pi | Hardware not available for Edition 1 |

## Consequences

- If Pi #1 (server) fails, the entire cluster is unavailable until restored
- Accepted risk R1 in the HLD risks register
- Mitigation: nightly SQLite backup to Pi #2 USB disk (milestone v1.7.0)
- Multi-master HA topology using ≥ 3 nodes is Edition 2 scope
