# Change seed: edge-service-publication

Status: ready

- Use-case IDs: reach-service-from-internet
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 5 after `provision-compute-host` (backend host) and the
  `cupix001` edge foundation; independent of the storage-redundancy seed.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.

## Deliverable guarantee

One selected home service is reachable from the internet through `cupix001`
over the established edge tunnel, answers on its declared public path, and
unrequested paths remain blocked. The selected service's admission boundary is
in effect; an unauthenticated request does not reach a protected backend, and a
family-VPN-only service is not published. The result does not claim application
availability or a resource grant; reachability is transport, not permission.

## Accepted decisions

### One selected service, explicit admission, no blanket bypass

- Context: the handover makes `cupix001` the only public edge and splits mail,
  Headscale, DERP and application routes across it. `adlerkopf` is in the
  separate `adlerhorst` LAN and is not a second authority inside the trio LAN
  (Q4/Q5).
- Options:
  1. **One selected service with its declared admission boundary** — publish
     only that path; unrequested paths stay blocked.
     In practice: `hs.example.com` reaches Headscale over the tunnel; an admin
     path on the same edge is blocked.
     Gain: a real edge path with a testable admission boundary.
     Cost: the actual first service, DNS/TLS and auth flow must be supplied;
     P6/P8 may block the claim.
  2. **Publish every application route at once** — one edge pass.
     In practice: all public services are exposed together.
     Gain: fewer changes.
     Cost: a failure exposes or breaks unrelated services; no per-service
     admission proof.
  3. **Blanket forward-auth bypass for native share/API flows** — simplify
     guest access.
     In practice: all paths skip edge authentication.
     Gain: fewer per-service auth exceptions.
     Cost: broader exposure; rejected by the handover's identity-aware edge.
- Chosen: **One selected service with its declared admission boundary**.
  Rejected: all routes at once because it prevents a per-service guarantee;
  blanket bypass because it violates the access boundary.

## Open questions

### First selected service and admission boundary

Which service is the first real publication, what is its backend, and is it
behind forward-authentication or its own native auth? Seafile share/API and
Immich native auth must be verified (P8), not guessed.

### DNS, TLS and Headscale behavior (P6)

Which public names, DNS control and certificate path are used? Does Headscale's
end-to-end encryption survive Caddy's TLS termination? A green route without
the end-to-end check does not satisfy the guarantee.

### Netcup port and policy (P7)

Is outbound port 25 allowed, can PTR be set, and which external firewall policy
admits the selected edge ports? These block mail or edge claims that depend on
them; they are not silently assumed.
