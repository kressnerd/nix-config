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
- [x] COMMIT: `a0e0c8e` — release note as subject, scenario title in the body.

---

## Task 2 — Scenario: `The personal laptop's browser profile lives under its XDG config directory and survives a root reset` (`@host:thiniel`)

**Dangerous area**: this scenario moves a persistent profile directory. The
configuration change is safe to apply (the copy precedes any deletion), and the
operator warning + rollback are in Task 6.

- [ ] RED: remove `@wip`. Extend `tests/assertions/thiniel-hm-invariants.nix`
      with the `programs.firefox.configPath` predicate, and
      `tests/assertions/thiniel-impermanence-invariants.nix` with the rendered
      profile files (XDG path present, `.mozilla/firefox` absent) and the
      persistence mount assertion on `config.systemd.mounts`. Targeted run
      (host evaluation) → MUST exit non-zero with those assertions named. Paste.
- [ ] GREEN: in `home/dan/features/productivity/browser.nix`, state the profile
      location guarded to Linux and move the persistence entry from `.mozilla`
      to `.config/mozilla`. Add the guards from the design: the MacBook's
      platform-default path assertion in `tests/assertions/J6G6Y9JK7L-invariants.nix`
      and the fleet CLI/alias guards in `tests/assertions/thiniel-hm-invariants.nix`
      (guards hold before and after — no RED phase of their own, recorded as
      guards, not scenarios). List files. Re-run → exit 0. Paste.
- [ ] REFACTOR: `nixfmt`; re-run both host evaluations (`thiniel`,
      `J6G6Y9JK7L`) → exit 0. Paste.
- [ ] COMMIT: record the hash.

---

## Task 3 — Scenario: `The flake exposes only outputs the checker interprets` (`@check:flake-output-contract`)

- [ ] RED: remove `@wip`. The check already exists (setup task) and fails today.
      Re-run the targeted command and paste the non-zero output.
- [ ] GREEN: withdraw the `colmenaHive` output and the `colmena` input from
      `flake.nix`; keep the Colmena CLI package and the aliases; the deployment
      plans already carry the re-registration step. Re-run → exit 0. Paste.
- [ ] REFACTOR: confirm the flake still exposes every other output
      (`nix flake show`/`nix flake check --no-build` → no unknown-output warning).
- [ ] COMMIT: record the hash.

---

## Task 4 — Scenario: `A booted device reproduces its identity surface from a single release` (`@e2e @check:integration-ssh-identity-selection`)

- [ ] RED: remove `@wip`. Add the node assertion
      (`config.home-manager.users.test.home.version.release == pkgs.lib.trivial.release`)
      to `tests/integration/ssh-identity-selection-test.nix`. Targeted run
      (evaluation of the check) → MUST exit non-zero: the profile's Home Manager
      release is 26.11 while the guest package set is 26.05. Paste.
- [ ] GREEN: pass `nixpkgs-unstable.legacyPackages.<system>` for this check
      through `tests/integration/default.nix` and the flake's linux checks
      block. Re-run → exit 0. Then build the check itself (`@e2e`):
      `nix build .#checks.x86_64-linux.integration-ssh-identity-selection` →
      the VM boots and the identity surface is observed. Paste both.
- [ ] REFACTOR: no behaviour change; re-run the build.
- [ ] COMMIT: record the hash.

---

## Task 5 — Scenario: `A booted device starts its coding agents from a single release` (`@e2e @check:integration-agent-tooling`)

- [ ] RED: remove `@wip`. Add the same node assertion to
      `tests/integration/agent-tooling-test.nix`. Targeted run → MUST exit
      non-zero for the same release difference. Paste.
- [ ] GREEN: the fixture takes the unstable guest package set (already wired by
      Task 4's change to the aggregator). Re-run the evaluation → exit 0, then
      build the check: `nix build .#checks.x86_64-linux.integration-agent-tooling`
      → the VM boots, both agents start. Paste.
- [ ] REFACTOR: no behaviour change; re-run the build.
- [ ] COMMIT: record the hash.

---

## Task 6 — Operator: relocate the live browser profile on `thiniel`

**Warning**: this moves the device's live browsing data (bookmarks, history,
saved logins) and touches `environment.persistence`. Do not delete the old
directory before the relocation and the rollback have both been confirmed.

- [ ] Apply the new configuration (`sudo nixos-rebuild switch --flake .#thiniel`).
- [ ] With the browser closed: `mkdir -p /persist/.config/mozilla` and
      `cp -a /persist/.mozilla/firefox /persist/.config/mozilla/firefox`.
- [ ] Open the browser and confirm bookmarks, history and saved logins; confirm
      `~/.mozilla` is no longer used and `~/.config/mozilla/firefox` is a mount.
- [ ] Exercise the rollback once with the old directory still present
      (`sudo nixos-rebuild switch --rollback` + `mv` back), then return to the
      new generation.
- [ ] Only then remove `/persist/.mozilla`.
- [ ] Record the operator confirmation (date, what was observed) here.

---

## Final verification

- [ ] `./scripts/givn-verify.sh` → `[givn-verify] OK`, and its output no longer
      prints any of the four reported warnings. Paste.
- [ ] `./scripts/givn-verify-e2e.sh` → `[givn-verify-e2e] OK`. Paste.
- [ ] `python3 scripts/givn-spec-trace.py` → 0 findings. Paste.
