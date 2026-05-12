# ADR-004 — Woodpecker CI over other CI runners

| Field     | Value      |
|-----------|------------|
| Status    | Accepted   |
| Date      | 2026-05-11 |
| Milestone | v1.2.0     |

## Decision

Use Woodpecker CI as the pipeline runner for Edition 1.

## Rationale

- ~50 MB RAM at idle — compatible with 1 GB RAM per Pi 2B node
- Native Gitea OAuth integration — no extra authentication configuration
- Pipeline-as-code via `.woodpecker.yml` stored alongside source code
- `arm/v7` container image available for both server and agent components
- Active project (Drone CI fork maintained by the community)

## Alternatives considered

| Alternative | Reason excluded |
|---|---|
| GitHub Actions | Requires outbound Internet access from the cluster for every job |
| Jenkins | 500+ MB RAM at idle — incompatible with Pi 2B constraint |
| Drone CI | Project archived; Woodpecker CI is the active maintained fork |
| GitLab CI | Excluded with GitLab itself — 2–4 GB RAM minimum |

## Consequences

- Woodpecker server deployed on Pi #1 (namespace `ci`)
- Woodpecker agent deployed on Pi #2 (namespace `ci`)
- CI/CD trigger strategy (push vs tag) deferred to milestone v1.13.0
- Full pipeline specification in milestone v1.14.0
