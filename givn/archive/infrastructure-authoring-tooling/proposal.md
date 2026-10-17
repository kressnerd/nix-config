# Proposal: infrastructure-authoring-tooling

## Release note

The personal laptop thiniel provides the OpenTofu and GitHub command-line tools for infrastructure authoring and repository work.

## Use-Case Context

- Use-case ID: reproduce-working-environment
- Ideation topic: none — requested directly for the personal laptop
- Seed path: none
- Confirmed Personas: owner--operator — the device owner confirmed this Persona on 2026-10-11 (user) and requested this tool set for their own laptop.

## Problem / Opportunity

The personal laptop thiniel is the owner's portable working device. It
currently carries neither an infrastructure-as-code engine nor a GitHub
command-line client. The owner therefore cannot author or inspect
infrastructure changes, nor perform repository operations that the GitHub
client exposes, from the laptop's ordinary working environment.

## Proposed Solution

The laptop thiniel provides two command-line tools in the owner's working
environment:

- an OpenTofu engine that reports its version when invoked, so
  infrastructure definitions can be evaluated and planned locally;
- a GitHub command-line client that reports its version when invoked, so
  repository work can be performed without leaving the terminal.

Both tools are available to the owner's ordinary account on a booted
device, not merely declared in the configuration. The tools carry no
credentials of their own: authentication state remains the owner's
deliberate action and is not created or persisted by this change.

## Capability Routing

`givn spec route` recommended `EXTEND quiet-configuration-evaluation`
(use case `publish-infrastructure-configuration`, lexical confidence
13.00). The recommendation is lexical: `quiet-configuration-evaluation`
governs evaluation completeness and warning freedom when publishing the
configuration, while the requested behavior is the presence of tools in the
owner's reproduced working environment.

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| infrastructure-authoring-tooling | EXTEND quiet-configuration-evaluation | `NEW in reproduce-working-environment` | The behavior is a device working-environment guarantee, not an evaluation or publication behavior. The owning use case is reproduce-working-environment, consistent with the existing rust-build-toolchain and current-agent-tooling capabilities. |

## Out of Scope

- Terraform, Terragrunt, Atmos, or any other infrastructure engine.
- Cloud provider SDKs, Kubernetes clients, or additional GitHub tooling
  beyond the GitHub command-line client.
- Creating, storing, or persisting GitHub authentication sessions or any
  other credential.
- Wiring the GitHub client as a git credential helper or changing the
  device's existing identity selection.
- Installing either tool on other hosts or on the macOS workstation.
- Graphical clients or editor extensions for Terraform/OpenTofu or GitHub.

## Open Questions

### D1 — Does the GitHub client also become the git credential helper?

- Question: When the laptop provides the GitHub command-line client, should
  it also be registered as the git credential helper for GitHub hosts, so
  git operations reuse the client's authentication session?
- Options:
  1. **Client only** — the tool is present and the owner authenticates it
     explicitly; git keeps its existing credential handling. Gain: no change
     to the device's established identity selection or credential paths;
     cost: the owner authenticates git and the client separately.
     In practice: `gh auth login` prepares the client, while `git push`
     keeps using the identity the device already declares.
  2. **Client and git credential helper** — the client is registered as the
     helper for GitHub hosts. Gain: one authentication session serves both
     tools; cost: changes how git obtains credentials and overlaps the
     device's existing identity contract.
     In practice: after `gh auth login`, `git push` authenticates through
     the client instead of the declared identity.
- Disposition: answered — the request names tooling, and the device's
  existing permitted identity selection already governs git credentials;
  registering the client as a helper would widen that contract. Option 1 is
  recorded as the boundary for this change.
