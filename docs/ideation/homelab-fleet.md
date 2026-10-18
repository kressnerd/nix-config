# Operating the home datacenter fleet

Status: ideation handoff complete 2026-10-17. The user confirmed the Frame,
both reused personas, the scope questions Q1/Q4/Q5, the seven-leaf permanent
mapping, the initial eight ready seeds and both persona promotions. A
2026-10-17 handover-coverage correction added the `preserve-host-state` seed
and the phase-coverage table; the seed count is now nine. This record starts
no givn change, edits no configuration, deploys nothing and performs no secret
operation. It describes host-level planning decisions, not observed behavior.

## Purpose

The repository's first ideas describe one home server (`adlerkopf`) and one
edge VPS (`cupix001`). The current design adds two hosts in a separate LAN:

- `pronix` — storage and infrastructure: BIOS/GRUB from microSD, LUKS2,
  btrfs mirrored pools, NFS/Samba, two NICs and iLO;
- `tinix001` — compute and applications: TPM2 unlock, impermanent root, two
  NVMe, one NIC with a storage VLAN subinterface, iGPU;
- `cupix001` — public edge: netcup VPS, WireGuard transport, Caddy, DERP and an
  inbound mail MTA.

`adlerkopf` remains a separate fourth host. It serves the `adlerhorst` LAN
(local applications and DNS) and is reachable only through Tailscale over a
slow internet connection. It is outside this topic's change boundary.

The topic answers one question: **can the owner provision, boot, keep data on,
expose, update and recover these three hosts as hosts?** It does not answer
whether a family application works, whether an application's data is
recoverable, or whether a personal device is ready. Those remain owned by the
existing `infrastructure-growth` topic and the permanent
`reproduce-working-environment` use case.

## People

| Party | Interest | Lens |
|---|---|---|
| Owner/operator | Provisions, unlocks, operates, updates and recovers the three hosts; judges whether the fleet matches the intended architecture. | Confirmed `owner--operator`; no new segment. |
| Family application users | Use applications hosted on `tinix001` through granted paths. Do not operate the fleet. | Confirmed `family--application-user`; no new segment. |
| Selected outside recipients | Reach specifically granted application resources through the public edge without general family-network access. | Same application-user lens; grant scope stays application-specific. |
| netcup, DNS and off-site backup operators | Supply the VPS account, public DNS/PTR and a restic-compatible destination. | External dependencies, not personas. |

## What the handover supplies

The 2026-10-17 architecture handover supplies hardware, roles, the VLAN/IP
plan, naming, fixed UIDs/GIDs, update windows, service placement, the mail
split, monitoring and backup phase structure. It also records decisions
D1–D16, assumptions A1–A8 and checks P1–P10.

These are design intent. They are **not** verified hardware inventory or
deployed behavior. The critical checks are:

- P1: both NVMe devices visible on `pronix`;
- P2: the Gen8 boots GRUB from microSD;
- P3: the NIC kernel module;
- P4: Clevis retry when Tang is unreachable;
- P5: TPM 2.0 on `tinix001`;
- P6: Headscale end-to-end encryption through the edge TLS;
- P7: netcup outbound port 25 and PTR;
- P8: Seafile share URL pattern;
- P9: Headscale behavior during a long control-plane outage;
- P10: iLO Virtual Serial Port shows the LUKS prompt.

## The seven host goals

Each goal is a separate future permanent leaf through the normal proposal/spec
flow. They are not capabilities hidden under a catch-all "server" goal.

