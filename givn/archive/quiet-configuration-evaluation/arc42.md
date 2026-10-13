# arc42 Impact Assessment — quiet-configuration-evaluation

Assessment of the change against all twelve arc42 chapters, in order. A "No" is
a checked result, not an omission.

| # | Chapter | Affected | Reason / what changed |
|---|---|---|---|
| 1 | 01 introduction-and-goals | **Yes** | Requirement R1 now carries the quiet-evaluation half: an evaluation prints no superseded-default, release-mismatch or unrecognised-output diagnostic (QS-015). No goal, priority or stakeholder changes. |
| 2 | 02 architecture-constraints | **Yes** | One constraint row added: a setting whose release default a profile superseded is stated explicitly at a value the operator chose, because the immutable state version forbids adopting release defaults by raising it. |
| 3 | 03 context-and-scope | **Yes** | The chapter enumerates the flake inputs and described Colmena as a declared-but-unused path; the withdrawn `colmena` input and hive made the input list, the diagram and the fleet row stale, so all three were updated. No new external interface appears. |
| 4 | 04 solution-strategy | **Yes** | The fleet-deployment row changes: the `colmena` input and the empty `colmenaHive` output are withdrawn and re-registered with the first server; the CLI and the aliases stay. |
| 5 | 05 building-block-view | **Yes** | The flake building block and its diagram no longer list `colmenaHive`; the flake-output contract check is named instead, the assertion-module count is corrected, and the two Home-Manager-based integration checks record their guest pin. |
| 6 | 06 runtime-view | **Yes** | The fleet-deployment scenario's note claimed the hive is declared with no nodes; it now records the withdrawal and the re-registration condition. No runtime flow changes: the changed settings are evaluation/activation-time values, no service, port, unit, or boot step changes, and the booted checks keep their flow shape (boot → activation → observe). |
| 7 | 07 deployment-view | **Yes** | The Colmena hive row records the withdrawal and the re-registration condition; `thiniel` gains a Browser profile property row (`~/.config/mozilla/firefox`, persisted as `.config/mozilla`). |
| 8 | 08 crosscutting-concepts | **Yes** | The persistence concept's example list now names `.config/mozilla` instead of `.mozilla` for the browser profile. |
| 9 | 09 architecture-decisions | **Yes** | One candidate assessed and routed: NOT_QUALIFIED → canonical artifact [chapter 2](02-architecture-constraints.md) plus the change design. The register still holds exactly one ADR; no ADR file was created. |
| 10 | 10 quality-requirements | **Yes** | QS-001's check list gains `flake-output-contract`; new QS-015 records the quiet-evaluation requirement and its assertion targets. The quality tree is unchanged. |
| 11 | 11 risks-and-technical-debt | **Yes** | R-023 (the two booted checks' guests follow the unstable pin) and R-024 (the live browser relocation) added; TD-010 updated to the withdrawn hive, TD-012 trimmed of the removed Colmena comment, TD-015 added (the compositor stays on the superseded conf format deliberately). |
| 12 | 12 glossary | **Yes** | `Superseded default` added; `Colmena hive` records the withdrawal and the re-registration condition. No other term changes: the browser profile location is an instance of the new term. |

## ADR qualification outcome

Candidate: *resolve a superseded release default by an explicit value instead of
raising the profile's `home.stateVersion`.*

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
  "canonical_artifact": "docs/arc42/02-architecture-constraints.md",
  "target_adr": null,
  "replacement_adr": null
}
```

Why the two failing dimensions fail: the choice is reversible within one change
by setting the two values back (`durable_consequence`), and the complete
rationale is already owned by the existing immutable-value constraint plus the
change design's D1/D2 records (`lower_level_artifact`). The register was
searched: ADR-0001 covers private operational values and no active or archived
ADR touches release defaults or state versions, so the route is
`CANONICAL_ARTIFACT`, not an amendment.

The second decision this change makes — building the two booted-device checks
from the pin their Home Manager follows — is a test-local pairing choice with
single-change reversibility, so it fails the gate and stays in the change design
(D3).

## Files touched in this assessment

| File | Change |
|---|---|
| `docs/arc42/01-introduction-and-goals.md` | R1 evidence extended with the quiet-evaluation requirement (QS-015) |
| `docs/arc42/02-architecture-constraints.md` | New constraint row: superseded defaults are stated explicitly |
| `docs/arc42/03-context-and-scope.md` | Input list, diagram and fleet row (the `colmena` input withdrawn) |
| `docs/arc42/04-solution-strategy.md` | Fleet-deployment row rewritten (hive withdrawn, CLI kept) |
| `docs/arc42/05-building-block-view.md` | Flake diagram entry and building-block row; assertion-module count; the two Home-Manager-based checks' guest pin |
| `docs/arc42/06-runtime-view.md` | Fleet-deployment note (withdrawal, re-registration condition) |
| `docs/arc42/07-deployment-view.md` | Colmena hive row; `thiniel` Browser profile row |
| `docs/arc42/08-crosscutting-concepts.md` | Persistence example: `.mozilla` → `.config/mozilla` |
| `docs/arc42/09-architecture-decisions.md` | New NOT_QUALIFIED candidate row |
| `docs/arc42/10-quality-requirements.md` | QS-001 check list; new QS-015 |
| `docs/arc42/11-risks-and-technical-debt.md` | R-023, R-024, TD-015 added; TD-010 updated; TD-012 trimmed |
| `docs/arc42/12-glossary.md` | `Superseded default` added; `Colmena hive` updated (written during the proposal step) |
| `docs/plans/adlerkopf/01-base-os.md`, `docs/plans/adlerkopf/X-cross-cutting.md`, `docs/plans/cupix001/13-colmena.md` | The first-server step re-registers the `colmena` input and the `colmenaHive` output |

`docs/impermanence-migration-plan.md` is a completed migration record and is
left unchanged; the current declaration is carried by chapter 8.

## Status

STATUS: DONE
