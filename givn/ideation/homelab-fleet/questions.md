# Open questions: operating the home datacenter fleet

## Q1 — Does the new host trio retire the existing home server `adlerkopf`?

- Status: closed 2026-10-17 (user)
- Blocks: the Frame's host inventory, the authority of the existing
  `adlerkopf` plan set and host configuration, and whether `tinix001` is new
  hardware or the existing `adlerkopf` machine reconfigured. Until it closes,
  the topic cannot name a current home-server target.
- Context: the repository's current home server is `adlerkopf` — a Lenovo
  M720q with one NVMe, LUKS2, btrfs impermanence, Secure Boot, TPM2 unlock,
  AdGuard and Caddy, documented by `docs/plans/adlerkopf/` and
  `docs/ADLERKOPF-DEPLOY-RUNBOOK.md`. The 2026-10-17 handover names `pronix`
  and `tinix001` instead and never mentions `adlerkopf`. `pronix` is clearly
  different hardware (HP MicroServer Gen8 class: four bays, microSD boot,
  iLO). `tinix001` could be new hardware (i7-8700T, 64 GB, two NVMe, RX550)
  or the M720q rebuilt under a new name; the handover's two-NVMe and RX550
  details do not match the current `adlerkopf` hardware declaration. The
  answer decides whether `hosts/adlerkopf` and its plan set are retired,
  migrated, or kept alongside a fourth host.
- Question: Should the current home server `adlerkopf` be retired in favor of
  `pronix` plus `tinix001`, kept as a separate fourth host, or reused
  physically as `tinix001` under the new name?

- Options:
  1. **Retire `adlerkopf`; the new trio is the production fleet.**
     Meaning: `pronix` takes storage and infrastructure, `tinix001` takes
     compute and applications, `cupix001` stays the edge. `hosts/adlerkopf`
     and `docs/plans/adlerkopf/` become historical input; the production
     fleet has no `adlerkopf` node.
     In practice: a rebuild of the fleet deploys `pronix`, `tinix001` and
     `cupix001`; AdGuard moves to `pronix`/`tinix001`, Caddy's home-lab role
     is replaced by `cupix001`, and no generation is built for `adlerkopf`.
     Gain: one coherent architecture matching the handover; no split-brain
     service placement or duplicate AdGuard/Caddy roles.
     Cost: the existing `adlerkopf` declarations, runbook, assertions and
     plan set must be retired or migrated; any service unique to them
     (AdGuard settings, Caddy DNS plugin, Mosquitto, Node-RED, Grafana plans)
     needs an explicit new home or withdrawal.
  2. **Keep `adlerkopf` as a separate fourth host.**
     Meaning: the new trio is added alongside the existing home server;
     `adlerkopf` remains deployed for its current or planned services.
     In practice: the fleet has four server nodes; `adlerkopf` may keep
     AdGuard/Caddy while `tinix001` runs applications, or the roles split in
     another way.
     Gain: no retirement or migration of existing work; the machine remains
     usable as a lab or secondary node.
     Cost: the handover gives no role or placement for `adlerkopf`, so the
     owner must define one; duplicate DNS/proxy/storage roles and a larger
     operating surface are likely.
  3. **Reuse the `adlerkopf` machine physically as `tinix001`.**
     Meaning: the M720q (or whatever hardware `adlerkopf` denotes) is
     renamed and reconfigured as the compute host; `pronix` is the new
     storage host. `hosts/adlerkopf` is renamed/retired; its TPM2,
     impermanence and Secure Boot work is reused where the hardware supports
     it.
     In practice: the physical box that would have been `adlerkopf` becomes
     `tinix001`; its disk layout is re-planned for two NVMe and its
     `hardware.nix` is regenerated.
     Gain: preserves the existing hardware and the validated M720q boot
     design; no third physical server.
     Cost: the handover's `tinix001` details (two NVMe, 64 GB, RX550) must be
     confirmed against the actual machine; the name change touches the
     runbook, secrets recipients and arc42 inventory.

- Resolution: **Keep `adlerkopf` as a separate fourth host** because the user
  selected it. The production fleet gains `pronix` and `tinix001` alongside
  the existing `adlerkopf`; `cupix001` remains the edge. This topic models the
  three named hosts. `adlerkopf` stays outside the topic's change boundary
  with its existing declarations and plan set; it enters the model only where
  a shared service, duplicated role or transition affects the trio (for
  example DNS, Caddy or storage). No change to `adlerkopf` is authorized by
  this answer. Rejected: retiring `adlerkopf` because the user chose to keep
  it; reusing the M720q as `tinix001` because the user chose a separate fourth
  host and the handover's `tinix001` hardware does not match the declared
  M720q.