| Goal | Owner's observable outcome | Contract |
|---|---|---|
| Provision a host into the fleet | The declared host is accepted with its base system, storage layout, network attachment and service roles present. | [provision-host](../../givn/ideation/homelab-fleet/use-cases/provision-host.md) |
| Boot an encrypted host without on-site intervention | The host reaches its declared services after a cold start without a person entering a passphrase at the console. | [boot-host-unattended](../../givn/ideation/homelab-fleet/use-cases/boot-host-unattended.md) |
| Restore storage redundancy after a device failure | The pool returns to its declared redundancy while the declared data remains readable. | [restore-storage-redundancy](../../givn/ideation/homelab-fleet/use-cases/restore-storage-redundancy.md) |
| Make a selected home service reachable from the internet | The selected service answers on its declared public path and unrequested paths remain blocked. | [reach-service-from-internet](../../givn/ideation/homelab-fleet/use-cases/reach-service-from-internet.md) |
| Apply a fleet update within its declared window | The intended update is in effect within each host's window, with the declared services available. | [apply-fleet-update](../../givn/ideation/homelab-fleet/use-cases/apply-fleet-update.md) |
| Resume a host's declared role after loss | A replacement host carries the role and persistent system state, and the role answers again. | [recover-host](../../givn/ideation/homelab-fleet/use-cases/recover-host.md) |
| Know when a host, pool or edge path is unhealthy | Each declared threshold breach produces a delivered alert; an undelivered alert is visible as a failure. | [observe-fleet-health](../../givn/ideation/homelab-fleet/use-cases/observe-fleet-health.md) |

The storage goal was narrowed during elaboration: it restores redundancy while
data stays readable, rather than joining availability and rebuild into two
outcomes. The health goal is observing only: its signal/threshold declaration
is a precondition, and its flow mutates no fleet state.

## Event chain

The [event storming](../../givn/ideation/homelab-fleet/eventstorming.md) records
41 events in four rendered canvases:

1. provision and boot a host;
2. restore storage redundancy after a device failure;
3. expose a selected service through the edge;
4. keep current, recover and observe.

Every event names its actor and command, target with kind, reacting policy and
read model. The chain introduces no repository-owned aggregate: configuration
records, hosts, storage, networks, the edge, unlock authorities, the monitoring
system and human interactions are named as those kinds. The four Mermaid
canvases were rendered with Mermaid CLI 12 and Chromium 155 and visually
inspected; that is diagram proof, not host behavior.

## Boundary with application outcomes

| Question | Owner |
|---|---|
| Can a family member use a hosted application through its permitted path? | `infrastructure-growth` (`make-application-available`, `adjust-application-reachability`, `access-shared-information`). |
| Is application state protected and recoverable after a server failure? | `infrastructure-growth` (`preserve-recoverable-application-state`, `recover-hosted-applications`). |
| Is a host provisioned, unlocked, storage-redundant and reachable as a host? | This topic. |
| Which host runs a service, and how does its data reach that host? | This topic supplies placement/storage; `infrastructure-growth` supplies the application outcome. |
| Can the owner reproduce a personal working environment? | The permanent `reproduce-working-environment` use case; outside this topic. |

A host-level outcome is not an application outcome. Provisioning a host does
not make an application available; an edge route is transport, not a resource
grant; host recovery does not restore application data.

## Ready change seeds

A seed is input to a later `/givn-propose`, not an active change. The cut is by
deliverable guarantee, not by phase number. The suggested order avoids the
unlock-chain cycle: `pronix` first with the manual passphrase fallback,
`tinix001` next with TPM2 and Tang, then unattended `pronix` boot.

