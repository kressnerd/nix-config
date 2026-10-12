# Use case: recover-hosted-applications

Status: elaborated domain draft; no restore performed or product/replacement selected.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Intended application users participating in restored-use checks.

## Goal
The Owner/operator restores usable hosted applications after a hosting-server failure under their accepted recovery conditions.

## Trigger
The Owner/operator starts recovery for applications made unavailable by a hosting-server failure.

## Preconditions
- The Owner/operator is authorized to recover the affected applications and prepare the intended replacement.
- The affected applications, intended current access requirements and accepted recovery conditions are identified.
- Supported reconstruction/capture/restore procedures are available for the selected applications; photo-specific qualification remains an operating input (open: Q17).
- Approved recovery-copy/bootstrap inputs may be supplied; their actual usability/availability is checked by the flow, not assumed from a path or job status.

## Main flow
1. Actor Owner/operator assesses the failed environment and affected scope; System records the failure reference, intended application/access requirements and candidate recovery evidence.
2. Actor Owner/operator selects a suitable permitted recovery point; System reports its captured state/time, usable coherent content, bootstrap availability and compliance with the accepted recovery conditions.
3. Actor Owner/operator approves replacement preparation; System re-establishes the intended hosting requirements and prerequisites needed for supported recovery.
4. Actor Owner/operator requests restoration of the selected point; System restores the required coherent application state through its supported procedure rather than claiming success from copied paths alone.
5. Actor Owner/operator checks recovered data and permitted use; System distinguishes verified recovery from missing state, failed startup, unsupported restore or unexpected access.
6. Actor Owner/operator authorizes return of intended access after successful checks; System re-establishes the application's current intended paths and reports the recovered state honestly.

## Extensions
- 1: Failure timing/scope cannot be established sufficiently for the data-loss assessment → report the uncertainty and do not claim precise compliance; protects truthful recovery-point expectations.
- 2a: No usable copy or independent bootstrap material survives → report recovery as blocked/incomplete without inventing state; protects the success guarantee.
- 2b: The usable point misses the declared target → disclose the miss and preserve the candidate; do not report the original recovery guarantee met. An owner-selected best-effort point requires explicit acceptance of its limitations; protects informed recovery rather than a silent target reduction.
- 3: Replacement preparation or required inputs fail → report the unmet prerequisite without asserting app readiness; protects completion and authorized scope.
- 4: Restoration is incomplete/unreadable/incompatible → report failure and do not reopen intended external access on that basis; protects usable coherent recovery (open: Q17 where the procedure is not selected).
- 5: Data/use or access checks fail, including stale sharing metadata conflicting with current intended rights → keep intended external access closed while the supported condition is unresolved; protects permitted recovered use without custom automatic grant reconciliation.
- 6: Returning the route would expose a VPN-only application or unrelated administration → reject the unintended scope; protects current application-specific reachability.

## Rules
- Reconstruct configuration and recover required state/bootstrap from valid permitted inputs; configuration declarations alone do not recreate unavailable data or private keys.
- Recovery includes the selected application's necessary coherent state, not just original media files or an empty directory.
- For the photo example, the delegated target is a usable capture point no earlier than 24 hours before the failure reference. A later restore completion does not make that point older relative to the failure.
- Recovery speed remains low priority for family infrastructure; no strict completion deadline or automatic failover is promised.
- Old permission/sharing metadata may be restored under the photo loss window. The owner checks current intended access through the application's supported controls before reopening; no automatic reconstruction of lost changes is invented.
- A verified restored app is reopened only through its current intended internet or family-VPN-only path. Native resource authorization remains app-owned.
- A best-effort older point may be useful, but it is not falsely described as meeting an unmet original target or containing later lost uploads/edits.

## Examples
Illustrative values explain known outcomes and do not claim real recovery.

- The photo server/storage fails at 18:00 on 11 October. Its usable point was captured at 02:00 on 11 October. Restoring it on 13 October still meets the 24-hour recovery-point condition relative to the failure: the lost-state window is sixteen hours, not the elapsed time to complete restoration.
- A job finished shortly before failure but its state was captured twenty-six hours before failure. The original photo target is missed; the recent job finish does not change that fact.
- Photo originals are restored, but required metadata is missing and the selected app cannot present the expected album. Recovery is incomplete, not accepted merely because files exist.
- An older point contains a sharing grant changed after capture. The owner must verify current intended application access through supported controls before making its guest path available again; no custom grant engine is built.

## Minimal guarantee
Recovery limitations/failures are reported without inventing lost state, falsely claiming target compliance, discarding surviving recovery evidence, or granting unrequested application/infrastructure access.

## Success guarantee
Intended users can use the recovered applications at verified state satisfying the accepted recovery conditions.

## Personas
- Owner/operator (`owner--operator`): advisory critique — distinguish copy/restore/check completion, measure the data point against failure, and preserve usable candidates when a step fails.
- Application user (`family--application-user`, generalized): advisory critique — actual backed-up content and correct granted use matter; recent state absent from the selected point must not be presented as recovered.

## Capabilities
- none — native recovery capabilities/targets follow proposal/spec, not invented here.

## Interactions
- none — no application-specific restore command, provider or credential scheme selected.

## Includes
- none — protection supplies prerequisite evidence but is not a leaf-to-leaf include or a promise that a new copy is created after loss.

## Extends
- none.

## Out of scope
- Refreshing/protecting application state as a separate goal — `preserve-recoverable-application-state`.
- Initial application setup as a separate goal — `make-application-available`.
- Changing intended reachability as a new administrative outcome — `adjust-application-reachability`; recovery reuses the current requirement.
- Reproducing the personal working environment — `reproduce-working-environment`; it has no inherited photo loss target.
- Building application sharing/data/authorization functions or automatic lost-grant reconciliation — external selected-application behavior.

## Diagram
See the rendered [failed-application recovery canvas](../eventstorming.md#canvas-recover-a-failed-hosted-application), consuming the assessed-candidate evidence created by the protection slice.

## Scenario skeletons
- Given a failure at 18:00 and a usable coherent photo point captured at 02:00 that day, When supported restoration and data/access checks complete two days later, Then the accepted recovery-point condition is assessed against the failure and intended use returns at that point.
- Given restored files lacking required coherent metadata, When recovered use is checked, Then recovery is not declared complete and intended external access is not reopened on that basis.
- Given an older usable point missing the declared target, When it is considered for recovery, Then the actual limitation is disclosed rather than silently lowering the guarantee.

These are Markdown contract skeletons, not observed restore results or `.feature` bindings. Real original-loss/restore/use behavior needs meaningful native VM/live proof with valid bootstrap inputs; a host evaluation cannot supply that evidence by itself.
