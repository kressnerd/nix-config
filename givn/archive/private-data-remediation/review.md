# Review: private-data-remediation

## Method

A delegated reviewer with no part in writing the change performed the review
skill's Step 0 fabrication audit (items 0–10) and the arc42
implementation-conformance check, reading the artifacts, the implementation, the
ten commits and the durable chapters. The orchestrator ran the two full runners
and the static checks, then applied every finding and re-ran them.

Change commits (`git log 6b3c446..HEAD`): `bbc97c1`, `f2ea2e9`, `35046ca`,
`6e77270`, `3dfcbbe`, `780bdec`, `c3581fe`, `72c5afa`, `2c4e938`, `799ae19`.
The history was rewritten with `git filter-repo` on 2026-10-12, so the
implementation revision is `bbc97c1` here and was `4c456b7` before the rewrite
(the reviewer confirmed the remap by the identical tree hash in the pre-rewrite
mirror). `tasks.md` records the post-rewrite hash.

Verification receipt (orchestrator, on the working tree):

```
$ python3 scripts/givn-spec-trace.py
[warn] integration check 'integration-adlerkopf' is not referenced by any scenario
[warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
givn-spec-trace: 9 scenario(s) across 2 feature file(s), 0 finding(s)

$ ./scripts/givn-verify.sh
[givn-verify] 1/5 spec traceability … 5/5 python test suite (scripts/)
256 passed in 8.09s
[givn-verify] OK

$ ./scripts/givn-verify-e2e.sh
[givn-verify-e2e] OK

$ git ls-files -z | xargs -0 python3 scripts/private_data_hygiene.py
[private-data-hygiene] no operational value, private-value file or plaintext secret recorded

$ givn lint --change private-data-remediation
givn lint: 1 file(s) checked — clean
```

## Step 0 — fabrication audit

**No fabricated scenario and no fabricated target.** All five scenarios bind to
exactly one resolving target each — three real flake checks and one real
`runNixOSTest` boot — the trace exits 0, and every artifact and check `design.md`
promised exists and passes.

| # | Check | Result |
|---|---|---|
| 0 | `@e2e` tag integrity | **Clean.** One `@e2e` scenario, bound to `@check:integration-private-data-separation`; no commit ever removed an `@e2e` tag (the reviewer checked `git log -p` across the change). |
| 1 | Traceability | **Clean.** 9 scenarios, exactly one binding each, all resolve; no `@e2e` on a unit/lint check. |
| 2 | Commit cross-check | **Clean after R-8.** Every checked task maps to a commit touching real configuration (`flake.nix`, `scripts/`, `tests/`, `hosts/`, `home/`); the recorded hash was stale after the rewrite and is remapped (R-8). |
| 3 | Promised-target existence | **Clean.** `private-stub/flake.nix`, `scripts/private_data_hygiene.py`, `tests/integration/private-data-separation-test.nix`, `.pre-commit-config.yaml`, `.github/workflows/secret-scan.yml`, `docs/arc42/adr/ADR-0001-private-data-strategy.md`, the two rebuild aliases, and the checks `private-data-defaults` / `private-data-hygiene` / `integration-private-data-separation` all exist. |
| 4 | RED evidence | **Finding R-5/R-6, remediated.** Scenarios 2–5 had no bound-target RED (the target did not resolve before implementation). Re-demonstrated at review by removing the implementation and observing the target fail for the expected reason — see "Bound-target RED re-demonstrations". |
| 5 | E2E reality | **Clean.** The `@e2e` target boots (`machine.start()`, `multi-user.target`, `systemd-networkd.service`) and asserts the booted interface carries the supplied address and not the placeholder — a real boot. |
| 6 | E2E isolation | **Clean after R-9.** `verify.command` ≠ `verify.e2e_command`; the `@e2e` scope is 2 of 9 scenarios (this change's one plus the sibling change's), a strict subset. |
| 7 | Safety | **Clean.** No plaintext secret added; no decryption invocation added; no `stateVersion` touched; `hosts/*/hardware.nix` untouched by any change commit. |
| 8 | Dangerous areas | **Clean.** The change touches `networking`; `design.md` carries a Deployment & Rollback section with the apply command, on-host verification, the out-of-band recovery per host, and the preflight. |
| 9 | Design conformance | **Findings R-1 to R-4, R-10 to R-12 (documentation drift), remediated.** Check names, file layout and commands match `design.md`; the scenario-1 rebinding was recorded in `design.md` and re-reviewed. |
| 10 | Remaining unfinished work | **None** after the remediations below. |