## Q2 — Which personas review this topic?

- Status: closed 2026-10-17 (user)
- Blocks: whether the phase reviews use the two confirmed project personas or
  require a new segment; it shapes the review lenses for Event Storming, Use
  Case Definition and Use Case Elaboration.
- Context: the project already has a confirmed owner/operator persona and a
  confirmed general application-user persona, both promoted from the
  `infrastructure-growth` topic. This topic's stakeholders are the same
  parties: the owner provisions and operates the fleet; family members and
  selected outside recipients use applications hosted on it. The personas'
  stable cores already cover the authority (fleet administration versus
  nonadministrative application use), the evaluation (operation/access/
  recovery evidence versus task success) and the vocabulary. A new segment is
  justified only by a difference in authority boundary, evaluation capability
  or own vocabulary.
- Question: Should this topic reuse the two confirmed personas as its review
  lenses, with topic-specific stances appended later, or should a new segment
  be created first?
- Options:
  1. **Reuse both existing personas** — use `owner--operator` and
     `family--application-user` unchanged; append dated topic stances.
     In practice: the owner lens critiques host provisioning and recovery;
     the application-user lens critiques whether the fleet leaves application
     use and outside-recipient access unchanged.
     Gain: no duplicate biography, consistent review across topics.
     Cost: no new segment is added for a fleet-specific stakeholder.
  2. **Create a new application-user segment** — only with a named
     distinguishing criterion (authority, evaluation or vocabulary).
     In practice: a family member who also administers the fleet is already
     the owner/operator lens, not a new segment.
     Gain: a sharper lens if a real difference exists.
     Cost: a new biography and a second review surface.
  3. **Use no personas** — proceed with actor roles only.
     In practice: no application-user critique of edge policy or access
     preservation.
     Gain: no persona work.
     Cost: loses the confirmed stakeholder lenses and the ideation
     instruction's expected review shape.
- Resolution: **Reuse both existing personas** because the user selected it;
  no distinguishing criterion justifies a new segment. `owner--operator`
  reviews provisioning, unlock, storage, update and recovery claims.
  `family--application-user` reviews whether the fleet preserves application
  use and granted access. Topic stances are appended as dated entries, never
  into the stable cores. Rejected: a new application-user segment because no
  authority/evaluation/vocabulary difference was named; no personas because
  the confirmed lenses already cover the stakeholders.

## Q4 — Which host set is the family-facing DNS and edge authority?

- Status: closed 2026-10-17 (user)
- Blocks: the service placement in the event chain (E3, E14, E21–E26) and the
  first Use Case Definition cut for DNS and edge reachability. It does not
  block the host-provisioning, boot, storage, update or recovery slices.
- Context: Q1 keeps `adlerkopf` as a separate fourth host with its existing
  declaration: AdGuard Home and Caddy with the netcup DNS plugin. The
  handover instead places AdGuard primary on `pronix`, AdGuard secondary on
  `tinix001`, and the public edge (Caddy, DERP, mail MTA) on `cupix001`. If
  both sets are intended to serve the same family clients, there are two DNS
  authorities and two proxy roles. The Frame records `adlerkopf` only where a
  duplicated role affects the trio, which is this case.
- Question: Should the trio become the family-facing DNS and edge authority
  while `adlerkopf` keeps its existing services for separate/lab use, or does
  `adlerkopf` remain the family-facing authority?
- Options:
  1. **Trio is the family-facing authority.** `pronix`/`tinix001` serve family
     DNS; `cupix001` serves the public edge. `adlerkopf` keeps its existing
     declarations but is not the intended family path.
     In practice: family devices get `pronix` and `tinix001` as resolvers;
     `hs.example.com` and application routes terminate on `cupix001`;
     `adlerkopf`'s AdGuard/Caddy remain for separate use and are not changed
     by this topic.
     Gain: one family-facing authority matching the handover; no split DNS or
     duplicate public edge.
     Cost: `adlerkopf`'s existing roles become non-authoritative for the
     family; the owner must avoid pointing family clients at them.
  2. **`adlerkopf` remains the family-facing authority.** The trio does not
     deploy family DNS or the public edge; it supplies storage, compute and
     host roles only.
     In practice: family devices keep `adlerkopf` as resolver and proxy;
     `cupix001` is not the family edge.
     Gain: no new DNS/edge authority and no transition.
     Cost: contradicts the handover's AdGuard pair and `cupix001` edge; the
     trio's edge and DNS phases are not implemented as written.
  3. **Both serve defined separate scopes.** The owner assigns clients or
     services to each authority.
     In practice: `adlerkopf` serves one network/lab; the trio serves the
     family; or DNS is split by domain.
     Gain: preserves both setups.
     Cost: two authorities to operate and explain; higher risk of a client
     using the wrong resolver or route.
