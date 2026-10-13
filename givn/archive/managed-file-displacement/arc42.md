# arc42 Impact Assessment — managed-file-displacement

Assessment of the change against all twelve arc42 chapters, in order. A "No" is a
checked result, not an omission.

| # | Chapter | Affected | Reason / what changed |
|---|---|---|---|
| 1 | 01 introduction-and-goals | No | No goal, priority, stakeholder or evidence-legend change: R1 is about evaluation, and this change is about applying a configuration to a device. The quality-scenario pointer lives in chapter 10 (QS-016). |
| 2 | 02 architecture-constraints | **Yes** | One constraint row added: applying a device's configuration completes when a program rewrote a managed file, each rewrite renamed beside the rendered file and kept. |
| 3 | 03 context-and-scope | No | No external interface, input, provider or consumer boundary changes; the helper and the option are internal to the repository. |
| 4 | 04 solution-strategy | No | The key-decision table's rows are unchanged: no new component, channel or tool is adopted — Home Manager's own `backupCommand` is used with a repository helper. |
| 5 | 05 building-block-view | **Yes** | The helpers block and its diagram entry name `mkManagedFileDisplacement`; the integration-test row counts six checks and records the third Home-Manager-based guest's pin. |
| 6 | 06 runtime-view | **Yes** | The repository-validation flow enumerates the integration checks; the sixth is added. |
| 7 | 07 deployment-view | **Yes** | `thiniel`'s browser-profile property records the failure mode the change removes (the browser rewrites the registry and its search state). |
| 8 | 08 crosscutting-concepts | **Yes** | New section "Managed files and their displacement": what a managed file is, how a program's write to it is answered, and that the behaviour is declared on every device. |
| 9 | 09 architecture-decisions | **Yes** | One candidate assessed and routed: NOT_QUALIFIED → the change design plus chapter 2. The register still holds exactly one ADR; no ADR file was created. |
| 10 | 10 quality-requirements | **Yes** | QS-016 added: a program's rewrite leaves the configuration appliable, every rewrite displaced. |
| 11 | 11 risks-and-technical-debt | **Yes** | R-025 added: displacement removes the loud signal that the operator had hand-edited a managed file; the displaced copy stays visible. |
| 12 | 12 glossary | **Yes** | `Managed file` and `Displaced file` added; the `Check` enumeration names the new integration check and the change that adds it. |

## ADR qualification outcome

Candidate: *displace a managed file that a program on the device rewrote, instead
of aborting the activation.*

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
  "canonical_artifact": "givn/changes/managed-file-displacement/design.md",
  "target_adr": null,
  "replacement_adr": null
}
```

Why the two failing dimensions fail: clearing the option reverses the behaviour
inside one change and a displaced file stays where it was renamed
(`durable_consequence`), and the complete rationale — including the two rejected
Home Manager mechanisms and their source evidence — is owned by the change design
and the constraint row in chapter 2 (`lower_level_artifact`). The register was
searched: ADR-0001 covers private operational values, and no active or archived ADR
touches activation behaviour or file rendering, so the route is
`CANONICAL_ARTIFACT`, not an amendment.

## Files touched in this assessment

| File | Change |
|---|---|
| `docs/arc42/02-architecture-constraints.md` | Constraint row: a rewritten managed file is displaced, never discarded |
| `docs/arc42/05-building-block-view.md` | Helpers block and diagram entry; integration-test row (six checks) |
| `docs/arc42/06-runtime-view.md` | The six integration checks |
| `docs/arc42/07-deployment-view.md` | `thiniel` browser-profile property: the failure mode removed |
| `docs/arc42/08-crosscutting-concepts.md` | New section: managed files and their displacement |
| `docs/arc42/09-architecture-decisions.md` | New NOT_QUALIFIED candidate row |
| `docs/arc42/10-quality-requirements.md` | New QS-016 |
| `docs/arc42/11-risks-and-technical-debt.md` | New R-025 |
| `docs/arc42/12-glossary.md` | `Managed file`, `Displaced file`; check enumeration |

## Status

STATUS: DONE
