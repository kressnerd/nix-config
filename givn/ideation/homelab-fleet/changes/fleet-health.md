# Change seed: fleet-health

Status: ready

- Use-case IDs: observe-fleet-health
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 9 after `provision-storage-host`, `provision-compute-host`
  and `edge-service-publication`; it needs real hosts and at least one edge
  path to observe.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.

## Deliverable guarantee

Each declared health-threshold breach on a host, storage pool or edge path
produces a delivered alert to the owner's declared channel, and an undelivered
alert is visible as a failure. An unknown signal is reported as unknown, not
healthy. The observation is read-only: it does not repair a host, pool, route
or service.

## Accepted decisions

### Delivered alert is the guarantee, not a green dashboard

- Context: the handover includes Prometheus/Loki/Grafana on the compute host
  and Gatus on the edge. Monitoring must be useful when a host is down, when
  the edge is down and when alert delivery fails.
- Options:
  1. **Declared thresholds with delivered alerts and visible non-delivery** —
     the owner's knowledge is the result.
     In practice: a disk threshold on `pronix` or a lost `tinix001` produces a
     delivered alert; a failed delivery is recorded as a failure.
     Gain: a truthful health guarantee that covers the observer's own failure.
     Cost: an alert channel and thresholds must be declared; a dashboard alone
     is not enough.
  2. **Dashboard-only monitoring** — the owner checks a UI.
     In practice: a failure is visible only if someone looks.
     Gain: less alerting work.
     Cost: no delivered-alert guarantee; a down host may go unnoticed.
  3. **Application-level uptime only** — monitor only user-facing services.
     In practice: a storage pool or host failure without a user-visible
     symptom is not observed.
     Gain: fewer signals.
     Cost: misses the host/pool/edge health this topic owns.
- Chosen: **Declared thresholds with delivered alerts and visible
  non-delivery**. Rejected: dashboard-only because it has no delivery
  guarantee; application-only because it misses host and pool health.

## Open questions

### Alert channel and recipient

Which channel carries alerts, who receives them, and how is delivery verified?
An address that is configured but never verified is not a delivery guarantee.

### Thresholds and signal set

Which host, pool and edge signals have thresholds, and what counts as a
breach? The handover names disk 95% as a test alarm; the full set must be
declared.

### Monitoring placement and self-observation

Where do Prometheus, Loki, Grafana and Gatus run, and what observes the
observer? If `tinix001` is down, the alert must still be produced by a
component that survives that failure.