### Bound-target RED re-demonstrations

Scenarios 2–5 originally recorded the *unresolved binding* as their pre-state
(honest, and `design.md` records the shared-target limitation for 2–4, but not a
failing target). Each target was therefore re-demonstrated by removing the
implementation and rebuilding:

| Scenario | Probe | Observed |
|---|---|---|
| 2 — the repository records no operational value | a staged file recording an operational value | `nix build …private-data-hygiene` → exit 1, `home-LAN subnet is recorded`, 1 finding |
| 3 — the value rule rejects | `VALUE_PATTERNS` emptied | exit 1, `guard accepted the value fixture` |
| 4 — the file and secret rules reject | `PRIVATE_VALUE_BASENAMES` / `SECRET_BASENAMES` emptied (value rule intact) | exit 1, `guard accepted the file fixture` |
| 5 — a booted host uses supplied values | the test module supplies `203.0.113.10` instead of `198.51.100.10` | exit 1, `RequestedAssertionFailed: command `ip -4 addr show | grep -F '198.51.100.10'` failed` |

Each probe was reverted from `HEAD` and the target confirmed passing again.
Scenario 1's original RED was a genuine failing assertion (the stub assertion on
the real defaults, exit 1), recorded in `tasks.md`.

## Arc42 implementation conformance

Independently re-derived from the implementation, `design.md` and `tasks.md`,
then compared against the durable chapters and `arc42.md`.

| Chapter / fact | Durable source | `arc42.md` claim | `design.md` | `tasks.md` | Implementation evidence | Match |
|---|---|---|---|---|---|---|
| Ch02 — `git+file://` constraint, stub must stay non-operational, guard rule | `02-architecture-constraints.md:18-20` | Yes | Technology Decisions | P1–P4 | `flake.nix` `inputs.private`; `private-stub/flake.nix`; `scripts/private_data_hygiene.py` | yes |
| Ch04 — key decision 9 and the technology row | `04-solution-strategy.md` | Yes | D1/D2, Overview | — | the same artifacts | yes |
| Ch05 — stub block, guard in support tooling, four integration checks | `05-building-block-view.md:42,51,140` | Yes | Architecture Impact | P2, scenario 5 | `private-stub/`, `tests/integration/default.nix` (4 entries) | yes |
| Ch06 — validation checks, the new scenario, the deploy failure mode | `06-runtime-view.md:33-38,49-97` | Yes | Verification Binding | scenarios 1–5 | `flake.nix:463` exposes `private-data-defaults`; the VM check boots | yes after R-1, R-10 |
| Ch07 — placeholders, private input, deploy commands | `07-deployment-view.md` | Yes | Document sanitization | scenario 2 | `hosts/adlerkopf/options.nix`; `home/dan/*.nix` aliases | yes |
| Ch08 — the concept, its failure mode, its verification | `08-crosscutting-concepts.md:38-78` | Yes | Deployment & Rollback | — | guard, stub, VM check, preflight | yes after R-1, R-4 |
| Ch09 — ADR-0001 registered | `09-architecture-decisions.md:16` | Yes | Decisions D1/D2 | — | `docs/arc42/adr/ADR-0001-private-data-strategy.md` | yes after R-12 |
| Ch10 — QS-001 / QS-002 | `10-quality-requirements.md:40-41` | Yes after R-3 | Overview | P5 | `nix flake check` green; all five configurations resolve | yes after R-3 |
| Ch11 — R-008, R-015, R-016, R-017 | `11-risks-and-technical-debt.md:18-21` | Yes | Blast Radius, Deployment & Rollback | rewrite tasks | `hosts/adlerkopf/tpm2.nix` fixed (`6e77270`) | yes |
| Ch12 — six new terms, the check list | `12-glossary.md:11,16,20,33,38,42` | Yes | — | — | the terms are used by the spec and the guard | yes after R-11 |
| Ch01, Ch03 — unaffected | chapter files | No | — | — | unchanged | yes |

