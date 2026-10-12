# Use case: access-shared-information

Status: elaborated observing contract; native app information/sharing behavior is not custom functionality to build.

## Level
!

## Actors
- Primary: Application user.
- Supporting: Owner/operator, only where manual family-use guidance is sought.
- Supporting: Hosted application supplying the native authorization/information response.

## Goal
The Application user accesses the information shared with them through a hosted application's supported flow.

## Trigger
The Application user opens the provided application/resource access route to view the shared information.

## Preconditions
- The hosted application supports the intended native information/authorization flow; the photo product and actual flow must be qualified in proposal/design (open: Q17).
- The intended information and native application grant already exist; this observing case does not create them.
- The user has the required native access inputs and can use the declared permitted path. If an application is family-VPN-only, its authorized private connection is an application access prerequisite, not a universal device-setup rule.
- Infrastructure hosting/access requirements identify the intended application without granting broad family or administration access merely from a shared resource.

## Main flow
1. Actor Application user opens the provided route; System admits the request only through the application's intended path and delivers its supported native flow.
2. Actor Application user supplies the native flow's required permitted access inputs; System preserves the application's own authorization decision without requiring unrelated general family-application access.
3. Actor Application user requests the intended shared information; System delivers the native application's permitted response without editing content, changing grants or changing infrastructure configuration.
4. Actor Application user views the result; System presents the intended information only within the application's supplied grant rather than treating endpoint reachability as permission to everything.

## Extensions
- 1: The request cannot arrive through a permitted path → report inability to reach the intended flow without broadening paths; protects the reachability boundary.
- 2a: Native access inputs are invalid, expired or no longer permitted → preserve the application's denial rather than bypassing it or creating a grant; protects resource authorization.
- 2b: A common edge prerequisite would require a photo invitee to obtain general family/private-network access → treat the infrastructure flow as incompatible, not the guest as needing wider authority; protects the accepted ordinary-internet guest requirement.
- 3: The native application cannot supply the intended information → do not claim that it was received; preserve the app's supported failure/result without inventing replacement content.
- 4: A family member needs guidance to use the provided flow → they may seek the Owner/operator's existing manual help and continue the same access goal if guidance resolves the issue; protects usable access without a new support application, response deadline or guaranteed solution.

## Rules
- This case observes already shared information and owns no content, grant, account, policy or infrastructure mutation.
- Native authentication/session internals are external app behavior; the contract does not assert a newly created sharing permission or implement an authorization engine.
- Network reachability and resource authorization are separate. A public endpoint need not expose public data, and a resource grant need not permit other applications/infrastructure.
- Selected outside photo recipients use ordinary internet access without private-network enrollment or general family-application access, subject to the application's own native conditions.
- Different applications may be family-VPN-only. The user's persona is still the general application-user segment, not an internet/VPN persona.
- Album sharing/editing, document editing and calendar management remain native external-application goals; this case's observable integration result is receipt of existing granted information.
- Family help is a manual existing relationship; no outsider support commitment or automatic retry/support product is inferred.

## Examples
Illustrative values do not select a photo product, registered host or native URI/token convention.

- A native grant permits an invited recipient to view album `Family holiday 2026`. The recipient follows its app-generated access route from an ordinary connection and can view the permitted album without a family-wide account or VPN enrollment.
- The same recipient has no grant to another album or application. Reaching the photo endpoint does not make those resources available.
- An illustrative private application is declared family-VPN-only. A request outside its permitted path does not reach its information flow; a user's ability to view an internet-shared album does not admit the private application.
- A family user asks the operator how to use the existing native access flow. Guidance may help them continue; the system promises no new help-desk service or response time.

## Minimal guarantee
Failure does not create new grants, broaden network/infrastructure access, edit information, or falsely represent unavailable/denied information as received.

## Success guarantee
The Application user can view the intended information within the native application's supplied grant through its permitted access path.

## Personas
- Application user (`family--application-user`, generalized stable segment): advisory critique — actual granted information must be usable, not merely a reachable port; outside recipients must not inherit wider family rights or network-enrollment requirements for the photo flow.
- Owner/operator (`owner--operator`): advisory critique — configure compatible native delivery and preserve the external application's authority; do not build missing app features or a new support service.

## Capabilities
- none — future infrastructure-delivery capability ownership and actual native proof targets follow proposal/spec; app data/sharing internals remain external.

## Interactions
- none — no invented native app API/URI/grant binding.

## Includes
- none.

## Extends
- none — manual recovery guidance is an extension of a step within this same goal where applicable, not a separate custom support use case.

## Out of scope
- Creating or changing native sharing grants, editing information, uploading photos or managing calendar data — the selected hosted applications' actor goals.
- Changing the application access policy — `adjust-application-reachability`.
- Deploying/recovering the app — `make-application-available` and `recover-hosted-applications`.
- Reproducing a personal working environment — `reproduce-working-environment`; accessing a private app does not define every device's base setup.
- Granting broader family, source-data or administration authority — not authorized by information sharing.

## Diagram
See the rendered [permitted application-use canvas](../eventstorming.md#canvas-use-an-application-through-its-permitted-path). The [family assistance canvas](../eventstorming.md#canvas-support-family-application-use) is an existing external human interaction, not custom software.

## Scenario skeletons
- Given an existing native photo grant for an invited recipient and the intended ordinary-internet path, When the user follows the native provided access flow, Then they can view the granted information without general family or private-network access.
- Given endpoint reachability but no native grant to another resource, When that resource is requested, Then the application's denial is preserved and no new grant is created.
- Given a VPN-only application and a request outside its permitted path, When the user attempts access, Then the information flow is not admitted through that path.

These are observing contract skeletons, not app-feature implementation or executed access proof. Real native integration must show the intended permitted information/denial through meaningful VM/live targets; a port-open, nonempty-response or fake native-app echo alone is insufficient.
