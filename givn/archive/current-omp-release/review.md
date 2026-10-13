# Review: current-omp-release

## Method

A delegated reviewer (`reviewer`, fresh context, no part in writing the change)
performed the fabrication audit, the arc42 implementation-conformance check, the
ubiquitous-language check, the overlap dispositions, the gap classification and
the README impact decision against the artifacts, the implementation and the
seven revisions of this change. The orchestrator ran the two gate runners on the
working tree and records their output below. Findings were remediated before
sign-off; nothing was deferred.

Revisions of this change (`git log --oneline 270ed64^..HEAD`):

| Revision | Scenario / purpose | Configuration files touched |
|---|---|---|
| `270ed64` | The personal laptop carries a current, guarded coding agent (+ T1 plumbing: guard check and driver, booted check registration, the pin) | `flake.nix`, `flake.lock`, `home/dan/features/development/omp.nix`, `tests/unit/hm-dev-modules-test.nix`, `tests/assertions/thiniel-invariants.nix` |
| `dfb3b42` | The work MacBook carries the personal laptop's current, guarded coding agent | `flake.nix`, `home/dan/J6G6Y9JK7L.nix`, `tests/assertions/J6G6Y9JK7L-invariants.nix` |
| `b615254` | A decryption attempt is refused… / Ordinary repository work passes the guard | none (specifier only: the two `@wip` removals; see F-REV-1) |
| `2551789` | A booted device starts its coding agent (e2e) | `flake.nix` (the linux-systems agent source) |
| `33c299a`, `87bc7c6`, `7efa293` | Task evidence, the e2e scope result, the operator confirmation | none (artifact records) |

## Verification receipt (orchestrator, on the working tree)

```
$ ./scripts/givn-verify.sh
[givn-verify] 1/5 spec traceability
[givn-verify] 2/5 flake evaluation (all outputs, current system)
[givn-verify] 3/5 build non-VM checks (unit + lint)
[givn-verify] 4/5 host configuration assertions (tests/assertions)
[givn-verify]   nixosConfiguration.adlerkopf
[givn-verify]   nixosConfiguration.cupix001
[givn-verify]   nixosConfiguration.nixos-vm-minimal
[givn-verify]   nixosConfiguration.thiniel
[givn-verify]   darwinConfiguration.J6G6Y9JK7L
[givn-verify] 5/5 python test suite (scripts/)
[givn-verify] OK
verify exit=0

$ ./scripts/givn-verify-e2e.sh
[givn-verify-e2e] OK
e2e exit=0

$ python3 scripts/givn-spec-trace.py
[warn] integration check 'integration-adlerkopf' is not referenced by any scenario
[warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
givn-spec-trace: 14 scenario(s) across 3 feature file(s), 0 finding(s)
trace exit=0
```

On top of the gates, the operator reports (2026-10-13) that both activations
succeeded and each machine reports a version at or above the asserted floor:
`omp 18.10.0` is what the configuration resolves to on thiniel and on
`J6G6Y9JK7L`, after `18.8.4` before the change.

## Fabrication audit

