# Use case: observe-fleet-health

Status: elaborated domain draft 2026-10-17; not an implementation, selected
monitoring product or observed alert.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Monitoring for the Owner/operator (collects signals and delivers
  alerts); Host, Storage and Edge (sources of the observed signals).

## Goal
The Owner/operator knows when a host, storage pool or edge path is unhealthy,
so each declared health-threshold breach produces a delivered alert and an
undelivered alert is visible as a failure.

## Trigger
The Monitoring system observes a declared health signal, or a declared
health threshold is exceeded.

## Preconditions
- The fleet's host, pool and edge roles are declared.
- Health signals and their thresholds are declared for each role.
- An alert channel and recipient are declared.
- The monitoring system is reachable and authorized to observe the declared
  signals.
- The observed host, pool or edge path is not being changed by this use case;
  observation is read-only.
- The declaration of signals, thresholds and alert channel is a separate
  monitoring setup subfunction, not part of this observing flow; it does not
  mutate fleet state during observation.

## Main flow
1. System observes the declared host, pool and edge signals; Monitoring
   collects the health status.
2. System compares each signal with its threshold; a breach produces an alert.
3. Monitoring delivers the alert to the declared recipient; System records the
   delivery.
4. Actor Owner/operator reads the health status and the alert; the value is
   the owner's knowledge of the breach, not a repair.

## Extensions
- 1: A source does not report its signal or the monitoring system cannot reach
  it → report the signal as unknown, not healthy; protects truthful health.
- 1: The monitoring system itself is unavailable → report the observation gap;
  do not claim fleet health.
- 2: A threshold is exceeded but no alert is created → report the alerting
  failure; protects the health guarantee.
- 3: Alert delivery fails, is refused or is unverified → record the
  undelivered alert; do not claim the owner was informed.
- 3: The alert is delivered to a channel the owner no longer monitors → report
  the channel as unverified; delivery to an address is not proof of receipt by
  a person.
- 4: The owner does not act on the alert → outside this use case; observation
  does not diagnose or repair.

## Rules
- Observation is read-only: no host, pool, route, generation or application
  state is changed by this use case.
- A green job, a successful scrape or a reachable endpoint is not health; a
  threshold breach and its delivery are the result.
- An unknown signal is unknown, not healthy.
- An undelivered alert is a failure of the health guarantee, not a silent
  success.
- The use case does not diagnose the cause, repair the fault, recover a host
  or restore a service.
- Monitoring is not a backup; a health signal is not a recovery point.
- The selected monitoring product and alert channel are implementation choices,
  not part of the goal.

## Examples
- A `pronix` filesystem crosses 95% usage. Monitoring raises an alert and
  delivers it to the owner's declared channel; the owner sees the breach.
- `tinix001` stops reporting. Monitoring marks its signals unknown and raises
  an alert; the absence is not reported as healthy.
- The edge tunnel is down. Monitoring raises an edge-path alert and the owner
  receives it.
- An alert is raised but delivery fails. The monitoring status records the
  undelivered alert; the owner is not claimed to have been informed.
- A scrape succeeds and returns no error, but the declared disk threshold is
  exceeded. The scrape success is not health; the threshold breach is.

## Minimal guarantee
Failure is reported without claiming health, without treating an unknown
signal as healthy, and without changing fleet state.

## Success guarantee
Each declared health-threshold breach produces a delivered alert, and an
undelivered alert is visible as a failure.

## Personas
- Owner/operator (`owner--operator`): advisory critique — a delivered alert is
  the result; a green dashboard or a successful scrape is not proof that the
  owner knows.
- Application user (`family--application-user`): advisory critique — the user
  has no monitoring duty; they experience the fault and the owner's response,
  not the alerting mechanism.

## Capabilities
- none — actual owned capabilities and native verification targets are
  selected through the normal proposal/spec flow, not fabricated in ideation.

## Interactions
- none — no monitoring, scrape or alert API is selected.

## Includes
- none — signal declaration, collection, thresholding and delivery are
  subfunctions of the one observing guarantee.

## Extends
- none.

## Out of scope
- Diagnosing or repairing a fault — `recover-host`,
  `restore-storage-redundancy`, `reach-service-from-internet` and
  `apply-fleet-update` own their respective changes.
- Application availability, access or recovery — `infrastructure-growth`.
- A service-level objective, commercial uptime commitment or response-time
  promise.
- Backup verification or restore drills — a separate recovery concern.
- Personal-device health — outside this topic.

## Diagram
See [Canvas 4 — keep current, recover and observe](../eventstorming.md#canvas-4--keep-current-recover-and-observe).
The observation slice is the enabling responsibility; this is not an observed
alert.

## Scenario skeletons
- Given a declared disk threshold on `pronix`, When the filesystem crosses the threshold, Then Monitoring raises an alert and delivers it to the owner's declared channel.
- Given a host that stops reporting, When Monitoring checks its signal, Then the signal is unknown, not healthy, and an alert is raised.
- Given an alert whose delivery fails, When the health status is checked, Then the undelivered alert is visible as a failure.
- Given a successful scrape with no error but a crossed threshold, When health is assessed, Then the threshold breach is the result, not the scrape success.
- Given an edge tunnel outage, When Monitoring observes it, Then an edge-path alert is delivered and the owner knows the path is unhealthy.

These are Markdown contract skeletons, not `.feature` deltas or asserted test
coverage. Real alert delivery requires a booted VM or confirmed hardware and
an actually monitored channel under `docs/GIVN-VERIFICATION.md`; no binding
name is invented here.