- Resolution: **Both serve defined separate scopes** because the user
  selected it. Q5 defines the split as separate LANs: `adlerkopf` serves the
  `adlerhorst` LAN (local applications and DNS); the trio serves its own LAN
  (family applications, DNS and the public edge). Neither set is the sole
  family-facing authority; they are authorities for different LANs, linked by
  Tailscale over a slow internet connection. Rejected: the trio as sole
  family-facing authority because the user chose to keep both scopes;
  `adlerkopf` as sole family-facing authority because it contradicts the
  handover's AdGuard pair and `cupix001` edge. This preserves both setups at
  the cost of two authorities to operate and explain; the split is recorded
  per LAN in Q5.

## Q5 — What are the two DNS/edge scopes?

- Status: closed 2026-10-17 (user)
- Blocks: the service placement in E3/E14 and the edge route declarations in
  E21; without the split, Use Case Definition cannot say which host serves
  which client or domain.
- Context: Q4 keeps both `adlerkopf` and the trio as authorities in separate
  scopes. The handover places AdGuard primary on `pronix`, secondary on
  `tinix001`, and the public edge on `cupix001`. `adlerkopf` already declares
  AdGuard and Caddy with the netcup DNS plugin. The owner must decide which
  clients and domains each scope serves, or a family device can receive
  conflicting DNS answers and two different public routes.
- Question: Which scope should `adlerkopf` serve, and which scope should the
  trio serve?
- Options:
  1. **`adlerkopf` is lab/legacy; the trio is family and public.** Family
     devices use `pronix`/`tinix001` for DNS; `cupix001` is the only public
     edge. `adlerkopf` keeps its services for separate/lab clients and is not
     in the family DHCP resolver list.
     In practice: a family laptop resolves through `pronix`/`tinix001`;
     `photos.example.com` terminates on `cupix001`; `adlerkopf`'s AdGuard
     and Caddy answer only devices the owner points at them.
     Gain: one family-facing path matching the handover; no conflicting
     resolver for family clients.
     Cost: `adlerkopf`'s existing family role is reduced to lab/legacy; the
     owner must update any client still pointed at it.
  2. **`adlerkopf` keeps family LAN DNS; the trio serves public edge and
     applications.** Family devices keep `adlerkopf` as resolver; `cupix001`
     terminates public routes; `pronix`/`tinix001` AdGuard is secondary or
     experimental and not in the family DHCP list.
     In practice: `adlerkopf` answers `grafana.lan` and family DNS;
     `photos.example.com` goes through `cupix001`; the trio's AdGuard is not
     the primary family resolver.
     Gain: preserves the existing family DNS path and `adlerkopf` work.
     Cost: contradicts the handover's AdGuard primary/secondary placement;
     the trio's DNS redundancy is not the family path.
  3. **Split by domain and service.** `adlerkopf` keeps `*.lan` names for its
     existing services; the trio serves new family application domains and
     the public edge; family clients query both or use conditional forwarding.
     In practice: `grafana.lan` resolves on `adlerkopf`;
     `photos.example.com` and new family names resolve through the trio;
     `cupix001` publishes only the selected public routes.
     Gain: preserves both naming schemes.
     Cost: two DNS authorities with conditional forwarding; more complex to
     explain and diagnose, and a client can still use the wrong resolver.
  4. **Separate LAN scopes.** `adlerkopf` serves the `adlerhorst` LAN (local
     applications and DNS); the trio serves its own LAN (family applications,
     DNS and the public edge). The two LANs are linked by Tailscale over a
     slow internet connection; no client sees both authorities as local
     resolvers.
     In practice: a device in the `adlerhorst` LAN resolves through
     `adlerkopf` and uses its local applications; a device in the trio LAN
     resolves through `pronix`/`tinix001` and reaches `adlerkopf` only via
     Tailscale.
     Gain: each LAN has one DNS/edge authority; no conflicting resolver or
     route for a local client.
     Cost: cross-LAN access is slow and Tailscale-dependent; `adlerkopf`'s
     applications are not local to the trio LAN.
- Resolution: **Separate LAN scopes** because the user supplied it:
  `adlerkopf` is in a different LAN, `adlerhorst`, reachable only via
  Tailscale over a slow internet connection, and serves that LAN's local
  applications and DNS. The trio serves its own LAN and the public edge.
  Rejected: the domain/service split because the user places the difference
  at the LAN boundary, not at a domain-name boundary; the trio-only and
  `adlerkopf`-only options because each LAN needs its own authority. No new
  persona or shared resolver is implied.
