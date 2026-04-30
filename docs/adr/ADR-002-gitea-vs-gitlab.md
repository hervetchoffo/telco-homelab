# ADR-002 — Git server: Gitea vs GitLab

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