| # | Item | Verdict | Evidence |
|---|---|---|---|
| 0 | `@e2e` tag integrity | CLEAN | Exactly three `@e2e` scenarios exist across the permanent corpus and this delta, each bound to an `integration-*` check; no permanent `.feature` file appears in the change's diff, so no tag was removed. `@e2e` never appears without an integration/host binding. |
| 1 | Traceability | CLEAN | `scripts/givn-spec-trace.py` exits 0: `14 scenario(s) across 3 feature file(s), 0 finding(s)`. Each delta scenario carries exactly one binding tag, and all four names resolve. |
| 2 | Commit cross-check | CLEAN with one recorded exception | Seven revisions; six touch real configuration. `b615254` touches only the delta feature (two `@wip` removals) because the two guard scenarios are characterization and their deliverable — the check and its driver — landed in `270ed64`; recorded as F-REV-1 and in `design-review.md` F11. |
| 3 | Promised-target existence | CLEAN | `nix eval .#checks.x86_64-linux --apply builtins.attrNames` lists both new checks alongside the pre-existing ones; every module, assertion, host import and test file design.md promised exists (`flake.nix` input + `agentPkgsFor` + two `ompPackage` args, `omp.nix`, the Mac import, both invariants files, the driver, the booted test, the integration aggregator). |
| 4 | RED evidence | CLEAN | thiniel: the floor assertion failed on `18.8.4` (exit 1) then passed. Mac: four named assertions failed (agent absent, floor, both model servers, guard) then passed. Booted check: the guest ran `/nix/store/…-omp-18.8.4/bin/omp --version` and stopped on `AssertionError: agent reports 'omp/18.8.4', below the floor 18.10`, then passed with the pin. The guard check's RED is the design-declared characterization mutation: the reviewer re-derived all 17 driver cases against the hook and confirmed each verdict matches the hook's dispatch, so inverting any one expectation genuinely exits non-zero (both mutations were run and recorded, `16/17`). |
| 5 | E2E reality | CLEAN | The e2e target is a real `pkgs.testers.runNixOSTest`: it boots, waits for `home-manager-test.service`, runs the agent from its declared store path and asserts `(major, minor) >= (18, 10)`, asserts the guard file is a regular file (`test -f`, and `test -L` fails), asserts both model servers are declared, and asserts no key material exists while the agent still starts. Not an evaluation. |
| 6 | E2E isolation | CLEAN | `verify.command` and `verify.e2e_command` are distinct; the e2e script filters `integration-*` only; `@e2e` scenarios (1 in this delta, 3 including the permanent corpus) are strictly fewer than the 14 in scope. |
| 7 | Safety | CLEAN | No plaintext secret; no `sops`/`age -d`/`ssh-to-age` invocation anywhere in the change (only prose, glossary text and synthetic case strings in the driver). The guard hook is unmodified. `system.stateVersion`/`home.stateVersion` unchanged (the only additions are prose and the new test user's own value); `hardware.nix` untouched. |
| 8 | Dangerous areas | CLEAN | The change touches no `boot.loader`, `networking`, `fileSystems`/disko, `environment.persistence`/impermanence, kernel or secret-wiring file. It adds one flake input, one package argument and one home activation entry; `design.md` carries a Deployment & Rollback section with apply, build-before-switch and rollback commands plus the note that the guard file is left harmlessly in place. |
| 9 | Design conformance | CLEAN | Implemented check names, file paths, module argument and wiring match `design.md` exactly; the reviewer found no silent deviation. |

**Fabrication audit result: clean, except the one recorded commit-granularity
exception (F-REV-1).** No tautological target was found: the guard driver's 17
verdicts were re-derived against the hook, and both host targets fail before the
change for a named reason.

## Arc42 implementation conformance

The reviewer independently derived the affected chapters from the implemented
tree, then compared them with `arc42.md`'s twelve rows and the durable chapters.
All twelve rows agree, and every chapter's content matches the tree:

| Chapter | arc42 claim | Tree contains | Verdict |
|---|---|---|---|
| 01 | the agent floor is the first supplied version requirement | matches | OK |
| 02 | own input for a fast-cadence tool + guard travels with the agent | both rows present | OK |
| 03 | `nixpkgs-agent` in diagram and table; model-server interface row | present | OK |
| 04 | key decision 10; decision 2 no longer lists `omp` under unstable | both present | OK |
| 05 | agent Level-3 entry; tests inventory gains the driver and a fifth VM file | present | OK |
| 06 | five `integration-*` checks named; guard scenario; evaluation-scope list gains `unit-agent-secret-guard` | matches the hook's unconditional block | OK |
| 07 | Coding-agent row in both host tables | present | OK |
| 08 | third single-package source; refusal at the tool boundary; a fourth kind of check | present | OK |
| 09 | one NOT_QUALIFIED candidate routed to `design.md`; register unchanged | matches `arc42.md` | OK |
| 10 | QS-014 added; QS-013 status updated | present | OK |
| 11 | R-018, R-019, R-020, R-021, TD-014 | all present | OK |
| 12 | four terms; `Check` row lists both new checks with the adding change | present | OK |
| README | "five QEMU VM checks" | updated | OK |

ARC42 CONFORMANCE: CLEAN

## Ubiquitous language

`Coding agent`, `Secret-access guard` (distinct from `Guard`), `Agent version
floor` and `Model server (MCP server)` are in `docs/arc42/12-glossary.md` and are
used by the spec, the design, the code and the chapters. One finding, fixed:
`design.md`'s file-change table said "MCP declaration" instead of the glossary
term; it now names `Model server (MCP server)`. The proposal keeps the older
phrase "shared servers" — a planning artifact that predates the term, which the
review accepts rather than rewriting an answered question's record.

## Overlap dispositions

| Finding | Decision | Rationale |
|---|---|---|
| `givn lint [SUBST]`: "The personal laptop carries a current, guarded coding agent" is a subset of the Mac scenario | **keep** | Inherent, not duplication: the Mac's assertion set is a strict superset (it adds the two model servers), and a scenario carries exactly one binding tag, so the two host targets cannot be merged into one scenario. |
| `givn spec duplicates` (permanent corpus) | n/a | No exact or structural match: `0 exact/structural match(es)`. |
| `givn spec coverage` (permanent corpus) | n/a | 9 behaviour entries, 2 `@e2e`; with this delta, 3 `@e2e` against 14 scenarios in scope. |

No scenario in this change is a long, multi-assertion narrative needing a
split-or-keep decision: each carries one `Given`/`When` and a small set of
`Then` steps describing one observable state.

## Gap classification

| Warning | Bucket | Resolution |
|---|---|---|
| `integration-adlerkopf` is referenced by no scenario | **Bucket 1** (an `integration-*` check no in-scope scenario binds; it is a real VM boot, so it is not a bucket-3 target) | Pre-existing (`78b5309`) and untouched by this change. The standing operator decision of 2026-10-12 (`givn/archive/host-specific-ssh-identities/review.md`) is to keep it, bound by the change that specifies adlerkopf's service-stack capability. That decision still applies, so the warning stays visible until that capability is specified — recorded, not silently excused. |
| `integration-vm-minimal-ssh` is referenced by no scenario | **Bucket 1** (same reasoning) | Pre-existing (`81698eb`); the check is bound in `givn/artifacts/specs/spec.feature`, which the traceability script does not scan. Same standing decision: keep. |

No bucket-2 gap exists: every scenario of this change is bound to a target that
exists and fails before the change. No bucket-4 category was invented.

## README impact

README-IMPACT: none. The `readme` addon is disabled in `givn/config.yaml` (the
project README is hand-maintained), `README.md` is untouched by this change, and
it carries no row about the agent, so there is nothing to refresh.

## Findings and remediation

| Finding | Severity | Remediation |
|---|---|---|
| F-REV-1: `b615254` is a spec-only revision shared by two checked tasks | MINOR | Recorded here and in `tasks.md` (T4.COMMIT / T5.COMMIT) and `design-review.md` (F11). The scenarios' deliverable landed in `270ed64`; each still carries its own mutation RED, GREEN and evidence, so no task is claimed without substance. Accepted rather than split, because separate revisions would each have touched only the specifier. |
| F-REV-2: `design.md` used "MCP declaration" instead of the glossary term | MINOR | Fixed: the row now says `Model server (MCP server)`. |
| F-REV-3: `tasks.md` T2.RED described the agent-present assertion as newly added | INFO | Fixed: the wording now records that `hmHasPkg "omp"` pre-existed and that the floor and guard assertions are the new ones. |
| F-REV-4: `docs/arc42/05` says "`tests/unit/default.nix` + 12 files" | INFO | No action: the count is pre-existing text and still matches the tree's twelve non-aggregator unit files; this change added an `.mjs` driver, which the chapter lists on its own row. |
| F10 (found during implementation): the guard's glob coverage does not include the user-side sops-nix secret directory | Low, accepted | **Closed by operator decision (2026-10-13): no guard change.** The keys must stay where sops-nix places them, and the agent does not receive key material in normal use — the MCP declaration's `!command` indirection is resolved by the MCP plugin on the client side of the connection, not by the agent's tools. The residual property (a session that deliberately asks the agent to read that path is not blocked) is accepted and left to the process rule in `CLAUDE.md`. Recorded as `design-review.md` F10 and `docs/arc42/11-risks-and-technical-debt.md` R-021. The driver's cases were corrected to the guard's declared set, and the scenario names the surfaces the guard actually covers. |

## Use-case and Persona conformance

The change preserves the owning use case `reproduce-working-environment`: its
change-side copy differs from the permanent contract only by the new capability
`current-agent-tooling`, its interaction row, two rules (version floor; guardrails
travel with the agent) and one example. Capability ownership is unchanged for
`permitted-identity-selection`, and its two `@host:` scenarios still pass.
Personas: `owner--operator` relevant (the operator uses the agent on both devices
and confirmed the activations); `family--application-user` unaffected, recorded
rather than assumed. Actors in the spec are the device and the session, not
personas.

## Sign-off checklist

- [x] Fabrication audit performed and recorded; one commit-granularity exception
      closed explicitly (F-REV-1).
- [x] Traceability gate exits 0; every scenario bound to exactly one existing
      target; every `@e2e` bound to an integration check.
- [x] Both runners green (`verify exit=0`, `e2e exit=0`), e2e scope a strict
      subset, runners not identical.
- [x] Every checked task carries RED evidence and a revision; the operator's
      activations are recorded as operator-reported.
- [x] Arc42 implementation conformance: CLEAN.
- [x] Ubiquitous language: consistent; one stray synonym fixed.
- [x] Overlap dispositions and gap classification recorded in the three buckets.
- [x] README impact decided consciously.
- [x] No plaintext secret, no decryption invocation, no `stateVersion` or
      `hardware.nix` change; dangerous areas untouched and the rollback path
      recorded.
- [x] No deferral without an operator decision.

REVIEW: PASS
