# GIVN Verification Model

Canonical verification policy for givn changes in this repository. Every
artifact instruction, skill, and hook references this document; none restates
it. Read it before writing a spec, a design, a task list, or a review.

## Why this is not the default givn model

Default givn assumes an application with a Gherkin/Cucumber step runner whose
step definitions are the executable specification. This repository is a
declarative Nix configuration for hosts (NixOS, nix-darwin) and a small set of
supporting scripts. There is no in-process interface and no per-step execution:
Nix verification is either evaluation-time (`lib.debug.runTests`, NixOS module
assertions) or a single QEMU VM derivation per integration test. A step
runner cannot bind to that, so the executable specification is bound to the
native targets directly.

## Binding tags

Every scenario carries **exactly one** binding tag. The tag names the native
target that proves the scenario. `scripts/givn-spec-trace.py` enforces this
and is run by the `tasks` and `review` hooks.

| Tag | Target | Meaning |
|---|---|---|
| `@check:<name>` | `nix build .#checks.<system>.<name>` | Unit test or linter derivation in the flake `checks` output (`unit-helpers`, `lint-deadnix`, …). |
| `@host:<name>` | `nix eval --raw .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath` (or `darwinConfigurations`) | The host configuration evaluates; this fires the `tests/assertions` module invariants. |
| `@deploy:<name>` | `pytest tests/deploy/test_<name>.py` | Post-deployment verification against a live host (pytest-testinfra). The file must exist. |

Tag placement follows Gherkin: the tag line goes **before** `Scenario:`. Tags
combine with the delta tags, e.g.:

```gherkin
@givn.delta @thiniel-boot

Feature: Thiniel boots with a deterministic root

  @givn.added @wip @host:thiniel
  Scenario: Root filesystem is wiped on every boot
    Given a booted thiniel
    When the system starts
    Then / is reset from the btrfs subvolume snapshot
```

`@check:` and `@host:` names must exist in the flake; `@deploy:` names must
have a matching deploy test file. A binding that does not resolve is a hard
failure of the traceability check.

## End-to-end scenarios (`@e2e`)

The `@e2e` tag marks a scenario that exercises the real interaction surface —
for a declarative configuration that means an actual boot or a live host, not
an evaluation. An `@e2e` scenario MUST bind to one of:

- `@check:integration-*` — a `pkgs.testers.runNixOSTest` VM test (real boot,
  real service startup, real port binding), or
- `@host:<name>` — a host configuration evaluation that a deploy test then
  confirms on real hardware, or
- `@deploy:<name>` — a deploy test against a live host.

Binding an `@e2e` scenario to a plain unit/lint check is a traceability
failure.

The `@e2e` scope is run by `verify.e2e_command`
(`scripts/givn-verify-e2e.sh`), which builds the `integration-*` checks for
the current system. It requires a Linux builder with KVM; on a non-Linux host
it fails loudly rather than reporting a false pass.

## Runners

| Command | Scope | Contents |
|---|---|---|
| `./scripts/givn-verify.sh` (`verify.command`) | non-`@e2e` | spec traceability; `nix flake check --no-build` (all outputs + checks for the current system); builds of the non-VM checks (unit + lint); assertion enforcement for every host configuration (`config.assertions`, the `tests/assertions` layer); the Python suite `scripts/tests` via `nix develop`. Buildability of a specific host is proven per scenario by the targeted `@host:<name>` command. |
| `./scripts/givn-verify-e2e.sh` (`verify.e2e_command`) | `@e2e` | builds every `integration-*` check for the current system; optional deploy tests. |
| `givn lint` | static | `.feature` syntax, `@wip`, delta tags. Runs no tests. |

`verify.command` must never be identical to `verify.e2e_command`: the e2e
command is the strict subset that actually boots a system.

### Runner result contract (givn 0.7.0)

Each scope command writes one JSON object to the path in `GIVN_RESULT_FILE`
when givn sets that variable, and keeps its previous behaviour when a developer
runs it directly:

```json
{"scope":"regular","total":7,"passed":7,"failed":0,"skipped":0}
```

`scope` is `regular` for `verify.command` and `e2e` for `verify.e2e_command`.
The counts are real scenario counts from `scripts/givn-scenario-count.py`, which
reads the `.feature` files and splits them by the `@e2e` tag — never hardcoded
and never inferred from the exit code. `givn archive` rejects a missing file, a
malformed result, a wrong scope, `total == 0`, a non-zero `failed` or `skipped`,
or counts that do not reconcile.

## Single-scenario (targeted) run

RED/GREEN/REFACTOR in the task loop runs the scenario's bound target directly,
not the whole suite:

| Binding | Targeted command |
|---|---|
| `@check:<name>` | `nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).<name>` |
| `@host:<name>` (NixOS) | `nix eval --raw .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath` |
| `@host:<name>` (darwin) | `nix eval --raw .#darwinConfigurations.<name>.config.system.build.toplevel.drvPath` |
| `@deploy:<name>` | `pytest tests/deploy/test_<name>.py` |

`nixos-rebuild build --flake .#<name>` / `darwin-rebuild build --flake
.#<name>` are the stronger variants for a host target when a full build is
wanted. Evaluating the toplevel derivation is enough to fire module
assertions and is the default targeted command.

## RED/GREEN without a step runner

The TDD loop is unchanged; only the mechanism differs.

- **RED** — write the scenario, add or extend its bound target (a
  `lib.debug.runTests` case, an assertion in the relevant
  `tests/assertions/*.nix`, a `runNixOSTest`, or a deploy test), run the
  targeted command, and confirm it fails for the expected reason. A scenario
  whose target already passes is not RED.
- **GREEN** — implement the configuration change (module option, service,
  firewall rule, secret wiring, host definition) and re-run the targeted
  command until it passes.
- **REFACTOR** — restructure with all scenarios still green.
- **COMMIT** — one `givn commit` per scenario.

When a change introduces a new target, wire it in before RED: unit tests into
`tests/unit/default.nix` and `flake.nix`, assertions into
`tests/assertions/default.nix`, VM tests into `tests/integration/default.nix`.

## Replacements for the application-oriented defaults

| Default givn concept | This repository |
|---|---|
| Cucumber/behave step definitions | The bound target's assertion (assertion, unit test, VM test, deploy test). |
| Step-definition files, one per capability | `tests/unit/`, `tests/assertions/`, `tests/integration/`, `tests/deploy/`. |
| Strict-mode proof | The targeted RED run must exit non-zero; an already-passing target is rejected. |
| Cobertura line/branch coverage | `scripts/givn-spec-trace.py`: every scenario bound to an existing target, every `@e2e` scenario bound to a VM/host/deploy target. Unreferenced `integration-*` checks are reported. |
| Browser driver / viewports / digital twins | NixOS VM integration tests and pytest-testinfra deploy tests. |
| `docker-compose up` local run | `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` / `nixos-rebuild build --flake .#<host>`; `nixos-vm-minimal` and the `*-vm` configurations boot locally. |

## What "observable behaviour" means here

A scenario asserts externally observable state of a host or system:

- a service is active and listening on a port;
- a firewall drops or accepts a connection;
- a file, user, group, or systemd unit exists with the expected properties;
- a secret is materialised at the declared path with the declared owner/mode;
- the system evaluates and builds, and every declared assertion holds;
- after a VM boot, the described state holds.

Internal module structure, option names, and helper functions belong in
`design.md`, not in the spec.
