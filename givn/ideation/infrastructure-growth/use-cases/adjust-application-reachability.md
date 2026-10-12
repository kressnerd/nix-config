# Use case: adjust-application-reachability

Status: elaborated domain draft; no firewall, topology or VPN product selected.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Affected application users participating in access checks.

## Goal
The Owner/operator changes an existing application's permitted access paths to match its intended users.

## Trigger
The Owner/operator requests a specified reachability change for an existing application.

## Preconditions
- The Owner/operator is authorized to change the application's infrastructure access paths.
- The application and requested intended path/audience are identified before the change request.
- The application supports its required native user/authorization flow; product-specific guest-flow qualification remains an operating prerequisite where applicable (open: Q17).
- Existing application/resource grants and unrelated applications' intended paths are known sufficiently to check the requested change without inventing new grants.

## Main flow
1. Actor Owner/operator submits the intended change; System identifies the application's single declared reachability requirement and the scope affected.
2. Actor Owner/operator approves that scope; System establishes the requested paths and removes paths no longer permitted for the application without changing its resource grants.
3. Actor Owner/operator checks representative permitted and unpermitted access; System distinguishes infrastructure reachability from the application's own authorization response.
4. Actor Owner/operator accepts the result; System reports the changed requirement effective only when the intended path is usable and unrequested paths are not admitted.

## Extensions
- 1: A requested path would contradict the application's supported native flow → report the incompatible requirement and do not claim completion; protects intended usable access rather than just endpoint exposure (open: Q17).
- 2: Establishing/removing an access path fails → report the effective incomplete state without silently treating the requested policy as applied; protects truthful reachability.
- 3a: An unpermitted path is still admitted → report failure and do not declare the boundary effective; protects restricted reachability.
- 3b: The path admits the request but the application denies a resource grant → distinguish that application-owned authorization result from route failure; protects the separation of reachability and resource rights.
- 4: An unrelated application's intended path changed as a side effect → report the unintended change instead of declaring the requested scope complete; protects bounded mutation.

## Rules
- Reachability is selected per application, not per persona or globally for every device.
- An internet-reachable application may keep all resources permission-controlled; endpoint access is not public data publication.
- A family-VPN-only application must not be admitted on ordinary internet paths solely because another application is public.
- Photo invitees must use the selected application's native guest flow over ordinary internet without obtaining general family-application/private-network access.
- VPN software/configuration is an application/network requirement when needed, not a universal personal-device readiness condition.
- A reachability change does not create, revoke, or broaden the native application's resource grants.
- No specific addresses, ports, topology, authentication exemptions, connection product or universal default is selected by this contract.

## Examples
Illustrative values do not select actual deployments or native endpoint formats.

- `photos.example.test` is designated internet-reachable for the qualified photo application's native sharing flow. A valid invited viewer can reach that flow through an ordinary connection; an ungranted request does not thereby receive the protected album.
- An illustrative `Private family app` is designated family-VPN-only. A permitted family connection can reach it; an ordinary internet connection cannot, even while the photo application's public path remains available.
- The operator changes one application's intended path. A different private application's path becomes public accidentally; that result is not accepted as a successful bounded change.

## Minimal guarantee
An incomplete or overbroad path change is not reported as successful, and no new application/resource or unrelated infrastructure access is granted by the reachability request.

## Success guarantee
The identified application is reachable through its requested paths and not through unrequested paths.

## Personas
- Owner/operator (`owner--operator`): advisory critique — the effective admitted paths, not only a declared option, must match the requested change.
- Application user (`family--application-user`, generalized): advisory critique — a guest must not be forced into general family/private-network access for the photo flow, while a reachable endpoint must not imply wider resource rights.

## Capabilities
- none — owned capability and native proof bindings are selected during proposal/spec, not invented here.

## Interactions
- none — no product-specific ingress/connection API selected.

## Includes
- none.

## Extends
- none — setup/recovery can consume this rule as a subfunction without asserting reuse of an independent reachability-change goal.

## Out of scope
- Initial complete application setup — `make-application-available`.
- Restoring applications after failure — `recover-hosted-applications`.
- Editing content or creating native application sharing grants — the selected external application's goals.
- Reproducing the owner's usual working environment — `reproduce-working-environment`; VPN remains a selected application requirement, not its defining goal.

## Diagram
See [establish application reachability](../eventstorming.md#canvas-establish-application-reachability) and [use the permitted path](../eventstorming.md#canvas-use-an-application-through-its-permitted-path), both rendered in the topic record.

## Scenario skeletons
- Given an existing application and a requested private-only path, When the Owner/operator applies and checks the change, Then the permitted private connection reaches it and ordinary internet paths do not.
- Given an internet-reachable qualified photo app and a valid native guest grant, When its guest path is checked through an ordinary connection, Then the supported flow is reachable without broader family access.
- Given a requested change for one application, When another application's boundary changes unintentionally, Then the requested change is not reported complete.

These are contract skeletons, not `.feature` deltas or executed network evidence. Future proof must exercise real admission/denial and native flows through resolving VM/live targets; evaluation of declared fields alone is insufficient.
