# Review: host-specific-ssh-identities

## Method

A delegated reviewer with no part in writing the change performed the review
skill's Step 0 fabrication audit, the arc42 implementation-conformance check,
the ubiquitous-language check, the overlap dispositions and the README impact
decision, reading the artifacts, the implementation and the six commits
(`2a20ef6`, `050622e`, `dfec80f`, `0244a91`, `8fd175a`, `21d8a30`) and running
the read-only checks (`scripts/givn-spec-trace.py`, `givn lint`,
`givn spec duplicates`, `givn spec coverage`, `git show`, `nix eval`). The
orchestrator ran the two full runners and records their output below.

Verification receipt (orchestrator, on the working tree, which also carries
changes unrelated to this one — `flake.lock`, the two staged `hosts/*/private.nix`
files, untracked `givn/ideation`, `givn/personas`, `docs/ideation`,
`docs/plans/private-data-remediation-plan.md`):

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

$ ./scripts/givn-verify-e2e.sh
[givn-verify-e2e] building: integration-adlerkopf integration-ssh-identity-selection integration-vm-minimal-ssh
[givn-verify-e2e] OK

$ python3 scripts/givn-spec-trace.py
[warn] integration check 'integration-adlerkopf' is not referenced by any scenario
[warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
givn-spec-trace: 4 scenario(s) across 1 feature file(s), 0 finding(s)
```

## Step 0 — fabrication audit

| # | Check | Result |
|---|---|---|
| 0 | `@e2e` tag integrity | **No finding.** The delta holds 4 scenarios and 1 `@e2e`; the tag sits on the booted-device scenario bound to `@check:integration-ssh-identity-selection`, and the single commit that introduced the spec (`2a20ef6`) already carries it there, so no committed revision ever had the tag on the thiniel scenario. Coverage was not removed to bypass a gate: the `@e2e` count is 1 of 4 before and after, the replacement is an enforced real boot, and the previously tagged scenario still carries an enforced `@host:thiniel` binding run by the non-`@e2e` runner. |
| 1 | Traceability | **No finding.** 4 scenarios, exactly one binding each, all four resolve; no `@e2e` on a unit/lint check. |
| 2 | Commit cross-check | **No finding.** Every checked scenario task has a commit touching real configuration (`flake.nix`, `modules/`, `home/dan/`, `tests/`), and all four recorded hashes match `git log`. |
| 3 | Promised-target existence | **No finding.** Every module, option, host declaration, assertion, VM check and flake check that `design.md` promised exists. |
| 4 | RED evidence | **No finding.** Each scenario's pasted RED is non-zero for the named reason and matches the committed assertions and the pre-fix module (`git show 050622e^:home/dan/features/cli/ssh.nix` hardcoded the MacBook path, rendered all four connection blocks and the three includes). `verify.command` ≠ `verify.e2e_command`. |
| 5 | E2E reality | **No finding.** The `@e2e` target is a `pkgs.testers.runNixOSTest` that boots (`machine.start()`, `multi-user.target`, `home-manager-test.service`) and asserts the booted device's `ssh -G` resolution and rendered `~/.ssh/config` — a real boot, not an evaluation standing in for one. |
| 6 | E2E isolation | **No finding.** The e2e runner builds only `integration-*` names (3 checks); the `@e2e` scope is 1 of 4 scenarios, a strict subset. |
| 7 | Safety | **No finding.** No secret file or plaintext credential added; no `sops`/decrypt invocation added; existing host `stateVersion`s unchanged (the only one in the diff is the new test VM's `home.stateVersion = "25.11"`); no `hardware.nix` touched. |
| 8 | Dangerous areas | **No finding.** No `boot.loader`, `networking`, `fileSystems`/disko, impermanence, kernel or secret wiring change; `design.md` nevertheless carries a Deployment & Rollback section with a concrete rollback, because the change rewrites `~/.ssh/config`. |
| 9 | Design conformance | **No finding for the implementation.** Option names, types, defaults, the sops gate, the rendered surfaces, host declarations, flake wiring, check name and all four target files match `design.md`; both post-design decisions are recorded in `design.md` and `design-review.md`. The only drift was a stale count inside `design-review.md` (F-2, fixed). |
| 10 | Remaining unfinished work | None beyond F-1 and F-2. |

## Arc42 implementation conformance

Independently re-derived from the implementation, `design.md` and `tasks.md`,
then compared against the durable chapters and `arc42.md`.

| Chapter / fact | Durable source | Claim | Implementation evidence | Match |
|---|---|---|---|---|
| Ch05 — new `myHome.ssh` option module | `05-building-block-view.md` | affected; new options module | `modules/home-manager/ssh/options.nix` (`personalIdentityFile` `str`, no default; `includedConfigs` `listOf str`, default `[ ]`) | yes |
| Ch05 — host user module declares what the device holds | `05` building-block table | via the chapter update | `home/dan/thiniel.nix:81`, `home/dan/J6G6Y9JK7L.nix:68-75` | yes |
| Ch08 — per-host identity declaration, fail-closed constraint | `08-crosscutting-concepts.md` | affected | `ssh.nix:26` (includes from the declaration), `ssh.nix:36` (identity file from the declaration) | yes |
| Ch08 — work entry only where the material is declared | `08` | affected | `ssh.nix:8` `holdsIdentity` + `lib.optionalAttrs` blocks | yes |
| Ch11 — R-001 declared-but-absent key fails closed | `11-risks-and-technical-debt.md` | affected | `ssh.nix:36` renders the path only; nothing checks existence | yes |
| Ch11 — TD-001 work key names remain literals | `11` | affected | `ssh.nix` work identity file literals | yes |
| Ch12 — glossary terms | `12-glossary.md` | affected | seven rows present after F-3 | yes |
| Ch09 — no ADR, empty register | `09-architecture-decisions.md` | no ADR | `docs/arc42/adr/` holds only `adr-template.md` | yes |
| Ch01-04, 06, 07, 10 — unaffected placeholders | chapter files | "No" impact, deliberately untouched | placeholders unchanged | yes |

ARC42 CONFORMANCE: CLEAN

## Ubiquitous language

F-3: the spec's observable assertions name "connection entry", and the glossary's
own definitions used the term, but it had no row. Fixed by adding the term to
`docs/arc42/12-glossary.md` (and to the chapter-12 impact list in `arc42.md`).
All other terms (identity declaration, identity file, identity material, personal
identity, private workspace, work identity) are present and reused consistently
across the spec, the design, `ssh.nix` and `git.nix`.

UBIQUITOUS LANGUAGE: CLEAN after F-3.

## Overlap dispositions

`givn spec duplicates` reports `0 exact/structural match(es)` and
`givn spec coverage` reports `0 behavior entries, 0 @e2e`: the permanent corpus
is empty because this change carries the first capability, so there are no
shape-match rows and no removed+added pairs to disposition. The deterministic
gate emitted no long-scenario finding; the longest scenario (the work laptop's
preserved identity surface, six steps) is **KEEP** — its four `Then`s state one
coherent outcome and cannot be RED'd independently, so splitting would produce
scenarios whose targets cannot fail on their own.

## README impact

The readme addon is disabled (`givn/config.yaml`: `readme: false`, with the
recorded rationale that the README is hand-maintained), so no machine-checked
line is required. Conscious decision: README-IMPACT: none — `README.md`
documents the project generically, names no identity path or per-device
declaration, and this change adds, changes or removes no project-level command,
flag or configuration surface.

## Traceability gap classification

| Gap | Classification | Disposition |
|---|---|---|
| `integration-adlerkopf` unreferenced | Bucket 1 — dead configuration as measured by the traceability model (an `integration-*` check no scenario binds; it is a reproducible VM boot, so not bucket 3) | **Operator decision (2026-10-12): keep the check; it is bound by the change that specifies its owning capability** (adlerkopf's service stack). The check predates this change (`78b5309`) and its assertions are real boots, so deleting another change's verification was rejected; the gap stays visible in the traceability warning until that capability is specified. |
| `integration-vm-minimal-ssh` unreferenced | Bucket 1 — same | **Operator decision (2026-10-12): keep the check; it is bound by the change that specifies its owning capability** (the minimal VM's SSH access). Pre-existing (`81698eb`), same reasoning. |

The change's own new check is referenced by the `@e2e` scenario, so it adds no
new gap. No fourth bucket is used; the deferral is recorded above with the
operator's decision, as the review skill requires.

## Findings

| # | Finding | Status |
|---|---|---|
| F-1 | The live-activation item in `tasks.md` was open, so the tasks gate could not pass. | Resolved by the operator's decision to activate on the running system and record the live check (below). |
| F-2 | `design-review.md` stated "5 scenarios" after the second hardening round reduced the delta to 4. | Fixed: the row now says 4 and explains the fold; the stale "first commit is still ahead" parenthetical was corrected to name `2a20ef6`. |
| F-3 | "connection entry" was load-bearing in the spec and used by the glossary without a definition. | Fixed: term added to `docs/arc42/12-glossary.md` and to the chapter-12 impact list. |

## Use-case and Persona conformance

`specs/reproduce-working-environment/usecase.md` is carried in the change; its
only edit is the Capabilities section naming `permitted-identity-selection`, and
the contract text is otherwise the accepted ideation text unchanged. The
implementation matches the capability statement: a device resolves private
repositories with the identity it holds, declares no connection for an identity
whose material it does not hold, and the work laptop's surface is preserved. No
Persona appears as a Gherkin actor; `owner--operator` has a recorded disposition
in the proposal, design, design-review and tasks, and `family--application-user`
is recorded as unaffected with a reason. The `(open: Q16)` qualifier is carried
explicitly and closed for thiniel's personal identity only (proposal D2).

Observation (not a finding): the use-case document's Diagram section points at
`givn/ideation/infrastructure-growth/eventstorming.md`, which exists in the
working tree but is untracked, so a fresh clone cannot follow that reference
until the owner commits the ideation topic.

## Sign-off checklist

- [x] Traceability exits 0 with every scenario bound to exactly one existing target.
- [x] Both runners exit 0 (`./scripts/givn-verify.sh`, `./scripts/givn-verify-e2e.sh`).
- [x] Every checked task has a commit touching real configuration and a recorded hash.
- [x] Fabrication audit clean across items 0–10.
- [x] Arc42 implementation conformance clean.
- [x] Ubiquitous-language check clean.
- [x] Overlap dispositions recorded; README impact decided.
- [x] Gap classification recorded for both unreferenced checks.
- [ ] Live activation on the running system recorded (`ssh -G github-personal` after the owner's switch) — this is the open item F-1.
