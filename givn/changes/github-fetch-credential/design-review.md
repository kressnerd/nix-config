# Design Review: github-fetch-credential

## Method

Four passes against the planning layer (`proposal.md`, the delta spec and use
case, `design.md`, `arc42.md`), the durable chapters the change edits, the
permanent use case, `docs/GIVN-VERIFICATION.md`, the repository rules and the
affected wiring (`flake.nix`, `hosts/**`, `tests/**`, `modules/**`,
`.pre-commit-config.yaml`, `.github/workflows/secret-scan.yml`). Load-bearing
claims were re-derived from the pinned sources (`Mic92/sops-nix` @ `ee48786`,
the Nix 2.35 manual, the gitleaks default rule set) and by direct command
(`nix config show` include probes, `readlink`/`stat` on the live rendered
template, `givn lint`, `scripts/givn-spec-trace.py`). This reviewer produced only
this artifact; every fix was applied by the change author, and each pass
re-verified what the pass before it raised.

## Findings and dispositions

| # | Pass | Was | Finding | Status |
|---|---|---|---|---|
| F-001 | 1 | Blocking | The VM fixture committed a plaintext age private key, which this repository's own gitleaks scan refuses (`age-secret-key` rule; `.pre-commit-config.yaml:13-17`; `.github/workflows/secret-scan.yml:21`; no allowlist) | **Resolved** — the fixture is now a build-time derivation; design.md's rejected alternative 7 names the rule, `docs/arc42/11` TD-016 records the non-reproducibility, and the "Unchanged" set names the gitleaks configuration |
| F-002 | 1 | Blocking | The fragment came from the owner's user session, so the `@e2e` VM test could not reach GREEN and root's boot-time reach was not guaranteed | **Resolved** — the Linux host renders through **system** activation into `/run/secrets/rendered/` (verified against sops-nix's NixOS template defaults and `pkgs/sops-install-secrets/main.go`: parent dirs `0751`, file written with the declared mode and chowned to the declared owner). The Mac's session-time rendering is recorded as R-029 (Low/Low) and accepted |
| F-003 | 1 | Blocking | `design.md`'s arc42 impact section contradicted `arc42.md` and the committed chapter edits | **Resolved** — now lists 05, 06, 08, 09, 10, 11, 12 and leaves 1, 2, 3, 4, 7 unchanged |
| F-004 | 1 | Blocking | The non-qualified ADR candidate named two canonical destinations | **Resolved** — `arc42.md:62` and `docs/arc42/09-architecture-decisions.md:60` both name exactly `givn/changes/github-fetch-credential/design.md` |
| F-005 | 1 | Advisory | The Decisions ledger quoted a proposal wording the proposal no longer carried | **Resolved** — quotes the proposal's current custody bullet verbatim |
| F-006 | 1 | Advisory | `@check:integration-github-fetch-credential` does not resolve yet (`givn-spec-trace` exit 1) | **Open, tracked deferral** — see "Tracked deferral" below |
| F-007 | 1 | Advisory | The use-case rule claimed an unasserted "reported" behaviour for a missing credential | **Resolved** — the rule now reads "…leaves the device's fetches unauthenticated, never silently replaced by another account's" |
| F-008 | 1 | Advisory | `givn lint` shape advisory: the two per-host scenarios share a shape | **Accepted and recorded** in `design.md`'s Verification Binding section (per-host assertion modules are this repository's per-device proof shape; the permanent spec uses it too) |
| F-009 | 1 | Advisory | The home-manager-side mechanism was not named | **Resolved** — `nix.extraOptions` (NixOS), `xdg.configFile."nix/nix.conf"` and the activation-written root file (Darwin) |
| N-001 | 2 | Blocking | The Mac's `sops.secrets`/`sops.templates` were placed in the darwin host module, contradicting the design's own Darwin render-layer decision and unevaluable there (only `sops-nix.homeManagerModules.sops` is imported, `flake.nix:377-382`) | **Resolved** — the secret and template are declared in `home/dan/J6G6Y9JK7L.nix`; the host module carries only the activation script, and the design records why (`design.md:118-124`, `:232-235`, `:244-247`; `docs/arc42/05:107`) |
| N-002 | 2 | Blocking | The exclusion assertion reads `mySystem.githubFetchCredential.enable` on adlerkopf, but no import site gave that host the option | **Resolved** — `hosts/common/global/default.nix` imports the pair, so every NixOS host has it; verified each of thiniel, adlerkopf, cupix001 and nixos-vm-minimal imports `../common/global` exactly once, the Darwin host imports nothing from `hosts/common`, and the default `false` declares nothing (`design.md:41`, `:238-241`) |
| N-003 | 2 | Advisory | `docs/arc42/10-quality-requirements.md:64` still described a "committed test fixture" | **Resolved** — now "a fixture its own derivation generates … never any recorded key" |
| N-004 | 2 | Advisory | `integration-github-fetch-credential` was still counted as a Home-Manager-loading check justified by the HM release pairing | **Resolved** — `docs/arc42/05:167` lists three HM-loading checks, `design.md:186-192` says the test follows `private-data-separation-test.nix`'s shape (plain package set, no HM pairing), and `arc42.md:31` now says "third" |
| N-005 | 2 | Advisory | The VM assertion "the value appears in … any store path the test greps" was unsatisfiable for the fixture's own dummy value | **Resolved** — `design.md:199-203` scopes the absence check to configuration files and the area outside the runtime secret directory, and states that the fixture's own store paths are ignored |
| O-001 | 3 | Blocking | `design.md`'s "Unchanged" list still excluded `hosts/common/**` while the "Changed" list added the option import there | **Resolved** — the line now reads "Unchanged: every other host profile and every other host module, `hardware.nix`, `stateVersion`, `.sops.yaml` …, `.pre-commit-config.yaml` and the gitleaks configuration" |
| O-002 | 3 | Advisory | `arc42.md:31` contradicted chapter 5 on the Home-Manager-loading check count | **Resolved** — `arc42.md:31` and `docs/arc42/05:167` both say three |

