# Event Storming: operating the home datacenter fleet

Status: complete for phase review 2026-10-17. The model covers the three named
hosts (`pronix`, `tinix001`, `cupix001`) and treats `adlerkopf` as a separate
fourth host outside the topic (Q1). It is a proposed event chain, not observed
runtime behavior.

## Scope and evidence

The chain follows the user's 2026-10-17 architecture handover: host roles,
storage pools, boot and unlock, edge reachability, service placement, update
windows, host recovery and health observation. Application behavior, family
sharing logic and the user-facing behavior of DNS, mail, Headscale, Authentik
or the hosted applications remain outside this chain. Their **placement** is
modeled as a service role on a host; their **user outcome** belongs to the
application or to `infrastructure-growth`.

The Frame's hardware, VLAN/IP plan, assumptions A1–A8 and verification points
P1–P10 are constraints, not verified facts. No host was provisioned, unlocked,
exported, updated, failed over or monitored for this model.

`adlerkopf` is not part of this chain. It serves the separate `adlerhorst` LAN
(local applications and DNS) and is reachable only through Tailscale over a
slow internet connection (Q5). It is not a second authority inside the trio's
LAN. No `adlerkopf` change is modeled.

## Kinds and consistency boundaries

The durable glossary declares no repository-owned aggregate. This chain
introduces none. Every target is named by its kind:

- **Actor** — a human role that issues a command.
- **Command** — an intention the actor expresses.
- **Configuration record** — a declaration in the repository; not an
  aggregate.
- **External system** — a host, storage, network, edge, unlock authority,
  monitoring system or failed/replacement host; not owned by this repository.
- **External interaction** — a human-to-human exchange.
- **Event** — a past-tense domain fact.
- **Policy** — a reaction rule that selects the next behavior.
- **Read model** — information the actor needs to inspect.

A **host** is an external system here; the durable glossary's `Host` term
(one declared machine configuration under `hosts/<host>/`) names the
declaration, not the running machine. A **storage pool**, **edge route**,
**unlock material**, **update window**, **host recovery**, **health signal**
and **service role** are candidate domain terms, not aggregates. They are
recorded in `domain-terms.md` with collision evidence.

## Event partners

