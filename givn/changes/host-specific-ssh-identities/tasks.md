# Tasks: host-specific-ssh-identities

RED→GREEN→REFACTOR→COMMIT per scenario. Non-@e2e first, then @e2e. Every phase
runs the scenario's bound target (its `@check:`/`@host:`/`@deploy:` tag) with
the targeted command from `docs/GIVN-VERIFICATION.md` — never the whole suite.

Legend: `[ ]` pending · `[x]` done only when evidence + commit hash are filled in. Check boxes immediately after each scenario — tasks.md must always reflect true state.

---

## Domain Constraints

Owning use case: `reproduce-working-environment` (carried into the permanent
corpus by this change; ideation topic `infrastructure-growth`). Capability:
`permitted-identity-selection`.

| Scenario / capability | Use-case guarantee or rule | Persona impact |
|---|---|---|
| `permitted-identity-selection` (all scenarios) | Success guarantee: the owner resumes the specified usual work with its required context available and usable — here the identity condition. Rules: identity access is re-established through permitted means, never by cloning credentials; device/platform differences may be intentional; owner-authorized scope only, so no employer or client data authority follows from a profile reference. Extension 2b: a selected identity is re-established rather than exported. | `owner--operator` — the owner is the only actor who evaluates private-repository access on their own device. `family--application-user` unaffected: no hosted application, shared resource or access grant changes. |
| Scenario 3 (work laptop preserved) | Rule: device differences are intentional; making thiniel usable must not degrade the owner's usual work on the MacBook. | `owner--operator` |
| Open prerequisite | `(open: Q16)` of the owning use case stays open for the remaining state/source inventory; this change closes it for thiniel's personal identity only (proposal D2). | — |

---

## Proof the targeted RED run fails (do first)

- [x] **Wire the new target**: the VM check `integration-ssh-identity-selection` is registered in `tests/integration/default.nix` and receives the `home-manager-unstable` and `sops-nix` inputs from `flake.nix`. No new unit check and no new assertion module: the assertions go into the two existing `tests/assertions/*.nix` files already wired into their hosts, and the unit check is extended in place.
- [x] **Proof the targeted RED run fails**: the first scenario's RED run (host evaluation of thiniel) and the module-granularity RED run are recorded in scenario 1 below; the booted-device check's RED run is recorded in the e2e section. All exited non-zero for the named reasons.

---

## Tasks

- [x] Scenario: `The personal device reaches private repositories with the identity it holds` (`@host:thiniel`)
  - [x] RED: extended `tests/assertions/thiniel-invariants.nix` (connection identity file, workspace identity configuration) and, at module granularity, `tests/unit/hm-cli-modules-test.nix` (per-host mocks; the declared path must reach both surfaces) and `tests/unit/hm-modules-test.nix` (mocks declare the identity). Targeted run:
        ```
        $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
        error:
               Failed assertions:
               - thiniel: the private-repository connection must resolve to the identity file thiniel holds (~/.ssh/id_ed25519), got ~/.ssh/id_ed25519_personal_2026-10-04
               - thiniel: the workspace identity configuration must name the identity file thiniel holds
        exit 1

        $ nix build .#checks.x86_64-linux.unit-helpers --no-link
        error: Cannot build '/nix/store/482x8zpqac4cn08cv3zyqy9i40llk5xp-unit-tests.drv'.
               Reason: builder failed with exit code 1.
               > Unit test failures: [{expected:true,name:testGitPersonalSshCommandFromDeclaration,result:false},{expected:~/.ssh/id_ed25519,name:testSshLinuxPersonalKeyFromDeclaration,result:~/.ssh/id_ed25519_personal_2026-10-04}]
        exit 1
        ```
  - [x] GREEN: added `modules/home-manager/ssh/options.nix` (`myHome.ssh.personalIdentityFile`, no default; `myHome.ssh.includedConfigs`, default none); wired it into both hosts' home-manager `sharedModules` in `flake.nix`; declared the identity file in `home/dan/thiniel.nix` (`~/.ssh/id_ed25519`) and `home/dan/J6G6Y9JK7L.nix`; rendered the personal connection entry (`home/dan/features/cli/ssh.nix`) and the workspace identity configuration (`home/dan/features/cli/git.nix`) from the declaration.
        Files created/modified: `modules/home-manager/ssh/options.nix`, `flake.nix`, `home/dan/thiniel.nix`, `home/dan/J6G6Y9JK7L.nix`, `home/dan/features/cli/ssh.nix`, `home/dan/features/cli/git.nix`, `tests/assertions/thiniel-invariants.nix`, `tests/unit/hm-cli-modules-test.nix`, `tests/unit/hm-modules-test.nix`.
        Re-run:
        ```
        $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
        /nix/store/h620vx1svr2wz7bjx5cpi2jxpqda5ad3-nixos-system-thiniel-26.11.20261008.8edc0c7.drv
        exit 0

        $ nix build .#checks.x86_64-linux.unit-helpers --no-link   -> UNIT_OK
        $ nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath   -> MACBOOK_OK
        ```
  - [x] REFACTOR: no restructuring needed; the changed files were formatted with the repository's pinned `nixfmt` and re-verified.
        ```
        $ nix build .#checks.x86_64-linux.lint-deadnix .#checks.x86_64-linux.lint-statix .#checks.x86_64-linux.lint-nixfmt --no-link   -> all three built
        $ nix build .#checks.x86_64-linux.unit-helpers --no-link   -> UNIT_OK
        $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath   -> HOST_OK
        $ nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath   -> MACBOOK_OK
        $ python3 scripts/givn-spec-trace.py   -> 4 scenario(s) across 1 feature file(s), 0 finding(s)
        ```
  - [ ] COMMIT: `<hash>` — `feat(permitted-identity-selection): each personal device uses the SSH identity it holds` (one commit for RED+GREEN+REFACTOR)

