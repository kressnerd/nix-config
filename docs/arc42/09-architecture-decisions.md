# 9. Architecture Decisions

This file is the chapter-09 register/index for architecture decisions. It is
not an ADR body and not a container for multiple ADRs. One architecturally
significant decision gets exactly one ADR, stored as a separate Markdown file
under `docs/arc42/adr/ADR-NNNN-short-slug.md`.

The ADR directory has its own index at [`docs/arc42/adr/README.md`](adr/README.md).
The individual files are created and maintained manually; this asset does not
scaffold ADR files.

## Register

| ADR | Title | Status | Date | File |
|---|---|---|---|---|
| [ADR-0001](adr/ADR-0001-private-data-strategy.md) | Supply private operational values through an overridable flake input | accepted | 2026-10-12 | [ADR-0001-private-data-strategy.md](adr/ADR-0001-private-data-strategy.md) |

The register holds one accepted decision, from the change
`private-data-remediation`. The other foundational choices of the baseline are
still owned by their existing artifacts (see the candidate assessment below); an
empty candidate row is not a missing artifact.

## Qualification gate

Before creating a file or adding a register entry, the complete qualification
procedure from the resolved `arc42-docs` addon instruction must be applied. The
gate is a strict Boolean over five mandatory dimensions:

```text
qualification = alternatives AND architectural_impact AND durable_consequence
              AND lower_level_artifact AND existing_adr_check
```

`must_be_shared` is supporting evidence only and cannot qualify a candidate by
itself. Three falsification tests fail a candidate outright: single-change
reversibility on one component, no constraint on at least two future changes or
components, and product-behaviour that belongs to a use case plus Gherkin. If a
mandatory dimension fails, no ADR is created and the decision is routed **once**
to its canonical artifact.

## Candidate assessment for this baseline

The repository's foundational choices were checked against the gate. None
qualified, because each candidate's rationale is already completely owned by a
lower-level artifact, or because reversing it touches one component:

| Candidate decision | Alternatives | Architectural impact | Durable consequence | Lower-level artifact | Existing-ADR check | Result | Canonical artifact |
|---|---|---|---|---|---|---|---|
| Per-host identity declaration instead of hardcoded keys in a shared feature (`myHome.ssh`) | PASS (hardcoded vs declared) | PASS (host/module contract) | **FAIL** — reversible within one change, touches one capability | **FAIL** — the complete rationale is owned by the change design | PASS | **NOT_QUALIFIED** | `givn/changes/host-specific-ssh-identities/design.md`; observable behaviour in the capability spec |
| Layered composition (`hosts/common` → host options → host modules → HM profile → features) | PASS | PASS | PASS (constrains every future host/feature change) | **FAIL** — rationale and worked example already owned by documentation and the change design | PASS | **NOT_QUALIFIED** | `docs/ARCHITECTURE.md`; `givn/changes/host-specific-ssh-identities/design.md` |
| Stable/unstable channel split with a `pkgs-unstable` shim and `follows` pinning | PASS | PASS (constrains every future package choice) | **FAIL** — reversible by editing inputs | PASS | PASS | **NOT_QUALIFIED** | `flake.nix`; `lib/helpers.nix`; [chapter 2](02-architecture-constraints.md) |
| Impermanence with explicitly declared persistence (`@root-blank` / initrd wipe + persistence lists) | PASS | PASS (data boundary) | PASS (data-loss consequences) | **FAIL** — owned by the host modules, persistence modules and [chapter 8](08-crosscutting-concepts.md) | PASS | **NOT_QUALIFIED** | host modules; `modules/*/persistence`; [chapter 8](08-crosscutting-concepts.md) |
| SOPS-nix with per-host age recipients and host-key-derived age keys | PASS | PASS (secret boundary) | PASS | **FAIL** — owned by `.sops.yaml`, the host modules and the process documentation | PASS | **NOT_QUALIFIED** | `.sops.yaml`; `CLAUDE.md`; [chapter 8](08-crosscutting-concepts.md) |
| Native verification with exactly one binding tag per scenario, no step runner | PASS | PASS (system-wide quality constraint) | PASS | **FAIL** — owned by the process document and enforced by script | PASS | **NOT_QUALIFIED** | [`docs/GIVN-VERIFICATION.md`](../GIVN-VERIFICATION.md); `givn/commands.yaml` |
| A dedicated nixpkgs pin for the coding agent, separate from the host package set | PASS (dedicated pin vs rebasing the shared input, vs upstream's own flake, vs upstream's prebuilt binaries) | PASS (adds a second package source and the rule for a tool whose cadence outruns the channel) | **FAIL** — reversible within one change by pointing the module argument back at the shared set and dropping the input | **FAIL** — the complete rationale is owned by the change design | PASS | **NOT_QUALIFIED** | `givn/changes/current-omp-release/design.md` (D1, D2); [chapter 2](02-architecture-constraints.md), [chapter 4](04-solution-strategy.md) |
| A repository-owned prebuilt package for the second coding agent (OpenCode 2.x, which nixpkgs does not carry) | PASS (repository-owned prebuilt package vs upstream's own Nix packaging) | PASS (adds a package source and the rule for a tool no channel carries) | **FAIL** — reversible within one change by pointing the module at another source | **FAIL** — the complete rationale is owned by the change design | PASS | **NOT_QUALIFIED** | `givn/changes/current-opencode-release/design.md` (D1); [chapter 2](02-architecture-constraints.md), [chapter 4](04-solution-strategy.md), [chapter 8](08-crosscutting-concepts.md) |
| Declarative provisioning (disko + nixos-anywhere) and boot integrity (lanzaboote + TPM2) on servers | PASS | PASS (deployment boundary) | PASS | **FAIL** — owned by host modules and the runbook | PASS | **NOT_QUALIFIED** | `hosts/adlerkopf/{disko,secure-boot,tpm2}.nix`; [`docs/ADLERKOPF-DEPLOY-RUNBOOK.md`](../ADLERKOPF-DEPLOY-RUNBOOK.md) |
| Resolve a superseded release default by an explicit value instead of raising the profile's state version | PASS (explicit value vs raising `home.stateVersion`, which would flip every release-gated default in every profile at once) | PASS (the choice fixes how far a release's new defaults reach into the existing profiles) | **FAIL** — reversible within one change by setting the two values back | **FAIL** — the immutable-value constraint and the change design own the complete rationale | PASS | **NOT_QUALIFIED** | [chapter 2](02-architecture-constraints.md) (immutable values); `givn/changes/quiet-configuration-evaluation/design.md` (D1, D2) |
| Displace a managed file a program on the device rewrote, instead of aborting the activation | PASS (Home Manager's backup extension alone, the extension with `overwriteBackup`, a numbered rename, or a manual step) | PASS (it fixes how the configuration answers a program's write to a file it renders) | **FAIL** — reversible within one change by clearing the option; a rewritten file stays where it is | **FAIL** — the activation behaviour and its naming are owned by the change design and [chapter 8](08-crosscutting-concepts.md) | PASS | **NOT_QUALIFIED** | `givn/changes/managed-file-displacement/design.md` (D1, D2); [chapter 2](02-architecture-constraints.md) |
| Supply the GitHub fetch credential to nix through a runtime-rendered include file, instead of a configuration literal, a session environment variable, a netrc file, or a root-owned group-readable secret | PASS (a generated `nix.conf` literal, `NIX_CONFIG`/an exported variable, `netrc-file`, a root-owned file readable through an existing group, a shell wrapper exporting the variable) | PASS (it fixes where a credential may enter the system: the secret store, decrypted at activation, never a store path and never the generated configuration) | **FAIL** — reversible within one change by removing the option pair, the declarations and the include lines; the boundary it relies on (the sops-nix secret store) already exists | **FAIL** — the complete rationale is owned by the change design (custody decision, rejected alternatives, Darwin injection point) | PASS | **NOT_QUALIFIED** | `givn/changes/github-fetch-credential/design.md` |

