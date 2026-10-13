# Review: github-fetch-credential

## Verdict

READY TO ARCHIVE: YES. The implementation, its delta specs and both verification
runners are green, and the one blocking finding (B-1, the `tasks.md` revision
format) has been fixed and the review gate now passes
(`givn check review --change github-fetch-credential` exits 0).

## Method

Four scenarios were implemented one RED→GREEN→REFACTOR→COMMIT cycle at a time,
each with its targeted command, pasted output and commit hash recorded in
`tasks.md`, followed by a separate commit recording the scenario-4 revision.
This review re-derives the audit from the tree, the commits and the two gates;
it trusted no summary line it could reproduce itself.

| Revision | Scenario / purpose | Configuration files touched |
|---|---|---|
| `7e4e302` | The laptop declares the credential it presents to the GitHub host | `modules/nixos/github-fetch-credential/{options,default}.nix`, `hosts/common/global/default.nix`, `hosts/thiniel/default.nix`, `tests/assertions/thiniel-invariants.nix` |
| `9922830` | The work MacBook declares the credential it presents to the GitHub host | `home/dan/J6G6Y9JK7L.nix`, `hosts/J6G6Y9JK7L/default.nix`, `tests/assertions/J6G6Y9JK7L-{invariants,darwin-invariants}.nix` |
| `2ffa755` | A host that does not build this configuration declares no credential | `tests/assertions/adlerkopf-invariants.nix` |
| `380799c` | A booted device materialises the declared credential and presents it to the GitHub host | `tests/integration/{default,github-fetch-credential-test}.nix`, `modules/nixos/github-fetch-credential/default.nix` |
| `1952359` | Record the scenario-4 revision in the task list | `tasks.md` (records only) |

## Findings

### Blocking

**B-1 — `tasks.md` recorded the four scenario revisions in a form the review
gate rejected. RESOLVED.**

Originally `tasks.md` used `- [x] **COMMIT** — …` with a nested
`- hash: <hash>` bullet, and `givn check review --change github-fetch-credential`
aborted with:

```
[integrity] no `- [x] COMMIT:` lines found in tasks.md — revision identifiers must be recorded
error: integrity check failed: hash presence
```

The four commits were real and their hashes correct (`7e4e302`, `9922830`,
`2ffa755`, `380799c` — each verified against `git show`); only the recorded form
differed from givn's required literal and the repository convention
(`givn/archive/managed-file-displacement/tasks.md:76,100,137`).

Resolved: `tasks.md` now records each commit as `- [x] COMMIT: \`<hash>\``
(`tasks.md:119,174,216,300`), confirmed with
`git diff -- givn/changes/github-fetch-credential/tasks.md`, and the gate's
integrity check passes. No other change has been made to the tree since the
audit below was carried out.

### Advisory

None.

## Fabrication audit

Files scanned: the four delta scenarios, the five commits above (diffs read with
`git show`), and every implemented file
(`modules/nixos/github-fetch-credential/{options,default}.nix`,
`hosts/common/global/default.nix`, `hosts/thiniel/default.nix`,
`home/dan/J6G6Y9JK7L.nix`, `hosts/J6G6Y9JK7L/default.nix`, the four
`tests/assertions/*-invariants.nix`, `tests/integration/{default,github-fetch-credential-test}.nix`,
`flake.nix`).