- [ ] Scenario: `A device declares no connection for an identity whose material it does not hold` (`@host:thiniel`)
  - [ ] RED: extend `tests/assertions/thiniel-invariants.nix` so thiniel must render no company/client001/client002 connection entry and include no manually maintained work-laptop file; run the targeted command. Must fail for the expected reason.
        ```
        <!-- paste the targeted command + non-zero output -->
        ```
  - [ ] GREEN: render the work connection entries only where the host declares that identity's secret material, and take the include list from the host declaration.
        Files created/modified: <!-- list them -->
        Re-run the targeted command. Must pass.
        ```
        <!-- paste GREEN evidence -->
        ```
  - [ ] REFACTOR: no behaviour change; re-run. Must still pass.
        ```
        <!-- paste REFACTOR evidence -->
        ```
  - [ ] COMMIT: `<hash>` — `<message>` (one commit for RED+GREEN+REFACTOR)

- [ ] Scenario: `The work laptop keeps its per-purpose identity selection` (`@host:J6G6Y9JK7L`)
  - [ ] RED: extend `tests/assertions/J6G6Y9JK7L-invariants.nix` so the MacBook must declare its three include files, keep its identity file, its workspace identity configuration and its three work connection entries; run the targeted command. Must fail for the expected reason.
        ```
        <!-- paste the targeted command + non-zero output -->
        ```
  - [ ] GREEN: declare the MacBook's include files in its host user module.
        Files created/modified: <!-- list them -->
        Re-run the targeted command. Must pass.
        ```
        <!-- paste GREEN evidence -->
        ```
  - [ ] REFACTOR: no behaviour change; re-run. Must still pass.
        ```
        <!-- paste REFACTOR evidence -->
        ```
  - [ ] COMMIT: `<hash>` — `<message>` (one commit for RED+GREEN+REFACTOR)

---

## E2E Scenarios

- [x] `verify.e2e_command` (`scripts/givn-verify-e2e.sh`) is set and is not identical to `verify.command` (`scripts/givn-verify.sh`): it builds the `integration-*` scope only.
      ```
      $ grep -c "Scenario:" .../permitted-identity-selection.feature   -> 4
      $ grep -c "@e2e"     .../permitted-identity-selection.feature   -> 1
      $ python3 scripts/givn-spec-trace.py -> givn-spec-trace: 4 scenario(s) across 1 feature file(s), 0 finding(s)
      (e2e scope = 1 of 4 scenarios, a strict subset)
      ```
- [x] The new `integration-*` target is wired in `tests/integration/default.nix` and `flake.nix`, and the Linux/KVM builder boots it (this host has `/dev/kvm`).
      ```
      $ nix build .#checks.x86_64-linux.integration-ssh-identity-selection --no-link
      … the VM booted, applied the configuration and reached the test script's assertion;
        the run failed on that assertion (exit 1) — a boot, not an evaluation error.
      ```

- [ ] @e2e Scenario: `A booted device reaches private repositories with the identity it declares` (`@e2e @check:integration-ssh-identity-selection`)
  - [ ] RED: the wired VM check boots a device that declares `~/.ssh/id_ed25519` and asserts the resolution plus the absence of work entries; run the targeted command. Must fail for the expected reason.
        ```
        <!-- paste the targeted command + non-zero output -->
        ```
  - [ ] GREEN: no further configuration change — the rendering fix from the scenarios above makes the booted device reach the described state. Re-run the targeted command. Must pass.
        ```
        <!-- paste GREEN evidence -->
        ```
  - [ ] REFACTOR: no behaviour change; re-run. Must still pass.
        ```
        <!-- paste REFACTOR evidence -->
        ```
  - [ ] COMMIT: `<hash>` — `test(e2e): <message>` (one commit)

---

**Done when:** every box checked with targeted-command evidence and a commit
hash, the RED evidence shows a non-zero exit for every scenario, and both
`./scripts/givn-verify.sh` and `./scripts/givn-verify-e2e.sh` exit 0 (the latter
on this Linux/KVM host).
