# Tasks: quiet-configuration-evaluation

RED→GREEN→REFACTOR→COMMIT per scenario. Non-`@e2e` first, then `@e2e`. Every
phase runs the scenario's bound target (its `@check:`/`@host:`/`@deploy:` tag)
with the targeted command from `docs/GIVN-VERIFICATION.md` — never the whole
suite.

Legend: an unticked box is pending; a ticked box counts as done only when
evidence and the commit hash are filled in. Check each scenario's box
immediately after completing it — `tasks.md` must always reflect true state.

---

## Domain Constraints

Owning use case: `publish-infrastructure-configuration` (permanent). New
capability: `quiet-configuration-evaluation`.

| Scenario / capability | Use-case guarantee or rule | Persona impact |
|---|---|---|
| `quiet-configuration-evaluation` (all scenarios) | Rule: a setting whose release default the configuration superseded is stated explicitly at a value the operator chose; an evaluation of the repository reports no migration, release-mismatch or unrecognised-output diagnostic to triage, and the flake declares only outputs the checker interprets. | `owner--operator` — the operator runs the checks and host builds and triages what they print. `family--application-user` is unaffected: no hosted application, shared resource or access path changes. |
| Scenario 2 (browser profile) | Rule: a value that relocates a device's data is carried out without discarding it; the immutable-value constraint forbids raising `home.stateVersion`, so the location is stated explicitly instead. | `owner--operator` — the owner's live browsing data moves with the profile. |
| Scenario 5 (flake outputs) | Rule: the flake declares only outputs the checker interprets. The withdrawal must not take the operator's fleet tooling with it (guards). | `owner--operator` — the fleet CLI and the aliases are the operator's tools. |
| Open prerequisite | The live profile move is an operator action on `thiniel`; the declared state is asserted here, and the move's completion is confirmed by the operator (last task). | — |

---

## Setup task (do first)

- [x] **Wire the new targets.** (a) `checks.<system>.flake-output-contract` is
      added to `flake.nix`'s checks block for all three systems (its own entry,
      like `private-data-defaults`), so the `@check:flake-output-contract`
      binding resolves. (b) `tests/assertions/thiniel-hm-invariants.nix` is a
      Home-Manager-level module; scenario 1 creates it and `home/dan/thiniel.nix`
      imports it — no `tests/assertions/default.nix` entry, mirroring
      `tests/assertions/J6G6Y9JK7L-invariants.nix`, which the Mac profile imports
      directly. (c) The two integration fixtures keep their existing wiring;
      scenario 3 and 4 only extend them.
      ```
      $ python3 scripts/givn-spec-trace.py
      [warn] integration check 'integration-adlerkopf' is not referenced by any scenario
      [warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
      givn-spec-trace: 22 scenario(s) across 4 feature file(s), 0 finding(s)
      exit 0
      ```
- [x] **Proof-of-RED for the new target.** The check reads the flake's declared
      outputs (`self.outputs`) and fails while `colmenaHive` is declared:
      ```
      $ nix build --no-link '.#checks.x86_64-linux.flake-output-contract'
      error: Cannot build '/nix/store/z7ga7i988c213f441a9p475v7l40nbax-flake-output-contract.drv'.
             Last 2 log lines:
             > the flake declares outputs the checker does not interpret:
             > colmenaHive
      exit 1
      ```
      Reading `self` directly instead of `self.outputs` failed on the flake-self
      bookkeeping names (`_type`, `inputs`, `narHash`, `outPath`, …), which is
      why the check reads `self.outputs`; recorded in the design.
- [x] **Confirm the runners differ**: `verify.command` = `./scripts/givn-verify.sh`,
      `verify.e2e_command` = `./scripts/givn-verify-e2e.sh` (`givn/commands.yaml`) — confirmed, not identical.

---

## Task 1 — Scenario: `The personal laptop states its compositor configuration format` (`@host:thiniel`)

