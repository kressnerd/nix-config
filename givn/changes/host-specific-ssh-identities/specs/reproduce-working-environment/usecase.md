# Use case: reproduce-working-environment

## Level
!

## Actors
- Device owner
- Supporting: Operators/providers of approved state or identity sources

## Goal
The Device owner reproduces a usable usual working environment on the selected personal device.

## Trigger
The Device owner requests reproduction of the specified usual working environment on a chosen laptop/workstation.

## Preconditions
- The Device owner is authorized to configure the target and handle the requested working state/identities.
- The intended tools/settings and required working files/application state/identity access are specified for that device; exact approved items, sources and state/version requirements must be supplied before implementation (open: Q16).
- Permitted definition/bootstrap inputs can be supplied without assuming the target's completed usual environment already exists.
- The required handling has supported semantics for the selected platform/application state; identical installations or exported hardware-bound credentials are not assumed.

## Main flow
1. Actor Device owner submits the intended environment and required approved state/source references; System identifies the device-specific configuration, needed working state and permitted identity/bootstrap prerequisites.
2. Actor Device owner supplies authorized bootstrap inputs or performs the supported re-establishment steps; System establishes needed source/identity access without broadening rights or exposing raw secret material.
3. Actor Device owner authorizes assembly of the intended context; System applies the selected configuration and supported retrieval/restoration/retention of required state in the order its dependencies require, preserving already available working data unless a particular replacement is explicitly authorized.
4. Actor Device owner attempts the defined usual work; System checks the intended tools/settings, usable required files/application state and permitted identity access rather than merely checking installation or populated directories.
5. Actor Device owner obtains the outcome; System reports work readiness only when the accepted complete context is usable and otherwise reports the unmet requirement.

## Extensions
- 1: Required state/source/version scope is incomplete or unauthorized → report the missing approved input and do not substitute a configuration-only goal; protects accepted full readiness (open: Q16).
- 2a: Independent bootstrap material is missing, unreadable or denied → report not ready; protects authorized access without pretending a credential path regenerates its secret.
- 2b: The selected identity cannot be exported but supports permitted re-establishment → use that supported owner/provider step without cloning it blindly; protects authorized usable identity access rather than byte-identical credentials.
- 3a: Source state is missing, wrong-version, unreadable or incompatible with supported handling → preserve usable existing state and report the failed requirement; protects usable required state.
- 3b: Applying incoming state would silently discard existing required work → stop that replacement unless specifically authorized; protects existing working data and does not invent an automatic conflict-resolution product.
- 4: Tools launch but required working data or identity access fails → report not ready rather than accepting installation as the result; protects the success guarantee.
- 5: A selected application needs private connectivity → treat its supported connection configuration/access as that application's requirement; protects the user's usual task without making VPN a universal base-device goal.

## Rules
- The user's selected guarantee includes required personal working state; software/settings-only completion is rejected.
- Approved source references and local persistence do not establish that actual required data or keys survive a loss. The required state must be available and usable from the selected permitted input.
- State may be correctly present, retrieved from an authoritative source, restored from a suitable copy, or supported identity access re-established. No particular source or backup product is selected.
- Declarative configuration cannot recreate unavailable uncommitted work, application state, or a lost private credential by referring to a path.
- Preserve owner-authorized scope; no arbitrary home-directory/credential cloning, extra resource rights, or employer/client-data authority follows from a profile reference.
- Device/platform differences may be intentional; reproducing the selected usual context is not forcing Linux/macOS to be identical.
- VPN is application-specific, not a universal base-environment condition. A selected application's connection needs may still cause its supported software/configuration to be present.
- No personal-data loss window, retention duration or recovery completion deadline is imported from the photo application's delegated 24-hour target.
- Check actual usable work context; a successful evaluation, launcher, directory creation or green transfer job is not alone work readiness.

## Examples
- The required context includes a configured editor/shell, a project workspace containing `work-in-progress.txt` with the approved `draft B` content, and permitted access to its intended development resource. The owner can open/use that work and authenticate through the approved identity after reproduction; only then is the requested context ready.
- The editor launches with the right settings, but the source did not supply the required uncommitted working file. The result is not ready even if a clean repository checkout exists.
- A source declaration refers to an age-key file, but no permitted bootstrap material makes it usable. The workflow cannot reconstruct the private credential from that reference and reports the missing input.
- A platform-bound identity is re-established through its supported owner/provider procedure rather than exported blindly. The required authorized resource becomes usable without a new permission grant.
- The selected usual context has no application requiring the family private path. Reproducing it does not impose VPN enrollment. A different selected application's private-path requirement is handled as that application's need.

## Minimal guarantee
An incomplete context is not reported as work-ready; existing required working data is not silently discarded, and unauthorized data/credential handling or extra identity/resource rights are not granted by the reproduction request.

## Success guarantee
The Device owner can resume the specified usual work on the selected device with its required context available and usable.

## Personas
- owner--operator

## Capabilities
- permitted-identity-selection

## Interactions

| Capability | Consumer action | E2E scenario |
|---|---|---|
| permitted-identity-selection | a device opens a connection to a private repository | A booted device reaches private repositories with the identity it declares |

## Includes
- none

## Extends
- none

## Out of scope
- Reconfiguring family applications' infrastructure reachability as a separate goal — `adjust-application-reachability`.
- Recovering hosted applications after server failure — `recover-hosted-applications`.
- Setting an additional personal-data failure/loss-window protection commitment — not yet selected; this contract does not silently promise a new universal backup guarantee.
- Granting new account/data authority, copying every credential, or migrating unrelated working contexts — not authorized by this goal.

## Diagram
See the rendered usual-work reproduction canvas, permitted identity/source
access canvas, and required state availability canvas in the
infrastructure-growth event storming
(`givn/ideation/infrastructure-growth/eventstorming.md`). These show source
inputs and failure outcomes, not actual personal-data retrieval.

