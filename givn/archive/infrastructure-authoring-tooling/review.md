# Review: infrastructure-authoring-tooling

## Fabrication audit

0. **@e2e tag integrity** — clean. The change's feature file carries one
   `@e2e` scenario, and it is still tagged `@e2e`; no tag was removed. The
   traceability check binds it to
   `@check:integration-infrastructure-tooling`.
1. **Traceability** — `python3 scripts/givn-spec-trace.py` exits 0:
   ```
   givn-spec-trace: 35 scenario(s) across 8 feature file(s), 0 finding(s)
   ```
   Every scenario carries exactly one binding tag. `@host:thiniel` resolves in
   `nixosConfigurations`; `@check:integration-infrastructure-tooling` exists in
   the flake `checks` output. The only output is the pre-existing advisory that
   `integration-adlerkopf` and `integration-vm-minimal-ssh` are not referenced
   by a scenario; this change neither introduces nor changes either check.
2. **Commit cross-check** — every checked task is backed by a commit touching
   real configuration:
   - `2966631` — feature module (OpenTofu), thiniel import, host assertion,
     integration target wiring, arc42 chapter update.
   - `f784a92` — GitHub CLI package and its assertion/guard.
   - `003403c` — the change's planning artifacts under `givn/changes` and the
     ejected arc42 template; the e2e target it names was wired and green under
     the two implementation commits above.
   No checked task rests only on a spec or artifact-only diff.
3. **Promised-target existence** —
   - `home/dan/features/cli/infrastructure-tooling.nix` exists and is imported
     by `home/dan/thiniel.nix`.
   - `tests/assertions/thiniel-invariants.nix` carries the OpenTofu assertion
     and the combined GitHub-client/credential-helper assertion.
   - `tests/integration/infrastructure-tooling-test.nix` exists and is
     registered in `tests/integration/default.nix`, which exposes
     `checks.x86_64-linux.integration-infrastructure-tooling`.
4. **RED evidence** — present in `tasks.md` for every scenario:
   - OpenTofu: host evaluation exited 1 with the named assertion.
   - GitHub CLI: host evaluation exited 1 with the named assertion.
   - E2E: the check exited 1 with "Path
     'home/dan/features/cli/infrastructure-tooling.nix' does not exist", then
     exited 0 after implementation.
   `verify.command` and `verify.e2e_command` are different strings in
   `givn/commands.yaml`.
5. **E2E reality** — the check boots a QEMU guest, waits for
   `home-manager-test.service`, and runs `tofu version` and `gh --version` as
   the ordinary test user from `/etc/profiles/per-user/test/bin`. It asserts a
   real boot, not an evaluation.
6. **E2E isolation** — 10 e2e scenarios out of 35 total (25 regular). The e2e
   scope is strictly smaller; `scripts/givn-verify-e2e.sh` builds only the
   `integration-*` checks.
7. **Safety** — no plaintext secret is added; no `sops`/decrypt invocation
   appears in any commit or script; `system.stateVersion`/`home.stateVersion`
   are unchanged; `hosts/thiniel/hardware.nix` is untouched.
8. **Dangerous areas** — none touched. The design still records apply,
   verification, and rollback for completeness.
9. **Design conformance** — the implementation matches `design.md`: the new
   feature module, the thiniel import, the assertion target, the integration
   test and its registration, and the package choices (`pkgs.opentofu`,
   `pkgs.gh`, no `programs.gh`). No silent deviation.

0 fabricated scenarios/targets found across 3 scenarios.

## Arc42 implementation conformance

| Arc42 chapter or fact | Durable-doc source | `arc42.md` claim | `design.md` | `tasks.md` | Implementation evidence | Match? |
|---|---|---|---|---|---|---|
| `cli/` inventory gains one module | `docs/arc42/05-building-block-view.md` | Affected, row 5 | New module under `features/cli/` | Scenario 1 GREEN creates it | `home/dan/features/cli/infrastructure-tooling.nix` exists; inventory says 15 modules | Yes |
| thiniel imports one more feature module | `docs/arc42/05-building-block-view.md` | Affected, row 5 | Import in `home/dan/thiniel.nix` | Scenario 1 GREEN imports it | `home/dan/thiniel.nix:9`; import count 43 | Yes |
| No architecture decision record | `docs/arc42/09-architecture-decisions.md` | Row 9 not affected; verdict NOT_QUALIFIED routed to `design.md` | D1 recorded; no ADR | No ADR task | No ADR file added; `docs/arc42/adr/` unchanged | Yes |
| No new risk or debt | `docs/arc42/11-risks-and-technical-debt.md` | Row 11 not affected | Additive, reversible | No risk task | Only package declarations and tests added | Yes |

ARC42 CONFORMANCE: CLEAN

## Coverage

Traceability coverage is the scenario-to-target mapping from
`scripts/givn-spec-trace.py` (35 scenarios, 0 findings). No instrumented
coverage applies (`addons.coverage` is disabled).

Coverage classification for this change: no dead config, no missing test
coverage, no hard-to-test gap. The two advisory unreferenced integration checks
(`integration-adlerkopf`, `integration-vm-minimal-ssh`) predate this change and
are not part of its scope; this change adds no unreferenced check.

## Use-case and Persona conformance

The owning use case is `reproduce-working-environment`. The new capability
`infrastructure-authoring-tooling` is a device working-environment guarantee and
passes the placement test for that goal. The confirmed Persona is
`owner--operator` (confirmed 2026-10-11, user); it is used only as a review
lens. No Persona biography is used as a Gherkin actor. No use-case scope
rejection criterion applies.

## Overlap dispositions

No deterministic overlap finding remains: the initially separate
credential-helper scenario was merged into the GitHub-client scenario before
implementation.

## Split-or-keep

No scenario exceeds the long-scenario threshold.

## Verification evidence

- `./scripts/givn-verify.sh` — regular scope, exit 0 (all outputs and checks
  evaluated, host assertions fired, Python suite green).
- `./scripts/givn-verify-e2e.sh` — e2e scope, exit 0 (the
  `integration-infrastructure-tooling` check booted the guest and ran both
  tools).

REVIEW: PASS
