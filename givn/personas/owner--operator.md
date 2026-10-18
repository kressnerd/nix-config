# Persona: hands-on infrastructure owner/operator

ID: owner--operator
Status: confirmed 2026-10-11 (user)

## Role

Hands-on owner/operator of the family-serving self-hosted infrastructure and their personal devices.

## Authority boundary

Changes server, network, application-access, and personal-device configuration. This does not imply unrestricted authority over other family members' personal data.

## Evaluation capability

Judges configuration changes, working access, and evidence that application data is recoverable. A successful backup job alone is not proof of restore.

## Own vocabulary

Applications, Nix, declarative configuration, impermanence, access setup, backups, recovery, servers, network, laptops, and workstations.

## Success criterion

Can make intended configuration changes and establish whether the resulting behavior and recovery meet the agreed requirements.

## Running record

- 2026-10-11 — Confirmed core from growing personal infrastructure

Source: the infrastructure-growth topic's operator-profile confirmation (Q8), where the user said "Adopt this profile". This is a review lens, not implemented permissions or authority to copy unrelated data. The complete topic-local history remains at givn/ideation/infrastructure-growth/personas/owner--operator.md; draft review findings and earlier superseded pending-question statements are not made project-wide defaults by this record.
- 2026-10-17 — Homelab-fleet host boundary

Source: the homelab-fleet topic's confirmed Frame, Q1 and Q4/Q5. `adlerkopf` remains a separate fourth host serving the `adlerhorst` LAN (local applications and DNS), reachable only through Tailscale over a slow internet connection. The trio (`pronix`, `tinix001`, `cupix001`) serves its own LAN and the public edge. Host recovery restores a host's role and persistent system state; application-state recovery and application access remain separate. This is a review stance, not a change to the stable core or an implementation authorization.

## Topic stances

### 2026-10-11 — Growing personal infrastructure

Confirmed direction from the infrastructure-growth Frame and application/reachability discussions: add family-serving applications without repeating common access setup; include backups and recovery in server/infrastructure setup; select internet or family-VPN-only reachability per application. Native applications own their sharing/authorization behavior; selected photo recipients use ordinary internet without general family/private-network access. These topic stances do not select a product, topology, blanket authentication bypass, or new access rights.

### 2026-10-11 — Family application-use support

The user states that family members use applications they operate and may need their help using them. No custom support product, response-time promise, outsider support obligation, or infrastructure-administration authority for family members is inferred.

### 2026-10-11 — Delegated photo recovery-point baseline

The user delegated a sensible choice for photo-data recovery. The assistant selected a 24-hour recovery-point planning target, with manual recovery and no strict completion deadline. This is not a numerical tolerance supplied by every stakeholder, a zero-loss guarantee, a production proof, or a target for every application/personal device. Recent sole-copy uploads or changes may be lost. Real supported consistent state, surviving bootstrap and verified restoration remain required.

### 2026-10-11 — State-inclusive usual working environment

The user explicitly requires a usable usual personal working environment including required files/application state and permitted identities. Software/settings-only completion is rejected. Use approved sources and supported retrieval/restoration or identity re-establishment; missing material means not ready, not fabricated data or blanket credential cloning. VPN remains an application requirement rather than a universal base-device gate. No personal-data loss window or new source product is chosen.

### 2026-10-17 — Homelab-fleet host boundary

The fleet topic's confirmed Frame places `adlerkopf` in the separate `adlerhorst` LAN, reachable only through Tailscale over a slow internet connection, and the trio (`pronix`, `tinix001`, `cupix001`) in its own LAN with the public edge. The owner lens reviews host provisioning, unattended boot, storage redundancy, edge publication, updates, host recovery and health as host-level outcomes. It does not merge application availability, application-state recovery or personal-device readiness into those claims. No deployment, secret operation or change is authorized by this stance.
