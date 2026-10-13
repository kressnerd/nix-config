# Tasks — current-omp-release

Release note (carried as every commit's message subject):
**Both personal devices run a current Oh My Pi (omp) coding agent from a freshly
pinned package set, with the same servers and decryption prohibition, and each
device refuses an agent older than 18.10.**

Native targets this change adds or extends:

| Target | Kind | Wiring |
|---|---|---|
| `checks.unit-agent-secret-guard` | `runCommand` check, all systems | `flake.nix` `checks` (all-systems block) + `tests/unit/agent-secret-guard.mjs` |
| `checks.integration-agent-tooling` | `runNixOSTest`, Linux | `tests/integration/agent-tooling-test.nix` + `tests/integration/default.nix` + the flake's linux-systems block |
| `tests/assertions/thiniel-invariants.nix` | assertions | imported by `home/dan/thiniel.nix`, fired by `@host:thiniel` |
| `tests/assertions/J6G6Y9JK7L-invariants.nix` | assertions | imported by `home/dan/J6G6Y9JK7L.nix`, fired by `@host:J6G6Y9JK7L` |

Use-case constraints that apply to every scenario below (from
`givn/changes/current-omp-release/specs/reproduce-working-environment/usecase.md`,
use case `reproduce-working-environment`):

- "The device's coding agent is at or above the accepted version floor, and
  currency is a floor rather than a schedule: refreshing the agent's source is
  the owner's deliberate action, not an automatic promise."
- "A device that carries the coding agent also carries its guardrails: the same
  secret-access guard is installed, so the same refusals hold wherever the agent
  runs. A device that carries the agent without the guard is not the accepted
  context."
- "Check actual usable work context; a successful evaluation, launcher,
  directory creation or green transfer job is not alone work readiness." — for
  this change the agent's *launch on a booted system* is the real-interface
  evidence, not the declaration alone.

---

## T1 — Setup: wire the targets and prove RED [x]

- [x] T1.1 Read the use-case rules above into this task list and keep them in
      every scenario task.
      Evidence: quoted verbatim at the top of this file; each scenario task below
      carries the two rules it realises (floor; guardrails travel with the agent).
- [x] T1.2 Confirm the runners differ: paste
      `grep -A2 'verify:' givn/commands.yaml`.
      Evidence: `verify.command = ./scripts/givn-verify.sh`, `verify.e2e_command =
      ./scripts/givn-verify-e2e.sh` — distinct, as the verify-e2e hook requires.
- [x] T1.3 Confirm the traceability gate's current state: run
      `python3 scripts/givn-spec-trace.py`; expected exit 1 with exactly the
      three findings (`@check:unit-agent-secret-guard` ×2,
      `@check:integration-agent-tooling`). Paste command + output.
      Evidence: exit 1, three `[FAIL]` lines naming exactly those bindings, plus
      two pre-existing `[warn]` lines for unreferenced integration checks.
- [x] T1.4 Wire the guard check: add `tests/unit/agent-secret-guard.mjs` (driver
      that imports `.omp/hooks/pre/secret-access-guard.js`, registers the
      `tool_call` handler, and asserts the refusal/allow table recorded in
      `design.md`) and expose `checks.unit-agent-secret-guard` in `flake.nix`
      (all-systems block, `nativeBuildInputs` = the agent package set's `bun`).
      **Proof-of-RED by mutation**: invert one expected verdict (expect
      `cat .sops.yaml` to be refused), run
      `nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).unit-agent-secret-guard`,
      confirm non-zero, paste; then restore the correct table and confirm exit 0,
      paste.
      Evidence (mutated, non-zero): exit 1 — `FAIL bash {"command":"cat .sops.yaml"}
      -> passed [expected refusal: MUTATION…]` and `15/17 verdicts as expected`.
      The same run exposed a wrong case of my own: `grep` over
      `~/.config/sops-nix/…` is *not* refused, because the guard's declared set is
      `/run/secrets/*`, a `sops/age/` path and `/var/lib/sops-nix/*`. The case was
      corrected to a denied shape and the gap recorded as finding F10 in
      `design-review.md` and as arc42 `R-021`.
      Evidence (restored, zero): exit 0 — `17/17 verdicts as expected`.
- [x] T1.5 Register the booted check: add `tests/integration/agent-tooling-test.nix`
      (node with home-manager, the test user, and the agent module), wire it in
      `tests/integration/default.nix`, and thread the agent package from
      `flake.nix`'s linux-systems block. Prove RED: run
      `nix build .#checks.x86_64-linux.integration-agent-tooling`; expected
      non-zero (the agent package does not resolve until T2 lands). Paste.
      Evidence: exit 1 after a real boot — the guest ran
      `/nix/store/…-omp-18.8.4/bin/omp --version` (the package the device declared
      at that moment) and the script stopped on
      `AssertionError: agent reports 'omp/18.8.4', below the floor 18.10`. So the
      RED is behavioural, not an evaluation error: the guest binary is
      PATH-independent by construction (`${ompPackage}/bin/omp`).
- [x] T1.6 Note for the reviewer: the arc42 chapter updates, the glossary terms
      and `arc42.md` from the design phase are part of this change and are
      committed with T2.
      Evidence: they are in revision `270ed64` (T2's commit).

## T2 — Scenario: The personal laptop carries a current, guarded coding agent [x]

Binding: `@host:thiniel`. Target: `tests/assertions/thiniel-invariants.nix`.
Targeted command:
`nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`.

- [x] T2.RED Remove `@wip` from this scenario only (keep the other four `@wip`).
      Extend `tests/assertions/thiniel-invariants.nix` with the agent-present
      assertion, the floor assertion
      (`lib.versionAtLeast (lib.getVersion <agent>) "18.10"`) and the
      declared-guard assertion (`config.home.activation ? installOmpSopsGuard`).
      Run the targeted command: MUST exit non-zero, failing on the floor
      assertion (`18.8.4`). Paste command + output.
      Evidence: exit 1 —
      `Failed assertions: - thiniel: Oh My Pi (omp) must be at version 18.10 or newer`.
- [x] T2.GREEN Implement the minimum change: add the `nixpkgs-agent` input
      (`github:NixOS/nixpkgs/master`) to `flake.nix`, build the agent package per
      system, pass it as `ompPackage` through `home-manager.extraSpecialArgs` for
      `thiniel`, and change `home/dan/features/development/omp.nix` to take
      `ompPackage` (keeping `pkgs` for coreutils). Update the module instantiation
      in `tests/unit/hm-dev-modules-test.nix`. Reduced files:
      `flake.nix` (input, `agentPkgsFor`, thiniel's arg, guard check, booted check
      arg), `flake.lock` (+17 lines, one new input), `home/dan/features/development/omp.nix`,
      `tests/unit/hm-dev-modules-test.nix`.
      Run the targeted command: MUST exit 0. Paste.
      Evidence: exit 0, and the configured agent resolves to `18.10.0`
      (`…home.packages --apply … .version`).
- [x] T2.REFACTOR Format and clean (`nix fmt .`, deadnix/statix on the changed
      files) without behaviour change; run the targeted command again: MUST still
      exit 0. Paste.
      Evidence: `nix fmt flake.nix …` then
      `nix build --no-link .#checks.x86_64-linux.lint-nixfmt .#checks.x86_64-linux.lint-deadnix .#checks.x86_64-linux.lint-statix`
      → exit 0; targeted eval still exit 0.
- [x] T2.COMMIT `givn commit -m "feat(current-agent-tooling): <release note>"`
      with the scenario title in the body; includes the arc42/glossary/`arc42.md`
      updates from the design phase. Record the hash.
      Hash: `270ed64` (also carries T1's plumbing: the guard check, its driver and
      the booted check's registration).

## T3 — Scenario: The work MacBook carries the personal laptop's current, guarded coding agent [x]

Binding: `@host:J6G6Y9JK7L`. Target: `tests/assertions/J6G6Y9JK7L-invariants.nix`.
Targeted command:
`nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath`.

- [x] T3.RED Remove `@wip` from this scenario only. Extend
      `tests/assertions/J6G6Y9JK7L-invariants.nix` with: the agent is in
      `home.packages`, the floor assertion, both model servers declared in
      `~/.omp/agent/mcp.json`, and the declared-guard assertion. Run the targeted
      command: MUST exit non-zero on "the coding agent must be installed". Paste.
      Evidence: exit 1 with all four named assertions:
      `the coding agent (omp) must be installed — import features/development/omp.nix`,
      `must be at version 18.10 or newer`, `must declare both shared model servers`,
      `the agent's secret-access guard must be declared for installation`.
      The server assertion reads `config.home.file…` defensively (`or null`), so the
      RED is a named assertion rather than a missing-attribute abort.
- [x] T3.GREEN Import `./features/development/omp.nix` into
      `home/dan/J6G6Y9JK7L.nix` and pass `ompPackage` through that host's
      `home-manager.extraSpecialArgs`. Files: `flake.nix` (aarch64-darwin
      `ompPackage` from the pin), `home/dan/J6G6Y9JK7L.nix` (import before
      `opencode.nix`).
      Run the targeted command: MUST exit 0. Paste.
      Evidence: exit 0 (`darwin-system-26.11.…drv` evaluates); the invariants'
      floor assertion is part of that evaluation.
- [x] T3.REFACTOR Keep the import list ordered as the other categories are;
      targeted command still exits 0. Paste.
      Evidence: `nix fmt` on the three files; `lint-nixfmt`/`lint-deadnix`/
      `lint-statix` exit 0; targeted eval exit 0.
- [x] T3.COMMIT `givn commit` with the release note as subject and the scenario
      title in the body. Record the hash.
      Hash: `dfb3b42`.

## T4 — Scenario: A decryption attempt is refused on a device that carries the guard [x]

Binding: `@check:unit-agent-secret-guard`. Target: `tests/unit/agent-secret-guard.mjs`
via `checks.unit-agent-secret-guard`. Targeted command:
`nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).unit-agent-secret-guard`.

- [x] T4.RED Remove `@wip` from this scenario only. This scenario is
      **characterization** (`design.md`, Verification Binding): the hook is
      unchanged by this change, so the behaviour RED is the mutation — invert the
      refusal expectation for one case (`sops -d f` expected to pass), run the
      targeted command, confirm non-zero, paste.
      Evidence: exit 1 —
      `FAIL bash {"command":"sops -d hosts/thiniel/secrets.yaml"} -> refused
      (sops material is protected by repository policy) [expected no verdict]`,
      `16/17 verdicts as expected`. The hook refused while the mutated table
      expected no verdict, which is what makes the check able to fail.
- [x] T4.GREEN Restore the correct refusal table; run the targeted command: exit
      0. Files: `tests/unit/agent-secret-guard.mjs` only. Paste.
      Evidence: exit 0 — `17/17 verdicts as expected`.
- [x] T4.REFACTOR Tidy the driver (case table extracted, no change in verdicts);
      targeted command still exits 0. Paste.
      Evidence: the case table was already a flat literal table with one comment
      per group; `lint-nixfmt`/`lint-deadnix`/`lint-statix` exit 0 and the check
      still exits 0 — no further restructuring was needed.
- [x] T4.COMMIT `givn commit`; release note as subject, scenario title in body.
      Hash: `b615254` — **merged with T5** (see T5.COMMIT): these two are
      characterization scenarios whose deliverable (the verdict check and its
      driver) landed with T1's plumbing in `270ed64`, so separate revisions would
      each have touched only the spec file. The merge is recorded here, in the T5
      entry and in `design-review.md`'s addendum.

## T5 — Scenario: Ordinary repository work passes the guard [x]

Binding: `@check:unit-agent-secret-guard` (same target, allow-cases).

- [x] T5.RED Remove `@wip` from this scenario only. Mutation RED: expect the
      allow-case `cat .sops.yaml` to be refused; run the targeted command,
      confirm non-zero, paste.
      Evidence: exit 1 —
      `FAIL bash {"command":"cat .sops.yaml"} -> passed [expected refusal:
      MUTATION: deliberately inverted expectation]`, `16/17 verdicts as expected`.
- [x] T5.GREEN Restore the correct allow-cases; targeted command exits 0. Paste.
      Evidence: exit 0 — `17/17 verdicts as expected`.
- [x] T5.REFACTOR Clean up; still exits 0. Paste.
      Evidence: `lint-nixfmt` exit 0; check exit 0.
- [x] T5.COMMIT `givn commit`; release note as subject, scenario title in body.
      Hash: `b615254` (shared with T4 — rationale in T4.COMMIT).

## T6 — Scenario (e2e): A booted device starts its coding agent [ ]

Binding: `@e2e @check:integration-agent-tooling`. Target:
`tests/integration/agent-tooling-test.nix`. Runner: `./scripts/givn-verify-e2e.sh`.

- [ ] T6.RED Remove `@wip` from this scenario only. Complete the booted check:
      guest asserts the agent runs by its declared store path
      (`sudo -u test env HOME=/home/test ${ompPackage}/bin/omp --version`)
      reporting at least `18.10`, the exit code being zero, that
      `~/.omp/agent/hooks/pre/secret-access-guard.js` is a regular file and not a
      symlink, and that no key material exists under the user's
      `~/.config/sops-nix/secrets/`. Run
      `nix build .#checks.x86_64-linux.integration-agent-tooling` with the agent
      package deliberately absent from the node's module arguments: MUST exit
      non-zero (missing argument / unmet assertion). Paste.
      Evidence:
- [ ] T6.GREEN Supply the agent package to the node and make the assertions pass.
      Run `./scripts/givn-verify-e2e.sh`; the check MUST pass. Paste.
      Files:
      Evidence:
- [ ] T6.REFACTOR Tidy the test module; re-run the check: still passes. Paste.
      Evidence:
- [ ] T6.COMMIT `givn commit`; release note as subject, scenario title in body.
      Hash:

## T7 — Full verification and operator hand-off [ ]

- [ ] T7.1 `python3 scripts/givn-spec-trace.py` exits 0 (every scenario bound to
      an existing target). Paste.
      Evidence:
- [ ] T7.2 `givn lint --change current-omp-release` exits 0 or 2 with no `@wip`
      left. Paste.
      Evidence:
- [ ] T7.3 `./scripts/givn-verify.sh` passes (all hosts evaluate, checks build,
      Python suite green). Paste the tail.
      Evidence:
- [ ] T7.4 Operator: apply on the laptop
      (`sudo nixos-rebuild switch --flake .#thiniel`) and confirm
      `omp --version` reports at least `18.10` there.
- [ ] T7.5 Operator: apply on the Mac
      (`sudo darwin-rebuild switch --flake .#J6G6Y9JK7L`), confirm
      `omp --version` reports at least `18.10`, that
      `~/.omp/agent/hooks/pre/secret-access-guard.js` exists as a regular file,
      and that `command -v omp` resolves to the configured agent (recording D4's
      confirmation on the machine the repository cannot observe).
- [ ] T7.6 Operator: record the rollback path used if either activation is
      rejected (`nixos-rebuild switch --rollback` / `darwin-rebuild rollback`).
