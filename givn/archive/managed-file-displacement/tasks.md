# Tasks: managed-file-displacement

RED→GREEN→REFACTOR→COMMIT per scenario. Non-`@e2e` first, then `@e2e`. Every
phase runs the scenario's bound target (its `@check:`/`@host:`/`@deploy:` tag)
with the targeted command from `docs/GIVN-VERIFICATION.md` — never the whole
suite. Check each box as its evidence is filled in.

---

## Domain Constraints

Owning use case: `reproduce-working-environment` (permanent, carried with the
new capability and rule). Capability: `managed-file-displacement`.

| Scenario / capability | Use-case guarantee or rule | Persona impact |
|---|---|---|
| `managed-file-displacement` (all scenarios) | Rule (new): applying the device's configuration completes even when a program on the device rewrote a file the configuration manages; the rewritten file is moved aside beside the rendered one and kept, never discarded. Rule: the flow preserves already available working data unless a replacement is explicitly authorized. | `owner--operator` — the operator applies the configuration to their own device and is the one who sees a failed activation. `family--application-user` unaffected: no hosted application, shared resource, or access path changes. |
| Scenario 3 (booted device) | Flow step 3: the owner authorises assembly of the intended context; the system applies the selected configuration — the activation must not depend on a manual file move. | `owner--operator` |
| Declared half | The setting is the same value everywhere Home Manager runs, so the invitation to hand-edit a managed file is not answered differently per device. | `owner--operator` |

---

## Setup task (do first)

- [x] **Wire the new targets.** (a) `tests/integration/managed-file-displacement-test.nix`
      is registered in `tests/integration/default.nix` and the flake's linux
      checks block passes the *declared* value
      (`self.nixosConfigurations.thiniel.config.home-manager.backupCommand`), so
      the boot proves the device's setting (done in Task 3's RED). (b) The two
      host assertions went into the existing system-level modules
      (`tests/assertions/common-global-invariants.nix` in Task 1,
      `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix` in Task 2), so no
      aggregator entry was needed. Evidence:
      ```
      $ python3 scripts/givn-spec-trace.py
      givn-spec-trace: 25 scenario(s) across 5 feature file(s), 0 finding(s)
      exit 0
      ```
- [x] **Proof-of-RED.** Recorded per scenario below: the two host assertions
      failed with their own messages, and the booted check failed with the guest's
      `Existing file '/home/test/.config/example/settings.conf' would be clobbered`.
- [x] **Confirm the runners differ**: `verify.command` = `./scripts/givn-verify.sh`
      vs `verify.e2e_command` = `./scripts/givn-verify-e2e.sh` (`givn/commands.yaml`) — confirmed.

---

## Task 1 — Scenario: `The personal laptop displaces a rewritten managed file` (`@host:thiniel`)

- [x] RED: removed `@wip` from this scenario only. Added the assertion to
      `tests/assertions/common-global-invariants.nix` (system-level, universal —
      it covers all four NixOS hosts). Targeted run:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      error:
      Failed assertions:
      - Global invariant violated: home-manager.backupCommand must be the repository's displacement command, so a rewritten managed file is renamed aside instead of aborting the activation
      exit 1
      ```
- [x] GREEN: added `mkManagedFileDisplacement` to `lib/helpers.nix` and set
      `home-manager.backupCommand` to it in `hosts/common/global/default.nix`.
      Files modified: `lib/helpers.nix`, `hosts/common/global/default.nix`.
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      /nix/store/ghy58lb0jabhi69jhzk503aiwm7chc7p-nixos-system-thiniel-26.11.20261008.8edc0c7.drv
      exit 0

      $ nix eval --raw .#nixosConfigurations.{adlerkopf,cupix001,nixos-vm-minimal}.config.home-manager.backupCommand
      /nix/store/5svscj0b3y2kg49m33jz54wm9dhqdxb7-hm-displace-managed-file   (adlerkopf, cupix001)
      /nix/store/j3xq941xcafbpxd8ra5ijv70kx2kfid6-hm-displace-managed-file   (nixos-vm-minimal)
      ```
      The first GREEN attempt failed with `Path 'hosts/lib/helpers.nix' does not
      exist`: the import from `hosts/common/global/` needs three levels up; fixed
      before the run above.
- [x] REFACTOR: `nix fmt` on both files; the targeted run above is post-format
      (exit 0).
- [x] COMMIT: `ed4a60c` — release note as subject, scenario title in the body.

