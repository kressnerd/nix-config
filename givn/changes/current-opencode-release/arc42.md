# arc42 Impact Assessment — current-opencode-release

Assessment of the change against all twelve arc42 chapters, in order. A "No" is
a checked result, not an omission.

| # | Chapter | Affected | Reason / what changed |
|---|---|---|---|
| 1 | 01 introduction-and-goals | **Yes** | The "reproducibly restore usable working environments" row now names the coding agents' version floors (plural) as the first supplied requirements out of the open inventory (Q16). No goal, quality goal or stakeholder changes. |
| 2 | 02 architecture-constraints | **Yes** | One technical constraint added: a tool that no channel carries at the required version is packaged in this repository, pinned by version and a checksum per platform, with a per-device version floor (OpenCode 2.x in `overlays/opencode`). The existing nixpkgs-input constraint (omp) is unchanged; the guardrails convention stays scoped to the guarded agent. |
| 3 | 03 context-and-scope | No | No new external interface: the npm registry source the overlay fetches from already exists, and OpenCode's MCP servers are already recorded. The repository-owned package is not a flake input, so the technical-context input table is unchanged. |
| 4 | 04 solution-strategy | **Yes** | New key decision 11: a repository-owned package for the second coding agent, with the rejected alternative (upstream's own Nix packaging, source build without an advertised cache). |
| 5 | 05 building-block-view | **Yes** | New Level-3 entry for `home/dan/features/development/opencode.nix` (required package argument, the global config, the key exports, its two importers). |
| 6 | 06 runtime-view | No | No new runtime flow: the change alters a package version and an assertion floor, and the booted check's flow shape (boot → activation → run the declared binary) already exists. The guard scenario is omp's and is unchanged. |
| 7 | 07 deployment-view | **Yes** | The "Coding agent" property row of both `thiniel` and `J6G6Y9JK7L` now names OpenCode, its source and its asserted floor. No topology, disk, boot or service change. |
| 8 | 08 crosscutting-concepts | **Yes** | The package-source concept gains a fourth entry: a repository-owned, hand-pinned prebuilt package for a tool no channel carries, with its failure mode (nothing signals a newer release) and a pointer to R-022. |
| 9 | 09 architecture-decisions | **Yes** | One candidate assessed and routed: NOT_QUALIFIED (`durable_consequence` and `lower_level_artifact` fail) → canonical artifact `givn/changes/current-opencode-release/design.md` (D1). The register still holds exactly one ADR; no ADR file was created. |
| 10 | 10 quality-requirements | **Yes** | QS-014 generalised: both agents' floors (`omp` `18.10`, OpenCode `2.0.28`) are asserted at evaluation time and observed on the booted VM that now carries both. The quality tree is unchanged. |
| 11 | 11 risks-and-technical-debt | **Yes** | R-022 added: the OpenCode package is hand-pinned and nothing signals a newer upstream release, so the floor assertions catch a regression but not staleness. |
| 12 | 12 glossary | **Yes** | Three entries: "Coding agent" now names both agents the devices carry (Oh My Pi (omp) and OpenCode) instead of omp alone; "Agent version floor" names both floors (`18.10` for omp, `2.0.28` for OpenCode); "Model server (MCP server)" records where each agent declares its servers. No new term: OpenCode is an instance of the existing term. |

## ADR qualification outcome

Candidate: *a repository-owned prebuilt package for OpenCode 2.x, which no
channel carries.*

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
  "canonical_artifact": "givn/changes/current-opencode-release/design.md",
  "target_adr": null,
  "replacement_adr": null
}
```

## Files touched in this assessment

| File | Change |
|---|---|
| `docs/arc42/01-introduction-and-goals.md` | Requirement row: coding agents' version floors (plural) |
| `docs/arc42/02-architecture-constraints.md` | New technical constraint row (repository-owned package + floor) |
| `docs/arc42/04-solution-strategy.md` | New key decision 11 |
| `docs/arc42/05-building-block-view.md` | New Level-3 entry for the OpenCode feature module |
| `docs/arc42/07-deployment-view.md` | Both hosts' coding-agent property rows |
| `docs/arc42/08-crosscutting-concepts.md` | Fourth package source |
| `docs/arc42/09-architecture-decisions.md` | New NOT_QUALIFIED candidate row |
| `docs/arc42/10-quality-requirements.md` | QS-014 generalised to both agents |
| `docs/arc42/11-risks-and-technical-debt.md` | New risk R-022 |
| `docs/arc42/12-glossary.md` | "Coding agent", "Agent version floor" and "Model server (MCP server)" name both agents |