ARC42 CONFORMANCE: CLEAN

## Ubiquitous language

The spec, `design.md`, the guard and the chapters reuse the same terms:
operational value, per-host private-value file, private source, documentation-range
placeholder, guard, stub, private input. All six are defined in
`docs/arc42/12-glossary.md`; the reviewer found no load-bearing term without a
row. The guard's own class labels (the `VALUE_PATTERNS` descriptions) are the
vocabulary the design's sanitization table now cites, which is why the table no
longer reproduces any literal value.

UBIQUITOUS LANGUAGE: CLEAN

## Overlap dispositions

`givn spec duplicates` reports `0 exact/structural match(es)` and
`givn spec coverage` reports `0 behavior entries, 0 @e2e` — the permanent corpus
is still empty (this change and the sibling `host-specific-ssh-identities` are
both unarchived). There are therefore no shape-match rows and no removed+added
pairs to disposition.

## Split-or-keep

The deterministic gate emitted no long-scenario finding. The longest scenario is
`The repository records no operational value` (four steps, three `Then`s): it is
**KEEP** — the three `Then`s are the one obligation the check enforces (a clean
tree), they cannot be RED'd independently, and splitting would produce scenarios
whose target cannot fail on its own. The same reasoning covers the shared
`private-data-hygiene` target for scenarios 2–4, recorded as an accepted
limitation in `design.md`.

## Traceability gap classification

| Gap | Classification | Disposition |
|---|---|---|
| `integration-adlerkopf` unreferenced | Bucket 1 — dead configuration as measured by the traceability model (an `integration-*` check no scenario binds; it is a real VM boot, so not bucket 3) | **Kept, with the operator's awareness.** It predates this change and verifies adlerkopf's service stack; deleting another change's verification was rejected. It stays visible in the traceability warning until the change that specifies adlerkopf's capability binds it. |
| `integration-vm-minimal-ssh` unreferenced | Bucket 1 — same | **Kept, with the operator's awareness**, for the same reason (the minimal VM's SSH access belongs to a future capability's spec). |

This change's own new check is referenced by its `@e2e` scenario, so it adds no
new gap. No fourth bucket is used.

## Findings

| # | Finding (from the delegated audit) | Severity | Disposition |
|---|---|---|---|
| R-1 | `docs/arc42/08-crosscutting-concepts.md` re-introduced the falsified claim that the stub assertion catches a forgotten `--override-input`, contradicting its own next paragraph and `design.md`/`ADR-0001`/R-008. | high | Fixed: the failure mode now states the assertion guards the defaults and the preflight refuses the deploy. |
| R-2 | `docs/arc42/06-runtime-view.md` asserted "the failure mode of a forgotten override is a failed evaluation (the stub assertion)", falsified by `design.md`. | high | Fixed: rewritten to name the preflight, consistent with the same chapter's closing sentence. |
| R-3 | Chapter 10's QS-001 still said the result depended on `hosts/adlerkopf/private.nix` and QS-002 marked adlerkopf blocked — both falsified by this change. | medium | Fixed: QS-001/QS-002 updated; `arc42.md` row 10 changed from "No" to "Yes". |
| R-4 | Stale `@host:adlerkopf` references survived in `02-architecture-constraints.md:19`, `08-crosscutting-concepts.md:68` and `tasks.md:34`. | low | Fixed: all three now name `@check:private-data-defaults`. |
| R-5 | Scenarios 2–5 had no bound-target RED (their pre-state was the unresolved binding). | medium | Fixed: re-demonstrated per scenario (table above). |
| R-6 | Scenarios 3 and 4 pasted passing (GREEN) output where RED evidence belongs. | medium | Fixed: the true RED runs (fixture accepted) are now pasted, with the GREEN runs kept where they belong. |
| R-7 | P5 was ticked with `<paste>` placeholders for its evidence. | medium | Fixed: the real `nix flake check` output and the override values are recorded, with the store-path comparison replaced by a value comparison and the reason stated. |
| R-8 | The SHA remap and the *Intended*-marker removal were staged but uncommitted, so `HEAD` still carried the stale hash and markers. | medium | Fixed: committed with this review. |
| R-9 | The E2E-setup task recorded "1 of 9" `@e2e` scenarios; the corpus holds 2 (this change's plus the sibling's). | low | Fixed: now "2 of 9", still a strict subset. |
| R-10 | `docs/arc42/README.md` said "three QEMU VM checks"; the flake exposes four. | low | Fixed. |
| R-11 | Chapter 6's validation step omitted `private-data-defaults`. | low | Fixed; `arc42.md` row 6 and the glossary row aligned. |
| R-12 | `ADR-0001`'s `alternatives` evidence named a private git submodule while its `## Considered Options` named git-crypt. | low | Fixed: the evidence now names the same six mechanisms and records the submodule as a variant of the chosen shape. |

