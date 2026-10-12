# Design Review: host-specific-ssh-identities

## Method

Phase 1 (grilling) ran in a fresh context: a delegated reviewer with no part in
writing the proposal, spec or design read every planning artifact and the
affected code, then returned ranked findings. Phase 2 (hardening) applied the
decisions reached; the orchestrator applied them directly and records each one
below rather than delegating a mechanical pass.

Artifacts grilled: `proposal.md`, `specs/reproduce-working-environment/usecase.md`,
`specs/reproduce-working-environment/permitted-identity-selection.feature`,
`design.md`, `arc42.md`, plus `docs/GIVN-VERIFICATION.md`, the arc42 chapters,
the affected modules, hosts, tests and flake wiring.

## Branch dispositions

| Branch | Result |
|---|---|
| Scope | No finding. The spec covers exactly the proposal: host-declared personal key, work entries only where secret material exists, includes only on the host that maintains them. Out-of-scope items (key generation/movement, MacBook effective change, include-file contents) are asserted by no step. |
| Tech choices | No finding. `myHome.ssh.personalIdentityFile` (no default) plus `myHome.ssh.includedConfigs` plus the existing `config.sops.secrets ? "git/<identity>/name"` gate is the repository's established shape. Only the two hosts that need it import the option module. |
| Missing scenarios | One low-severity gap found (the MacBook's workspace identity surface was unasserted) and closed. Error paths (a host importing the feature without declaring a key; a declared-but-absent key) are design/chapter-11 material, not spec material. |
| Testability | Verified against today's rendering: thiniel resolves `github-personal` to `~/.ssh/id_ed25519_personal_2026-10-04`, renders the three work entries and the three includes, and its workspace profile names the same foreign path — so scenarios 1, 2 and 4 are genuinely RED-able. Scenario 3 is a regression guard: its RED is the MacBook's include list, which the preceding scenario turns into a host declaration the MacBook has not yet filled. A deliberately false home-manager assertion was proven to fail the darwin toplevel evaluation, which validates scenario 3's bound target. |
| Verification binding completeness | 4 scenarios, exactly one binding tag each; `scripts/givn-spec-trace.py` exits 0; every `@check:`/`@host:` name resolves; `verify.e2e_command` differs from `verify.command`. (The count was 5 when this branch was grilled; the second hardening round below folded the module-granularity scenario into scenario 1's RED step, leaving the unit check as a target of scenario 1 in `design.md`, not a scenario.) |
| Binding coverage | Every scenario has a design row with a non-empty bound target and targeted run command. |
| Deployment & rollback | Apply command, on-host verification and rollback recorded; the rollback claim holds because `/nix` is persisted on thiniel. |
| Persona disposition | `owner--operator` (confirmed 2026-10-11): relevant, the owner is the only actor who evaluates private-repository access on their own device. `family--application-user`: not affected — no hosted application, shared resource or access grant changes. No persona is used as a Gherkin actor; no persona invented or promoted. |
| ADR qualification | NOT_QUALIFIED. Alternatives pass, `architectural_impact` borderline, `durable_consequence` fails (reversal is deleting the required option and re-inlining two paths) and `lower_level_artifact` fails (the design owns the full rationale); falsification tests 1 and 2 fail the candidate; the register is empty. Route: `CANONICAL_ARTIFACT` — single destination `design.md`. |
| arc42 chapters | Independently re-derived: Yes = 05, 08, 11, 12; No = 01, 02, 03, 04, 06, 07, 09, 10 — identical to `arc42.md`. The seven untouched chapters still hold scaffold placeholders and are deliberately out of this change's impact. |
| Ubiquitous language | `docs/arc42/12-glossary.md` holds every term the design and spec use: identity declaration, identity file, identity material, personal identity, private workspace, work identity. |

## Findings and dispositions

| # | Finding | Disposition |
|---|---|---|
| F-001 | `arc42.md` carried the assessment table but not the artifact's completion marker (`STATUS: DONE`), so `givn status` still reported `arc42-docs` as the next required artifact. | Fixed: `arc42.md` now opens with a `## Status` section containing `STATUS: DONE`. |
| F-002 | The headline scenario's `@e2e` tag had no enforcing target in the `@e2e` scope: the runner builds only `integration-*` checks, none of which touched identity selection, and no deploy-test target exists. | Resolved by operator decision (below): the capability gains a booted-device VM check, which the `@e2e` runner builds on every run. The tag moves to that scenario; the thiniel scenario keeps its `@host:thiniel` binding and the live device confirmation stays implementation evidence. Rationale recorded under "Operator decision". |
| F-003 | Scenario 3's bound target was named as the darwin-level invariants file, while this repository keeps home-manager invariants in the home-manager-level file. | Fixed: scenario 3 now binds to `tests/assertions/J6G6Y9JK7L-invariants.nix`. A probe (a deliberately false home-manager assertion) confirmed that a false home-manager assertion fails `nix eval .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath`, so the target is enforcing. |
| F-004 | The non-qualified ADR decision named two canonical homes ("this design and the capability spec"). | Fixed: `design.md` and `arc42.md` now name `design.md` alone as the rationale's canonical destination; the spec owns the observable behaviour, not the rationale. |
| F-005 | The chapter-12 impact row under-reported the glossary work (two of the four added terms). | Fixed: both rows list all six terms, including the two added under F-007. |
| F-006 | The MacBook's workspace identity configuration was asserted nowhere, although the change rewrites it for that host. | Fixed: a third `Then` was added to scenario 3 and a matching assertion to the home-manager invariants for that host. |
| F-007 | `personal identity` and `work identity` are load-bearing terms in the spec, proposal and design but had no glossary entry. | Fixed: both terms added to `docs/arc42/12-glossary.md`. |
| F-008 | Seven chapters still contain scaffold placeholders, so a literal file-integrity check fails for them. | Confirmed deliberate: the independent walk marks all seven "No" impact, and `arc42.md` now states explicitly that they are left untouched. |

## Operator decision — `@e2e` enforcement

Question put to the operator: the headline scenario was tagged `@e2e` but bound
to a host configuration evaluation that the `@e2e` runner never builds, and the
repository has no deploy-test target.

Decision: **add a booted-device VM integration check** (`integration-ssh-identity-selection`,
`pkgs.testers.runNixOSTest`) and bind the new end-to-end scenario to it, rather
than documenting the gap or adding deploy-test tooling. Applied: the check is
wired in `tests/integration/default.nix` and receives the `home-manager-unstable`
and `sops-nix` inputs from `flake.nix`; the new scenario
`A booted device reaches private repositories with the identity it declares`
carries `@givn.added @e2e @check:integration-ssh-identity-selection`. The
consequence recorded at decision time: this check boots a VM on a Linux/KVM
builder (present on thiniel), and the `@e2e` gate fails loudly on a non-Linux
host rather than passing vacuously — that is the repository's existing policy,
not something this change alters.

The `@e2e` tag consequently moves from the thiniel scenario to the booted-device
scenario. The single commit that introduced the delta spec (`2a20ef6`) already
carries the tag on the booted-device scenario, so no committed revision of this
change ever had it on the thiniel scenario, and no gate is bypassed: the `@e2e`
scope is now enforced by a real boot instead of being asserted without a target.
Keeping the tag on the host-bound scenario would have left it permanently
unenforced by the `@e2e` runner, which builds `integration-*` checks only.

## Hardening performed

- `design.md`: scenario 3's bound target and the `@e2e` scope paragraph
  corrected; the new VM check added to the verification table, the test-target
  table and the architecture-impact list.
- `specs/.../permitted-identity-selection.feature`: third `Then` on scenario 3;
  new `@e2e` scenario.
- `docs/arc42/12-glossary.md`: personal identity, work identity.
- `arc42.md`: `STATUS: DONE`, single canonical destination, all six terms, the
  explicit placeholder-chapter note.
- `givn lint`: clean. `scripts/givn-spec-trace.py`: 4 scenarios, 0 findings.

Second round, after the operator decision changed the binding plan:

- The module-granularity scenario (`@check:unit-helpers`, "The declared device
  identity reaches both connection and workspace configuration") was folded into
  the thiniel scenario's RED step. Reason: in `.feature` order it asserted no
  behaviour the host scenario does not, so once the host scenario was GREEN it
  could no longer fail — a target that already passes is not RED. The unit check
  stays in the design's test-target table as the fast target for scenario 1.
- The `@e2e` tag moved to the booted-device scenario (see the operator decision
  above).
- The scenario order in the spec is the order the tasks execute: thiniel's
  identity, thiniel's absent foreign surface, the work laptop's preserved
  surface, then the booted device.

## Sign-off

DESIGN-REVIEW: PASS
