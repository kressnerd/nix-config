# arc42 Impact Assessment — current-omp-release

Assessment of the change against all twelve arc42 chapters, in order. A "No" is
a checked result, not an omission.

| # | Chapter | Affected | Reason / what changed |
|---|---|---|---|
| 1 | 01 introduction-and-goals | **Yes** | The "reproducibly restore usable working environments" requirement row now records that the coding agent's version floor is the first version requirement supplied out of the open inventory (Q16). No goal, quality goal or stakeholder changes. |
| 2 | 02 architecture-constraints | **Yes** | Two rows added: a technical constraint (a tool whose cadence outruns the channel gets its own nixpkgs input and a declared version floor — `nixpkgs-agent` plus the per-device floor assertion) and a convention (a device that carries the agent also carries the secret-access guard, installed as a regular file). |
| 3 | 03 context-and-scope | **Yes** | `nixpkgs-agent` added to the flake-input set in the technical-context diagram and table; the coding agent's two model servers (`context7`, `kagi-search`) recorded as an external interface now consumed from both devices, with the key-less-device behaviour observed by the booted check. No new scope boundary. |
| 4 | 04 solution-strategy | **Yes** | New key decision 10 (a dedicated pin for the fast-moving coding agent, with the package — not a package set — passed to the module); decision 2's unstable list no longer names the agent. |
| 5 | 05 building-block-view | **Yes** | New Level-3 entry for the agent feature module (package argument, server declaration, guard activation, its two importers); the tests inventory gains the guard driver check and the fifth VM check. |
| 6 | 06 runtime-view | **Yes** | New scenario "A coding-agent tool call meets the secret-access guard" (verdict flow, steps, and what is deliberately not proven). |
| 7 | 07 deployment-view | **Yes** | "Coding agent" row added to the property tables of `thiniel` and `J6G6Y9JK7L` (source pin, floor, servers, guard). No topology, disk, boot or service change. |
| 8 | 08 crosscutting-concepts | **Yes** | Dual-channel concept extended with the third, single-package source and its refresh command; a "refusal at the tool boundary" bullet added to error handling; the testability concept notes the guard verdict check as a fourth kind of check. |
| 9 | 09 architecture-decisions | **Yes** | One candidate assessed and routed: NOT_QUALIFIED (`durable_consequence` and `lower_level_artifact` fail) → canonical artifact `givn/changes/current-omp-release/design.md` (D1, D2). The register still holds exactly one ADR; no ADR file was created. |
| 10 | 10 quality-requirements | **Yes** | New scenario QS-014 (agent version floor, asserted and observed on a booted VM); QS-013's status updated to name the supplied version requirement. The quality tree is unchanged (no new quality goal). |
| 11 | 11 risks-and-technical-debt | **Yes** | R-018 (pin staleness), R-019 (master-pinned source bringing an unreviewed change), R-020 (guard check mirroring the hook event shape), R-021 (the guard's glob coverage misses the user-side sops-nix secret directory, found while implementing the guard check) and TD-014 (no target exercises a live-session refusal). |
| 12 | 12 glossary | **Yes** | Terms added: `Coding agent`, `Secret-access guard` (contrasted with the existing `Guard`, the repository hygiene rule), `Agent version floor` and `Model server (MCP server)`; the `Check` row now lists the two checks this change adds. |

## ADR qualification outcome

Candidate: *a dedicated nixpkgs pin for the coding agent, separate from the host
package set.*

```json
{
  "qualification": "NOT_QUALIFIED",
  "alternatives": "PASS",
  "architectural_impact": "PASS",
  "durable_consequence": "FAIL",
  "lower_level_artifact": "FAIL",
  "existing_adr_check": "PASS",
  "must_be_shared": "SUPPORTING",
  "routing": "CANONICAL_ARTIFACT",
  "canonical_artifact": "givn/changes/current-omp-release/design.md",
  "target_adr": null,
  "replacement_adr": null
}
```

Evidence: the alternatives are the dedicated pin, rebasing the shared
`nixpkgs-unstable` input, upstream's own flake, and upstream's prebuilt release
binaries (proposal D1, design D2). The pin adds a second package source to the
flake graph, which is why `architectural_impact` passes. It fails
`durable_consequence` because it is reversed inside one change by pointing the
module argument back at the shared package set and dropping the input; it fails
`lower_level_artifact` because the complete rationale (including the rejected
alternatives and the measured substitutability of both platforms) is owned by
the change design. The existing register was searched before proposing a new ID:
no record covers package-source pinning. Route: `design.md` (D1, D2) plus
chapter 2 and chapter 4, recorded once.

## Diagram policy

Every diagram touched by this assessment is a Mermaid fenced block (chapter 3's
context flowchart, chapter 6's sequence diagram). Chapter 7's fleet topology
remains the static inline SVG that the chapter already used, untouched by this
change.

## Status

STATUS: DONE