- [x] RED: removed `@wip` from this scenario only. Created
      `tests/assertions/thiniel-hm-invariants.nix` with the superseded-default
      predicate for `wayland.windowManager.hyprland.configType` (via
      `lib.hm.deprecations.mkStateVersionOptionDefault` in deferred mode) and
      imported it in `home/dan/thiniel.nix`. Targeted run:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      error:
      Failed assertions:
      - dan profile: thiniel: the compositor configuration format must be stated by the device, not resolved from the release's superseded default (set wayland.windowManager.hyprland.configType)
      exit 1
      ```
- [x] GREEN: stated `wayland.windowManager.hyprland.configType = "hyprlang"` in
      `home/dan/features/linux/hyprland.nix` with its rationale comment.
      Files created/modified: `tests/assertions/thiniel-hm-invariants.nix` (new),
      `home/dan/thiniel.nix` (import), `home/dan/features/linux/hyprland.nix`.
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      /nix/store/xxax24mkjqx6vivl2zf5j3yh4iml8zxx-nixos-system-thiniel-26.11.20261008.8edc0c7.drv
      exit 0
      ```
      The compositor's migration warning is gone from that output; only the
      browser-profile warning remains (scenario 2).
- [x] REFACTOR: no behaviour change; the touched Nix files were formatted with
      the repository's `nix fmt` (nixfmt) and the targeted run re-executed:
      ```
      $ nix fmt flake.nix home/dan/thiniel.nix home/dan/features/linux/hyprland.nix tests/assertions/thiniel-hm-invariants.nix
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      /nix/store/xxax24mkjqx6vivl2zf5j3yh4iml8zxx-nixos-system-thiniel-26.11.20261008.8edc0c7.drv
      exit 0
      ```
- [x] COMMIT: `8d58126` — release note as subject, scenario title in the body.

---

## Task 2 — Scenario: `The personal laptop's browser profile lives under its XDG config directory and survives a root reset` (`@host:thiniel`)

**Dangerous area**: this scenario moves a persistent profile directory. The
configuration change is safe to apply (the copy precedes any deletion), and the
operator warning + rollback are in Task 6.

- [x] RED: removed `@wip`. Extended `tests/assertions/thiniel-hm-invariants.nix`
      with the `programs.firefox.configPath` predicate, and
      `tests/assertions/thiniel-impermanence-invariants.nix` with the rendered
      profile files and the persistence declaration (its existing `hmHasDir`
      helper; the naive `builtins.elem` form is wrong because the elements are
      attribute sets, and deep-forcing one throws the impermanence module's
      removed-`method` error). Targeted run:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      error:
      Failed assertions:
      - thiniel: the browser profile must be rendered under /home/dan/.config/mozilla/firefox (profiles.ini)
      - thiniel: the browser profile must no longer be rendered under ~/.mozilla/firefox
      - thiniel: .config/mozilla must be in HM persistence so the relocated browser profile survives the root reset
      - thiniel: .mozilla must not be in HM persistence once the browser profile moved under the XDG config directory
      - dan profile: thiniel: the browser profile location must be stated by the device, not resolved from the release's superseded default (set programs.firefox.configPath)
      exit 1
      ```
- [x] GREEN: `home/dan/features/productivity/browser.nix` states
      `programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox"`
      guarded to Linux (`// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux`)
      and moves the persistence entry from `.mozilla` to `.config/mozilla`. The
      guards are added with it: the MacBook's platform-default path in
      `tests/assertions/J6G6Y9JK7L-invariants.nix`, the fleet CLI and alias
      guards in `tests/assertions/thiniel-hm-invariants.nix` (guards, no RED
      phase — they must hold before and after).
      Files modified: `home/dan/features/productivity/browser.nix`,
      `tests/assertions/thiniel-hm-invariants.nix`,
      `tests/assertions/thiniel-impermanence-invariants.nix`,
      `tests/assertions/J6G6Y9JK7L-invariants.nix`.
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      /nix/store/0vm4d6y540y4m0nzgr9cj1py00b3s86w-nixos-system-thiniel-26.11.20261008.8edc0c7.drv
      exit 0
      ```
      The legacy-path assertion had to be narrowed to `.mozilla/firefox/` after
      the first GREEN run: `~/.mozilla/native-messaging-hosts` legitimately stays
      where it is (the release's own migration note says native messaging hosts
      are not moved), which the `.mozilla/` prefix would have failed on.
- [x] REFACTOR: formatted all four touched files with `nix fmt`; both affected
      host evaluations pass:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      /nix/store/0vm4d6y540y4m0nzgr9cj1py00b3s86w-nixos-system-thiniel-26.11.20261008.8edc0c7.drv
      $ nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath
      /nix/store/jh3if382f1ng92d79y48nhi07kdinjdw-darwin-system-26.11.4cff07d.drv
      exit 0
      ```
      Independent observations: the profile renders under
      `/home/dan/.config/mozilla/firefox/…`, `.mozilla` keeps only
      `native-messaging-hosts`, the persistence list carries `.config/mozilla`
      and no `.mozilla`, and the host evaluation prints zero migration warnings.
