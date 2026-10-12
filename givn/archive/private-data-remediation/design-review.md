# Design Review: private-data-remediation

## Method

Phase 1 (grilling) ran in a fresh context: a delegated reviewer with no part in
writing the proposal, spec, design or arc42 update read the full planning layer
and the code it touches, then returned ranked findings. Phase 2 (hardening)
applied the decisions reached; the orchestrator applied them directly and
records each below rather than delegating a mechanical pass.

Artifacts grilled: `proposal.md`, `specs/publish-infrastructure-configuration/{usecase.md,operational-data-separation.feature}`,
`design.md`, `arc42.md`, plus `docs/GIVN-VERIFICATION.md`, the source plan
`docs/plans/private-data-remediation-plan.md`, `scripts/givn-spec-trace.py`, the
verify runners, `flake.nix`, the two affected hosts, the test wiring, `.gitignore`
and every chapter under `docs/arc42/`.

## Branch dispositions

| Branch | Result |
|---|---|
| Scope | One finding (F-002): the spec carries no `cupix001` scenario although the design names it affected. Resolved by recording why a `cupix001` scenario cannot go RED and where its obligations are covered. |
| Tech choices | One finding (F-001, blocker): the private-input architecture fits the `git+file://` constraint, but the design made the stub's placeholder assertion the guard against a forgotten `--override-input`, which is unsound. Fixed with an operator decision (below). The reviewer also noted a `path:` override would avoid requiring a git repository for the private flake; the `git+file://` form is kept because the operator's private repository is already a git repository and `path:` would not exercise the same source rule. |
| Missing scenarios | Three findings: `cupix001` (F-002), guard enforcement before commit and on CI (F-003), and the use case's "report not safe to publish" flow (folded into F-003's disposition and the operator-confirmed history-rewrite task). F-002 and F-003 are recorded, not converted into scenarios, because neither can bind to a native target that can fail. |
| Testability | One finding (F-010): three scenarios share one check, so per-scenario RED attribution is weak. Recorded as an accepted limitation with the rationale. Scenario 1's RED is confirmed to require the stub assertion to be authored first (the documented targeted command exits 0 today); recorded in `design.md`. |
| Verification-binding completeness | No finding in the tags themselves: exactly one binding tag per scenario, `@e2e` binds to `@check:integration-*`, `verify.e2e_command` differs from `verify.command`. One finding (F-013): the two new checks do not exist yet, so `scripts/givn-spec-trace.py` exits 1 with four findings — expected before implementation, and the repository's "wire it in before RED" rule applies; the checks land before the `tasks`/`review` gates. |
| Deployment & rollback | Two findings: the forgotten-override claim (F-001) and the rollback assuming the connectivity a wrong network value removes (F-007). Both fixed: the apply command is aligned with the `--target-host` flow, the preflight guards the deploy, and the out-of-band path is named per host. |
| Risk | The single most likely failure is a forgotten `--override-input` applying a placeholder address. The mitigation is now the deploy-path preflight, not the stub assertion; the recovery is generation rollback plus, for a wrong value that removes SSH, adlerkopf's local systemd-boot menu. Recorded as R-008. |
| Decision ledger | No finding. D1 and D2 both resolve in `design.md`'s `## Decisions` section, with the rejected alternatives recorded. |
| Use-case and Persona context | No finding. The use case `publish-infrastructure-configuration` owns the capability `operational-data-separation`; `owner--operator` is confirmed and relevant, `family--application-user` is confirmed and correctly declared unaffected; no Persona is invented or used as a Gherkin actor. |
| Deferrals | One finding (F-003): the pre-commit and CI wiring is an outcome with no scenario. Resolved by recording it as an operator-owned process control with the operator's acceptance (below), not as an unrecorded deferral. |
| Architecture documentation (arc42) | Two findings: the index still declared the register empty (F-005) and four chapters presented intended artifacts as current (F-011). Both fixed. The independent 12-row re-derivation agrees with `arc42.md` on every row. |

## Independent arc42 verdict

The reviewer re-derived the chapter set from proposal/specs/design before opening
`arc42.md`. All 12 rows agree.

| # | Chapter | Reviewer | `arc42.md` | Agree |
|---|---|---|---|---|
| 1 | 01 introduction-and-goals | No | No | yes |
| 2 | 02 architecture-constraints | Yes | Yes | yes |
| 3 | 03 context-and-scope | No | No | yes |
| 4 | 04 solution-strategy | Yes | Yes | yes |
| 5 | 05 building-block-view | Yes | Yes | yes |
| 6 | 06 runtime-view | Yes | Yes | yes |
| 7 | 07 deployment-view | Yes | Yes | yes |
| 8 | 08 crosscutting-concepts | Yes | Yes | yes |
| 9 | 09 architecture-decisions | Yes | Yes | yes |
| 10 | 10 quality-requirements | No | No | yes |
| 11 | 11 risks-and-technical-debt | Yes | Yes | yes |
| 12 | 12 glossary | Yes | Yes | yes |

