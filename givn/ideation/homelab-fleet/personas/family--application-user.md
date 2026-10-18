Reuse: family--application-user, base 2026-10-11; this file adds record entries only.

## Running record

- 2026-10-17 — homelab-fleet: the reused application-user lens reviewed the
  fleet use cases. It accepted that host provisioning, edge publication and
  host recovery do not grant application resources, do not widen access and do
  not claim application availability or application-state recovery.
- 2026-10-17 — homelab-fleet: the lens noted that cross-LAN access to
  `adlerhorst` is slow and Tailscale-dependent; no family member gains an
  infrastructure-administration role or a second resolver in the trio LAN.

## Topic stances

- 2026-10-17 — homelab-fleet: a published edge route is transport, not a
  grant. The hosted application still decides which resources a family member
  or selected outside recipient may use. A recovered host is not a recovered
  application.
