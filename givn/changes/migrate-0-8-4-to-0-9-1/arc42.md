# arc42 Impact Assessment — migrate-0-8-4-to-0-9-1

Assessment of the change against all twelve arc42 chapters, in order. A "No" is a
checked result, not an omission.

Scope assessed: the proposal, the design bundle, and `migration.yaml`. The change
migrates this repository from Givn 0.8.4 to 0.9.1: it inventories any project
rule displaced from a generated skill/command file or from the managed
`AGENTS.md` block, records surviving rules in the project-owned `extensions:` map
of `givn/config.yaml`, and verifies the installed files. The managed refresh
already landed in `9207d06`; project-owned replacements
(`givn/artifacts/*/instructions.md`, `givn/skills/*/SKILL.md.tmpl`) stay
byte-for-byte. No product module, host, flake input, secret, or deployment path
is touched.

Inventory outcome: the pre-upgrade revision `9207d06^` tracks no generated
skill or command file, the managed `AGENTS.md` block has no diff across the
upgrade, the tracked replacement templates are unchanged, and the operator
confirmed no hand edits. No displaced project rule was found, so no
`extensions:` entry is recorded and no chapter follows from this change.

| # | Chapter | Affected | Reason / what changed |
|---|---|---|---|
| 1 | 01 introduction-and-goals | No | No goal, priority, stakeholder or evidence-legend change: the product requirements and quality goals describe the host configuration, not the specification toolchain. |
| 2 | 02 architecture-constraints | No | No technical, organisational or legal constraint on the system changes. The `givn/config.yaml` hooks row stays as recorded; the migration adds no requirement a host must satisfy. |
| 3 | 03 context-and-scope | No | No external interface, input, provider or consumer boundary changes. Generated agent rule files are developer tooling on the operator's machine, outside the documented system context. |
| 4 | 04 solution-strategy | No | No component, channel, input or package source is adopted or removed. The toolchain version bump does not alter the repository's strategy table. |
| 5 | 05 building-block-view | No | No Nix module, helper, overlay, host profile or test target is added, changed or removed. The change edits only `givn/config.yaml` (and possibly nothing at all, if no rule was displaced). |
| 6 | 06 runtime-view | No | No verification, boot, identity, activation or deployment flow changes: the `verify.command` suite and the QEMU checks are untouched. |
| 7 | 07 deployment-view | No | No host, platform, fleet topology or deployment step changes. |
| 8 | 08 crosscutting-concepts | No | The documented cross-cutting concepts are product concerns (identity, persistence, secrets, packages, assertions). The spec-workflow paragraph names `givn/config.yaml` and `givn/commands.yaml` as the graph and hooks; that statement remains true and the migration adds no concept to it. |
| 9 | 09 architecture-decisions | No | No ADR qualifies. The one candidate — where displaced project rules durably live (extensions map vs project-owned replacement templates vs hand-edited generated files) — fails `architectural_impact`, `durable_consequence`, and `lower_level_artifact`; it is routed once to the change design. No register or ADR-directory change. Verdict below. |
| 10 | 10 quality-requirements | No | No quality scenario is added or re-measured. The suite and its coverage are unchanged. |
| 11 | 11 risks-and-technical-debt | No | No new risk or debt item. A dropped displaced rule would be recorded in the change inventory and design, but the migration introduces no architectural risk; the pre-0.9.0 gap (project rules kept in regenerable generated files) is what the migration closes, not a new obligation. |
| 12 | 12 glossary | No | No term is introduced: the inventory found no displaced project rule, so no `extensions:` entry is recorded and no new tooling term enters the project's vocabulary. Existing Givn workflow terms (`Binding tag`, `RED/GREEN/REFACTOR`) are unchanged. |

## ADR qualification outcome

Candidate: *record surviving project rules in the project-owned `extensions:`
map of `givn/config.yaml` instead of keeping them in generated rule files.*

```json
{
  "qualification": "NOT_QUALIFIED",
  "alternatives": "PASS",
  "architectural_impact": "FAIL",
  "durable_consequence": "FAIL",
  "lower_level_artifact": "FAIL",
  "existing_adr_check": "PASS",
  "must_be_shared": "SUPPORTING",
  "routing": "CANONICAL_ARTIFACT",
  "canonical_artifact": "givn/changes/migrate-0-8-4-to-0-9-1/design.md",
  "target_adr": null,
  "replacement_adr": null
}
```

Evidence for the failing dimensions: the decision configures one tool
(`givn/config.yaml`) and fixes no component boundary, durable contract,
dependency direction, or deployment/data boundary of the host configuration
(`architectural_impact`); undoing it is a one-change edit of that file, because
generated files are regenerable and `givn upgrade` never touches user-owned
lines (`durable_consequence`); and the complete rationale — including the two
rejected alternatives, the `local-only` policy evidence, and the replacement
templates — is owned by the change proposal and design (`lower_level_artifact`).
The active register and archived ADRs were searched: ADR-0001 covers private
operational values, and no record covers the specification toolchain, so the
route is `CANONICAL_ARTIFACT`, not an amendment or supersession.

## Files touched in this assessment

| File | Change |
|---|---|
| — | None. No chapter file and no ADR file changes; this marker is the only artifact. |

## Status

STATUS: DONE
