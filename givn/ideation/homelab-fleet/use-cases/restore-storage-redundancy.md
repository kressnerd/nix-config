# Use case: restore-storage-redundancy

Status: elaborated domain draft 2026-10-17; not an implementation, selected
filesystem or observed failure.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Storage for the Owner/operator (the pool and its devices perform
  the degraded serving and rebuild).

## Goal
The Owner/operator restores storage redundancy after a device failure, so the
pool returns to its declared redundancy while the declared data remains
readable.

## Trigger
A storage device in a declared pool fails.

## Preconditions
- The storage pool is established with its declared devices and redundancy
  level.
- The pool belongs to one host and one declared data class; its devices and
  mount points are declared.
- A replacement device with a compatible capacity and role is available, or
  its absence is an acknowledged blocker.
- The pool's data is declared available for the duration of a single-device
  failure; a two-device failure is outside this guarantee.
- The pool is not claimed as a backup; an independent copy is a separate
  concern.

## Main flow
1. System observes a storage-device failure; the pool reports the failed
   device.
2. System continues serving the declared data from the remaining devices and
   reports the pool as degraded.
3. Actor Owner/operator installs a compatible replacement device; System
   records the replacement in the declared pool.
4. Actor Owner/operator starts the pool rebuild; System rebuilds the declared
   redundancy.
5. Actor Owner/operator checks data availability and pool health; System
   reports redundancy restored only after the rebuild completes and the
   declared data is readable.

## Extensions
- 1: The failure makes the pool unavailable rather than degraded → data
  availability is lost; stop and report. This is outside the single-device
  guarantee and must not be presented as a successful degraded serving.
- 2: A read or write fails although the pool reports degradation → report the
  data-availability failure; do not infer health from the pool state alone.
- 3: The replacement is incompatible, too small or belongs to another pool →
  do not add it; protects the declared layout.
- 4: The rebuild fails or is interrupted → redundancy is not restored; report
  the pool as degraded and retain the available data.
- 5: Data is readable but redundancy is not restored → report availability and
  redundancy separately; do not call the pool healthy.
- 5: A second device fails during the degraded window → the single-device
  guarantee no longer applies; report the loss of availability and do not
  claim recovery.

## Rules
- Degraded is not full redundancy; data availability and redundancy are
  separate claims.
- A pool is not a backup. A same-host snapshot, a local persistence area or a
  provider snapshot does not establish survival of the host or storage loss.
- The declared pool uses mirrored data and metadata; no parity-based layout is
  introduced by this use case.
- `degraded` is not a permanent mount option; it is a reported state during a
  failure.
- The replacement device is part of the declared pool; an undeclared device is
  not added.
- A scrub or rebuild is not a backup and does not prove application
  consistency.
- Application-state recovery remains external (`infrastructure-growth`); this
  use case protects stored data availability, not application consistency.

## Examples
- A media pool has four 1 TB devices in a mirrored layout. One device fails;
  the pool serves the declared media as degraded. The owner installs a
  replacement, the rebuild completes, and redundancy is reported restored.
- An appdata pool has two NVMe devices. One fails; the pool serves the
  declared application data while degraded. A replacement is installed and the
  pool is rebuilt.
- A pool reports "degraded" but a read of a declared file fails. The result is
  a data-availability failure, not a healthy degraded pool.
- A device fails and no compatible replacement is available. The pool remains
  degraded; the owner reports the missing replacement rather than claiming
  restoration.

## Minimal guarantee
Failure is reported without claiming full redundancy, without silently
dropping already available data, and without treating a pool or snapshot as an
independent backup.

## Success guarantee
The pool's declared redundancy is restored, and the declared data remained
readable throughout the failure, replacement and rebuild.

## Personas
- Owner/operator (`owner--operator`): advisory critique — a degraded pool is
  not a healthy pool; a rebuild in progress is not restored redundancy.
- Application user (`family--application-user`): advisory critique — the user
  needs the stored data to remain usable; a pool label or a green scrub is not
  the user's result, and no application-level recovery is claimed.

## Capabilities
- none — actual owned capabilities and native verification targets are
  selected through the normal proposal/spec flow, not fabricated in ideation.

## Interactions
- none — no storage command or device model is selected.

## Includes
- none — pool creation and replacement are subfunctions of the one
  availability guarantee.

## Extends
- none.

## Out of scope
- Backing up or restoring application state — `infrastructure-growth`
  (`preserve-recoverable-application-state`, `recover-hosted-applications`).
- Recovering a failed host — `recover-host`.
- Booting a host — `boot-host-unattended`.
- Publishing a service at the edge — `reach-service-from-internet`.
- Observing health — `observe-fleet-health`.
- A two-device failure or a full pool loss — outside this single-device
  guarantee.

## Diagram
See [Canvas 2 — restore storage redundancy after a device failure](../eventstorming.md#canvas-2--restore-storage-redundancy-after-a-device-failure).
The canvas shows the enabling responsibilities, not a real device failure.

## Scenario skeletons
- Given a redundant pool with declared data, When one storage device fails, Then the declared data remains readable and the pool is reported degraded.
- Given a degraded pool, When a compatible replacement is installed and the rebuild completes, Then redundancy is reported restored and the data is readable.
- Given a degraded pool with a read failure, When availability is checked, Then the result is a data-availability failure, not a healthy degraded pool.
- Given a degraded pool with no compatible replacement, When the owner reports the state, Then the missing replacement is recorded and redundancy is not claimed.
- Given a second device failure during the degraded window, When availability is assessed, Then the single-device guarantee is reported as no longer applicable.

These are Markdown contract skeletons, not `.feature` deltas or asserted test
coverage. Real failure and rebuild results require a booted VM or confirmed
hardware under `docs/GIVN-VERIFICATION.md`; no binding name is invented here.
