# Use Case Definition: operating the home datacenter fleet

Status: draft for sizing review 2026-10-17. The cut follows the confirmed
Frame, the two reused personas (Q2), and the closed scope questions Q1, Q4 and
Q5. It selects no implementation, release order or change seed.

## Boundary

The topic's boundary is **fleet operation** for `pronix`, `tinix001` and
`cupix001`. `adlerkopf` serves the separate `adlerhorst` LAN and is outside
the change boundary (Q1/Q5). Application availability, per-application
reachability and application-state recovery remain owned by
`infrastructure-growth`; the application behavior of DNS, mail, Headscale,
Authentik and the hosted applications remains external. Personal-device
reproduction remains the permanent `reproduce-working-environment` use case.

A host-level outcome is not an application outcome. Provisioning a host does
not make an application available; publishing an edge transport does not grant
an application resource; recovering a host does not recover application data.

## Leaf goals and boundaries

Every proposed case is level `!`, with one primary actor and one observable
outcome. No summary use case is needed: the topic itself is not an actor goal,
and the seven leaves do not share one success guarantee that a `+` would own.

| Stable use-case ID | Actor's goal | Primary actor | Nature | Single outcome / closure | Boundary and affected stakeholders |
|---|---|---|---|---|---|
| `provision-host` | Provision a host into the fleet | Owner/operator | Changing | The declared host is accepted into the fleet with its base system, storage layout, network attachment and service roles present. | One host per invocation. Does not claim an application is available or a service role is healthy; does not change `adlerkopf`. Owner; family users are affected only through the resulting placement. |
| `boot-host-unattended` | Boot an encrypted host without on-site intervention | Owner/operator | Changing | The host reaches its declared services after a cold start without a person entering a passphrase at the console. | One host per invocation. The passphrase fallback is an extension that protects the same boot guarantee; it is not a second success outcome. Does not claim data or application availability. Owner; family users affected by outage duration. |
| `restore-storage-redundancy` | Restore storage redundancy after a device failure | Owner/operator | Changing | The pool returns to its declared redundancy while the declared data remains readable. | One storage pool per invocation. Does not claim backup independence or application consistency; a degraded pool is not full redundancy. Owner; family users affected by data availability. |
| `reach-service-from-internet` | Make a selected home service reachable from the internet | Owner/operator | Changing | The selected service is reachable through the established public transport, and unrequested paths remain blocked. | One selected service per invocation. Establishes transport and admission, not application availability, resource grants or a blanket edge-auth bypass. Owner; selected outside recipients and family users where the service grants them access. |
| `apply-fleet-update` | Apply a fleet update within its declared window | Owner/operator | Changing | The intended software update is in effect within each host's window, with the declared services available. | One update cycle per invocation. Does not claim a backup, a rollback drill or an application-state restore. Owner; family users affected by the service window. |
| `recover-host` | Resume a host's declared role after loss | Owner/operator | Changing | A replacement host carries the declared role and persistent system state, and the role answers again. | One failed host per invocation. Application data and application access are dependencies, not this goal; a fresh install alone is not recovery. Owner; family users affected by the outage. |
| `observe-fleet-health` | Know when a host, pool or edge path is unhealthy | Owner/operator | Observing | The owner receives an alert for each declared health-threshold breach, and an undelivered alert is visible as a failure. | Read-only over fleet state; no configuration, route, pool or host mutation. Does not diagnose or repair. Owner; application users are affected only through the owner's response. |

## Sizing checks

1. **One goal, one primary actor.** Each Goal is one active-verb phrase naming
   the owner's outcome. No Goal joins two verb phrases with "and". The
   primary actor is the owner/operator throughout; the application user is a
   stakeholder or supporting role, never a second primary actor in these
   seven leaves.
2. **Closure.** The owner can stop after a host is accepted, a host boots
   unattended, redundancy is restored while data stayed readable, a service is
   reachable through the edge, an update returns the declared services, a
   failed host's role answers again, or a health breach is delivered. Each
   stopping point leaves the fleet in a consistent state.