Chapter-file integrity: all 12 chapter files exist and hold real content; a scan
for Unicode box-drawing characters and `+---` pseudo-diagrams found none; the
ADR-0001 register entry exists in chapter 9 and in `adr/README.md`, and the
ADR's "Bad, because" consequences appear in chapter 11 (R-008, R-015).

## Findings and dispositions

| # | Finding | Disposition |
|---|---|---|
| F-001 | **Blocker.** The design made the stub's placeholder assertion the sole guard against a forgotten `--override-input`. That is unsound: a clean-clone/CI evaluation and a forgotten override are the same stub evaluation, and after this change the defaults *are* placeholders, so the assertion passes in both and a placeholder address would be applied to a real host. | Fixed by operator decision (below): the guard moves to the deploy path as a preflight. Every claim that the assertion catches a forgotten override is corrected in `design.md`, `ADR-0001`, chapters 6, 8 and 11, and R-008. |
| F-002 | The spec has no `cupix001` scenario although the design names it affected; its options default to empty strings, so the rule "defaults are documentation-range placeholders" is not literally true there. | Recorded: the rule now reads "documentation-range placeholders or empty", the stub accepts the empty form, and `design.md` records why a `cupix001` scenario cannot go RED and that its obligations are covered by scenario 2 and the untracking step. |
| F-003 | The guard's enforcement before commit and on CI is a proposal outcome with no scenario, and no native target can bind it. | Recorded as an operator-owned process control in `design.md` (the guard *rule* is verified by `@check:private-data-hygiene`; the hook and CI wiring is not). Accepted by the operator with the F-001 decision. |
| F-004 | The sanitization inventory omitted three tracked files carrying the WireGuard subnet (`docs/plans/adlerkopf/03-wireguard.md`, `docs/plans/cupix001/05-wireguard.md`, `docs/plans/cupix001/13-colmena.md`). | Fixed: added to the table, and the sanitization task re-runs `git grep` per class rather than trusting the table. |
| F-005 | `docs/arc42/README.md` still stated the ADR register and directory index are empty, contradicting the ADR-0001 entry this change adds. | Fixed: the "Current state summary" now records ADR-0001 and the remaining non-qualified candidates. |
| F-006 | The design omitted untracking the two `hosts/*/private.nix` files, which are in the git index today, so the guard's file rule and scenario 2 could not go GREEN; the `.gitignore` bullet wrongly said the files are untracked in this change. | Fixed: the untracking step (`git rm --cached`) is recorded in the Architecture Impact list and the `.gitignore` bullet corrected. |
| F-007 | The rollback record assumed the SSH connectivity a wrong network value removes, and the apply command omitted the `--target-host` form used by the deploy flow. | Fixed: the apply command is aligned with the remote flow, and the out-of-band recovery is named per host (adlerkopf's local systemd-boot menu; cupix001's provider console, to be confirmed before its first deploy). |
| F-008 | `design.md` named the ADR path as `docs/adr/0001-private-data-strategy.md`, not the arc42 storage path. | Fixed: both references now read `docs/arc42/adr/ADR-0001-private-data-strategy.md`. |
| F-009 | The guard's value rule was under-specified, and the negative fixture used an already-leaked literal, so it could not distinguish a class rule from a denylist. | Fixed: `design.md` specifies the value rule as classes (LAN subnet, WireGuard subnet, provider resolver pattern, public address/MAC, port) plus structural rules, and the fixture uses an in-class value that is not any literal currently in the tree. |
| F-010 | Three scenarios share one `@check:private-data-hygiene` target, weakening per-scenario RED attribution. | Recorded as an accepted limitation in `design.md` with the rationale (one rule, three independent fixtures; splitting would add two trivial derivations without new behaviour). |
| F-011 | Chapters 5, 6, 8 and 12 described artifacts this change has not yet created as current. | Fixed: inline `Intended` markers plus a note in `arc42.md` recording that they become plain declarations once the change's tasks land. |
| F-012 | Chapter 7's fleet topology is an inline SVG, not a Mermaid block. | Accepted deviation: the chapter-7 SVG exception is already recorded in `docs/arc42/README.md`'s diagram policy (the layout carries information Mermaid cannot express), and this change does not alter the diagram's form. Not a new deviation. |
| F-013 | `scripts/givn-spec-trace.py` exits 1: `@check:private-data-hygiene` and `@check:integration-private-data-separation` are not in the flake yet. | Expected before implementation and recorded in `design.md`; the checks are wired in before the `tasks`/`review` gates run the trace, per the repository's "wire it in before RED" rule. |

## Operator decision — forgotten-override guard

Question put to the operator: the plan made the stub's placeholder assertion the
guard against a deploy that omits `--override-input`, but the assertion passes in
exactly that case (a clean clone and a forgotten override are the same stub
evaluation), so a placeholder address would be applied to a real host.

