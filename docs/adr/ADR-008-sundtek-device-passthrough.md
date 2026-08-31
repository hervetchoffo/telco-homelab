# ADR-008 — Sundtek tuner device passthrough strategy for Tvheadend on K3s

| Field     | Value                                              |
|-----------|-----------------------------------------------------|
| Status    | Proposed                                             |
| Date      | 2026-08-29                                           |
| Milestone | v1.3.0 (research) — implementation deferred to v1.11.0 |

## Context

While preparing v1.3.0's hardware inventory tooling, the Sundtek Docker
wiki (<https://sundtek.de/wiki/index.php?title=Docker>) was reviewed to
understand what, if anything, needs to happen on the **host** OS before
the Sundtek driver — installed inside the Tvheadend container per
ADR/project convention — can actually reach the physical tuner.

The finding changes the shape of v1.11.0's work, so it is recorded now
while the research is fresh, even though implementation and validation
against the real MediaTV Pro III MiniPCIe tuner (confirmed USB ID
`2659:1212`, see `docs/hardware/inventory-pi-agent.txt`) is deferred.

### The core mechanism

Docker's (and by extension any container runtime's) device passthrough
works by reading the **major:minor numbers of an existing host device
node** at container-creation time, then adding those numbers to the
container's device cgroup allow-list. If `/dev/dvb/adapter0/frontend0`
does not exist on the host *before* the container is created, there is
nothing for the runtime to read — passthrough has no node to point at.

This means `/dev/dvb/adapterN/{frontend0,dvr0,demux0}` character device
nodes must be **pre-created on the host**, even though the actual driver
logic that makes them functional runs *inside* the Tvheadend container.
`/dev/bus/usb` — the raw USB interface the in-container driver talks to
— must also be passed through.

## Options under consideration

### Option A — Host driver installed in "docker host" stub mode

Install the real Sundtek driver on the host, but set `enabledocker=on`
in `/etc/sundtek.conf`. In this mode the host driver does not touch the
USB device at all — it only creates the dummy `/dev/dvb/adapterN/*`
nodes matching the tuner actually detected, then exits immediately.

- ✅ Officially documented, supported path
- ✅ Self-corrects the adapter count/numbering to match the real tuner
  (the MediaTV Pro III MiniPCIe is a hybrid tuner and may expose more
  than one adapter — this option observes that directly rather than
  assuming it)
- ⚠️ Installs a host-level package purely to run in a no-op stub mode —
  a small deviation from the project's preference for keeping the host
  OS minimal (see `inventory-node.sh`'s existing driver-on-host note)

### Option B — Manually created dummy device nodes

Skip host driver installation entirely; create the nodes directly via
`mknod`, using the fixed DVB major number (`212`) and the per-adapter
minor pattern documented by Sundtek (`frontend0`/`dvr0`/`demux0` =
`+1`/`+5`/`+3` per adapter, offset by 6 per additional adapter).

- ✅ Zero host package footprint — consistent with keeping the driver
  entirely inside the container image (immutable infrastructure)
- ⚠️ The documented major:minor pattern is generic; it has not yet been
  verified against how many adapters this specific tuner model actually
  exposes. Must be validated against real driver output (e.g. via a
  one-off container run) before being scripted as a permanent step.

## Kubernetes translation (not Docker CLI)

The wiki's instructions are Docker-CLI-specific (`docker create
--device=/dev/dvb --device=/dev/bus/usb`). K3s Pod specs have no direct
equivalent of `--device`. The standard translation is:

- `hostPath` volumes for `/dev/dvb` and `/dev/bus/usb`, mounted into the
  Tvheadend container
- Either `securityContext.privileged: true`, or explicit device cgroup
  rules for a less permissive alternative

For a single-tenant home lab, `privileged: true` is the pragmatic
choice, but it is a real trade-off against the project's general
least-privilege posture and should be weighed explicitly — and noted in
the HLD's security considerations section — when this ADR is finalized.

## Decision

**Not yet made.** This ADR captures the research and both candidate
options ahead of time. A final decision — and the move to `Accepted` —
happens at v1.11.0, once the real adapter enumeration from the physical
tuner is observed (most likely via Option A used transiently as a
diagnostic step, even if Option B or a hybrid is chosen for the final
scripted implementation).

## Consequences

- v1.3.0 does not implement any device passthrough. `inventory-node.sh`'s
  tuner detection remains USB-level only (vendor/product ID via `lsusb`),
  as already documented in its output.
- Whichever option is finalized must be captured as an idempotent script
  (e.g. `scripts/setup-tuner-devices.sh`) run on `pi-agent` before the
  Tvheadend Kubernetes manifest is applied — consistent with the
  project's IaC principle that host-level prerequisites are scripted,
  not performed manually.
- The `privileged: true` trade-off (if selected) should be flagged in a
  future security-hardening review, alongside the global IPv6 exposure
  noted separately during v1.3.0 validation.

## Alternatives considered

| Alternative | Reason not (yet) selected |
|---|---|
| Kubernetes Device Plugin framework | Significant additional complexity for a single-tenant home lab; better suited to shared multi-tenant clusters needing dynamic device allocation |
| Skip host-side node pre-creation entirely | Contradicts the documented mechanism — the container runtime's device cgroup allow-list is fixed at container-creation time, not discoverable at runtime |

## References

- Sundtek Docker wiki: <https://sundtek.de/wiki/index.php?title=Docker>
- `docs/hardware/inventory-pi-agent.txt` — confirmed tuner USB ID `2659:1212`