3. **Goal-shaped, never component-shaped.** No Goal names a server, store,
   proxy, panel, CLI or browser. The public boundary is described in the
   boundary and preconditions, not in the Goal; the capabilities under
   `reach-service-from-internet` will be transport, admission and route
   behavior. "Storage" names the data-availability outcome, not btrfs or a
   disk model.
4. **Level discipline.** All seven are leaves. No leaf's flow names three or
   more distinct actor goals. `observe-fleet-health` is a single observing
   goal; it owns no mutating capability. No `+` is introduced because no
   summary's success guarantee is a conjunction of these leaves.
5. **Mutation containment.** `observe-fleet-health` owns zero mutating
   interactions. Provisioning mutates host/base/storage/network/placement;
   boot mutates the running host; redundancy restoration mutates the pool and
   replacement device; edge reachability mutates the tunnel and edge route;
   updates mutate host generations; recovery mutates replacement hardware and
   restored state. No observing case claims a state change.
6. **Extension discipline.** The boot passphrase fallback is an extension of
   the automatic-unlock step and protects the same boot guarantee. A storage
   replacement is a main-flow step after a degraded pool, not a new goal. An
   update failure is an extension that protects the "declared services return"
   guarantee, not a new success outcome. Edge authentication failure is an
   extension that protects the "unrequested paths remain blocked" guarantee.
7. **Precondition and flow consistency.** Preconditions hold before the
   trigger and are not established by the main flow: hardware and firmware
   checks, VLAN/IP plan, domain/DNS control, off-site state source and
   reachable Tang/TPM are preconditions where used. The success guarantee is
   established by the flow, never assumed. A trigger is an owner action or an
   observed failure, never a desire.
8. **Implementation independence.** Goal, Trigger, Main flow and Guarantees
   do not name btrfs, LUKS, Clevis, Tang, TPM2, Caddy, WireGuard, Clevis JWE,
   systemd-cryptenroll, Nix, disko or any other mechanism. Those appear only
   in Rules, Examples or design work. A rebuild in another technology leaves
   the same goals and guarantees.
9. **Relationship semantics.** No Includes between the seven leaves: sharing
   a host or a network does not make one goal a child of another. Any
   mandatory shared fragment (for example, the declared host role) is level
   `-` at ideation, not a permanent leaf. No Extends between leaves; the only
   extensions are failure handling inside a leaf.

## Shared subfunctions and external context — not new leaves

| Element | Treatment | Reason |
|---|---|---|
| Declare the host role, provisioning requirements and service placement | Setup subfunction before `provision-host` | A precondition of the provisioning flow, not a step that establishes the guarantee. |
| Enroll unlock material | Setup subfunction before `boot-host-unattended` | Preparation for the recurring boot guarantee; it does not deliver a usable host on its own. |
| Establish the public transport path | `-` subfunction of `reach-service-from-internet` | The transport has no actor value without the selected route and admission boundary. |
| Health thresholds and alert channel | Setup subfunction before `observe-fleet-health` | A precondition of the observing flow, not a mutation inside it. |
| Application availability, native application sharing/authorization | External, owned by `infrastructure-growth` and the hosted applications | This topic supplies host placement and transport; it does not build application features. |
| Application-state protection and recovery | External, owned by `infrastructure-growth` | A recovered host is not a recovered application; a storage pool is not a backup. |
| DNS answers, mail delivery, Headscale control-plane behavior, Authentik login | External service behavior; placement is E3/E14, access transport is E21–E26 | The user-facing outcome belongs to the service or a future application-level use case, not to host provisioning. |
| Personal working-environment reproduction | External, owned by `reproduce-working-environment` | No device-owner persona or personal-state data is imported. |

## Personas and stakeholders