| ID | Past-tense event | Actor and command | Target and kind | Reacting policy | Actor's read model |
|---|---|---|---|---|---|
| E1 | Fleet membership declared | Owner/operator: declare host role | Fleet inventory — configuration record | A host has one declared role in the fleet | Declared fleet |
| E2 | Host provisioning requirements recorded | Owner/operator: declare provisioning requirements | Host provisioning definition — configuration record | Requirements are host-specific; they reference the unlock and service roles | Declared requirements |
| E3 | Service role assigned | Owner/operator: assign service role | Service placement — configuration record | A family-facing role has one intended host; `adlerkopf` serves the separate `adlerhorst` LAN (Q4/Q5) | Declared placement |
| E4 | Host base system installed | Owner/operator: install base system | Host — external system | Install from the declared provisioning definition | Provisioning result |
| E5 | Host storage layout applied | Owner/operator: apply storage layout | Storage — external system | Declared pool layout; no undeclared pool | Provisioning result |
| E6 | Host network attachment established | Owner/operator: attach host to networks | Network — external system | Declared VLAN/IP plan and host role | Provisioning result |
| E7 | Host accepted into fleet | Owner/operator: check host provisioning | Host — external system | Base system, storage and network are present; a partial host is not accepted | Fleet inventory |
| E8 | Unlock material enrolled | Owner/operator: enroll unlock material | Unlock authority (Tang or TPM) — external system | The host role selects Tang or TPM; the passphrase slot remains a fallback | Unlock readiness |
| E9 | Host cold-started | Owner/operator: start host | Host — external system | — | Boot result |
| E10 | Root unlocked automatically | Unlock authority for the owner/operator: unlock root | Host — external system | Automatic unlock by host role | Boot result |
| E11 | Root unlock failed | Unlock authority for the owner/operator: unlock root | Host — external system | Automatic unlock did not produce a usable root | Boot result |
| E12 | Root unlocked manually | Owner/operator: supply passphrase | Host — external system | initrd-SSH or iLO serial console; the passphrase slot is retained | Boot result |
| E13 | Host services started | Host — external system | Host — external system | Start the declared service roles after the root is usable | Boot result |
| E14 | Service role active on host | Owner/operator: check service role | Host — external system | The declared role answers on its intended network; a configured unit is not proof | Role status |
| E15 | Storage pool established | Owner/operator: create storage pool | Storage — external system | Declared pool layout and RAID level | Pool layout |
| E16 | Storage device failed | Storage — external system | Storage — external system | Report the failure; do not equate it with data loss | Pool health |
| E17 | Storage pool degraded | Storage — external system | Storage — external system | Continue serving from the remaining devices; do not claim full redundancy | Pool health |
| E18 | Replacement device installed | Owner/operator: replace device | Storage — external system | The replacement belongs to the declared pool | Pool health |
| E19 | Storage pool rebuilt | Owner/operator: rebuild pool | Storage — external system | Redundancy is restored only when the rebuild completes | Pool health |
| E20 | Data availability restored | Owner/operator: check data availability | Storage — external system | The pool is healthy and the declared data is readable | Pool health |
| E21 | Edge route declared | Owner/operator: declare edge route | Edge route — configuration record | Only selected services are admitted; a route is not a resource grant | Declared routes |
| E22 | Edge tunnel established | Owner/operator: establish tunnel | Network — external system | Static edge link between `cupix001` and `tinix001` | Tunnel status |
| E23 | Edge route published | Owner/operator: publish route | Edge — external system | Declared route, authentication boundary and backend | Effective edge routes |
| E24 | Service reached from internet | Application user: open service | Edge — external system | A permitted edge route admits the request | Connectivity result |
| E25 | Unrequested path blocked | Application user: open unrequested path | Edge — external system | No declared route or no admission; reachability grants no resource rights | Connectivity result |
| E26 | Edge route withdrawn | Owner/operator: withdraw route | Edge — external system | The route stops admitting requests | Effective edge routes |
| E27 | Update window declared | Owner/operator: declare update window | Update policy — configuration record | Host-specific window and reboot order | Declared windows |
| E28 | Host update applied | Owner/operator: apply update | Host — external system | Apply within the declared window | Update result |
| E29 | Host reboot required | Host — external system | Host — external system | A kernel, module or initrd change requires a reboot | Update result |
| E30 | Host rebooted within window | Owner/operator: reboot host | Host — external system | Reboot only inside the window; respect the Tang-before-pronix order | Update result |
| E31 | Service returned after update | Host — external system | Host — external system | Declared service roles answer again | Service status |
| E32 | Update failed | Host — external system | Host — external system | Report the failure; do not present a partial update as complete | Update result |
| E33 | Host failure observed | Owner/operator: assess host | Failed host — external system | Distinguish failure from planned maintenance | Failure information |
| E34 | Replacement host provisioned | Owner/operator: provision replacement | Replacement host — external system | Reuse the declared provisioning definition | Replacement readiness |
| E35 | Host state restored | Owner/operator: restore host state | Replacement host — external system | Restore declared persistent system state and bootstrap; application data is a dependency, not part of this claim | Restore result |
| E36 | Host role resumed | Owner/operator: check host role | Host — external system | The declared role and service placement answer again | Fleet readiness |
| E37 | Host recovery failed | Owner/operator: check host role | Host — external system | Report the failure; do not claim fleet readiness | Fleet readiness |
| E38 | Host health signal observed | Monitoring — external system | Monitoring — external system | Collect host, pool and edge signals | Health status |
| E39 | Health threshold exceeded | Monitoring — external system | Monitoring — external system | Apply the declared threshold per signal | Alert |
| E40 | Alert delivered | Monitoring — external system | Owner/operator — external interaction | Deliver to the owner through the declared channel | Alert |
| E41 | Alert not delivered | Monitoring — external system | Owner/operator — external interaction | Record the delivery failure; a silent non-delivery is not health | Alert |

## Canvas 1 — provision and boot a host