---

## Task 2 — Scenario: `The work MacBook displaces a rewritten managed file` (`@host:J6G6Y9JK7L`)

- [x] RED: removed `@wip`. Added the same assertion to
      `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix` (the HM-level file
      cannot see darwin system options). Targeted run:
      ```
      $ nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath
      error:
      Failed assertions:
      - J6G6Y9JK7L: home-manager.backupCommand must be the repository's displacement command, so a rewritten managed file is renamed aside instead of aborting the activation
      exit 1
      ```
- [x] GREEN: set `home-manager.backupCommand` to the same helper in
      `hosts/J6G6Y9JK7L/default.nix`. Re-run:
      ```
      $ nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath
      /nix/store/spkdk1kbyc6n04aihpb30mvdf5adagq5-darwin-system-26.11.4cff07d.drv
      exit 0
      ```
- [x] REFACTOR: `nix fmt` on both files; the run above is post-format (exit 0).
- [x] COMMIT: `9ee7a60` — release note as subject, scenario title in the body.

---

## Task 3 — Scenario: `A booted device activates although a program rewrote a managed file` (`@e2e @check:integration-managed-file-displacement`)

- [x] RED: removed `@wip`. Wired the fixture and, for this run only, passed
      `null` from the flake so the guest reproduced the pre-change declaration.
      Targeted run:
      ```
      $ nix build --no-link '.#checks.x86_64-linux.integration-managed-file-displacement'
      machine: waiting for unit home-manager-test.service
      !!! RequestedAssertionFailed: unit "home-manager-test.service" reached state "failed"
      # from the guest log:
      hm-activate-test[704]: Existing file '/home/test/.config/example/settings.conf' would be clobbered
      exit 1
      ```
      A first RED run failed for the wrong reason — `mkdir: cannot create
      directory '/home/test/.config/fontconfig': Permission denied` — because the
      seeding step created `/home/test/.config` as root; the seed now creates the
      whole path for the test user (`install -d -o test -g users`), which is what
      the grilling's F5 asked for.
- [x] GREEN: passed the declared value again
      (`self.nixosConfigurations.thiniel.config.home-manager.backupCommand`), which
      is the repository's displacement command. Targeted run:
      ```
      $ nix build --no-link '.#checks.x86_64-linux.integration-managed-file-displacement'
      building '/nix/store/ksnl2gcza9npssynd8pyjjinpxl9f679-vm-test-run-managed-file-displacement.drv'...
      exit 0
      ```
      The guest booted, `home-manager-test.service` succeeded, the test script
      asserted the rendered link plus both displaced copies: `.1` still holds
      `written even earlier` (the earlier rewrite untouched) and `.2` holds
      `written by a program` (the newest rewrite) — the repeat case F1 found.
      Files: `tests/integration/managed-file-displacement-test.nix` (new),
      `tests/integration/default.nix`, `flake.nix`.
- [x] REFACTOR: `nix fmt` on the three files; the build above is post-format (exit 0).
- [x] COMMIT: `bf77831` — release note as subject, scenario title in the body.

---

## Operator step (applies the setting to the device; not executed by this change)

Applying the setting to a live device is the owner's action, not a repository
change: the declared state and the behaviour are proven by the booted check, and
this step only puts it on `thiniel`. It is the same step that failed twice on
2026-10-13; it now applies cleanly, and the files that made it fail are already
parked beside their rendered versions.

1. `sudo nixos-rebuild switch --flake .#thiniel` on the laptop (the browser may
   stay open: nothing needs to be freed, and any conflicting managed file is
   renamed aside rather than aborting).
2. Confirm the activation completes and `home-manager-dan.service` reports a new
   activation timestamp.
3. The next time the browser rewrites a managed file, the switch completes and a
   `<name>.<n>` copy sits beside the rendered file — record that observation here.

## Final verification

- [x] `./scripts/givn-verify.sh` → `[givn-verify] OK` (256 python tests, all
      non-VM checks built, every host evaluated; the flake evaluation still prints
      no warning to triage).
- [x] `./scripts/givn-verify-e2e.sh` → `[givn-verify-e2e] OK` (all six
      `integration-*` checks built, including the new one).
- [x] `python3 scripts/givn-spec-trace.py` → 25 scenarios, 0 findings;
      `givn lint --change managed-file-displacement` → no `@wip` left (one shape
      advisory on the two host scenarios, which cannot be merged without dropping
      a binding).
