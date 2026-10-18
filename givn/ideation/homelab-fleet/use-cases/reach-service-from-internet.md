# Use case: reach-service-from-internet

Status: elaborated domain draft 2026-10-17; not an implementation, selected
proxy or observed route.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Application user (opens the selected service through the
  published path); Network and public entry for the Owner/operator (carry the
  transport and admit the selected request).

## Goal
The Owner/operator makes a selected home service reachable from the internet,
so the service answers on its selected public path and unrequested paths remain
blocked.

## Trigger
The Owner/operator requests publication of one selected home service at the
public entry.

## Preconditions
- The selected service runs on a declared host and its backend address and
  port are declared.
- The service's reachability policy is supplied: internet-accessible or
  family-VPN-only. This use case honors the policy; it does not choose it.
- A public domain, DNS control and the public entry are available.
- The public entry and the home-side transport endpoints are declared.
- The selected service's intended admission boundary is supplied: native
  application authentication, public-entry forward-authentication, or a
  documented selected bypass for a native share/API flow.
- No blanket public-entry authentication bypass or administrative exposure is
  authorized.
- The selected service is not already published on an unrequested path.

## Main flow
1. Actor Owner/operator declares the public route for one selected service;
   System records the public name, backend, admission boundary and intended
   reachability policy.
2. Actor Owner/operator establishes the transport between the public entry and
   the home-side service; System connects the entry to the declared backend.
3. Actor Owner/operator publishes the route; System admits requests for the
   declared public name, terminates the public transport at the entry, and
   forwards to the declared backend.
4. Actor Application user opens the selected service through its public path;
   System admits the permitted request and the service answers.
5. Actor Owner/operator checks an unrequested path on the same entry; System
   blocks it and reports the connectivity result.
6. Actor Owner/operator checks the selected service's declared admission
   boundary; System confirms that the boundary is in effect for the selected
   path.

## Extensions
- 1: The route declaration lacks a selected service, backend or admission
  boundary → do not publish; protects the admission guarantee.
- 1: The declared policy is family-VPN-only → do not publish an internet
  route; protects the selected private boundary.
- 2: The transport cannot be established or does not become healthy → do not
  publish the route; report the transport failure.
- 3: Route publication fails, the public transport identity is invalid, or the
  public entry cannot reach the backend → report the failure; do not claim
  reachability.
- 4: A permitted request does not reach the backend or the backend does not
  answer → report a transport failure; this is not proof of application
  availability.
- 5: An unrequested path is reachable → withdraw or repair the route; protects
  the "unrequested paths remain blocked" guarantee.
- 6: The declared admission boundary is not in effect, or a native share/API
  bypass is broader than declared → withdraw or repair the route; protects the
  access boundary.
- 6: The selected service's native auth flow cannot work through the declared
  boundary → report the mismatch; do not silently bypass authentication.
- Any: The Owner/operator withdraws the route → the service stops being
  reachable on that path; this is the expected withdrawal outcome, not a
  failure.

## Rules
- A published route admits transport; it does not grant an application
  resource or make the application available.
- Only selected services are admitted. No wildcard route, blanket
  forward-auth bypass or administrative interface is published by this use
  case.
- Reachability is per selected service. A family-VPN-only service is not made
  internet-reachable as a side effect of publishing another service.
- The selected service's native authorization remains in force; the edge
  boundary must not grant broader access than the service's declared policy.
- The edge tunnel is the transport for the selected backends. It does not
  replace the private-network control plane, and it does not make the home
  network generally reachable.
- DERP, the mail MTA or any other service is published only when it is the
  selected service; no incidental exposure follows.
- A reachable endpoint, a valid certificate or a green proxy status is not
  proof that the application is available or usable.
- P6 (Headscale end-to-end encryption through TLS) and P8 (Seafile share URL
  pattern) are checks, not facts; an unknown result blocks the affected
  admission claim.

## Examples
- The Owner/operator publishes `hs.example.com` to the private-network control
  service on `tinix001` over the edge tunnel. A client reaches it and the
  WebSocket path works; the public route does not expose the storage VLAN.
- The Owner/operator publishes `photos.example.com` to the photo application's
  native authentication. The edge does not add forward-authentication; the
  application still decides which albums a recipient may view.
- The Owner/operator publishes `paperless.example.com` behind
  forward-authentication. An unauthenticated request is rejected, not
  forwarded.
- A service whose declared policy is family-VPN-only is not published; a
  request from the ordinary internet does not reach it.
- A route is published and the backend answers, but a request for an
  administrative path is also admitted. The route is withdrawn or repaired;
  the admission guarantee is not claimed.

## Minimal guarantee
Failure is reported without publishing an unrequested service, without
granting a resource or broader access, and without claiming application
availability from transport alone.

## Success guarantee
The selected service answers on its declared public path through the
established public transport, and unrequested paths remain blocked.

## Personas
- Owner/operator (`owner--operator`): advisory critique — a public route is a
  transport boundary, not an application grant; the unrequested path and
  admission boundary are part of the result.
- Application user (`family--application-user`): advisory critique — the user
  reaches the selected service only within its grant; no general family
  network or other application access is implied by a public endpoint.

## Capabilities
- none — actual owned capabilities and native verification targets are
  selected through the normal proposal/spec flow, not fabricated in ideation.

## Interactions
- none — no proxy, DNS, tunnel or certificate API is selected.

## Includes
- none — tunnel establishment and certificate handling are subfunctions of
  the one reachability guarantee.

## Extends
- none.

## Out of scope
- Choosing an application's internet-versus-VPN reachability policy —
  `infrastructure-growth` (`adjust-application-reachability`).
- Making the application available or restoring its state —
  `infrastructure-growth`.
- Application resource grants, native sharing/authorization behavior or
  administrative functions — the hosted application.
- Mail delivery, DNS answers, Headscale control-plane behavior or Authentik
  login — external service behavior.
- Provisioning the host — `provision-host`.
- Booting the host — `boot-host-unattended`.
- Applying a fleet update — `apply-fleet-update`.
- Recovering a host — `recover-host`.
- Observing health — `observe-fleet-health`.

## Diagram
See [Canvas 3 — expose a selected service through the edge](../eventstorming.md#canvas-3--expose-a-selected-service-through-the-edge).
The canvas shows the enabling responsibilities, not a live route.

## Scenario skeletons
- Given a selected service with a declared backend and admission boundary, When the Owner/operator establishes the tunnel and publishes the route, Then the service answers on its public path and an unrequested path is blocked.
- Given a service whose declared policy is family-VPN-only, When publication is requested, Then the internet route is not published and the private boundary is retained.
- Given a published route behind forward-authentication, When an unauthenticated request arrives, Then the edge rejects it rather than forwarding it.
- Given a published route whose backend does not answer, When reachability is checked, Then a transport failure is reported and application availability is not claimed.
- Given a published route that admits an administrative path, When the admission boundary is checked, Then the route is withdrawn or repaired and the guarantee is not claimed.

These are Markdown contract skeletons, not `.feature` deltas or asserted test
coverage. Real reachability and admission results require a booted VM or
confirmed hardware under `docs/GIVN-VERIFICATION.md`; no binding name is
invented here.