```mermaid
flowchart TD
  subgraph Provisioning
    O["Actor: owner/operator"]
    C1["Command: declare host role"]
    R1["Configuration record: fleet inventory"]
    E1(["Event E1: fleet membership declared"])
    RM1["Read model: declared fleet"]
    C2["Command: declare provisioning requirements"]
    R2["Configuration record: host provisioning definition"]
    E2(["Event E2: host provisioning requirements recorded"])
    RM2["Read model: declared requirements"]
    C3["Command: assign service role"]
    R3["Configuration record: service placement"]
    E3(["Event E3: service role assigned"])
    RM3["Read model: declared placement"]
    C4["Command: install base system"]
    C5["Command: apply storage layout"]
    C6["Command: attach host to networks"]
    H["External system: host"]
    S["External system: storage"]
    N["External system: network"]
    E4(["Event E4: host base system installed"])
    E5(["Event E5: host storage layout applied"])
    E6(["Event E6: host network attachment established"])
    C7["Command: check host provisioning"]
    E7(["Event E7: host accepted into fleet"])
    RM4["Read model: fleet inventory"]
    C8["Command: enroll unlock material"]
    U["External system: unlock authority (Tang or TPM)"]
    E8(["Event E8: unlock material enrolled"])
    RM5["Read model: unlock readiness"]
    C9["Command: start host"]
    E9(["Event E9: host cold-started"])
    P1{"Policy: automatic unlock by host role"}
    P2{"Policy: manual fallback via initrd-SSH or iLO"}
    E10(["Event E10: root unlocked automatically"])
    E11(["Event E11: root unlock failed"])
    C10["Command: supply passphrase"]
    E12(["Event E12: root unlocked manually"])
    E13(["Event E13: host services started"])
    C11["Command: check service role"]
    E14(["Event E14: service role active on host"])
    RM6["Read model: boot result"]
    RM7["Read model: role status"]
  end

  O --> C1 --> R1 --> E1 --> RM1
  O --> C2 --> R2 --> E2 --> RM2
  E2 --> C3 --> R3 --> E3 --> RM3
  O --> C4 --> H --> E4
  O --> C5 --> S --> E5
  O --> C6 --> N --> E6
  O --> C7 --> H
  E4 --> E7
  E5 --> E7
  E6 --> E7
  E7 --> RM4
  E7 --> C8 --> U --> E8 --> RM5
  RM5 --> C9
  O --> C9 --> H --> E9
  E9 --> P1 --> U
  U -->|Success| E10
  U -->|Failure| E11
  E11 --> P2 --> C10 --> H --> E12
  E10 --> E13
  E12 --> E13
  E13 --> RM6
  E13 --> E14
  E3 --> E14
  O --> C11 --> H --> E14 --> RM7
```

The host is accepted only when base system, storage layout, network attachment
and declared roles are present. Enrollment happens before the first unattended
cold start. A failed automatic unlock falls back to the retained passphrase
slot; it does not silently claim a successful boot.

## Canvas 2 — restore storage redundancy after a device failure

```mermaid
flowchart TD
  subgraph Storage
    O["Actor: owner/operator"]
    C1["Command: create storage pool"]
    S["External system: storage"]
    E15(["Event E15: storage pool established"])
    RM1["Read model: pool layout"]
    E16(["Event E16: storage device failed"])
    P1{"Policy: continue serving from remaining devices"}
    E17(["Event E17: storage pool degraded"])
    RM2["Read model: pool health"]
    C2["Command: replace device"]
    E18(["Event E18: replacement device installed"])
    C3["Command: rebuild pool"]
    E19(["Event E19: storage pool rebuilt"])
    C4["Command: check data availability"]
    E20(["Event E20: data availability restored"])
  end

  O --> C1 --> S --> E15 --> RM1
  S --> E16 --> P1 --> S --> E17 --> RM2
  O --> C2 --> S --> E18 --> RM2
  O --> C3 --> S --> E19 --> RM2
  O --> C4 --> RM2 --> E20
```

A failed device makes the pool degraded, not absent. Data availability is
restored only after the replacement is installed and the rebuild completes.
`degraded` is never treated as full redundancy.

## Canvas 3 — expose a selected service through the edge