| Requirement | Evidence | Clean? |
|---|---|---|
| No scenario lost `@e2e` | `git log -p --follow` on the delta feature shows only `@wip` removed from the four scenarios; the booted scenario keeps `@e2e @check:integration-github-fetch-credential` | CLEAN |
| Every `@e2e` scenario binds to an integration check | the only `@e2e` scenario binds `@check:integration-github-fetch-credential`, a `pkgs.testers.runNixOSTest` | CLEAN |
| Traceability | `python3 scripts/givn-spec-trace.py` → `givn-spec-trace: 29 scenario(s) across 6 feature file(s), 0 finding(s)`, exit 0; its two `[warn]` lines are pre-existing unreferenced checks (see Coverage) | CLEAN |
| Commit cross-check | the four scenario commits each touch real configuration (`*.nix` under `modules/`, `hosts/`, `home/`, `tests/`); the record commit touches only `tasks.md`, as intended | CLEAN |
| Promised targets exist | `modules/nixos/github-fetch-credential/{options,default}.nix` (option pair + secret/template/include); the import in `hosts/common/global/default.nix`; opt-in in `hosts/thiniel/default.nix`; the Mac's secret/template/include in `home/dan/J6G6Y9JK7L.nix` and its root-side activation script in `hosts/J6G6Y9JK7L/default.nix`; the four assertions; `tests/integration/github-fetch-credential-test.nix` wired in `tests/integration/default.nix` and exposed as `checks.integration-github-fetch-credential` (evaluated by `nix flake check`; built by the e2e runner) | CLEAN |
| RED evidence | each scenario's targeted command failed non-zero for the reason `design.md` predicted: thiniel `attribute 'githubFetchCredential' missing` (exit 1); J6G6Y9JK7L `attribute '"nix/nix.conf"' missing` (exit 1); adlerkopf `attribute 'mySystem' missing` (exit 1); the VM `flake … does not provide attribute … integration-github-fetch-credential` (exit 1). Every command matches `docs/GIVN-VERIFICATION.md`'s "Single-scenario (targeted) run" table. The VM RED is the target's absence, which is this scenario's documented RED mode (the target is new; the module that makes it pass was implemented in scenario 1) | CLEAN |
| E2E reality | `tests/integration/github-fetch-credential-test.nix` calls `machine.start()` and `wait_for_unit("multi-user.target")`, then asserts the booted guest's `stat -c '%a %U'` is `400 owner`, that `nix config show access-tokens` reports `github.com=<fixture value>` for the owner's account **and** for root, and that a second account's `cat` fails — real booted state, not an evaluation | CLEAN |
| E2E isolation | `verify.command` = `./scripts/givn-verify.sh`, `verify.e2e_command` = `./scripts/givn-verify-e2e.sh` — different strings; the e2e runner builds only `integration-*` attributes; `scripts/givn-scenario-count.py` reports regular `21`, e2e `8` (total `29`), so the e2e scope is a strict subset | CLEAN |
| Safety | no plaintext secret in any changed file: the only age-key-family / `ghp_`-family matches are the literal pattern names in `design.md` and the test's comment; `hosts/*/secrets.yaml` are unchanged; the fixture's key is generated inside a derivation; `.pre-commit-config.yaml` and the gitleaks config are untouched; `scripts/` is untouched (no sops or decrypt invocation); the only sops invocations are the fixture's build-time `sops --encrypt` to a generated key, which the design records as the deliberate way to keep the scanners strict; no host's `stateVersion` changed (the new `system.stateVersion = "25.11"` is the VM guest's); `hosts/*/hardware.nix` untouched. `python3 scripts/private_data_hygiene.py --tree .` reports findings only in pre-existing files (`docs/plans/private-data-remediation-plan.md`, `hosts/*/private.nix`, the gitignored `ROTATION-TODO.md`), none of them in this change | CLEAN |
| Dangerous areas | the change touches secret wiring; `design.md` carries a "Deployment & Rollback" section with the operator step, the apply commands and concrete rollbacks (`nixos-rebuild switch --rollback` / `darwin-rebuild switch --rollback`) | CLEAN |
| Design conformance | the module, its option names, the rendered fragment content and owner/mode, the include mechanism, the four assertion files and the VM check all match `design.md` as reviewed. The two factual corrections found while wiring the VM (nested `github:` → `access-token:` key; the initrd tmpfiles mechanism instead of `sops.age.keyFile` + system tmpfiles) were folded into `design.md` and re-reviewed (`design-review.md`), not kept silently | CLEAN |

0 fabricated scenarios/targets found across 4 scenarios.

## Arc42 implementation conformance

Independent walk of the twelve durable chapters against `design.md`, `tasks.md`
and the completed implementation gives affected = 05, 06, 08, 09, 10, 11, 12 and
unaffected = 01, 02, 03, 04, 07 — matching both `design.md` and `arc42.md`.

| Arc42 chapter or fact | Durable-doc source | `arc42.md` claim | `design.md` | `tasks.md` | Implementation evidence | Match? |
|---|---|---|---|---|---|---|
| New NixOS option pair and the 7th integration check | `05-building-block-view.md:89,167` | row 05 | "Architecture Impact" | Scenarios 1–4 | `modules/nixos/github-fetch-credential/`, `tests/integration/github-fetch-credential-test.nix` | MATCH |
| Credential-supply runtime flow (per-platform render layer) | `06-runtime-view.md:230` | row 06 | "Render layer" decisions | Scenario 4 | module + VM boot | MATCH |
| New cross-cutting concept + present-pairs list | `08-crosscutting-concepts.md:85,159` | row 08 | "Architecture Impact" | Scenarios 1–4 | module with `options ? sops` guard | MATCH |
| ADR candidate row, register unchanged | `09-architecture-decisions.md:60` | row 09 (NOT_QUALIFIED) | "Decisions" | — | `design-review.md` ADR verdict | MATCH |
| Quality scenario QS-017 | `10-quality-requirements.md:56` | row 10 | "Verification Binding" | Scenario 4 | the booted check's assertions | MATCH |
| Risks R-026–R-029, debt TD-016 | `11-risks-and-technical-debt.md:35-38,60` | row 11 | "Secrets & Safety", "Open Technical Questions" | — | design + fixture rationale | MATCH |
| Glossary term *GitHub fetch credential* | `12-glossary.md:23` | row 12 | Summary | — | module, assertion names | MATCH |

Every affected chapter contains current, decision-specific content (no
placeholder). Chapters 01–04 and 07 were re-read and correctly left untouched:
the change adds no goal, constraint, external partner, strategy or topology.

ARC42 CONFORMANCE: CLEAN

## Coverage gap classification

| Location | Traceability finding | Classification | Action |
|---|---|---|---|
| `integration-adlerkopf` | referenced by no scenario | Bucket 1 (pre-existing; standing operator decision recorded in `givn/archive/host-specific-ssh-identities/review.md`) | Keep |
| `integration-vm-minimal-ssh` | referenced by no scenario | Bucket 1 (pre-existing; its scenario lives in the unscanned reference template `givn/artifacts/specs/spec.feature`) | Keep |

No bucket-2 gap: all four scenarios of this change are bound to exactly one
existing target, and each target's recorded RED failed before its
implementation. No bucket-3 target, no invented fourth bucket.

## Overlap dispositions

For every shape-match finding involving this change's delta, one row.
Decision must be one of: `duplicate`, `variant`, `boundary`.

| Scenario A | Scenario B | Disposition |
|---|---|---|
| The laptop declares the credential it presents to the GitHub host | The work MacBook declares the credential it presents to the GitHub host | variant |

The two scenarios hold the same contract for two devices whose credential
supply differs by platform (system activation vs. home-manager session) and is
proven by two different host assertion modules. This per-device shape is the
repository's established pattern (`permitted-identity-selection`,
`current-agent-tooling`, `managed-file-displacement`) and is accepted in
`design.md` ("The `givn lint` shape advisory … is accepted deliberately"). No
removed+added pair exists (all four delta scenarios are `@givn.added`), so there
is no supersession to explain, and no scenario exceeds the long-scenario
threshold, so no split-or-keep row is required.