## Branch dispositions (final)

| Branch | Result |
|---|---|
| Scope | No finding. The spec covers exactly the proposal (both build machines declare, a non-build host declares none, a booted device materialises and both accounts present it); the out-of-scope items are asserted by no step. |
| Tech choices | No finding. `!include` tolerance re-verified (`NIX_CONFIG='!include /nonexistent/xx' nix config show` → exit 0; `!include /etc/shadow` as a non-root account → exit 0; the strict `include` form → exit 1); the home-manager `sops.templates` defaults (`…/rendered/<name>`, mode `0400`, written as the user) match the design and are live in this repository (`readlink -f ~/.gitconfig` → `/run/user/1000/secrets.d/35/rendered/gitconfig`, `-r--------`, owner `dan`); the NixOS system template supports `owner`/`mode` and its default path is `/run/secrets/rendered/<name>`; nix reads `~/.config/nix/nix.conf` per the Nix 2.35 manual, which the Darwin include relies on. |
| Missing scenarios | No finding. The use-case rule's failure wording is fixed; the store-path/process-environment prohibitions are asserted by the `@e2e` target, which is allowed to assert more than the scenario states. |
| Testability | No finding. Scenarios 1 and 3 fail first on the absent option (assertion wired before the option module lands), then pass once the option exists and the host opts in; scenario 2 fails on its named assertions, which are written against existing options; the `@e2e` target now needs no user session and its absence assertion is scoped. |
| Verification binding completeness | No finding. Four scenarios, exactly one binding tag each; the `@e2e` scenario binds to a `@check:integration-*` name; `verify.e2e_command` differs from `verify.command`; the three `@host:` names resolve. |
| Binding coverage | No finding beyond the F-006 deferral: every scenario has a design row with a bound target and a targeted command, and the design records the exact RED for the target that is not yet wired. |
| Deployment & rollback | No finding (secret wiring): the operator encryption step precedes the apply, both apply commands and the on-host checks are given, and rollback is `--rollback`/generation selection with the include failing soft. |
| Persona disposition | No finding: `owner--operator` (confirmed 2026-10-11) relevant; `family--application-user` unaffected; no Persona invented, promoted, or used as a Gherkin actor. |
| ADR qualification | No finding: one candidate, `NOT_QUALIFIED`, one canonical destination, evidence matching `design.md`'s alternatives; no MADR required and none missing. |
| Risk | Recorded: R-026 (the surviving plaintext token file), R-027 (the repository's own failing evaluation, carried as D2 with owner *the operator*), R-028 (the Mac's root-side file), R-029 (the Mac's session-time rendering), TD-016 (the fixture's non-reproducibility). Each names its mitigation; the deployment rollback path is recorded. |
| arc42 chapters | No finding. Independent walk of the selection table: Yes = 05, 06, 08, 09, 10, 11, 12; No = 01, 02, 03, 04, 07 — matching `arc42.md`. All twelve chapter files exist with real content and no ASCII-art diagrams; the edited chapters match the design; the glossary carries *GitHub fetch credential* with its contrast pair; every edit is now consistent with every other. |
| Ubiquitous language | No finding: the design's load-bearing terms are in `docs/arc42/12-glossary.md`, and no term is reused inconsistently. |
| Gates | `givn lint --change github-fetch-credential` exits 2 (four `@wip` findings plus the accepted F-008 shape advisory); `scripts/givn-spec-trace.py` exits 1 on the F-006 deferral, whose resolution condition is recorded below. |
| Open technical questions | O1 (macOS `sudo`/`HOME`) is covered by writing root's own file and confirmed on the machine; O2 (Determinate Nix drop-ins) is optional; O3 (fixture reproducibility) is accepted as TD-016. None is a blocker. |

## Tracked deferral

**F-006 — the `@e2e` target is not wired into the flake yet.**
`scripts/givn-spec-trace.py` exits 1 with that single finding today. Per
`docs/GIVN-VERIFICATION.md`, a change wires a new target *before* its RED run:
the tasks step adds `tests/integration/github-fetch-credential-test.nix` to
`tests/integration/default.nix` and exposes
`checks.integration-github-fetch-credential` in `flake.nix`, and
`givn-spec-trace` must then exit 0. No `@e2e` tag was moved or removed, and no
gate is bypassed — the check is planned, not suppressed.

## Sign-off

All findings from all four passes are resolved or explicitly accepted; the one
open item is the recorded tasks-step deferral above, which the design plans and
which cannot be closed before that step.

DESIGN-REVIEW: PASS
