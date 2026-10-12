# 1. Introduction and Goals

This chapter states who the system serves and what it must achieve. It is the
current-state baseline of the repository; where a requirement is aspirational
rather than implemented, that is said explicitly.

## Evidence status

Every claim in this documentation is labelled by the strongest evidence that
supports it:

| Label | Meaning |
|---|---|
| **Declared** | The Nix source declares it and it is rendered into a configuration. |
| **Verified** | A native verification target reproduced it (host evaluation, assertion, unit test, or a booted QEMU VM). |
| **Intended** | Accepted requirement or confirmed decision that is not implemented in the working tree. |
| **Unknown** | Not decidable from the repository. |

The distinction matters because most host configuration here is *declared*
but not *reproduced on live hardware*: `docs/GIVN-VERIFICATION.md` defines the
evaluation-time and VM tests that exist, and the repository holds no recorded
live deployment of these hosts in the working tree.

## What this system is

A single declaratively managed repository (`flake.nix`) that produces the
complete operating-system and user configuration for a small fleet:

- four NixOS hosts — `adlerkopf`, `cupix001`, `thiniel`, `nixos-vm-minimal`;
- one nix-darwin host — `J6G6Y9JK7L`;
- supporting Python tooling, reusable modules, assertion/unit/integration
  tests, and the `givn` specification workflow.

The system under development is the configuration itself. Its end product is a
set of system generations applied to hosts by NixOS/nix-darwin activation.

## Requirements overview

The confirmed requirements come from two sources, kept separate here.

### Owner requirements (confirmed, from ideation)

The ideation topic "Growing personal and family infrastructure" records the
confirmed purpose and stakeholders used in this chapter; it is the authority
for intent, not evidence that a capability exists
([topic](../ideation/infrastructure-growth.md), [resume state](../../givn/ideation/infrastructure-growth/session.md)):

| Requirement | Origin | State in this repository |
|---|---|---|
| Operate a self-hosted environment for the owner's family so members are not forced onto cloud applications. | User-confirmed purpose | **Intended** — no hosted application is deployed; no family-facing service exists in the working tree. |
| Reproducibly restore personal laptops/workstations as *usable working environments* (tools, working state, permitted identities). | Confirmed goal | **Partly implemented** — device configuration and identity selection exist ([chapter 5](05-building-block-view.md), [chapter 8](08-crosscutting-concepts.md)); required working state/version inventory is an open input (Q16). |
| Reachability is decided **per application** (internet-exposed vs. family-VPN-only). | Confirmed policy | **Intended** — no application or VPN is implemented; the netcup VPS (`cupix001`) is planned as the edge ingress gateway and is still a skeleton ([chapter 4](04-solution-strategy.md)). |
| Backup/recovery belongs to server/infrastructure setup. | Confirmed | **Intended** — no backup job exists; the only recorded stances are thiniel's explicit deferral and the unconfirmed restic plan on adlerkopf ([chapter 11](11-risks-and-technical-debt.md) TD-008). |
| Household document sharing and a household calendar are valid tasks; a photo album is the first example. | Confirmed | **Intended** — no application deployed. |

### Implemented repository requirements

The requirements the current source actually satisfies:

| # | Requirement | Evidence |
|---|---|---|
| R1 | Every host configuration evaluates and every declared gate passes in one command. | `nix flake check`; `scripts/givn-verify.sh` (**Verified** — wiring is present; see [chapter 10](10-quality-requirements.md)). |
| R2 | A host can only use identity material it declares. | `myHome.ssh` option + SSH feature + VM test `integration-ssh-identity-selection` (**Verified** for thiniel and J6G6Y9JK7L; see [chapter 8](08-crosscutting-concepts.md)). |
| R3 | Secrets are never stored in plaintext and are decrypted only on the target host. | `sops-nix` + `.sops.yaml` recipients (**Declared/Verified** for evaluation; **Unknown** on live hosts). |
| R4 | State that must survive a root wipe is declared, not assumed. | `modules/{nixos,home-manager}/persistence` options + per-host persistence lists (**Declared/Verified** at evaluation time). |
| R5 | Every change follows Red-Green-Refactor against a bound native target. | `docs/GIVN-VERIFICATION.md` + `givn/commands.yaml` hooks (**Declared process**, enforced by `scripts/givn-spec-trace.py`). |

## Quality goals

Priorities are relative within this document, not absolute business SLAs. Each
goal is elaborated into a measurable scenario in
[chapter 10](10-quality-requirements.md).

| Priority | Quality attribute | Motivation |
|---|---|---|
| 1 | Reproducibility / declarativeness | The system is configuration-as-code; there is no manual host state to reproduce. A change is only real if the configuration evaluates and the host generation builds. |
| 2 | Security of access material | Private keys and secrets are the highest-value assets. Identity selection must fail closed, secret material must be age-encrypted at rest, and secrets must never leave the machine they belong to. |
| 3 | Recoverability / auditability of change | The history of decisions, tests and hooks (`givn`, one commit per scenario, native binding tags) is the mechanism by which a change stays provable. |
| 4 | Boot determinism on stateful hosts | Root filesystems are impermanent by design; a reboot must return a known state and must not lose declared persistent state. |
| 5 | Operational safety during deployment | Server changes must be applied without physical console access (TPM2 unlock, Secure Boot, key-only SSH) and must be reversible by generation rollback. |

These goals are architecturally significant because they dictate the channel
split, the option/feature layering, the impermanence model, the SOPS wiring,
and the native verification model — all of which recur across
[chapter 4](04-solution-strategy.md) to [chapter 8](08-crosscutting-concepts.md).

## Stakeholders

Stakeholders are the confirmed personas from ideation plus concrete technical
actors. Persona IDs refer to the project-level persona files.

| Role | Expectation |
|---|---|
| Owner/operator ([`owner--operator`](../../givn/personas/owner--operator.md)) | Configures the fleet and private devices, evaluates actual operation, access and recoverability, and may help family members use applications. Is the only actor with administrative authority over the repository. |
| Family application user ([`family--application-user`](../../givn/personas/family--application-user.md)) | Uses the functions/resources granted to them, including invited outside recipients, without operating shared infrastructure. **Intended** — no hosted application exists yet. |
| Device owner (actor role in recovery flows) | Receives a reproduced working environment on the selected device. |
| Backup agent for the owner/operator (actor role) | Supports a preservation flow under the owner's delegation. **Intended** — no agent is implemented. |
| Development agents (technical) | Read the repository under the rules in `AGENTS.md` and `CLAUDE.md`; are prohibited from calling `sops`/`age`/`ssh-to-age` or reading secret material. |
| External service operators (GitHub, Bitbucket, netcup SCP, public DNS resolvers) | Supply the endpoints the configuration consumes — not stakeholders in the product sense. |
| Repository maintainer of the web of documentation | Needs a current, non-contradictory account of the fleet; this arc42 set is that account. |

## Related documents

- Functional intent and stakeholder confirmations: [`docs/ideation/infrastructure-growth.md`](../ideation/infrastructure-growth.md).
- Verification policy: [`docs/GIVN-VERIFICATION.md`](../GIVN-VERIFICATION.md).
- Module layering in prose: [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md); feature modules: [`docs/HOME-MANAGER.md`](../HOME-MANAGER.md).
- Known stale prose (not authoritative): the host inventory in `docs/ARCHITECTURE.md` and parts of `CLAUDE.md` still describe removed hosts (`pronix`) and `*-vm` variants — see [chapter 11](11-risks-and-technical-debt.md) TD-005.
