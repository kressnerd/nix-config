# Frame: growing personal infrastructure

Status: confirmed 2026-10-11 (user) — the expanded family-infrastructure Frame is adopted for discussion/modeling only.

## User-supplied context

On 2026-10-11, the user described this repository as the Nix configuration for their laptops, workstations, and servers. It contains a growing self-hosted home lab and an edge proxy for the infrastructure and network. The user requested discussion through givn ideation. They subsequently named two outcomes: set up new applications without repeating access setup, and replace a failed server without losing its data through backups. They consider Nix's declarative configuration, combined with impermanence, the baseline for consistency and traditional server-maintenance problems.

The user then requested a revision: backups and recovery are part of server/infrastructure setup, not an optional application add-on. Recovery time has low importance because the applications serve their family rather than commercial customers. Their vision is a self-hosted "datacenter for my family" so family members do not have to use cloud services. They explicitly retain network configuration and laptop/workstation configuration/setup changes in the discussion scope.

The user then said "Adopt this revision", confirming the vision, stakeholders, scope, and priorities below without resolving the parked data-loss, network-outcome, or personal-device-outcome questions.

## Research protocol

- Ran `givn instructions`, `givn instructions dialog`, `givn status`, and `givn spec tree`.
- `givn status` reports no changes. `givn spec tree` produced no specification entries; `givn/specs/**/*` returned no files. There is no permanent specification ownership to reuse yet.
- No existing topic session or persona files were found by the ideation/persona path inventory; the topic and project persona directories were reported missing. No personas have been created or confirmed.
- Read `README.md`, Repository Structure and What's Included: describes cross-platform host configuration, shared host settings, composable user features, secrets management, and VM deployment.
- Read `docs/ARCHITECTURE.md`: describes system, host, user, and feature composition. Its listed hosts do not cover the user's full description; it is a documented structural baseline, not a complete current inventory.
- Read `docs/arc42/01-introduction-and-goals.md`, `03-context-and-scope.md`, `07-deployment-view.md`, and `12-glossary.md`: these are unfilled templates. They establish no concrete stakeholder interests, deployment boundaries, domain vocabulary, or aggregate declarations.
- Read `docs/edge-all.md`, Context, Goal, and Architecture: documents intended identity-aware ingress through cupix001 to home-lab backends, with authentication in the home lab. This is design intent, not evidence of deployed behavior. No running infrastructure was inspected.
- Reviewed `docs/plans/cupix001/07-caddy.md:1-145`: proposes common security headers, forwarded authentication, and per-application backend routes. These are existing access design records to reuse when modeling onboarding; the desired future reuse guarantee is not yet a use-case contract.
- Reviewed `docs/impermanence-migration-plan.md:1-85`: documents colocating persistence declarations with their owning features. This is a persistence design record, not failed-storage recovery evidence.
- Searched ingress behavior in `hosts/cupix001` and `modules`, then searched `forward_auth`, `reverse_proxy`, and `authentik` across `hosts/**/*.nix`, `modules/**/*.nix`, and `home/**/*.nix`: no matches in that configured-source scope. This does not establish what private configuration or live deployments contain. No deployed ingress or backup operation has been tested.
- Read-only recovery research examined `hosts/adlerkopf/impermanence.nix:20-38`, its disk/import configuration, application plans, and deployment runbook. It found explicitly persisted local state (for example `/var/lib/private/AdGuardHome`), but no application-data backup/restore implementation for that host in the examined repository configuration. `docs/plans/adlerkopf/X-cross-cutting.md` contains a backup proposal with its destination still to be confirmed. These are source-level findings, not a claim about live hosts or external/private backup arrangements; no restore drill was run.
- `hosts/adlerkopf/caddy.nix:1-10` enables Caddy with the netcup DNS plugin; this is configured source, not merely an access plan. That file does not declare application routes or identity-aware authentication. The earlier directive search does not mean no Caddy instance is configured; no live proxy behavior was verified.
- `hosts/thiniel/default.nix:546-548` explicitly records automated versioned backups as deferred and distinguishes ownCloud sync from versioned backup. This is another source-level gap note, not evidence about external backup arrangements.
- Expanded-scope documentation research distinguishes two planned network narratives: `docs/plans/adlerkopf/03-wireguard.md:1-131` describes remote-client access to the home LAN, while `docs/plans/cupix001/05-wireguard.md:1-59` describes an edge-to-home-lab tunnel. These records are design intent, not proof of live connectivity, and do not answer the user's desired new network outcomes.
- `README.md:84-127`, `docs/ARCHITECTURE.md:52-79`, and `docs/CONTAINERS.md:1-60,141-160` document operator-managed personal-device environments and development setup. They support the existing scope/vocabulary baseline, not assumptions about family members' expertise, device needs, or new personal-device goals.