## Delta-spec merge readiness

The delta feature is `@givn.delta @github-fetch-credential` with four new
`@givn.added` scenarios whose titles do not exist in the permanent corpus
(`givn/specs/reproduce-working-environment/` holds
`current-agent-tooling.feature`, `managed-file-displacement.feature`,
`permitted-identity-selection.feature`), so the merge is a clean append with no
title collision. The delta `usecase.md` preserves the base revision
(`7b854f…`), adds the capability `github-fetch-credential` (declared, with its
interaction row) and adds no conflicting relationship. Merge is ready.

## Independent checks re-derived

- `!include` tolerance (the design's "missing and unreadable both leave exit
  status 0"): reproduced with an isolated `NIX_CONF_DIR` — a readable include
  yields the value (`exit 0`), while a mode-`000` include and a missing include
  both leave `exit 0` with no stderr. The blast-radius claim holds: an account
  that cannot read the fragment keeps running nix.
- Promised flake check resolves: `nix flake check` evaluated
  `checks.x86_64-linux.integration-github-fetch-credential` to
  `…-vm-test-run-github-fetch-credential.drv`.
- Both runners: `./scripts/givn-verify.sh` → `[givn-verify] OK`; `./scripts/givn-verify-e2e.sh`
  → `[givn-verify-e2e] OK`.

## Use-case and Persona conformance

Owning contract: `reproduce-working-environment`, carried in this change with
the new capability `github-fetch-credential`, its two rules (a device presents
only the credential it declares, readable by root and the owner alone, never a
world-readable path or a process environment variable; the credential is
recorded only encrypted and a rerooted device re-materialises it), an example
and its interaction row. Goal, guarantees, actors and typed relationships are
unchanged. Goal and success guarantee are single outcomes, the trigger names the
primary actor, and no added rule or interaction names a mechanism. No Persona was
invented: `owner--operator` (confirmed 2026-10-11) is the operator whose own
machines and credential this is; `family--application-user` is not affected — no
hosted application, shared resource or access path changes.

## Deferrals

None for the change's checks. The operator-only steps are recorded, not
deferrals of a mandatory check: adding `github/access-token` to the two
`secrets.yaml` files is human-only and needed only to deploy, and the
MacBook's runtime state is confirmed on the machine because that host cannot be
built off macOS. Neither gates this change: the declared state is asserted at
evaluation time and the materialisation is proven by the booted VM check.

## Sign-off

- [x] Review gate integrity (tasks.md revision identifiers) — fixed; B-1 resolved.
- [x] Traceability exits 0; one binding per scenario; no unbound scenario; `@e2e` bound to a VM check.
- [x] Every checked task has a verified commit touching real configuration.
- [x] Every promised module/option/host/check exists; the new check is exposed as `checks.integration-github-fetch-credential`.
- [x] Every scenario's targeted RED failed non-zero for its own stated reason before the implementation, and passes after.
- [x] No `@e2e` tag was removed; the booted check asserts real booted state (mode/owner, owner and root `nix config show`, a second account's read fails).
- [x] `verify.e2e_command` differs from `verify.command`; the e2e scope is the `integration-*` subset (8 of 29 scenarios).
- [x] Safety: no plaintext secret, no sops or decrypt invocation in any script, `stateVersion`/`hardware.nix` untouched, the secret scans unchanged.
- [x] A secret-wiring change carries a "Deployment & Rollback" section with concrete rollbacks.
- [x] Implementation (commands, file layout, check names) matches `design.md`; the two corrections went through a `design.md` update and re-review.
- [x] Every coverage gap classified (two pre-existing bucket-1 checks kept) and resolved; no finding excused outside the three buckets.
- [x] Both runners green: `./scripts/givn-verify.sh` → `[givn-verify] OK`; `./scripts/givn-verify-e2e.sh` → `[givn-verify-e2e] OK`.
- [x] Fabrication audit clean: 0 fabricated scenarios/targets.
- [x] Arc42 conformance clean; ubiquitous language clean (`GitHub fetch credential` is in the glossary, in alphabetical order, and used consistently).
- [x] `givn lint` clean (only the accepted shape advisory, dispositioned above); no `@wip` remains.

README-IMPACT: none. The `readme` addon is disabled (`readme: false`), and the
change adds no command, flag or configuration key a README reader would use: it
declares a per-machine secret, one option pair and one integration check. The
behaviour is documented in the arc42 set (chapters 6, 8) and the glossary, which
is where a reader looks for it.

REVIEW: PASS