Decision: **preflight in the deploy path**. The per-host rebuild alias evaluates
the host with the override and refuses to deploy when the network values are
documentation-range or empty, so nothing is built or applied when the preflight
fails. Rejected: a host-side activation refusal (the new generation is already
the boot default when activation runs, so a later reboot can still boot the
placeholder configuration, and a first install has no previous configuration to
keep) and accepting the residual risk (a forgotten override would silently apply
a placeholder address). The stub assertion stays, with its corrected scope: it
guards the *defaults*, not the forgotten override.

Consequence recorded at decision time: the guard is operator-owned process
control — it protects the operator's own deploy commands, and a raw
`nixos-rebuild` without the preflight remains unguarded. The recovery for a wrong
value that removes SSH is out of band (adlerkopf's local systemd-boot menu).

## Hardening performed

- `design.md`: the deploy preflight, the corrected forgotten-override claims, the
  apply command with `--target-host`, the out-of-band recovery, the guard value
  rule, the untracking step, the corrected ADR path, the `cupix001` note, the
  accepted sharing limitation, the process-control record, and the carried open
  inputs.
- `specs/.../operational-data-separation.feature` and `usecase.md`: the rule and
  the flows now read "documentation-range placeholders or empty"; the missing
  value now makes the *deploy* refuse.
- `docs/arc42/adr/ADR-0001-private-data-strategy.md`: the consequence and the
  confirmation corrected.
- `docs/arc42/{05,06,08,11,12}.md` and `docs/arc42/README.md`: intended markers,
  the corrected risk mitigation, the new checks in the glossary, and the state
  summary.
- `arc42.md`: the intended-artifact note.

## Second review — after the implementation-time design correction

Implementation surfaced two facts that changed `design.md`, so the review was
re-run in a fresh context (`design.md` changed → the artifact un-gates).

- **`@host:adlerkopf` cannot be a bound target.** `nix eval
  .#nixosConfigurations.adlerkopf.config.system.build.toplevel.drvPath` exits 1
  on the *pre-change* revision too: `boot.initrd.luks.devices.cryptroot.device`
  has conflicting definitions (disko's `disk-nvme0n1-cryptroot` against
  `hosts/adlerkopf/tpm2.nix`'s `cryptroot`). `nix flake check` passes because it
  does not force that option, so the canonical `@host:` targeted command can
  neither isolate a stub-assertion failure nor ever exit 0. The placeholder
  scenario rebinds to `@check:private-data-defaults`; the defect is recorded as
  R-017.
- **The `path:` lock claim was wrong.** A `path:` flake input *does* get a
  `flake.lock` entry (`./private-stub`); the corrected claim is that the lock
  records only the stub path, never the private flake's URL.

The reviewer confirmed the R-017 record and the arc42 verdicts, and found four
consistency gaps the correction had left behind; all four are fixed:

| # | Finding | Disposition |
|---|---|---|
| G-001 | `tasks.md` scenario 1 still bound `@host:adlerkopf` with a GREEN criterion its targeted command can never meet. | Fixed: rebound to `@check:private-data-defaults` with the check's targeted command and a masked RED expectation. |
| G-002 | `design.md`'s Use-Case Traceability table still named `@host:adlerkopf` for the placeholder rule and for Main flow 4. | Fixed: both rows now name `@check:private-data-defaults` (and `@check:private-data-hygiene` for flow 4). |
| G-003 | `ADR-0001`'s Confirmation still relied on a `@host:adlerkopf` evaluation. | Fixed: it now names `@check:private-data-defaults` and cites R-017 for why the host binding is unavailable. |
| G-004 | `design.md`'s Secrets & Safety retained the falsified "no lock entry" claim, and the trace-gate paragraph named two checks instead of three. | Fixed: both corrected; `tasks.md`'s finding count corrected to five across three checks. |

No further finding was raised; the reviewer's confidence in the remaining
consistency was 0.9 and every raised item is closed above.

## Third correction — the R-017 rationale

The operator asked that local adlerkopf branch work be preserved. Inspecting the
branches showed `main` already carries 22 of the 23 commits on
`worktree/roo-f8e9n` / `worktree/roo-geph2` by patch-id, except one hunk of
`f8dd195`: `main` has the lanzaboote `v1.0.0` half of that commit but not its
`hosts/adlerkopf/tpm2.nix` half (removing the stale
`device = "/dev/disk/by-partlabel/cryptroot"` line). That missing half is the
exact cause of R-017. Applying it makes
`nix eval .#nixosConfigurations.adlerkopf.config.system.build.toplevel.drvPath`
exit 0.

This is a factual correction, not a decision change: scenario 1 keeps its
`@check:private-data-defaults` binding, now justified on its own merits (a check
that forces only the networking options cannot be masked by a defect in a
different subsystem) rather than by the host command being unusable. `design.md`
(paragraph), R-017 and `ADR-0001` (parenthetical) are corrected accordingly; the
spec, the verification table and the tasks are unaffected. No new decision was
taken, so no additional grill was required.

DESIGN-REVIEW: PASS