## Use-case and Persona conformance

Owning use case: `publish-infrastructure-configuration`, introduced by this
change; capability `operational-data-separation`. The implementation matches the
contract: hosts receive their operational values only from outside the repository,
the public defaults stay non-operational, a revision that would record an
operational value or a private-value file or an unencrypted secret is refused, and
a checkout without private values still evaluates. The main flow's step 5
(confirming the published history) is discharged by the rewrite recorded in
`tasks.md`. No use-case scope-rejection criterion applies: one goal, one primary
actor (the owner/operator, named in the trigger), no capability placement
failure, no mutation under an observing goal, extensions reference their steps,
preconditions are not established by the flow, and the goal and guarantees name
no mechanism.

Personas: `owner--operator` (confirmed 2026-10-11) — the only actor; the change
is the operator's own repository and hosts. `family--application-user` —
recorded as unaffected, with the reason (no hosted application, access path or
shared resource changes). No Persona is invented, silently promoted, or used as
a Gherkin actor.

## Sign-off checklist

- [x] Fabrication audit clean across items 0–10; all findings remediated.
- [x] `scripts/givn-spec-trace.py` exits 0; every scenario bound to exactly one
      existing target; no unbound scenario.
- [x] Every checked task has a commit touching real configuration; the recorded
      hash resolves (remapped after the rewrite).
- [x] Every promised module/option/host/check exists and is exposed.
- [x] Bound-target RED evidence present for every scenario (scenario 1's failing
      assertion; scenarios 2–5 re-demonstrated by removing the implementation).
- [x] Every `@e2e` scenario binds to `@check:integration-*` and actually boots; no
      `@e2e` tag was removed.
- [x] `verify.e2e_command` is not identical to `verify.command`; the e2e scope is
      the `integration-*` subset (2 of 9 scenarios).
- [x] No plaintext secret; no decryption invocation; `stateVersion` and
      `hosts/*/hardware.nix` untouched.
- [x] The dangerous area (`networking`) carries a design.md Deployment & Rollback
      section.
- [x] Implementation matches the reviewed `design.md`; the two deviations (the
      scenario-1 rebinding, the R-017 rationale) went through a design.md update
      and a design-review re-run, not a silent shortcut.
- [x] Coverage classification uses the traceability run; every gap classified and
      resolved (two pre-existing unreferenced checks kept with the operator's
      awareness; none of this change's own gaps).
- [x] No `@wip` tags remain; no implementation-layer detail in the spec.
- [x] Scenario execution evidence recorded per scope in this receipt.
- [x] No finding excused with a classification outside the three buckets.

## Archive note

Archiving this change is a separate step (`givn archive --change
private-data-remediation`). It merges the delta into the permanent corpus,
creating the first permanent use case, and requires a clean tree; the sibling
change `host-specific-ssh-identities` is also `ready-to-archive` and its recorded
blocker is now gone, so it should be archived after this one.

REVIEW: PASS