- [x] COMMIT: `5d147b8` — release note as subject, scenario title in the body.

---

## Task 3 — Scenario: `The flake exposes only outputs the checker interprets` (`@check:flake-output-contract`)

- [x] RED: removed `@wip`. The target already exists (setup task) and failed
      against the tree that still declared the hive — that run is the RED
      evidence:
      ```
      $ nix build --no-link '.#checks.x86_64-linux.flake-output-contract'
      error: Cannot build '/nix/store/z7ga7i988c213f441a9p475v7l40nbax-flake-output-contract.drv'.
             Last 2 log lines:
             > the flake declares outputs the checker does not interpret:
             > colmenaHive
      exit 1
      ```
- [x] GREEN: withdrew the `colmenaHive` output and the `colmena` input from
      `flake.nix` (and the input from the outputs arguments), replaced by a
      comment pointing at the deployment plans' re-registration step; the
      Colmena CLI package and the aliases stay (guarded in scenario 2);
      `nix flake lock` pruned the orphaned lock nodes without bumping any input.
      Files modified: `flake.nix`, `flake.lock`.
      ```
      $ nix build --no-link '.#checks.x86_64-linux.flake-output-contract'
      building '/nix/store/mx227lylz1qsnlzvgmiwahb74xhnk4f1-flake-output-contract.drv'...
      exit 0

      $ nix flake check --no-build --no-write-lock-file
      (no 'unknown flake output' line; only the two booted-device mismatch
       warnings, scenarios 4 and 5, and the informational omitted-systems note)
      ```
- [x] REFACTOR: `nix fmt flake.nix`; the flake still evaluates for every host
      (`nix flake check --no-build` evaluates all outputs and checks) with the
      lock-diff limited to pruning the removed input's nodes.
- [x] COMMIT: `f4e5b16` — release note as subject, scenario title in the body.

---

## Task 4 — Scenario: `A booted device reproduces its identity surface from a single release` (`@e2e @check:integration-ssh-identity-selection`)

- [x] RED: removed `@wip`. Added the node assertion to
      `tests/integration/ssh-identity-selection-test.nix` (the node became a
      module function to read `config`/`pkgs`). Targeted run:
      ```
      $ nix eval --raw '.#checks.x86_64-linux.integration-ssh-identity-selection.drvPath'
      error:
      Failed assertions:
      - the test profile's Home Manager release must equal the guest package set's release (change quiet-configuration-evaluation)
      exit 1
      ```
- [x] GREEN: `tests/integration/default.nix` takes `unstablePkgs` and gives it
      to the two checks that load the devices' Home Manager modules;
      `flake.nix` passes `nixpkgs-unstable.legacyPackages.<system>`. The
      aggregator change covers both Home-Manager-based checks; scenario 5 adds
      the second fixture's own assertion.
      Files modified: `tests/integration/default.nix`, `flake.nix`,
      `tests/integration/ssh-identity-selection-test.nix`.
      ```
      $ nix eval --raw '.#checks.x86_64-linux.integration-ssh-identity-selection.drvPath'
      /nix/store/sx6849f2pncr9vnc3a60567a56f4rbgf-vm-test-run-ssh-identity-selection.drv
      exit 0
      ```
- [x] REFACTOR: `nix fmt` on the touched Nix files; the `@e2e` build itself is
      the real-interface proof:
      ```
      $ nix build --no-link '.#checks.x86_64-linux.integration-ssh-identity-selection'
      building '/nix/store/sx6849f2pncr9vnc3a60567a56f4rbgf-vm-test-run-ssh-identity-selection.drv'...
      exit 0
      ```
      The derivation runs the QEMU VM (boot, Home Manager activation, the
      identity-surface script), so the guest boots with the paired releases and
      the declared identity surface is observed on the device.
