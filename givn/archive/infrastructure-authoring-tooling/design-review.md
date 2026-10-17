# Design Review: infrastructure-authoring-tooling

## Grilling

### Scope

No issue found. The proposal asks for OpenTofu and the GitHub CLI on thiniel;
the spec adds exactly those two tools plus the credential-helper boundary the
proposal already fixed in D1. No other host, cloud SDK, Terraform variant, or
authentication state is introduced. "Done" names the host (`thiniel`) and the
observable end state (the tools run and report versions on a booted device).

### Tech choices

No issue found. `pkgs.opentofu` has no Home Manager module, so a package
declaration is the simplest fit. `programs.gh` exists but enables the git
credential helper by default, which contradicts D1; `home.packages` is the
smaller option that satisfies the scenario. `tenv` (used by the macOS
workstation's `cloud-tools`) was considered and rejected because it adds a
version-manager state directory and an imperative install step, neither of
which the request asks for. Both packages come from the host's existing
`nixpkgs-unstable` package set; no new channel or overlay is introduced. The
new feature module is importable by the VM test, which packages inline in
`home/dan/thiniel.nix` would not be.

### Missing scenarios

One gap found and hardened: the proposal's D1 boundary (the GitHub client must
not become a git credential helper) was recorded only in prose. The guard is
now a `Then` step of the existing GitHub-client scenario, backed by the same
`@host:thiniel` assertion, and the design's verification table records it. No
separate scenario was kept because it would be a strict subset of this one.
No error path or boot-failure scenario is needed: the tools are invoked on
demand and hold no service, socket, or persisted state.

### Testability

No issue found after hardening. The two `@host:thiniel` scenarios fire
`tests/assertions/thiniel-invariants.nix` during host evaluation; the package
assertions fail before implementation. The credential-helper guard is combined
with `gh` package presence in one assertion, so the GitHub scenario has a
genuine RED (gh absent) while the guard holds before and after. The `@e2e` check is wired
before RED: the guest imports the feature module, so the check fails to
evaluate until the module exists, then runs both tools after boot.

### Verification-binding completeness

No issue found. Every scenario carries exactly one binding tag. `@host:thiniel`
resolves in `nixosConfigurations`. The new `@check:integration-infrastructure-tooling`
is registered by `tests/integration/default.nix` (to be confirmed by the
`tasks` hook, which runs `scripts/givn-spec-trace.py` after implementation).
The `@e2e` scenario binds to an `integration-*` check. `verify.e2e_command` is a
strict subset of `verify.command` in `givn/commands.yaml`.

### Deployment and rollback

Not a dangerous area. `design.md` still records the apply command, on-host
verification, and rollback for completeness: `nixos-rebuild switch --flake
.#thiniel`, `tofu version` / `gh --version`, and
`nixos-rebuild switch --rollback`.

### Risk

The single most likely failure is a wrong package attribute or a channel
without the package, which would make the host evaluation fail before any
activation. Mitigation: the design verified both attributes and versions
against the pinned `nixpkgs-unstable` input (`opentofu` 1.13.1, `gh` 2.102.0).
The change is additive; the rollback is switching to the previous generation.

### Decision ledger

Decides D1: the GitHub client is package-only; no git credential helper is
registered. Realized in `home/dan/features/cli/infrastructure-tooling.nix` and
guarded by the credential-helper scenario. No other proposal question exists.

### Use-case and Persona context

No issue found. The owning use case is `reproduce-working-environment`;
capability ownership is new (`infrastructure-authoring-tooling`) and recorded in
the use-case delta. The confirmed Persona is `owner--operator` (confirmed
2026-10-11), relevant because the owner uses the laptop's working environment.
No Persona biography is used as a Gherkin actor.

### Deferrals

None. No mandatory check is deferred.

### Architecture documentation

Independently re-derived the 12-row table before opening `arc42.md`: only
chapter 05 is affected (the new `cli/` module and the thiniel import count).
`arc42.md` agrees; no omission or contradiction. `docs/arc42/05-building-block-view.md`
was updated (`cli/` 14 → 15, thiniel imports 42 → 43). Chapter 09 correctly
records no ADR: the qualification verdict is `NOT_QUALIFIED`, routed once to
`design.md`, with alternatives, architectural impact, durable consequence, and
lower-level-artifact evidence recorded in `arc42.md`. Chapter 11 needs no change
because no "Bad, because…" consequence exists without an ADR. All twelve
chapter files exist, contain real content, and contain no ASCII or
box-drawing diagrams (checked `docs/arc42/*.md` for box-drawing characters and
pseudo-table diagrams; none found).

## Hardening applied

- Added the credential-helper boundary as a `Then` step of the GitHub-client
  scenario in
  `specs/reproduce-working-environment/infrastructure-authoring-tooling.feature`.
- Extended the design's verification-binding and test-target tables for that
  guard.
- No other design decision changed.

`givn lint --change infrastructure-authoring-tooling` is clean.

DESIGN-REVIEW: PASS
