# Session: operating the home datacenter fleet

- Topic: homelab-fleet (provisional descriptive name).
- Updated: 2026-10-17.
- Phase: Handoff complete 2026-10-17; handover-coverage correction applied. The user confirmed the seven-leaf mapping, the initial eight ready seeds and promotion of both persona stances. A 2026-10-17 correction added `preserve-host-state` (nine seeds) and the phase-coverage table. The `provision-storage-host` proposal and its delta spec are written; design is next.
- Progress: recorded the user-supplied 2026-10-17 architecture handover for `pronix`, `tinix001` and `cupix001`; inventoried the existing repository ideas (`hosts/adlerkopf`, `docs/plans/adlerkopf/`, `hosts/cupix001`, `docs/plans/cupix001/`, `docs/edge-all.md`, `docs/ideation/infrastructure-growth.md`) and the durable specs; drafted and adopted the Frame; Q1 closed — `adlerkopf` stays a separate fourth host outside this topic; Q2 closed — both personas reused; Event Storming recorded E1–E41 with four rendered canvases; Q4/Q5 closed — `adlerkopf` serves the separate `adlerhorst` LAN (local apps and DNS), the trio serves its own LAN and the public edge, cross-LAN via Tailscale; seven use cases elaborated; nine ready change seeds written; readable topic published at `docs/ideation/homelab-fleet.md`; both topic stances promoted to the central persona files; handover phase coverage now maps all 14 phases and names the remaining DNS/Headscale, Authentik and mail gaps; `provision-storage-host` proposal and delta spec written.
- User-supplied direction: `pronix` is the storage and infrastructure host (HP MicroServer Gen8 class), `tinix001` is the compute host, `cupix001` is the public edge VPS. The attached handover supplies hardware, disk layouts, boot and unlock decisions, VLAN/IP plan, naming, fixed IDs, update windows, service placement, mail split, monitoring and backup phase structure. These are current design details, not verified hardware or deployed behavior.
- Frame status: confirmed. `adlerkopf` is kept as a separate fourth host per Q1; no `adlerkopf` change is modeled. Discussion/modeling only; no implementation authorization.
- Next action: `givn instructions design --change provision-storage-host`. Design must resolve D1–D3 (device identities, pool-2 feasibility, private network values) and choose the native targets; the real values need the operator's hardware/live-installer input and must not be guessed.
- Outputs: `frame.md`, `eventstorming.md`, `domain-terms.md`, `questions.md`, `use-case-definitions.md`, seven `use-cases/*.md`, topic-local `personas/*.md`, nine `changes/*.md`, the readable `docs/ideation/homelab-fleet.md`, the two appended central persona stances, `givn/changes/provision-storage-host/proposal.md`, and `givn/changes/provision-storage-host/specs/provision-host/provision-storage-host.feature`. No configuration, deployment or secret operation was started.

## Review evidence — 2026-10-17

- A fresh-context mechanical checklist completed: event coverage E1–E41, canvas
  kind prefixes, all seven contract schemas, the observing case's read-only
  flow, closed Q1/Q2/Q4/Q5, and use-case/out-of-scope identity all passed. Its
  one `Host` finding was a false positive and is clarified in
  `domain-terms.md`: `Host` is a reused durable term, not a new confirmation.
- Fresh-context semantic review attempts stalled without a final answer and
  were cancelled; no finding was produced. A self-review applied the corrections
  the mechanical pass could not judge: precondition/main-flow contradictions
  were removed (declarations, enrollment, pool establishment and update windows
  are preconditions), mechanism vocabulary was removed from Goal/Trigger/
  Success where possible, the storage goal was narrowed to one outcome, and the
  observing flow was made read-only.
- This is document/structure proof. No host, storage, edge, update, recovery or
  monitoring behavior was exercised.

## Persona reuse inventory — 2026-10-17

| Stakeholder type | Existing segment | Proposed match or new-segment justification | State |
|---|---|---|---|
| Infrastructure owner/operator | `owner--operator` (confirmed 2026-10-11) | Same authority (fleet and access configuration), evaluation (operation, access, recovery evidence) and vocabulary (Nix, servers, storage, backups). This topic adds dated stances, not a new segment. | Confirmed reuse (Q2). |
| Family application users | `family--application-user` (confirmed 2026-10-11) | Same nonadministrative application-use core. Host roles, VLANs, storage pools and edge mechanics are not application-user distinctions. | Confirmed reuse (Q2). |
| Selected outside recipients | `family--application-user` | Same application-use lens; grant scope and internet reachability remain application policies, not a new persona. | Confirmed reuse; no new segment. |
| External service operators (netcup, DNS, off-site backup) | none | Not an application user or a fleet operator. They supply endpoints and account state; they have no use case in this repository. | No persona; recorded as external dependencies. |

Topic-local reuse records are created under `personas/` with the `Reuse:`
header and dated entries only. The central persona files are unchanged;
promotion of the dated entries is offered separately at Handoff and is not
automatic.