## Problem and vision

Problem: grow a family-serving self-hosted infrastructure without repeating common application-access work or losing application data when a server fails, while retaining the ability to change the network and personal-device setup.

Vision: provide a self-hosted "family datacenter" that lets family members use applications without having to rely on cloud services, with the owner/operator able to evolve its servers, network, laptops, and workstations.

| Proposed goal | Observable outcome | Boundary |
|---|---|---|
| Add an application without repeating access setup | A new application becomes usable with the applicable established access rules; common access arrangements are reused rather than rebuilt. | Which arrangements are shared and which application-specific details remain is not settled. No assumption that all applications are public or share identical permissions. |
| Recover applications and data after server failure | The owner/operator can restore affected applications and their data on a replacement server using backups established as part of infrastructure setup. | Recovery speed has low priority. Under the user's explicit delegation, the assistant chooses a 24-hour recovery-point target for the photo application as a planning assumption, not a zero-loss guarantee or a universal target for every application (Q3). |
| Reproduce the usual working environment | On the chosen laptop/workstation, the owner can resume usual work with intended tools/settings, required working files/application state, and authorized identities available. | State comes from approved sources or supported re-establishment; declarations alone do not recreate unavailable data. VPN stays application-specific. No blanket credential copying or personal-data recovery-point target is assumed; the photo target is not imported (Q7/Q15). |

The actor goals now include complete usual-work readiness, application onboarding, recovery, and intended per-application reachability. They are not finalized use-case contracts, technical designs, or change seeds. Network changes remain in scope; no unrequested topology redesign, universal VPN setup, or additional actor goal is invented.

## Baseline and constraints

- Nix's declarative configuration and impermanence remain the user's baseline for consistency and host maintenance. This does not exclude changing the network or laptop/workstation setup.
- Reproducible configuration and explicitly persistent state do not by themselves demonstrate that application data can be restored after storage failure.
- Application data, required secrets/keys, and any shared access dependencies must be considered when defining recovery. The exact recovery scope remains to be modeled, not assumed implemented.
- Backup and recovery provisions belong in server/infrastructure setup. Recovery speed has low priority for this family-serving environment; no commercial-scale uptime objective or automatic failover requirement is imposed.
- Delegated photo-data assumption: at most 24 hours of recent application state lost after complete original-server/storage failure; manual recovery with no strict completion deadline. A consistent, restorable copy must survive that failure. Recent sole-copy photos may still be lost; a schedule alone does not demonstrate target compliance. Application data includes the nonreconstructible state needed for supported recovery, not just original photo files. No backup product, storage destination, retention policy, or target for other applications is selected.
- The vision is to avoid requiring family members to use cloud applications. This does not yet establish a blanket ban on external dependencies, provider hosting, or off-site backup destinations.
- No backup tool, storage destination, access mechanism, replication scheme, or availability target is selected by this Frame.

## Scope

Confirmed activity: discuss the user's idea through ideation.

Confirmed discussion scope: family-serving self-hosted infrastructure, application onboarding/common access, server setup with backup/recovery, network changes for intended application reachability, and reproducing the owner's usable personal working environment including required state/identity access. VPN is application/network work, not a mandatory base-device gate. State inventories, approved source products, platform-specific details, and implementation choices are later work; they are not permissions to copy arbitrary data or secrets. No topology, application product, personal-data recovery target, commercial commitment, or deployment is selected.

Not authorized: configuration edits, deployments, givn change creation, implementation, or promotion of personas or domain terms.

Confirmed family tasks are photo-album sharing, shared-document access, and household-calendar management, with more applications expected. Reachability is per application: some applications must be internet-accessible, while others are inside the family VPN only. In the photo example, selected outside recipients use ordinary internet access without private-network enrollment or general family-application access. The hosted application owns guest sharing/authorization; this repository supplies compatible hosting/reachability, persistent state, and backups, not application-internal functionality. No blanket edge-auth bypass, administrative exposure, or VPN-product selection is implied.

## Stakeholder inventory

