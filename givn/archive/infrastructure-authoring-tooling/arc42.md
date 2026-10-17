# arc42 Documentation Update: infrastructure-authoring-tooling

## Impact assessment

| # | Chapter | Affected? | Reason | Summary of change (if Yes) |
|---|---|---|---|---|
| 1 | 01 introduction-and-goals | No | The change adds no goal, stakeholder, or quality goal; it furnishes an existing working-environment goal. | |
| 2 | 02 architecture-constraints | No | No legal, technical, or organisational constraint is introduced or relaxed. | |
| 3 | 03 context-and-scope | No | No external system or interface is added; the tools are local command-line programs. | |
| 4 | 04 solution-strategy | No | The package-selection strategy is already covered by the feature-module approach; no major technical strategy changes. | |
| 5 | 05 building-block-view | Yes | A new feature module joins the `cli/` inventory and thiniel imports one more module. | `cli/` count 14 → 15 with `infrastructure-tooling`; thiniel profile import count 42 → 43. |
| 6 | 06 runtime-view | No | No runtime flow, service, or boot sequence changes; tools are invoked on demand. | |
| 7 | 07 deployment-view | No | Host topology and node roles are unchanged. | |
| 8 | 08 crosscutting-concepts | No | The change deliberately leaves identity selection and secrets untouched; no cross-cutting concept changes. | |
| 9 | 09 architecture-decisions | No | Package selection has no durable architectural boundary; it is owned by the change design. No ADR is created (see verdict below). | |
| 10 | 10 quality-requirements | No | No quality scenario or threshold is added or changed. | |
| 11 | 11 risks-and-technical-debt | No | The change is additive and reversible within one apply; it introduces no new risk or debt. | |
| 12 | 12 glossary | No | The terms OpenTofu and GitHub CLI are ordinary product names, not project domain terms. | |

## Notes

ADR action: NONE
ADR target: none

qualification: NOT_QUALIFIED
alternatives: PASS — design.md compares the feature module against inline host packages and cloud-tools, and `pkgs.opentofu` against `tenv`, and `pkgs.gh` against `programs.gh`.
architectural_impact: FAIL — choosing two packages installs no component boundary, ownership boundary, durable contract, deployment/data boundary, or system-wide quality constraint.
durable_consequence: FAIL — reversal is a package-list edit plus one apply; no migration, interface change, or cross-component coordination.
lower_level_artifact: FAIL — the complete rationale is owned by the capability spec and `design.md`; an ADR would duplicate them.
existing_adr_check: PASS — searched `docs/arc42/09-architecture-decisions.md` and `docs/arc42/adr/`; only ADR-0001 (private-data strategy) exists and it does not cover package selection.
must_be_shared: FAIL — a contributor does not need this package choice to avoid violating a fundamental architecture rule.
routing: CANONICAL_ARTIFACT
canonical_artifact: design.md
target_adr: none
replacement_adr: none

---

## Status

STATUS: DONE
