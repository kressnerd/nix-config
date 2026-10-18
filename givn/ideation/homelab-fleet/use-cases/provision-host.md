# Use case: provision-host

Status: elaborated domain draft 2026-10-17; not an implementation, selected
mechanism or observed host.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: none. Hardware and firmware preparation are preconditions.

## Goal
The Owner/operator provisions a declared host into the fleet so it is accepted
with its base system, storage layout, network attachment and service roles
present.

## Trigger
The Owner/operator requests provisioning of one specific host with its declared
role and requirements.

## Preconditions
- The host's fleet membership and role are declared (E1).
- The host's provisioning requirements are recorded: base system, storage
  layout, network attachment and service placement (E2/E3).
- The host's hardware and firmware are prepared for the declared boot mode and
  storage devices; P1/P3/P5 and the other handover checks have produced a
  usable result where the role depends on them.
- The VLAN/IP plan, naming and host addresses are declared; no address or name
  conflicts with an existing fleet member.
- Installation access and the required secrets/bootstrap material are
  available without assuming the completed host already exists.
- The host is not already accepted under another role.
- `adlerkopf` remains in the separate `adlerhorst` LAN and is not a target of
  this provisioning.

## Main flow
1. Actor Owner/operator installs the base system; System writes the declared
   base system to the host.
2. Actor Owner/operator applies the storage layout; System creates the
   declared pools, maps and mount points.
3. Actor Owner/operator attaches the host to its networks; System establishes
   the declared LAN, storage and management addressing.
4. Actor Owner/operator checks the provisioning; System verifies base system,
   storage layout, network attachment and declared service roles, and accepts
   the host only when all are present.
5. Actor Owner/operator checks the declared service role; System confirms that
   the role answers on its intended network and reports the role status.

## Extensions
- 1: Base-system installation fails, or the host boots in the wrong mode → do
  not accept a partially installed host; protects the declared boot contract.
- 2: The storage layout cannot be applied because a declared device is absent,
  a pool cannot be created, or a mount is missing → do not accept the host;
  protects the declared data layout.
- 3: Network attachment fails, an address conflicts, or the host is reachable
  on an unrequested network → do not accept the host; protects the VLAN and
  address boundary.
- 4: A declared service role is configured but not active on its intended
  network → report provisioning as incomplete; do not present the host as
  accepted.
- 5: The role check cannot be performed because the host is unreachable → do
  not claim role status; protects truthful acceptance.

## Rules
- A host is accepted only when its base system, storage layout, network
  attachment and declared service roles are present; a host that merely boots
  is not accepted.
- One host has one declared role in the fleet; roles are not duplicated
  silently.
- No undeclared storage pool, filesystem, network path or service role is
  created by provisioning.
- A service role's placement does not make its application available; the
  application's own behavior and access grants remain external.
- `adlerkopf` is not changed or migrated by this use case; it serves the
  separate `adlerhorst` LAN.
- P1–P10 are checks, not facts. An unknown result blocks acceptance only where
  the declared role depends on it.
- The public repository records no operational address or secret; those values
  come from the approved private input.

## Examples
- `pronix` is accepted only after the microSD boot path works, the ODD SSD and
  the two NVMe devices are visible, the four SATA SSDs form the declared media
  pool, and both NICs carry the declared LAN and storage addresses.
- `tinix001` is accepted after its two NVMe devices form the declared system
  pool, its single NIC carries the LAN address and the storage VLAN
  subinterface, and its declared roles answer.
- `cupix001` is accepted after its public address, internal address and
  declared edge role are present; the edge tunnel and public routes are
  established by `reach-service-from-internet`, not by provisioning.
- A host boots successfully but its media pool is missing. It is not accepted;
  the missing layout is reported.
- A host is accepted with a role whose unit is configured but not answering.
  This is rejected: the acceptance check requires the role to answer.

## Minimal guarantee
Failure is reported without accepting a partial host, without creating
undeclared pools or network paths, and without changing `adlerkopf`.

## Success guarantee
The host is accepted into the fleet with its declared base system, storage
layout, network attachment and service roles present.

## Personas
- Owner/operator (`owner--operator`): advisory critique — a booting host or a
  configured unit is not an accepted host; the storage, network and role
  checks must be real.
- Application user (`family--application-user`): advisory critique — the
  provisioning result must not widen application access or require the user to
  understand host roles; application availability is not claimed here.

## Capabilities
- none — actual owned capabilities and native verification targets are
  selected through the normal proposal/spec flow, not fabricated in ideation.

## Interactions
- none — no installation or configuration API is selected.

## Includes
- none — shared declaration/preparation subfunctions do not assert a
  leaf-to-leaf relationship.

## Extends
- none.

## Out of scope
- Booting the host without a passphrase — `boot-host-unattended`.
- Keeping data available across a storage-device failure —
  `restore-storage-redundancy`.
- Making a service reachable through the edge — `reach-service-from-internet`.
- Applying a fleet update — `apply-fleet-update`.
- Resuming a failed host's role — `recover-host`.
- Observing fleet health — `observe-fleet-health`.
- Application availability, reachability or state recovery —
  `infrastructure-growth`.
- Changing `adlerkopf` or its `adlerhorst` services — outside this topic
  (Q1/Q5).

## Diagram
See [Canvas 1 — provision and boot a host](../eventstorming.md#canvas-1--provision-and-boot-a-host).
The canvas shows the enabling responsibilities, not observed provisioning.

## Scenario skeletons
- Given a declared host role and provisioning requirements, When the Owner/operator installs the base system, applies storage and network, and checks the host, Then the host is accepted only with all declared parts present.
- Given a host that boots but has no declared storage pool, When acceptance is checked, Then the host is not accepted and the missing layout is reported.
- Given a declared service role whose unit is configured but does not answer, When the role is checked, Then provisioning is incomplete.
- Given `adlerkopf` in the separate `adlerhorst` LAN, When a trio host is provisioned, Then `adlerkopf` is unchanged and no family-facing role is assigned to it.

These are Markdown contract skeletons, not `.feature` deltas or asserted test
coverage. Real provisioning results require a meaningful native VM/live target
under `docs/GIVN-VERIFICATION.md`; no binding name is invented here.