```mermaid
flowchart TD
  subgraph Edge
    O["Actor: owner/operator"]
    U["Actor: application user"]
    C1["Command: declare edge route"]
    R["Configuration record: edge route"]
    E21(["Event E21: edge route declared"])
    RM1["Read model: declared routes"]
    C2["Command: establish tunnel"]
    N["External system: network"]
    E22(["Event E22: edge tunnel established"])
    RM2["Read model: tunnel status"]
    C3["Command: publish route"]
    X["External system: edge"]
    E23(["Event E23: edge route published"])
    RM3["Read model: effective edge routes"]
    C4["Command: open service"]
    C5["Command: open unrequested path"]
    E24(["Event E24: service reached from internet"])
    E25(["Event E25: unrequested path blocked"])
    RM4["Read model: connectivity result"]
    C6["Command: withdraw route"]
    E26(["Event E26: edge route withdrawn"])
  end

  O --> C1 --> R --> E21 --> RM1
  O --> C2 --> N --> E22 --> RM2
  RM1 --> C3
  RM2 --> C3
  O --> C3 --> X --> E23 --> RM3
  P1{"Policy: permitted edge route"} --> X
  P2{"Policy: no route or no admission"} --> X
  RM3 --> P1
  U --> C4 --> X -->|Permitted| E24 --> RM4
  U --> C5 --> X -->|Unrequested| E25 --> RM4
  O --> C6 --> X --> E26 --> RM3
```

A declared route is not a resource grant. Reaching an endpoint is separate
from permission to use an application resource. The edge admits only the
selected route; everything else is blocked.

## Canvas 4 — keep current, recover and observe

```mermaid
flowchart TD
  subgraph Update
    O["Actor: owner/operator"]
    C1["Command: declare update window"]
    R["Configuration record: update policy"]
    E27(["Event E27: update window declared"])
    RM1["Read model: declared windows"]
    C2["Command: apply update"]
    H["External system: host"]
    E28(["Event E28: host update applied"])
    E29(["Event E29: host reboot required"])
    P1{"Policy: reboot inside the window, Tang before pronix"}
    C3["Command: reboot host"]
    E30(["Event E30: host rebooted within window"])
    E31(["Event E31: service returned after update"])
    E32(["Event E32: update failed"])
    RM2["Read model: update result"]
    RM3["Read model: service status"]
  end

  subgraph Recovery
    FH["External system: failed host"]
    C4["Command: assess host failure"]
    E33(["Event E33: host failure observed"])
    RM4["Read model: failure information"]
    C5["Command: provision replacement"]
    RH["External system: replacement host"]
    E34(["Event E34: replacement host provisioned"])
    C6["Command: restore host state"]
    E35(["Event E35: host state restored"])
    RM5["Read model: restore result"]
    C7["Command: check host role"]
    E36(["Event E36: host role resumed"])
    E37(["Event E37: host recovery failed"])
    RM6["Read model: fleet readiness"]
  end

  subgraph Observation
    M["External system: monitoring"]
    E38(["Event E38: host health signal observed"])
    P2{"Policy: threshold per signal"}
    E39(["Event E39: health threshold exceeded"])
    E40(["Event E40: alert delivered"])
    E41(["Event E41: alert not delivered"])
    RM7["Read model: health status"]
    RM8["Read model: alert"]
  end

  O --> C1 --> R --> E27 --> RM1
  O --> C2 --> H --> E28 --> RM2
  H --> E29 --> P1 --> C3 --> H --> E30 --> E31 --> RM3
  H --> E32 --> RM2
  O --> C4 --> FH --> E33 --> RM4
  O --> C5 --> RH --> E34
  E34 --> C6
  O --> C6 --> RH --> E35 --> RM5
  O --> C7 --> RH
  E35 --> E36 --> RM6
  RH --> E37 --> RM6
  H --> M
  S2["External system: storage"] -.-> M
  X2["External system: edge"] -.-> M
  M --> E38 --> P2 --> E39 --> RM8
  E39 --> E40 --> RM7
  E39 --> E41 --> RM7
```

Recovery restores the host role and declared system state. Application data
and application-specific access restoration remain with
`infrastructure-growth`; a recovered host is not a recovered application.
Alert delivery is part of the health claim: a monitoring system that cannot
deliver an alert has not established that the owner knows.

## Reverse narrative

