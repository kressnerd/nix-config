# Design: {{CHANGE_ID}}

## Overview

> How will we implement this change? Summarise the approach, the hosts
> affected, and the observable end state. Read `docs/GIVN-VERIFICATION.md`
> first — it owns the binding-tag model, the runner commands, and the
> targeted-run commands referenced below.

## Use-Case Traceability

> Owning use-case ID: <usecase-id or none>
> Ideation source: <topic-id or none>
> Confirmed Persona IDs: <ids or none — record `none` with the reason; a host
> configuration change normally has no user-visible surface>
>
> Map the use-case guarantees, rules, events, and capability ownership to
> technical decisions and their bound verification target. Actors remain
> distinct from Personas.

| Use-case contract element | Technical decision | Bound verification target |
|---|---|---|
| | | |

## Technology Decisions

> Which Nix modules, option paths, channel pins, packages, or helper functions
> will be used? Justify non-obvious decisions (why this module/option over the
> alternatives?). Technology-decision justification belongs here; do not
> promote it to ADR candidacy unless the arc42 qualification procedure passes.
>
> **Channel pinning:** prefer `nixpkgs-26.05` (stable); justify every
> `unstable` use.
>
> **Version freshness (mandatory):** never write a version number from memory.
> For each versioned choice, state the channel as the resolution strategy, OR
> record a looked-up version with how/when it was checked.

| Decision | Choice | Channel / source | Why |
|---|---|---|---|
| (e.g. reverse proxy) | (e.g. nginx module) | (e.g. nixpkgs-26.05) | (e.g. already used on cupix001; no new module) |

## Decisions

> The ledger resolving the proposal's open questions. One entry per question
> ID; every `D<n>` either appears here or is explicitly carried with a named
> owner. A question that originated in an ideation seed records the seed
> reference beside the ledger ID.

- Decides D1: <decision> — <where it is realized>
- Carried D2 (seed Q5): <why it stays open> — owner: <who>, decided in: <artifact>

## Verification Binding

> One row per scenario in the change's `specs/**/*.feature`. Read
> `docs/GIVN-VERIFICATION.md` for the binding tags, the runner commands, and
> the targeted-run commands; do not restate the policy here.
>
> Suite runner (`verify.command`): `{{VERIFY_COMMAND}}`
>
> Every scenario carries exactly one binding tag; `@e2e` scenarios bind to
> `@check:integration-*`, `@host:<name>`, or `@deploy:<name>`. Every binding
> name must resolve. The targeted command must exit non-zero before the fix —
> an already-passing target is not RED.

| Scenario title | Binding tag | Bound target (file / check / host) | Targeted run command | Expected RED failure mode |
|---|---|---|---|---|
| (e.g. reverse proxy rejects a non-allowlisted address) | `@host:cupix001` | `tests/assertions/network.nix` fired by the cupix001 config evaluation | `nix eval --raw .#nixosConfigurations.cupix001.config.system.build.toplevel.drvPath` | the new assertion fails; evaluation exits non-zero |
| (e.g. helper joins two derived paths) | `@check:unit-helpers` | `tests/unit/default.nix` → check `unit-helpers` | `nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).unit-helpers` | the new `lib.debug.runTests` case fails |

## Test Targets Added/Changed

> Name every test target this change adds or extends, and the flake `checks`
> entry or host import that wires it in. A target that is not wired in is
> never run.

| Target file | Kind | Wired in by | Covers scenarios |
|---|---|---|---|
| (e.g. `tests/unit/default.nix`) | unit (`lib.debug.runTests`) | flake `checks.unit-helpers` | |
| (e.g. `tests/assertions/foo.nix`) | assertion | imported by `tests/assertions/default.nix`, fired on host evaluation | |
| (e.g. `tests/integration/foo.nix`) | VM (`pkgs.testers.runNixOSTest`) | flake `checks.integration-foo` | |
| (e.g. `tests/deploy/test_foo.py`) | deploy (pytest-testinfra) | `@deploy:foo` binding | |

> New unit tests go into `tests/unit/default.nix` and `flake.nix`; new
> assertions into `tests/assertions/default.nix`; new VM tests into
> `tests/integration/default.nix`.

## Architecture Impact

> Which existing modules, options, and host definitions are affected? Which are
> new? Name the files under `modules/nixos`, `modules/home-manager`,
> `hosts/<host>/`, `hosts/common/`, and `lib/`. Include a Mermaid diagram when
> the structure is non-obvious.

## Secrets & Safety

> - **sops targets:** for each secret this change wires, the declared path, the
>   sops key name, and the target owner/mode. Never a plaintext secret.
> - **`stateVersion` invariants:** `system.stateVersion` and
>   `home.stateVersion` are never changed.
> - **`hardware.nix` untouched:** generated and read-only; this change must not
>   modify it.
> - Any other invariant the change must preserve.

## Deployment & Rollback

> Mandatory when the change touches `boot.loader`, `networking`,
> `fileSystems`/disko, `environment.persistence`/impermanence, kernel, or
> secrets. Delete the section only when none of those apply.
>
> - **Apply command:** (e.g. `nixos-rebuild switch --flake .#<host>`)
> - **On-host verification:** (the service status, port, firewall rule, or
>   materialised secret that confirms it on the real host)
> - **Rollback:** (the exact mechanism — previous boot generation, `switch
>   --rollback`, or restoring the pre-change generation)

## Blast Radius

> What can break, on which hosts, and how detectable it is. Name the affected
> hosts and whether a bad apply is recoverable remotely.

## arc42 Chapter Impact

> Which arc42 chapters (`docs/arc42/`) does this change affect? Relevant only
> when the arc42 addon is enabled.

## Open Technical Questions

> List unresolved HOW decisions before moving to tasks.
