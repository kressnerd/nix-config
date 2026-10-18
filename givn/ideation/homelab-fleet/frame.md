# Frame: operating the home datacenter fleet

Status: confirmed 2026-10-17 (user) — the Frame is adopted for discussion and
modeling only; it authorizes no configuration, deployment, secret operation or
givn change. `adlerkopf` remains a separate fourth host outside this topic's
change boundary (Q1).

## User-supplied context

On 2026-10-17 the user supplied a German architecture handover ("Homelab-
Architektur pronix / tinix001 / cupix001") and asked to align the repository's
existing first ideas with it. The handover names three hosts:

- `pronix` — storage and infrastructure host; Xeon E3-1265L v2, 16 GB ECC,
  one 512 GB SATA SSD in the ODD port, four 1 TB SATA SSDs in the bays, two
  2 TB NVMe on a PCIe card, two 1 GbE ports and iLO 4. It boots BIOS/GRUB from
  a microSD card, unlocks LUKS through Clevis/Tang with an initrd-SSH and iLO
  serial-console fallback, and exports NFS and Samba.
- `tinix001` — compute host; i7-8700T, 64 GB, two 1 TB NVMe, one 1 GbE port and
  a currently installed RX550 the handover recommends removing. It runs the
  applications, databases, Headscale, Tang and the secondary DNS resolver, and
  unlocks LUKS by TPM2.
- `cupix001` — existing netcup VPS; the public edge with WireGuard, Caddy,
  DERP, an inbound mail MTA and Gatus.

The handover also supplies the VLAN/IP plan, naming, fixed UIDs/GIDs, update
windows, per-host phase structure, open verification points (P1–P10) and
explicit decisions D1–D16. These are design intent from the user. They are
**not** verified hardware inventory, deployed configuration or observed
runtime behavior.

## Research protocol

Commands and sources inspected before this draft:

- `givn instructions`, `givn instructions ideation`,
  `givn instructions dialog`, `givn instructions domain-modeling`,
  `givn status`, `givn spec tree`.
- `givn status` reports no active change and ten archived changes.
  `givn spec tree` reports exactly two permanent use cases:
  `publish-infrastructure-configuration` (operational-data separation, quiet
  evaluation) and `reproduce-working-environment` (agent tooling, GitHub fetch
  credential, authoring tooling, managed-file displacement, identity
  selection, Rust toolchain). **No permanent use case owns host provisioning,
  boot/unlock, storage redundancy, edge ingress, fleet updates or host-state
  recovery.**
- `docs/arc42/01-introduction-and-goals.md`, `03-context-and-scope.md`,
  `07-deployment-view.md`, `09-architecture-decisions.md`,
  `12-glossary.md`: current-state baseline. It declares `adlerkopf`,
  `cupix001`, `thiniel`, `nixos-vm-minimal` and `J6G6Y9JK7L`; it calls
  `cupix001` a skeleton with no services and calls `pronix` a removed host
  whose prose is stale.
- `docs/ARCHITECTURE.md`: older structural baseline; its host list is known
  stale and does not include `pronix` or `tinix001`.
- `hosts/adlerkopf/`: declared home server (Lenovo M720q, one NVMe, LUKS2,
  btrfs impermanence, systemd-boot plus lanzaboote Secure Boot, TPM2 unlock,
  key-only SSH, Caddy with the netcup DNS plugin, AdGuard Home). It is a
  declaration; no live deployment is recorded.
- `docs/plans/adlerkopf/00-index.md` and `01-base-os.md`: the "first idea" for
  the home server. Phases are marked pending; the plan assumes one NVMe,
  systemd-boot/UKI and TPM2.
- `hosts/cupix001/`: declared VPS skeleton (hostName, firewall on, sops,
  disko, no services, no VPN, no ingress).
- `docs/plans/cupix001/00-index.md`, `docs/edge-all.md`,
  `docs/CUPIX001-DEPLOYMENT.md`: the "first idea" for the edge. They describe
  Caddy forward-auth, DERP, WireGuard, CrowdSec and nftables, largely not
  implemented; the plan set itself marks the phase state as in progress.
- `docs/ideation/infrastructure-growth.md` and
  `givn/ideation/infrastructure-growth/`: handoff-complete ideation for
  family applications, per-application reachability, application-state
  protection/recovery and personal-work reproduction. Its goals remain valid;
  it does not model host provisioning.
- `givn/personas/owner--operator.md` and
  `givn/personas/family--application-user.md`: the two confirmed review lenses.
- `docs/ideation/secure-token-keys.md`: unrelated topic; no reuse needed.
- `flake.nix`: declared inputs include `disko`, `sops-nix`, `impermanence`,
  `lanzaboote` and `nixos-anywhere`; no `pronix` or `tinix001` host output
  exists. No Colmena hive is declared.
- `git log --oneline -15`: recent work is documentation/tooling, not host
  provisioning.

Gaps established by the inventory:

1. The repository has no `hosts/pronix` or `hosts/tinix001`, and no
   permanent spec for provisioning either.
2. The existing home-server plan targets `adlerkopf`; the handover targets
   `pronix` and `tinix001` and never mentions `adlerkopf`.
3. The cupix001 edge plan and `docs/edge-all.md` describe a partly different
   edge stack (CrowdSec, nftables, Nginx in the historical document, Caddy in
   the plan set) from the handover (Caddy, DERP, Postfix MTA, Gatus).
4. The arc42 deployment view and the README/CLAUDE host inventory disagree
   with both the working tree and the handover.
5. No host-level use case exists for boot/unlock, storage-device failure,
   fleet updates, mail ingress or off-site host-state recovery.

## Problem and vision

**Problem.** The repository's first ideas describe one home server
(`adlerkopf`) and one edge gateway (`cupix001`). The current design adds a
storage/infrastructure host (`pronix`) and a compute host (`tinix001`) while
keeping `adlerkopf` as a separate fourth host, with `cupix001` as the only
public entry. The existing adlerkopf plans, cupix001 plans, arc42 baseline and
ideation topic therefore disagree about which hosts exist, what each owns, and
how the new hosts are provisioned, unlocked and recovered. Without one current
account, a proposal cannot bind to a real target and the owner cannot tell
which plan is authoritative.

**Vision.** The owner can provision each of the three named hosts from the
declarative repository, boot it without an on-site keyboard in the intended
failure modes, keep family data across a failed storage device, run the
family applications on the compute host, expose only the selected edge
services to the internet, and recover a host and its declared state after a
failure. The three named hosts have one vocabulary, one identity/UID
convention and one update order. `adlerkopf` remains a separate host with its
existing plans; the topic records it only where a shared service or transition
affects the trio.

The problem is hosting infrastructure, not application behavior: the
applications, their native sharing logic and the family's use of them remain
owned by the existing `infrastructure-growth` topic.

## Scope

### In scope

- Host lifecycle for `pronix`, `tinix001` and `cupix001`: provisioning from
  the flake, disk layout, boot mode, encrypted-root unlock, first boot,
  rebuild/update and retirement.
- Host roles and service placement: storage exports, application host,
  public edge, DNS pair, Tang, Headscale, mail split, monitoring and backup
  staging.
- Network segmentation and reachability between LAN, storage VLAN, management
  VLAN, WireGuard edge link and Tailscale/Headscale.
- Declared persistent state and recovery provisions at host level.
- Fleet-wide conventions: fixed UIDs/GIDs, repository layout, naming,
  update windows, secrets distribution.
- Reconciliation of the existing first-idea documents (adlerkopf plans,
  cupix001 plans, edge-all, arc42 host inventory) with the current trio,
  recording which of their choices the trio supersedes and which remain
  `adlerkopf`-specific.

### Out of scope

- Application-internal features, family sharing/authorization logic, photo
  album behavior, document editing and calendar functions. Those stay with
  the hosted applications and the `infrastructure-growth` topic.
- Personal laptops/workstations (`thiniel`, `J6G6Y9JK7L`) and the personal
  working-environment goal.
- Changes to `adlerkopf`. It remains a separate fourth host with its existing
  declarations, runbook and plan set. The topic records it only where a
  shared service, duplicated role or transition affects the trio; no
  `adlerkopf` generation, migration or retirement is authorized.
  `adlerkopf` serves the separate `adlerhorst` LAN and is reachable only
  through Tailscale over a slow internet connection (Q5); the trio serves its
  own LAN.
- Hardware procurement, physical racking and cabling. Firmware/hardware
  checks are preconditions or subfunctions, not actor goals.
- Actual deployment, secret generation, data migration or live verification
  during ideation.
- Selection of a commercial backup destination, mail reputation provider or
  router model beyond the handover's stated assumptions.

## Stakeholders and interests

| Party | Interest | Evidence | Confirmation |
|---|---|---|---|
| Owner/operator | Provisions, unlocks, operates, updates and recovers the three hosts; judges whether the fleet matches the intended architecture. Has administrative authority over the repository. | User supplies the architecture and asks to align the repository. | Confirmed reuse (Q2): `owner--operator`. |
| Family application users | Use the applications hosted on `tinix001` through their permitted paths. Do not operate the fleet or choose its topology. | `infrastructure-growth` confirmed the family-serving purpose and application-user role. | Confirmed reuse (Q2): `family--application-user`. |
| Selected outside recipients | Reach specifically granted application resources through `cupix001` without general family-network access. | `infrastructure-growth` confirmed selected outside recipients and ordinary-internet guest sharing. | Confirmed reuse (Q2): same application-user lens. |
| External service operators (netcup, DNS, off-site backup target) | Supply the VPS account, public DNS/PTR and a restic-compatible destination. They have no administrative role in this repository. | User-supplied assumptions A5–A8. | External dependencies, not personas. |

Stakeholders who never touch the system but have an interest: family members
whose data is stored on `pronix`/`tinix001`. They are represented by the
application-user lens; no new data-ownership authority is inferred.

## Baseline and constraints

These are the handover's current design details. They are recorded as
constraints for modeling, not as verified facts.

### Hardware and role

| Host | Role | Distinguishing property |
|---|---|---|
| `pronix` | Storage and infrastructure | BIOS/GRUB from microSD, LUKS2, btrfs multi-device RAID1, two NICs, iLO. |
| `tinix001` | Compute and applications | TPM2 unlock, impermanent root, two NVMe, one NIC with a storage VLAN subinterface, iGPU. |
| `cupix001` | Public edge | netcup VPS, public IPv4/IPv6, WireGuard to `tinix001`, Caddy/DERP/mail MTA. |
| `adlerkopf` | Separate fourth host, outside this topic | Lenovo M720q, one NVMe, LUKS2, TPM2, impermanence, AdGuard and Caddy in the existing declaration. Kept per Q1; no change is modeled here. It serves the separate `adlerhorst` LAN (local applications and DNS), reachable only through Tailscale over a slow internet connection (Q5). |

`tinix002`/`tinix003` are reserve machines outside this plan.

### Supplied decisions

- Storage stack `disk → LUKS2 → btrfs` with RAID1 data and metadata; no
  MergerFS/SnapRAID; three pools on `pronix` (OS, appdata, media).
- `pronix` boots BIOS/GRUB from microSD with an unencrypted `/boot`.
- `pronix` unlocks through Clevis/Tang (Tang on `tinix001`) with initrd-SSH
  and iLO serial-console fallback; `tinix001` unlocks through TPM2.
- No KVM guests and no DMZ in the home network; `cupix001` is the only edge.
- Applications run host-native as NixOS modules; OCI containers only when no
  module exists.
- Databases stay local to `tinix001`; they are never placed on NFS.
- Headscale runs on `tinix001`; DERP runs on `cupix001`.
- A static WireGuard tunnel connects `cupix001` and `tinix001`.
- Mail splits: inbound MTA on `cupix001`, Dovecot/submission on `tinix001`.
- AdGuard runs on both `pronix` (primary) and `tinix001` (secondary).
- Impermanence starts on `tinix001`; `pronix` may get it later.
- The RX550 is removed; the iGPU serves Jellyfin/Immich.
- The network stays 1 GbE.

### Supplied open assumptions

A1 VLAN-capable router/switch; A2 both NVMe visible behind the PCIe card;
A3 TPM 2.0 on `tinix001`; A4 `cupix001` runs or can migrate to NixOS;
A5 outbound port 25 allowed; A6 controllable domain/DNS/PTR; A7 500 GB today,
+250 GB/year; A8 an off-site restic-compatible target exists.

### Supplied verification points

P1 both NVMe visible on `pronix`; P2 Gen8 boots GRUB from microSD; P3 NIC
kernel module; P4 Clevis retry when Tang is unreachable; P5 TPM 2.0 on
`tinix001`; P6 Headscale end-to-end encryption through Caddy TLS; P7 outbound
port 25 and PTR at netcup; P8 Seafile share URL pattern; P9 Headscale behavior
during a long control-plane outage; P10 iLO VSP shows the LUKS prompt.

## Boundary with `infrastructure-growth`

| Question | Owner |
|---|---|
| Can a family member use a hosted application through its permitted path? | `infrastructure-growth` (`make-application-available`, `adjust-application-reachability`, `access-shared-information`). |
| Is application state protected and recoverable after server failure? | `infrastructure-growth` (`preserve-recoverable-application-state`, `recover-hosted-applications`). |
| Is a host provisioned, unlocked, updated, storage-redundant and reachable as a host? | This topic. |
| Which host runs an application and how does its data reach that host? | This topic supplies placement/storage; `infrastructure-growth` supplies the application outcome. |
| Can the owner reproduce a personal working environment? | `reproduce-working-environment` permanent spec; outside this topic. |

Application availability is not claimed by provisioning a host. Host
provisioning is not claimed by making an application available. A change seed
from this topic may be a dependency of an application seed, but it must not
silently absorb that seed's application, access or recovery guarantee.

## Gaps and next action

Q1 is closed: `adlerkopf` remains a separate fourth host and is outside this
topic's change boundary. The Frame is confirmed (2026-10-17): it models the
three named hosts only. The existing `adlerkopf` plan set stays authoritative
for that host; it is not a template that the trio silently inherits. The
handover's hardware and assumptions remain unverified.

Next: Event Storming is complete; Q4/Q5 place `adlerkopf` in the separate
`adlerhorst` LAN and the trio in its own LAN. Use Case Definition starts after
the fresh-context reviews. The handover's hardware and assumptions remain
unverified.

### Frame quality review

Pending a fresh-context review. Findings are advisory; the user arbitrates.
