# Use case: apply-fleet-update

Status: elaborated domain draft 2026-10-17; not an implementation, selected
update tool or observed update.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Host for the Owner/operator (applies the update and reports
  whether a reboot is required).

## Goal
The Owner/operator applies a fleet update within its declared window, so the
fleet runs the intended software update and the declared services return within
the host's window.

## Trigger
The declared update window opens for a host.

## Preconditions
- An update window and host order are declared.
- The intended update is available from the approved source.
- The host is accepted and reachable.
- The host's declared service roles are known.
- The Tang host (`tinix001`) is running when `pronix` reboots; the declared
  windows preserve that order.
- A supported previous state or rollback path exists for a failed update.
- Application-state backup is not assumed; this use case does not create one.

## Main flow
1. Actor Owner/operator applies the intended update to the selected host;
   System applies the update and reports the result.
2. System reports whether the host requires a reboot for the update to take
   effect.
3. Actor Owner/operator reboots the host inside the declared window; System
   performs the reboot and brings the host back.
4. Actor Owner/operator checks the declared services; System reports the
   update result and whether the services returned.

## Extensions
- 1: The update fails to apply or the build is unusable → report the failure;
  do not claim the host is updated.
- 2: A reboot is required but the window has closed → defer the reboot; the
  update is not complete.
- 3: The host fails to boot or unlock after the update → the boot guarantee
  failed; use the supported fallback and report the update as incomplete.
- 3: The host returns with a previous supported state or an unsupported state
  → report the rollback; do not claim the intended update.
- 4: A declared service does not return within the window → report the service
  failure and use the supported previous state if available; the update
  guarantee is not met.
- 4: `pronix` reboots while the Tang host is unavailable → the automatic
  unlock fails; the update is not complete until the boot guarantee is met.
- 4: The update succeeds but an application's own state is missing → host
  update success is reported; application recovery remains external and is
  not claimed.

## Rules
- A green build or a successful activation is not a returned service.
- Reboots happen only inside the declared window; an update that requires a
  reboot outside the window is deferred.
- The declared order keeps `tinix001` (Tang) running while `pronix` reboots.
  `cupix001`'s window is separate.
- The update changes host software; it does not create a backup, restore
  application data or migrate application state.
- A rollback restores service but does not satisfy the intended-update
  guarantee; the result reports both facts.
- A host that returns with an unsupported or unknown generation is not
  reported as updated.
- The update window is not a recovery deadline or a data-loss window.

## Examples
- `pronix` applies a kernel update at 04:00 while `tinix001` is running Tang.
  It reboots inside its 04:00–04:45 window and its storage roles return.
- `tinix001` applies an update at 05:00, reboots, and its applications return;
  the Tang service is available again before any later `pronix` reboot.
- `cupix001` applies an edge update at 03:00; the tunnel and selected routes
  return inside its 03:00–03:30 window.
- An update is applied but the host needs a reboot after the window closed.
  The reboot is deferred; the host is not reported as fully updated.
- An update returns the host on the previous generation. Service is restored,
  but the intended update is reported as not achieved.

## Minimal guarantee
Failure is reported without claiming the intended update, without rebooting
outside the declared window, and without treating a rollback as a successful
update.

## Success guarantee
The intended software update is in effect within each host's window, with the
declared services available.

## Personas
- Owner/operator (`owner--operator`): advisory critique — the window and the
  returning services are the result; a successful activation alone is not
  enough.
- Application user (`family--application-user`): advisory critique — the user
  experiences the service window and the return; update mechanics and
  generations are not their concern.

## Capabilities
- none — actual owned capabilities and native verification targets are
  selected through the normal proposal/spec flow, not fabricated in ideation.

## Interactions
- none — no update, reboot or rollback command is selected.

## Includes
- none — window declaration, update application, reboot and service check are
  subfunctions of the one update guarantee.

## Extends
- none.

## Out of scope
- Booting the host without a passphrase — `boot-host-unattended`.
- Provisioning the host — `provision-host`.
- Recovering a failed host — `recover-host`.
- Restoring storage redundancy after a device failure —
  `restore-storage-redundancy`.
- Publishing a service at the edge — `reach-service-from-internet`.
- Observing health — `observe-fleet-health`.
- Application-state backup or restore — `infrastructure-growth`.
- Personal-device updates — outside this topic.

## Diagram
See [Canvas 4 — keep current, recover and observe](../eventstorming.md#canvas-4--keep-current-recover-and-observe).
The update slice is the enabling responsibility; this is not an observed
update.

## Scenario skeletons
- Given a declared window and a running Tang host, When `pronix` applies its update and reboots inside the window, Then the storage roles return and the update is reported complete.
- Given an update that requires a reboot after the window closed, When the Owner/operator checks the result, Then the reboot is deferred and the update is not reported complete.
- Given an update that returns the host on the previous generation, When the result is checked, Then service is reported restored but the intended update is not claimed.
- Given `pronix` reboots while the Tang host is unavailable, When the boot result is checked, Then the automatic unlock failure is reported and the update is incomplete.
- Given a service that does not return inside the window, When the result is checked, Then the service failure is reported and the update guarantee is not met.

These are Markdown contract skeletons, not `.feature` deltas or asserted test
coverage. Real update and reboot results require a booted VM or confirmed
hardware under `docs/GIVN-VERIFICATION.md`; no binding name is invented here.