A framework/tooling fact — "this repository uses `stylix`", "`givn` is the
specification workflow", "Colmena is the intended fleet deployer" — is a
current-state deployment/process fact, not a decision with alternatives, and is
owned by the corresponding chapter, host module, or process document.

## Individual ADR contract

Before creating a file or adding a register entry, read and pass the complete
qualification procedure from the resolved Arc42 addon instruction. This chapter
records the register contract only; it does not duplicate the qualification
formula, LLM verdict schema, or routing values. A failed candidate is routed
exactly once to its canonical feature, design, Arc42, process,
project-documentation, or code location. A refinement amends an existing ADR;
it does not create a parallel file.

Each individual file is written and tailored from the ADR template at
[`docs/arc42/adr/adr-template.md`](adr/adr-template.md). That template is
self-contained: it embeds the frontmatter contract, the Qualification gate, the
LLM qualification verdict, the MADR checklist evidence, and every required MADR
section, so it is authoritative at authoring time even when the resolved Arc42
instruction is not loaded. Use it to produce the complete MADR structure,
including `## Qualification`, `## Context and Problem Statement`,
`## Decision Drivers`, `## Considered Options`, `## Decision Outcome`,
`### Consequences`, `### Confirmation`, `## Pros and Cons of the Options`, and
`## More Information`, with real frontmatter and an `ADR-QUALIFICATION: PASS`
verdict whose route-specific target fields are valid.

Allowed statuses are `proposed`, `rejected`, `accepted`, `deprecated`, and
`superseded by ADR-NNNN`. A superseded status must name a concrete existing
replacement ID, such as `superseded by ADR-027` or `superseded by ADR-0042`;
placeholders are invalid in completed ADRs. Keep
[`docs/arc42/adr/README.md`](adr/README.md) and this register linked to the
current or historical file.

## Archive

An archived historical ADR keeps its ID and filename and is moved to
`docs/arc42/adr/archive/ADR-NNNN-short-slug.md`. Update both indexes when the
path changes. Do not move ADRs into `givn/archive/<change>/`; that path is for
change artifacts, not durable architecture decisions.
Non-ADR material is not archived as an ADR. Move useful information once to its
canonical feature, design, Arc42, process, project-documentation, or code
location, and remove the redundant record.
