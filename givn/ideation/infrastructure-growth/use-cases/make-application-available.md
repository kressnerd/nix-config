# Use case: make-application-available

Status: elaborated domain draft; not a selected product, implemented capability or observed deployment.

## Level
!

## Actors
- Primary: Owner/operator.

## Goal
The Owner/operator makes a self-hosted application available to its intended users under its agreed hosting requirements.

## Trigger
The Owner/operator requests setup of a selected application with its intended users, access paths and recovery requirements.

## Preconditions
- The Owner/operator is authorized to configure the intended hosting environment.
- The application supports the needed native user functions and permitted access flow; product-specific qualification/capture/restore details must be supplied before implementation (open: Q17).
- Hosting requirements identify the application, intended users/paths, necessary persistent application state, and recovery conditions.
- Required permitted operating/bootstrap inputs can be supplied independently of an already completed application setup.

## Main flow
1. Actor Owner/operator submits the agreed setup requirements; System identifies the intended operation, access, persistent-state and recovery obligations without rebuilding common access arrangements for each application.
2. Actor Owner/operator supplies permitted operating/bootstrap inputs; System establishes the inputs needed for the supported application setup without exposing raw secret material or granting extra rights.
3. Actor Owner/operator approves the intended setup; System establishes the selected application's operation, persistent application state and declared access paths.
4. Actor Owner/operator requests evidence of required data protection; System establishes and assesses a supported coherent recovery copy that survives the original server/storage failure boundary, rather than treating a configured job as a created copy.
5. Actor Owner/operator checks intended use; System reports the application available only when its supported user flow and required hosting/recovery conditions are satisfied.

## Extensions
- 1: The selected application's supported behavior or recovery procedure does not satisfy a requirement → identify the mismatch and do not claim availability; protects the agreed hosting/readiness guarantee (open: Q17).
- 2: An operating/bootstrap input is missing or unauthorized → report the unmet prerequisite without inventing credentials; protects permitted access and truthful completion.
- 3: Configuration or access-path establishment fails → report incomplete setup and do not represent the application as ready; protects the success guarantee.
- 4: No usable surviving consistent recovery copy exists, or the protection target is missed → report protection as unmet rather than silently finishing a config-only setup; protects the recovery-readiness condition.
- 5: The intended user flow cannot be completed through the declared path → report the failed check and retain the declared boundary; protects usable availability and does not authorize a blanket access bypass.

## Rules
- The result is one complete application-readiness outcome; access, persistent state and recovery provisions are necessary conditions of that outcome.
- Common infrastructure arrangements are reused; application-specific paths/state and its supported native behavior remain explicit.
- The application supplies photo/document/calendar functionality and resource authorization; this repository does not build them.
- Internet reachability does not make all resources public. A family-VPN-only application is not made internet-reachable as a side effect of adding another application.
- The photo guest flow admits the application's selected outside recipients without general family-application access or private-network enrollment.
- Backup configuration, same-server persistence, and a green copy-job status do not alone establish a usable independent recovery copy.
- The photo example uses the delegated 24-hour recovery-point target. No universal target, retention policy, automatic failover, new support product or copied credential privilege follows.

## Examples
Illustrative values explain known requirements; they are not actual applications, registered addresses or selected route formats.

- A qualified photo application contains an album named `Family holiday 2026`. Its native guest link is usable over ordinary internet access by an invited recipient; that recipient is not asked to join the private network or obtain general family-application access. The supported recovery state is coherently captured outside the original failure boundary and meets the photo target before setup is declared ready.
- An application designated `Family-VPN-only` becomes usable through its permitted private path, while adding the internet-reachable photo application does not publish that private application.
- An application starts successfully, but its first recovery operation produced no usable copy. Setup is reported incomplete; service start-up is not the complete hosting result.

## Minimal guarantee
Failure is reported without claiming complete availability/protection, granting unrequested access, or silently discarding existing required application data or surviving recovery evidence.

## Success guarantee
The selected application is usable by its intended users under its agreed complete hosting requirements.

## Personas
- Owner/operator (`owner--operator`): advisory critique — a running process or configured backup flag is not complete setup; state and supported recovery evidence must exist.
- Application user (`family--application-user`, generalized stable segment): advisory critique — the intended native flow must work through the allowed path without broader access requirements or infrastructure administration.

## Capabilities
- none — actual owned capabilities and native verification targets are selected through the normal proposal/spec flow, not fabricated in ideation.

## Interactions
- none — no product-specific API or command binding selected.

## Includes
- none — shared setup/protection subfunctions do not assert a leaf-to-leaf relationship.

## Extends
- none.

## Out of scope
- Changing an already available application's intended paths as a new goal — `adjust-application-reachability`.
- Restoring applications after a failure as a new goal — `recover-hosted-applications`.
- Implementing the hosted app's sharing, editing, calendar or authorization behavior — owned by the selected external application.
- Reproducing the owner's personal work environment — `reproduce-working-environment`.

## Diagram
See the rendered [setup/recovery-copy canvas](../eventstorming.md#canvas-establish-setup-and-create-recovery-copies) and [application-reachability canvas](../eventstorming.md#canvas-establish-application-reachability). Those canvases show the enabling responsibilities, not actual deployment evidence.

## Scenario skeletons
- Given a qualified application and agreed hosting requirements, When the Owner/operator requests setup and required inputs are supplied, Then intended users can use the native flow under the declared paths and complete hosting/recovery requirements.
- Given an application that starts but lacks a usable required recovery copy, When setup readiness is checked, Then setup is not declared complete and the protection gap is reported.
- Given an existing VPN-only application, When a different application is made internet-reachable, Then the existing application's intended private boundary remains effective.

These are Markdown contract skeletons, not `.feature` deltas or asserted test coverage. Real setup/access/state results require meaningful native VM/live targets under `docs/GIVN-VERIFICATION.md`; no binding name is invented here.