| Seed | Ship-alone guarantee | Use cases | Suggested start |
|---|---|---|---|
| [provision-storage-host](../../givn/ideation/homelab-fleet/changes/provision-storage-host.md) | `pronix` is accepted with its base system, storage layout, network and storage roles; it boots with the declared unlock path and its exports are reachable. | `provision-host` | 1; P1–P3 must be usable. |
| [provision-compute-host](../../givn/ideation/homelab-fleet/changes/provision-compute-host.md) | `tinix001` is accepted with its system pool, network, NFS automounts and roles; it unlocks through TPM2 and exposes Tang on the storage VLAN, with a reported passphrase fallback. | `provision-host`, `boot-host-unattended` | 2; depends on the storage host for NFS and supplies Tang. |
| [unattended-storage-boot](../../givn/ideation/homelab-fleet/changes/unattended-storage-boot.md) | `pronix` cold-starts without a console passphrase through Tang; a missing Tang is reported and the passphrase fallback remains available. | `boot-host-unattended` | 3; depends on 1 and 2. |
| [storage-redundancy](../../givn/ideation/homelab-fleet/changes/storage-redundancy.md) | A declared `pronix` pool keeps its data readable through one device failure and returns to its declared redundancy after replacement and rebuild. | `restore-storage-redundancy` | 4; depends on 1. |
| [edge-service-publication](../../givn/ideation/homelab-fleet/changes/edge-service-publication.md) | One selected home service is reachable through `cupix001`, its admission boundary is in effect, and unrequested paths are blocked. | `reach-service-from-internet` | 5; depends on 2 for the backend and the edge foundation. |
| [fleet-update](../../givn/ideation/homelab-fleet/changes/fleet-update.md) | The declared hosts apply the intended update inside their windows, reboot only when required, and their services return; a rollback is reported as such. | `apply-fleet-update` | 6; depends on 1–3 for hosts and the Tang order. |
| [preserve-host-state](../../givn/ideation/homelab-fleet/changes/preserve-host-state.md) | A host's declared persistent system state and bootstrap have a usable copy outside the host, and a supported restore check succeeds; application data remains separate. | `recover-host` | 7; depends on 1–2 and supplies the source for host recovery. |
| [host-recovery](../../givn/ideation/homelab-fleet/changes/host-recovery.md) | A failed host's role and persistent system state are restored on a replacement, and the role answers; application recovery remains separate. | `recover-host` | 8; depends on 1–2 and the `preserve-host-state` source. |
| [fleet-health](../../givn/ideation/homelab-fleet/changes/fleet-health.md) | Each declared host, pool or edge threshold breach produces a delivered alert, and an undelivered alert is visible as a failure. | `observe-fleet-health` | 9; depends on 1–2 and at least one edge path. |

## Handover phase coverage

The handover has 14 phases; the seed cut is by deliverable guarantee, not by
phase. This table makes every phase's owner explicit. "Later seed" means a
follow-up candidate that does not exist yet, not a ready seed.

| Handover phase | Scope | Local owner | Status |
|---|---|---|---|
| 0 | Preparation: repo, IDs, VLANs, hardware checks, RX550 removal, microSD | Preconditions of seeds 1–3; P1–P3, P5, P10 remain checks | Covered as preconditions/open checks |
| 1 | `pronix` base OS | `provision-storage-host` | Seeded |
| 2 | `pronix` storage pools and exports | `provision-storage-host` + `storage-redundancy` | Seeded |
| 3 | `tinix001` base | `provision-compute-host` | Seeded |
| 4 | `pronix` unattended unlock | `unattended-storage-boot` | Seeded |
| 5 | `cupix001` edge and tunnel | `edge-service-publication` | Partly seeded: foundation and one selected service; full DERP/mail/Gatus edge stack is a later seed |
| 6 | Headscale and DNS redundancy | No seed yet; later `homelab-fleet` seed(s) for the private-network control plane and the AdGuard pair | Gap |
| 7 | Identity/Authentik | No seed yet; later `homelab-fleet` seed for the identity provider and edge forward-auth | Gap |
| 8 | Service wave 1 (Immich, Jellyfin, Seafile, paperless, Calibre-web) | `infrastructure-growth` owns application availability/access/recovery; `homelab-fleet` supplies storage and placement | External + seeded placement |
| 9 | Mail (Postfix MTA, Dovecot/SOGo, LMTP, rspamd/DKIM) | No seed yet; later `homelab-fleet` seed for the mail split | Gap |
| 10 | Home and development (Home Assistant, Node-RED, grocy, Forgejo) | `infrastructure-growth` or a future application topic; not host provisioning | External |
| 11 | Monitoring (Prometheus/Loki/Grafana, Gatus, Alertmanager) | `fleet-health` at the guarantee level; the exact stack is design detail | Seeded at guarantee level |
| 12 | Backup (restic, DB dumps, restore checks) | `infrastructure-growth` for application-state protection/recovery; `preserve-host-state` for host system state | Split ownership, now explicit |
| 13 | Completion and options (validation matrix, runbook, optional pronix impermanence, `verifyClients`) | Not a deliverable; runbook and optional decisions | Out of scope for seeds |

