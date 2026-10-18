# Use case: recover-host

Status: elaborated domain draft 2026-10-17; not an implementation, selected
restore procedure or observed recovery.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Replacement host for the Owner/operator (receives the declared
  role and restored system state); approved state source or bootstrap (supplies
  the permitted recovery material).

## Goal
The Owner/operator resumes a failed host's declared role, so a replacement host
carries the role and persistent system state and the role answers again.

## Trigger
The Owner/operator observes that a declared host is lost and cannot be
recovered in place.

## Preconditions
- The failed host's role, provisioning definition and service placement are
  declared.
- Replacement hardware or a replacement instance is available.
- An approved source for the host's persistent system state and bootstrap
  exists and survives the declared failure boundary; a reference that
  regenerates missing private material is not a source.
- Application data and application-specific recovery are identified as
  separate dependencies; they are not assumed to be part of host state.
- The Owner/operator observes that the host is unavailable; the failure cause
  is not yet distinguished from planned maintenance.
- The failed host's secrets/bootstrap can be re-established through an
  approved procedure.

## Main flow
1. Actor Owner/operator assesses the unavailable host; System records the
   observed failure and distinguishes it from planned maintenance.
2. Actor Owner/operator provisions a replacement host from the declared
   provisioning definition; System establishes the replacement as a fleet host.
3. Actor Owner/operator restores the host's persistent system state and
   bootstrap from the approved source; System restores the declared state on
   the replacement.
4. Actor Owner/operator checks the declared role and service placement; System
   confirms that the role answers again and reports fleet readiness.

## Extensions
- 1: The observed unavailability is planned maintenance → do not start host
  recovery; protects against a duplicate replacement.
- 1: The failure cause is unknown or the failed host may still be active →
  establish the failure boundary before replacing; protects against split
  identity or conflicting state.
- 2: Replacement provisioning fails → report the failure; do not claim a
  replacement host.
- 3: The approved state source is missing, unreadable, unauthorized or
  wrong-version → do not claim host recovery; preserve already available
  required state and report the unmet prerequisite.
- 3: The supported restore procedure fails or produces unusable state → report
  the failure; do not claim restored state.
- 4: The role does not answer or answers on an unrequested path → report the
  failure; do not claim fleet readiness.
- 4: The host role answers but application data is absent → host recovery may
  be complete, but application recovery is reported as pending and is not
  claimed. The distinction is explicit.
- 4: The replacement's identity or secrets conflict with the failed host →
  resolve the identity before resuming the role; protects fleet identity.

## Rules
- Host recovery is not application recovery. Application data, application
  consistency and application access restoration remain with
  `infrastructure-growth`.
- A fresh install is not recovery; the host's persistent system state and
  bootstrap must be restored from an approved source.
- The state source must survive the declared failure boundary; a same-host
  persistence area, a local snapshot or a source reference that regenerates
  missing material is not enough.
- The replacement carries the declared role; recovery does not introduce a
  new role or an undeclared service placement.
- A failed restoration is not success, even if the replacement boots.
- The recovered host does not automatically reopen application access;
  application recovery and access checks are separate.
- `adlerkopf` is not a recovery target or a source for the trio; it serves the
  separate `adlerhorst` LAN.

## Examples
- `tinix001` loses both system NVMe devices. The Owner/operator provisions a
  replacement, restores the declared persistent system state from the approved
  source, and confirms that the declared roles answer. Application data on
  `pronix` and the application-state recovery remain separate.
- `pronix` loses its microSD boot device but its storage pools survive. The
  Owner/operator rebuilds the boot path, restores the declared system state,
  and confirms the storage exports answer. The surviving pools are not a
  host-state backup.
- `cupix001` is rebuilt at the provider. The Owner/operator restores its
  declared edge role and confirms the tunnel and selected routes. Application
  access is re-established only after the separate access checks.
- A replacement boots but its state source is unreadable. Host recovery is
  reported failed; the boot is not treated as recovered state.
- A replacement host answers its role but the application's data is missing.
  Host recovery is complete; application recovery is reported pending, not
  silently merged into one success.

## Minimal guarantee
Failure is reported without claiming a recovered host, without inventing
missing state or credentials, and without claiming application recovery.

## Success guarantee
A replacement host carries the failed host's declared role and persistent
system state, and the role answers again.

## Personas
- Owner/operator (`owner--operator`): advisory critique — a booting
  replacement is not a recovered host; the state source and the role check are
  part of the result.
- Application user (`family--application-user`): advisory critique — the user
  regains use only when the application is separately recovered and access is
  checked; host recovery alone is not their result.

## Capabilities
- none — actual owned capabilities and native verification targets are
  selected through the normal proposal/spec flow, not fabricated in ideation.

## Interactions
- none — no backup, restore or deployment command is selected.

## Includes
- none — replacement provisioning and state restore are subfunctions of the
  one host-recovery guarantee.

## Extends
- none.

## Out of scope
- Application-state protection and recovery — `infrastructure-growth`.
- Provisioning a new host in normal operation — `provision-host`.
- Booting a host without a passphrase — `boot-host-unattended`.
- Restoring storage redundancy after a device failure —
  `restore-storage-redundancy`.
- Applying a fleet update — `apply-fleet-update`.
- Publishing a service at the edge — `reach-service-from-internet`.
- Observing health — `observe-fleet-health`.
- Recovering `adlerkopf` or its `adlerhorst` services — outside this topic.

## Diagram
See [Canvas 4 — keep current, recover and observe](../eventstorming.md#canvas-4--keep-current-recover-and-observe).
The recovery slice is the enabling responsibility; this is not an observed
recovery.

## Scenario skeletons
- Given a failed host and an approved state source that survives the failure, When the Owner/operator provisions a replacement and restores the declared state, Then the replacement carries the role and the role answers.
- Given a failed host whose state source is unreadable, When recovery is attempted, Then host recovery is reported failed and the boot is not treated as recovered state.
- Given a replacement that answers its role but lacks application data, When readiness is checked, Then host recovery is complete and application recovery is reported pending.
- Given an observed unavailability that is planned maintenance, When the Owner/operator assesses it, Then no replacement is started.
- Given a replacement whose identity conflicts with the failed host, When the role is resumed, Then the conflict is resolved before fleet readiness is claimed.

These are Markdown contract skeletons, not `.feature` deltas or asserted test
coverage. Real recovery results require a booted VM or confirmed hardware and
a supported state source under `docs/GIVN-VERIFICATION.md`; no binding name is
invented here.
