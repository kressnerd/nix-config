# Review: managed-file-displacement

## Method

Three scenarios implemented one RED→GREEN→REFACTOR→COMMIT cycle at a time, each
with its targeted command, evidence and commit hash recorded in `tasks.md`. This
review re-derives the audit from the tree and the commits, and folds in an
independent read-only review run in a fresh context (`ReviewDisplacement`).

| Revision | Scenario / purpose | Configuration files touched |
|---|---|---|
| `ed4a60c` | The personal laptop displaces a rewritten managed file | `lib/helpers.nix`, `hosts/common/global/default.nix`, `tests/assertions/common-global-invariants.nix` |
| `9ee7a60` | The work MacBook displaces a rewritten managed file | `hosts/J6G6Y9JK7L/default.nix`, `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix` |
| `bf77831` | A booted device activates although a program rewrote a managed file | `tests/integration/{default,managed-file-displacement-test}.nix`, `flake.nix` |

## Fabrication audit

| Requirement | Evidence | Clean? |
|---|---|---|
| No scenario lost `@e2e` | The delta's booted scenario is declared `@givn.added @e2e @check:integration-managed-file-displacement`; the commits only remove `@wip` | CLEAN |
| Every `@e2e` scenario binds to an integration check | as above | CLEAN |
| Traceability | `python3 scripts/givn-spec-trace.py` → 25 scenarios across 5 feature files, 0 findings, exit 0 | CLEAN |
| Commit cross-check | all three checked scenario tasks map to commits that touch `*.nix` under `lib/`, `hosts/`, `tests/` (table above); the hashes resolve | CLEAN |
| Promised targets exist | `mkManagedFileDisplacement` in `lib/helpers.nix`; the option in both declaration sites; the fixture registered and wired; both assertions present; `integration-managed-file-displacement` in `nix eval .#checks.x86_64-linux --apply builtins.attrNames` | CLEAN |
| RED evidence | thiniel: exit 1 naming the displacement assertion; MacBook: exit 1 naming it; the boot: exit 1 with the guest line `Existing file '/home/test/.config/example/settings.conf' would be clobbered` and `home-manager-test.service: Failed with result 'exit-code'`. Each RED fails for its own reason; the booted RED is the clobber, not a permissions or evaluation error (the first attempt's permission failure is recorded and was fixed before the accepted run) | CLEAN |
| E2E reality | the check boots a QEMU VM, waits for `home-manager-test.service`, and asserts the rendered link plus both displaced copies (`.1` untouched, `.2` the newest rewrite) — a real boot asserting observable state, not an evaluation wearing the tag | CLEAN |
| E2E isolation | `verify.command` = `./scripts/givn-verify.sh`, `verify.e2e_command` = `./scripts/givn-verify-e2e.sh`; the e2e command builds the `integration-*` scope only; 25 scenarios total, 3 `@e2e` | CLEAN |
| Safety | no secret, no sops invocation, `stateVersion` unchanged, no `hardware.nix` touched; the helper only renames a file inside its own directory | CLEAN |
| Arc42 conformance | table below | CLEAN |
| Ubiquitous language | `Managed file` and `Displaced file` are in the glossary (alphabetical), and the plan, the design and the code use them; no inconsistent reuse | CLEAN |

## Independent review findings

A fresh-context read-only review (`ReviewDisplacement`, task tool, agent
`reviewer`) audited items 0–10 against the tree and the commits. It passed the
`@e2e` integrity, commit cross-check, promised-target, RED-specificity (including
that the booted RED is the guest's own clobber line), e2e-reality (the seed
provably precedes the home profile's activation), e2e-isolation, safety and
design-conformance items, and found no behavioural defect. It raised four
documentation defects, all fixed before sign-off:

| # | Severity | Finding | Disposition |
|---|---|---|---|
| 1 | P3 | Two glossary rows were out of the table's own alphabetical order. | **Fixed**: `Displaced file` now follows `disko` and `Managed file` follows `Intended`. |
| 2 | P3 | `tasks.md` still carried the abandoned `backupFileExtension` wording in the setup task. | **Fixed**: both occurrences name `backupCommand`. |
| 3 | P3 | `design.md` listed arc42 chapter 01 as affected while `arc42.md` marks it unaffected and the chapter was not modified. | **Fixed**: the chapter list now starts at 02, matching the assessment. |
| 4 | P3 | `design.md` cited Home Manager source line numbers from the release-26.05 input instead of the `home-manager-unstable` revision the device and the guest actually run. | **Fixed**: the citations were re-verified in the unstable revision's source (`modules/files/check-link-targets.sh:29-30`, `modules/files.nix:353-355`, `modules/files.nix:356-359`) and now name that revision. |

## Arc42 implementation conformance

| Arc42 chapter or fact | Durable-doc source | `arc42.md` claim | Implementation evidence | Match? |
|---|---|---|---|---|
| A rewritten managed file is displaced, never discarded | `02-architecture-constraints.md` (constraint row) | row 2 | `lib/helpers.nix` (`mkManagedFileDisplacement`), both declaration sites | MATCH |
| Managed files and their displacement | `08-crosscutting-concepts.md` (new section) | row 8 | the helper's script and the option | MATCH |
| The helper, the two declaration sites, six integration checks | `05-building-block-view.md` (helpers row, integration row, diagram) | row 5 | `lib/helpers.nix`, `hosts/*`, `tests/integration/default.nix` | MATCH |
| The repository-validation flow enumerates six checks | `06-runtime-view.md` | row 6 | the flake's checks output | MATCH |
| `thiniel`'s browser-profile property records the removed failure mode | `07-deployment-view.md` | row 7 | `hosts/common/global/default.nix`, the fixture's boot | MATCH |
| Quality scenario: a rewrite leaves the configuration appliable | `10-quality-requirements.md` QS-016 | row 10 | the booted check + the two host assertions | MATCH |
| Risk R-025 (displacement removes the loud signal) | `11-risks-and-technical-debt.md` | row 11 | the helper's rename, documented in chapter 8 | MATCH |
| Glossary terms and the check enumeration | `12-glossary.md` | row 12 | the helper, the new check | MATCH |
| Candidate assessed and routed, no ADR created | `09-architecture-decisions.md` | row 9 | the candidate row and the verdict in `arc42.md` | MATCH |

ARC42 CONFORMANCE: CLEAN

## Coverage gap classification

| Location | Traceability finding | Classification | Action |
|---|---|---|---|
| `integration-adlerkopf` | referenced by no scenario | Bucket 1 (pre-existing; standing operator decision recorded in `givn/archive/host-specific-ssh-identities/review.md`) | Keep |
| `integration-vm-minimal-ssh` | referenced by no scenario | Bucket 1 (pre-existing; its scenario lives in the unscanned reference template `givn/artifacts/specs/spec.feature`) | Keep |

No bucket-2 gap: every scenario of this change is bound to a target that exists
and failed before its implementation. No bucket-3 target, no invented fourth
bucket.

## Use-case and Persona conformance

Owning contract: `reproduce-working-environment`, carried in this change with the
new capability `managed-file-displacement`, its rule (a rewritten managed file is
displaced and kept, each time it is rewritten), its interaction row (a device
applies its configuration) and an example; the base revision is stamped
(`7b854f…` = the permanent file as it stood). Goal, guarantees, actors and typed
relationships are preserved; no Persona was invented — `owner--operator`
(confirmed 2026-10-11) is the operator who applies the configuration, and
`family--application-user` is recorded as not affected.

## Deferrals

None. Both runners pass. The operator step (applying the setting to `thiniel`) is
recorded in `tasks.md` and does not gate the change: the declared state and the
behaviour are verified by the booted check.

## Sign-off

- [x] Traceability exits 0; one binding per scenario; `@e2e` bound to an integration check.
- [x] Every scenario's RED failed for its own reason before the implementation and passes after.
- [x] Every target promised by `design.md` exists; the new check is wired and named in the flake.
- [x] Safety: no secret, no `stateVersion` change, no `hardware.nix` change; the helper only renames.
- [x] Both runners green: `./scripts/givn-verify.sh` → `[givn-verify] OK`,
      `./scripts/givn-verify-e2e.sh` → `[givn-verify-e2e] OK` (six `integration-*` checks built).
- [x] Arc42 conformance clean; ubiquitous language clean; gaps classified.
- [x] Fabrication audit clean: 0 fabricated scenarios/targets.

README-IMPACT: none. The `readme` addon is disabled (`readme: false`), and the
change adds no command, flag or configuration key a README reader would use: it
sets one Home Manager option and adds one check. The behaviour is documented in
the arc42 set (chapter 8) and the glossary, which is where a reader looks for it.

REVIEW: PASS