- [x] COMMIT: `aebcdd6` — release note as subject, scenario title in the body.

---

## Task 5 — Scenario: `A booted device starts its coding agents from a single release` (`@e2e @check:integration-agent-tooling`)

- [x] RED: removed `@wip`. Added the same node assertion to
      `tests/integration/agent-tooling-test.nix` (the node became a module
      function). The aggregator's guest-package-set change is one wiring change
      shared with scenario 4, so RED was proven against the fixture's pairing
      before it, with the aggregator temporarily passing the release set again:
      ```
      $ nix eval --raw '.#checks.x86_64-linux.integration-agent-tooling.drvPath'   # release pkgs + assertion
      error:
      Failed assertions:
      - the test profile's Home Manager release must equal the guest package set's release (change quiet-configuration-evaluation)
      exit 1
      ```
- [x] GREEN: the fixture takes the unstable guest package set through
      `tests/integration/default.nix` (already wired by scenario 4); the
      temporary revert was undone.
      ```
      $ nix eval --raw '.#checks.x86_64-linux.integration-agent-tooling.drvPath'
      /nix/store/a5x0vvyc20vh8f3zbc3v8gfrgbb8fk74-vm-test-run-agent-tooling.drv
      exit 0
      ```
- [x] REFACTOR: `nix fmt` on the fixture; the `@e2e` build is the real-interface
      proof — the VM boots, Home Manager activates, both agents start and report
      their floors, and the guard lands where the agent discovers hooks:
      ```
      $ nix build --no-link '.#checks.x86_64-linux.integration-agent-tooling'
      building '/nix/store/a5x0vvyc20vh8f3zbc3v8gfrgbb8fk74-vm-test-run-agent-tooling.drv'...
      exit 0
      ```
- [x] COMMIT: `d485719` — release note as subject, scenario title in the body.

---

## Task 6 — Operator procedure (carried with the change, not executed by it)

**Warning**: this moves the device's live browsing data (bookmarks, history,
saved logins) and touches `environment.persistence`. A partial execution presents
an empty profile although the configuration is correct. The repository cannot
restore browsing data, so the copy precedes any deletion and the old directory is
removed only after the relocation *and* the rollback have been confirmed.

This is the one step the change deliberately leaves to the device owner: the
configuration and its declared state are complete and asserted without it, and
applying a new generation plus moving personal data on the daily-driver laptop is
the owner's action, not a repository change. The procedure:

1. Apply the new configuration: `sudo nixos-rebuild switch --flake .#thiniel`.
2. With the browser closed:
   `mkdir -p /persist/.config/mozilla` and
   `cp -a /persist/.mozilla/firefox /persist/.config/mozilla/firefox`.
3. Open the browser and confirm bookmarks, history and saved logins;
   `~/.config/mozilla/firefox` must be the profile in use.
4. Exercise the rollback once while the old directory still exists:
   `sudo nixos-rebuild switch --rollback` (the home profile rolls back with the
   system generation), then
   `mv /persist/.config/mozilla/firefox /persist/.mozilla/firefox` before the
   reboot that remounts the persistence, and switch forward again.
5. Only then remove `/persist/.mozilla`.
6. Record the date and what was observed here.

---

## Final verification

- [x] `./scripts/givn-verify.sh` → `[givn-verify] OK` (256 python tests, all
      non-VM checks built, every host evaluated) — and the flake evaluation no
      longer prints any of the four reported warnings:
      ```
      $ nix flake check --no-build --no-write-lock-file 2>&1 | grep -E "unknown flake output|has changed from|mismatched versions"
      (no output)
      ```
      The only remaining line is the checker's informational note that it omitted
      the incompatible systems, which is out of scope (Out of Scope section of
      the proposal).
- [x] `./scripts/givn-verify-e2e.sh` → `[givn-verify-e2e] OK` (all five
      `integration-*` checks built, including the two whose guest package set
      moved to the pinned unstable set).
- [x] `python3 scripts/givn-spec-trace.py` → 22 scenarios, 0 findings; `givn lint
      --change quiet-configuration-evaluation` → clean (no `@wip` left).
- [x] The live browser relocation on `thiniel` is the operator procedure recorded
      in Task 6; it is deliberately not executed by this change.