Which events must have happened for **a service to be reached from the
internet**? E24 requires E23 (route published), which requires E22 (tunnel
established) and E21 (route declared), which assemble E21's configuration
record from E1/E2/E3 (host role, provisioning requirements, service
placement). E24 also requires E13 (host services started), which requires E9
(host cold-started) and either E10 (automatic unlock) or E12 (manual unlock);
both require E8 (unlock material enrolled), which requires E7 (host accepted)
and E4/E5/E6 (base system, storage, network). The chain starts at E1 (fleet
membership declared) and E2 (provisioning requirements recorded).

Which events must have happened for **data availability to be restored**?
E20 requires E19 (pool rebuilt), which requires E18 (replacement installed)
after E16 (device failed) and E17 (pool degraded). E17 requires E15 (pool
established). A pool that was never established cannot be degraded; a
replacement that was not rebuilt does not restore redundancy.

Which events must have happened for **host role resumed**? E36 requires E35
(state restored) and E34 (replacement provisioned). E35 requires a surviving
state source and a supported restore procedure; a fresh install alone does not
restore declared system state. E34 reuses E2's provisioning definition, not a
new architecture.

Which events must have happened for **an alert to be delivered**? E40
requires E39 (threshold exceeded), which requires E38 (signal observed) and a
declared threshold. E38 requires the monitoring system to observe the host,
pool or edge. An undelivered alert (E41) is recorded as a failure, not as
health.

## Coverage check

| Slice | Events | Use-case candidate |
|---|---|---|
| Provisioning | E1–E7, E14 | Provision a host into the fleet |
| Unattended boot | E8–E13 | Keep an encrypted host bootable without on-site intervention |
| Storage redundancy | E15–E20 | Restore storage redundancy after a device failure |
| Edge reachability | E21–E26 | Make a selected home service reachable from the internet |
| Updates | E27–E32 | Keep the fleet current within its declared windows |
| Host recovery | E33–E37 | Resume a host's role after loss |
| Health observation | E38–E41 | Know when a host, pool or edge path is unhealthy |

The cut is provisional; Use Case Definition applies the sizing rules and may
merge or split. Application user outcomes for mail, DNS, Headscale, Authentik
and the hosted applications are not separate leaves here: their placement is
E3/E14, their reachability is E21–E26, and their user behavior belongs to the
application or `infrastructure-growth`.

## Persona reactions — advisory review lenses

- **Owner/operator:** the chain separates a declared host from an accepted
  host, and a degraded pool from restored redundancy. The risky points are
  the ones the handover already names: P1/P2 (pronix boot and NVMe), P4
  (Clevis retry), P5 (TPM), P6/P9 (Headscale), P10 (iLO prompt). The model
  does not let a green job, a configured unit or a same-host snapshot stand in
  for a reached service, a rebuilt pool or a resumed role.
- **Application user:** the chain preserves the existing boundary: reachability
  is not a grant, and a family-facing edge route does not expose other
  applications. An application user does not operate the fleet or decide its
  topology. Host recovery is not application recovery; a user's photos or
  documents are covered by the application-state topic, not by a fresh host.

## Open questions and term state

- Q4 and Q5 are closed: `adlerkopf` serves the separate `adlerhorst` LAN;
  the trio serves its own LAN and the public edge. The service placement in
  E3/E14 therefore assigns no family-facing role to `adlerkopf`, and the edge
  routes in E21–E26 belong to the trio. Cross-LAN access remains a Tailscale
  dependency, not a shared local authority.
- Candidate terms and collision checks are in `domain-terms.md`. No term is
  confirmed; no durable glossary entry is changed.

## Rendering verification — 2026-10-17

All four Mermaid sources rendered with Mermaid CLI 12.0.0 using Chromium
155.0.8059.79 from nixpkgs. Each SVG was opened in headless Chromium and
captured at 2200×2200; the four screenshots were visually inspected. Every
actor, command, configuration record, external system, policy, event and read
model label was visible, including the kind prefixes and E-numbers. The
prerequisite edges added after the first inspection (unlock readiness before
cold start, role assignment before active role, route/tunnel before
publication, replacement before state restore, storage/edge signals before
monitoring) are present in the final captures.

This is diagram syntax/layout proof, not host, storage, edge, update,
recovery or monitoring behavior. The temporary SVG/PNG render surface lives
under `/tmp/fleet-render` and is not part of the repository.
