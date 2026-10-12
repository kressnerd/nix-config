# arc42 Documentation Update: private-data-remediation

## Impact assessment

| # | Chapter | Affected? | Reason | Summary of change (if Yes) |
|---|---|---|---|---|
| 1 | 01 introduction-and-goals | No | The change adds no repository goal, stakeholder, or quality attribute; the new use case's goal is recorded in its own contract (`specs/publish-infrastructure-configuration/usecase.md`). | |
| 2 | 02 architecture-constraints | Yes | The change replaces the "adlerkopf depends on a non-committed private.nix" constraint with the `git+file://` source rule and adds the stub's placeholder requirement and the guard rule. | Three technical-constraint rows added; the old private.nix row removed. |
| 3 | 03 context-and-scope | No | No external system, interface, or user-facing surface changes; the repository keeps its role and its consumers. | |
| 4 | 04 solution-strategy | Yes | Operational-data separation is a fundamental choice that shapes the whole configuration. | Key decision 9, a technology-choice row, and the intro note that one choice now qualifies as an ADR. |
| 5 | 05 building-block-view | Yes | The change adds a building block (`private-stub/`) and a support script (the guard). | Stub node and edge in the L1 diagram, a stub building-block row, the guard named in the support-tooling row, and the integration-check list extended to four. |
| 6 | 06 runtime-view | Yes | The change adds a runtime flow (values resolved at evaluation and overridden at deploy) and changes the validation and deploy flows. | New "Private operational values at evaluation and deploy time" scenario; `private-data-hygiene` added to the validation checks; the deploy trigger gains the override. |
| 7 | 07 deployment-view | Yes | The host values now come from the private input, and the deployment view carried the real addresses. | Real LAN/gateway defaults replaced with documentation-range placeholders; `private.nix` references replaced with the private input; deploy commands updated. |
| 8 | 08 crosscutting-concepts | Yes | Operational-data separation is a new cross-cutting concept with a rationale, a failure mode, and its verification. | New "Operational-data separation" section, referencing ADR-0001. |
| 9 | 09 architecture-decisions | Yes | One decision passed the qualification gate. | ADR-0001 registered; the register no longer empty. |
| 10 | 10 quality-requirements | No | No new quality scenario is introduced; the separation strengthens the existing security and reproducibility goals, which are recorded in chapters 4 and 8. | |
| 11 | 11 risks-and-technical-debt | Yes | The old private.nix risk is resolved, two new risks follow from ADR-0001's consequences, and implementation surfaced a pre-existing defect. | R-008 replaced (forgotten override); R-015 (two-repository drift), R-016 (history until the rewrite) and R-017 (pre-existing adlerkopf toplevel conflict) added. |
| 12 | 12 glossary | Yes | The change introduces durable domain terms. | Added: documentation-range placeholder, guard, operational value, per-host private-value file, private source, stub. |

## Notes

- Chapters 5, 6, 8, 12 and the ADR describe the pieces this change introduces
  (`private-stub/`, the `private` input wiring, `private-data-hygiene`,
  `integration-private-data-separation`, `ADR-0001`). They do not exist in the
  working tree until this change's tasks land; the inline markers read
  *Intended: introduced by the change `private-data-remediation`* and become
  plain declarations once the tasks land.
- The one-time history rewrite is a task of this change, not an arc42 chapter
  update: no repository check can read git history, so it is recorded as an
  operator-confirmed task (change decision D2) and as risk R-016.
- The plan document `docs/plans/private-data-remediation-plan.md` quotes the
  real values by design and stays out of the recorded tree; the durable content
  is this change's design, ADR-0001, and the chapter updates above.
- Chapter 11 also carries the "Bad, because…" consequences recorded against
  ADR-0001 (two-repository friction; the load-bearing placeholder assertion).

ADR action: NEW_ADR
ADR target: docs/arc42/adr/ADR-0001-private-data-strategy.md

```text
qualification: QUALIFIED
alternatives: PASS
architectural_impact: PASS
durable_consequence: PASS
lower_level_artifact: PASS
existing_adr_check: PASS
must_be_shared: SUPPORTING
routing: NEW_ADR
canonical_artifact: null
target_adr: null
replacement_adr: null
```

---

## Status

STATUS: DONE