| Party | Evidence | Interests | Confirmation |
|---|---|---|---|
| Repository and infrastructure owner/operator | User requests the infrastructure goals and usable usual working environment including required personal state. | Operate family infrastructure; reuse access; recover application data; resume usual work on the chosen device with required configuration, working state, and authorized identities. | Stakeholder/Frame and personal-state-inclusive readiness confirmed in Q7/Q15; no new persona or broader data authority granted. |
| Family members relying on the applications | User says family members only use operated applications, may need support, and confirms selected outside album viewers. | Use self-hosted applications; receive owner/operator help; share photo albums with selected recipients; access documents and manage a household calendar. | Stakeholder, Frame, persona, tasks, and selected guest audience confirmed. Specific application/network mechanisms remain undefined. |
| Selected outside recipients | User permits selected outside album viewers over ordinary internet access and requests a general application-user persona. | Use the application functions/resources granted to them without general access to other family applications or infrastructure. | Represented by the generalized confirmed application-user lens; access scope and reachability remain application-specific. |

The user requested a general application-user persona rather than album- or network-channel-specific segments. Reuse the confirmed nonadministrative application-user core for family members and invited recipients; application permission scope stays specific, and internet/VPN reachability is an application policy, not a persona distinction. Family support needs remain a dated stance, not proof of low technical skill or a support commitment for outsiders.

## Gaps and next action

Handoff is complete: all named outcomes, six leaf mappings and four standalone deliverable guarantees were confirmed; both persona promotions were approved/applied. The readable topic and ready seeds are published with current operating/source/product inputs explicit. Reviews and diagram/document proof establish planning quality, not deployed recovery or real work readiness. Normal proposal/spec flow starts only when the user selects a seed; no implementation, deployment, data transfer or durable glossary promotion was started.

## Frame quality review

A fresh-context reviewer checked the adopted expanded Frame and found no blocker to persona proposals. The review confirmed scope fidelity, owner/operator and family interests, backups/recovery as infrastructure, low recovery-speed priority separate from unresolved data loss, and discussion-only authority. Applied source-inventory corrections for the enabled adlerkopf Caddy instance and thiniel's deferred-backup note, without claiming implemented application routing or live recovery proof. The candidate-term first-use citation is corrected after research updates. No new human decision fork was identified; review remains advisory.

## Personal-state source inventory — source evidence, not runtime proof

A read-only scout inspected the tracked personal profiles, related feature/persistence modules, and relevant host declarations without reading secret/key/data payloads or private-flake data.

| Category | Source evidence | What it does not prove |
|---|---|---|
| Intended software/settings | `home/dan/thiniel.nix:1-82`, `home/dan/J6G6Y9JK7L.nix:1-96`, `home/dan/global/default.nix:1-17` compose different device profiles and feature modules. | Successful profile activation, availability of all external runtime dependencies, or an actual usable rebuilt device. |
| Working files | `modules/home-manager/persistence/default.nix:8-27` retains `dev` and `Projects` locally on the Linux profile when persistence is enabled. | A surviving off-device copy or recovery of uncommitted/lost work. |
| Mutable application state | Feature declarations retain browser/editor, messaging, keyring, and other application state on Linux; examples include `features/productivity/browser.nix:64-71`, `features/productivity/vscode-fhs.nix:18-25`, and `features/linux/gnome-keyring.nix:1-20`. | That every persisted cache is required, every state format is portable, or a path copy is a supported application restore. |
| Identity/bootstrap | `home/dan/thiniel.nix:55-65` consumes a locally held SOPS age key; `features/cli/ssh.nix:61-63` retains SSH state; `features/cli/sops-age-key.nix:1-7` supplies a discovery symlink. The macOS profile also references an age-key location. | Key contents exist, are accessible, survive device loss, or are escrowed; a reference/symlink is not recovery material. |
| Remote synchronization | The Linux profile imports Maestral and ownCloud features; their source declarations configure clients and local state retention. | Authentication, current remote contents, provider version history, application-consistent backup, or a tested recovery source. Sync may supply useful state but is not by itself backup proof. |
| Backup/recovery gap | `hosts/thiniel/default.nix:546-548` explicitly defers automated backups; inspected tracked declarations provide no demonstrated personal-state backup/escrow procedure. | Absence of all out-of-repo/private backups. macOS uses ordinary persistent home storage; lack of impermanence is not a claim that its files disappear on reboot. |

Exact approved datasets, source/version bindings, and independent bootstrap availability are operating/design inputs recorded in Q16. Do not infer external escrow from installed tools or apply the photo data-loss window to personal state. No personal contents, private key bytes, or provider sessions were inspected.
