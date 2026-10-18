# Proposal: provision-storage-host

## Release note

`pronix` joins the fleet as an accepted storage host, booting through its declared unlock path and serving its declared storage exports and shares on the storage network.

## Use-Case Context

- Use-case ID: `provision-host`
- Ideation topic: `homelab-fleet`
- Seed path: `givn/ideation/homelab-fleet/changes/provision-storage-host.md`
- Confirmed Personas: `owner--operator` (primary actor and reviewer; confirmed reuse in Q2) and `family--application-user` (affected review lens; this change has no family-facing interface; confirmed reuse in Q2). No Persona biography is copied.

## Problem / Opportunity

The repository declares no `pronix` host. The existing home-server plans target `adlerkopf`, a different machine in the separate `adlerhorst` LAN, and `hosts/cupix001` is still a skeleton. The operator therefore cannot provision the storage and infrastructure host that the current architecture places in the trio's LAN.

The gap has concrete consequences: the later compute host has no declared NFS exports to mount, the later storage-redundancy seed has no pool to test, and the operator cannot tell whether a host that boots is actually accepted with its storage, network and service roles.

The opportunity is to make `pronix` a real accepted host before any application, edge or recovery work depends on it. This keeps the first deliverable small and avoids the unlock-chain cycle: unattended `pronix` boot depends on Tang on `tinix001`, so the first storage-host change keeps the declared passphrase fallback.

## Proposed Solution

The operator declares `pronix` as the storage and infrastructure host in the trio's LAN, with its declared boot path, encrypted root, storage pools, network attachments and storage roles. Operational addresses and device identities come from the approved private input; the public configuration still evaluates without them.

When provisioning completes, the operator observes:

- the host is reachable on its declared LAN, storage and management addresses;
- the declared boot path starts the host, and the declared encrypted root opens through the declared unlock path; the retained passphrase remains the fallback when the primary unlock material is unavailable;
- the declared pools are mounted and the declared `media`, `photos`, `books`, `appdata` and `backup-staging` exports are reachable from the intended storage network;
- the declared Samba shares answer to their intended family accounts;
- the declared storage maintenance schedule (scrub and snapshots) is active;
- a host that boots but lacks a declared pool, has an address conflict, is reachable on an unrequested network, or has a configured but non-answering storage role is reported as not accepted;
- `adlerkopf` and its `adlerhorst` services are unchanged.

Acceptance is a host-level outcome. It does not claim that an application is available, that application state is recoverable, or that the storage pool is redundant against a device failure. Those are separate seeds.

## Capability Routing

`givn spec route --change provision-storage-host` reported `EXTEND quiet-configuration-evaluation` (score 13.00) on a lexical signal. That capability owns release-default warning suppression, not host provisioning; the score came from a capability text containing `none` and generic evaluation words. No existing capability owns host acceptance, storage layout, network attachment or service-role checks.

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| Accept `pronix` into the fleet as the storage host | `EXTEND quiet-configuration-evaluation` | `NEW in provision-host` | The route match is a lexical false positive; `quiet-configuration-evaluation` does not own host provisioning. The new capability owns the accepted-host outcome for `pronix`. |

## Out of Scope

- Unattended `pronix` boot through Tang/Clevis and the `tinix001` unlock chain; that is the `unattended-storage-boot` seed.
- `tinix001` provisioning, TPM unlock and Tang service; that is the `provision-compute-host` seed.
- `cupix001` edge publication beyond one selected service, DERP, Headscale, mail and Caddy. The `edge-service-publication` seed covers one selected service; the rest are uncovered follow-up candidates, not ready seeds.
- Storage-device failure and rebuild proof; that is the `storage-redundancy` seed.
- AdGuard's primary/secondary DNS role, the mail split, Headscale/DERP, Authentik and the full monitoring stack have no ready seed yet; they are follow-up candidates in the handover-coverage table. Restic application-data copies belong to `infrastructure-growth`; host system state is the `preserve-host-state` seed; host recovery is the `host-recovery` seed.
- Application availability, per-application reachability and application-state recovery; owned by `infrastructure-growth`.
- Personal laptops/workstations and the `reproduce-working-environment` use case.
- Changes to `adlerkopf` or its `adlerhorst` services; it remains a separate fourth host outside this topic.
- Hardware procurement, racking and firmware flashing; hardware/firmware preparation is a precondition, not this change's outcome.
- Recording operational addresses, device identities or secrets in the public repository.

## Open Questions

### D1 — Real `pronix` device and boot values

- Question: Which `/dev/disk/by-id` values identify the microSD boot device, the ODD SSD, the four SATA SSDs and the two NVMe devices; does P1 show both NVMe devices; does P2 boot the declared loader from microSD; and which kernel module drives the NIC (P3)?
- Options:
  1. **Supply the observed values from the live installer** — record them in the approved private input and use them for the host declarations; gain: the host matches the real hardware and can be accepted; cost: requires physical access and a live boot before the change can complete; in practice: the microSD is declared by its observed `by-id` value, and the two NVMe devices both appear.
  2. **Use documentation-range placeholders** — keep the public stub and defer the real values; gain: the proposal and spec can advance; cost: the host cannot be accepted, and a placeholder deploy can lock the operator out; in practice: the host evaluates but no real storage is mounted.
- Disposition: carried — owner `owner--operator`; `design.md` resolves D1 before implementation. The real values are not recorded in the public repository.

### D2 — Pool 2 feasibility (A2)

- Question: Does the PCIe NVMe card expose both NVMe devices to Linux, so the appdata pool can be a separate two-device pool, or must the layout be reduced?
- Options:
  1. **Both NVMe devices visible** — keep the separate appdata pool; gain: the declared pool split matches the handover; cost: the PCIe card must be verified; in practice: both devices appear and the appdata pool is created.
  2. **Only one device visible** — reduce the layout and place the appdata subvolumes in the remaining pool; gain: a truthful layout without a pool that cannot exist; cost: the handover's three-pool split changes; in practice: the acceptance check requires only the pools that the hardware supports.
- Disposition: carried — owner `owner--operator`; `design.md` resolves D2 after P1. The reduction must be recorded, not silently claimed as a separate pool.

### D3 — Real network and private values

- Question: Which LAN, storage VLAN, management VLAN and addresses does `pronix` use, and which values are supplied by the approved private input?
- Options:
  1. **Private input supplies the real values** — the host is declared with the operator's actual addresses; gain: the host is reachable and can be accepted; cost: the private input must be present and correct before deployment; in practice: the LAN and storage addresses come from the private flake input, not the public tree.
  2. **Public stub only** — no real address is supplied; gain: a clean clone evaluates; cost: the host is not accepted and a stub deploy is unsafe; in practice: the configuration evaluates but the host has documentation-range addresses.
- Disposition: carried — owner `owner--operator`; `design.md` resolves D3 before implementation, and the deploy preflight must refuse a stub-only override.
