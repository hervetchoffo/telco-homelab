# ADR-005 — Traefik as ingress controller

| Field     | Value      |
|-----------|------------|
| Status    | Accepted   |
| Date      | 2026-05-11 |
| Milestone | v1.2.0     |

## Decision

Use Traefik (bundled with K3s) as the ingress controller for Edition 1.

## Rationale

- Zero additional RAM cost — deployed automatically by K3s on first boot
- CRD-based `IngressRoute` objects enable host-based and path-based routing
  without extra annotation syntax
- Built-in TLS termination via cert-manager `Certificate` objects
- No additional installation or configuration required for basic use

## Alternatives considered

| Alternative | Reason excluded |
|---|---|
| Nginx Ingress Controller | ~50 MB extra RAM; requires separate install; no benefit over Traefik for this scale |
| HAProxy Ingress | Less ARM community support; no bundled advantage |

## Consequences

- All HTTP/S traffic enters the cluster through Traefik on Pi #1 (ports 80/443)
- Four `IngressRoute` CRD objects required: Nginx, Gitea, Woodpecker, Tvheadend
- DNS entries for `*.homelab.local` must resolve to `192.168.1.100`
- cert-manager deployed alongside Traefik for automated TLS certificate lifecycle
- Full Traefik configuration in milestone v1.10.0