## Open inputs before implementation

The [question ledger](../../givn/ideation/homelab-fleet/questions.md) retains the
full decisions and rejected alternatives. The seeds carry their own open
inputs. The common ones are:

- actual device IDs, NIC names, boot results and TPM/Tang state (P1–P5, P10);
- real LAN, storage VLAN, management VLAN and private-input values;
- the first selected edge service, its admission boundary and DNS/TLS path
  (P6, P8);
- netcup outbound port and PTR (P7);
- the host-state source created by `preserve-host-state` and the replacement
  material; the application-data restic target is a separate concern;
- the alert channel, thresholds and a monitoring component that survives a
  compute-host outage;
- the mail split's real DNS/PTR, relay and mailbox behavior (P7) when a mail
  service is selected;
- the DNS pair, Headscale/DERP, Authentik and mail split have no ready seed
  yet; they are follow-up candidates in the phase coverage table.

These are not configurations already implemented or verified. Missing inputs
prevent the corresponding guarantee; they do not justify a weaker success.

## Terminology

Candidate terms are recorded in the [topic term record](../../givn/ideation/homelab-fleet/domain-terms.md):
fleet, accepted host, storage pool, storage device, edge route, unlock
material, update window, host recovery, health signal and service role. None is
confirmed by this topic. `Host` is a reused durable-glossary term, cited rather
than re-confirmed. No durable glossary entry was changed.

## Verification and evidence

- The seven contracts have every schema heading, rules, concrete examples,
  main-flow extensions, minimal/success guarantees, persona lenses, diagram
  references and Markdown scenario skeletons.
- The four Mermaid canvases rendered and were visually inspected; all kind
  prefixes and E-numbers are visible.
- A mechanical structure check passed the event coverage, canvas kind,
  schema-heading, closed-question, use-case-ID and out-of-scope checks. A
  fresh-context semantic review was attempted but did not return findings; a
  self-review fixed precondition/main-flow contradictions, mechanism wording
  and the observing flow. Findings remain advisory.
- This is document, diagram and structure proof. No host was provisioned,
  unlocked, exported, failed, rebuilt, updated, recovered or monitored. No
  application was deployed. No secret, private input or live hardware was read.

## Handoff record

- Frame: confirmed 2026-10-17; Q1 keeps `adlerkopf` as a separate fourth host;
  Q4/Q5 place it in the `adlerhorst` LAN via Tailscale and the trio in its own
  LAN with the public edge.
- Personas: both confirmed reuse by Q2. Topic-local records exist under
  `personas/`. The user confirmed promotion of both dated stances; they are
  appended to the central `owner--operator` and `family--application-user`
  files without changing the stable cores.
- Use-case-to-permanent mapping: the user confirmed the seven-leaf mapping.
  Each goal maps to its own `givn/specs/<use-case-id>/usecase.md` through the
  normal proposal/spec flow. No permanent leaf directory was created here.
- Seeds: the user confirmed the initial eight `Status: ready` files. The
  2026-10-17 coverage correction added `preserve-host-state`, so nine
  `Status: ready` files now exist under `changes/`. They are inputs to
  `/givn-propose`, not proposals, changes or deployment authorization.
- Coverage correction: [Handover phase coverage](#handover-phase-coverage)
  maps all 14 handover phases. Phases 6 (Headscale/DNS), 7 (Authentik) and 9
  (mail) remain gaps with no ready seed; they are follow-up candidates, not
  delivered capabilities.
- Proposal: after handoff, the user started `provision-storage-host`. Its
  proposal is `givn/changes/provision-storage-host/proposal.md`; this ideation
  record remains the source and is not replaced by the proposal.