| Use case | Owner/operator lens | Application-user lens |
|---|---|---|
| Provision a host | Critical: a declared host is not an accepted host. | Affected through placement; no administrative role. |
| Boot a host unattended | Critical: a cold start without a console is the operational baseline. | Affected by outage; no passphrase or console role. |
| Restore storage redundancy | Critical: degraded is not redundant; a pool is not a backup. | Affected when stored data is unavailable; no pool operation. |
| Reach a service through the edge | Critical: transport is not a resource grant; unrequested paths stay blocked. | Affected when the selected service is granted; no general network access inferred. |
| Apply a fleet update | Critical: a window and a returning service, not a green rebuild alone. | Affected by the service window; no update authority. |
| Recover a host | Critical: role and system state restored; application data is separate. | Affected by outage; no recovery operation. |
| Observe fleet health | Critical: an undelivered alert is not health. | Affected only through the owner's response; no monitoring duty. |

No new persona segment is created. The confirmed `owner--operator` and
`family--application-user` lenses review the elaborated contracts.

## Handoff mapping (confirmed 2026-10-17)

Each `!` leaf maps to its own future permanent leaf through the normal
proposal/spec flow. The user confirmed this mapping and the initial eight-seed
cut; the 2026-10-17 coverage correction added `preserve-host-state`, so nine
seeds now exist. No permanent directory is created by ideation.

| Use case | Future permanent leaf |
|---|---|
| `provision-host` | `givn/specs/provision-host/usecase.md` |
| `boot-host-unattended` | `givn/specs/boot-host-unattended/usecase.md` |
| `restore-storage-redundancy` | `givn/specs/restore-storage-redundancy/usecase.md` |
| `reach-service-from-internet` | `givn/specs/reach-service-from-internet/usecase.md` |
| `apply-fleet-update` | `givn/specs/apply-fleet-update/usecase.md` |
| `recover-host` | `givn/specs/recover-host/usecase.md` |
| `observe-fleet-health` | `givn/specs/observe-fleet-health/usecase.md` |

## Elaborated contracts

All seven leaves are elaborated under `use-cases/`:

- [provision-host](use-cases/provision-host.md)
- [boot-host-unattended](use-cases/boot-host-unattended.md)
- [restore-storage-redundancy](use-cases/restore-storage-redundancy.md)
- [reach-service-from-internet](use-cases/reach-service-from-internet.md)
- [apply-fleet-update](use-cases/apply-fleet-update.md)
- [recover-host](use-cases/recover-host.md)
- [observe-fleet-health](use-cases/observe-fleet-health.md)

Each contract has rules, concrete examples, main flow with extensions,
minimal/success guarantees, persona lenses, a diagram reference and Markdown
scenario skeletons. They are domain drafts, not `.feature` deltas, selected
products or verified behavior.

## Use Case Definition / Elaboration phase gate

A fresh-context mechanical checklist passed the contract schemas, event
coverage, closed questions and use-case identity; its one `Host` finding was a
false positive clarified in `domain-terms.md`. Fresh-context semantic review
attempts stalled and were cancelled; a self-review fixed the
precondition/main-flow contradictions, removed mechanism vocabulary from
Goal/Trigger/Success where possible, narrowed the storage goal to one outcome,
and made the observing flow read-only. Findings remain advisory; the user
arbitrates.

## Open inputs before elaboration

- P1–P10 remain checks, not facts: pronix NVMe visibility and microSD boot,
  NIC module, Clevis retry, TPM presence, Headscale/TLS behavior, netcup port
  25/PTR, Seafile URL pattern, control-plane outage, iLO serial prompt.
- A1–A8 remain assumptions: VLAN capability, PCIe NVMe visibility, TPM,
  cupix001 NixOS migration, outbound port 25, DNS/PTR control, data growth,
  off-site restic target.
- The actual replacement-device procedure, state source/bootstrap, alert
  channel and edge-selected services are supplied in the respective
  proposal/design. Missing inputs prevent the guarantee; they do not justify a
  weaker intermediate success.
