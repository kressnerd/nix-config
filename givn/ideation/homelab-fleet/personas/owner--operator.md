Reuse: owner--operator, base 2026-10-11; this file adds record entries only.

## Running record

- 2026-10-17 — homelab-fleet: the Frame was confirmed after Q1 kept
  `adlerkopf` as a separate fourth host in the `adlerhorst` LAN, and Q4/Q5
  placed the trio (`pronix`, `tinix001`, `cupix001`) in its own LAN. The review
  lens accepted host-level use cases for provisioning, unattended boot,
  storage redundancy, edge publication, updates, host recovery and health.
- 2026-10-17 — homelab-fleet: the storage leaf was narrowed to restoring
  redundancy while data stayed readable; the observing leaf's monitoring
  declaration moved to a precondition so observation owns no mutation.

## Topic stances

- 2026-10-17 — homelab-fleet: `adlerkopf` is not a recovery source or a second
  authority inside the trio LAN. It serves `adlerhorst` and is reached only via
  Tailscale over a slow internet connection. Host recovery restores a host's
  role and system state; application-state recovery and application access
  remain separate guarantees.
