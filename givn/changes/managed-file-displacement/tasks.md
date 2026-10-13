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

- [ ] **Wire the new targets.** (a) `tests/integration/managed-file-displacement-test.nix`
      is registered in `tests/integration/default.nix` and the flake's linux
      checks block passes the *declared* value
      (`self.nixosConfigurations.thiniel.config.home-manager.backupFileExtension`),
      so the boot proves the device's setting. (b) The two host assertions go into
      the existing system-level modules (`tests/assertions/common-global-invariants.nix`,
      `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix`), so no aggregator entry
      is needed. Evidence: `python3 scripts/givn-spec-trace.py` → 0 findings (paste).
- [ ] **Proof-of-RED.** The two host assertions fail against the current tree
      (`backupFileExtension` is `null`), and the booted check fails for the
      clobber reason while the declared value is `null`. Paste the non-zero runs.
- [ ] **Confirm the runners differ** (`givn/commands.yaml`).

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
- [x] COMMIT: `PENDING_HASH_1` — release note as subject, scenario title in the body.

---

## Task 2 — Scenario: `The work MacBook displaces a rewritten managed file` (`@host:J6G6Y9JK7L`)

- [ ] RED: remove `@wip`. Add the same assertion to
      `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix` (the HM-level file
      cannot see darwin system options). Targeted run:
      `nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath`
      → MUST exit non-zero. Paste.
- [ ] GREEN: set `home-manager.backupCommand` to the same helper in
      `hosts/J6G6Y9JK7L/default.nix`. Re-run → exit 0. Paste.
- [ ] REFACTOR: `nix fmt`; re-run → exit 0.
- [ ] COMMIT: record the hash.

---

## Task 3 — Scenario: `A booted device activates although a program rewrote a managed file` (`@e2e @check:integration-managed-file-displacement`)

- [ ] RED: remove `@wip`. Wire the fixture (setup task) and, for this run only,
      pass `null` to it from the flake so the guest reproduces the pre-change
      state (today's declared value). Targeted run:
      `nix build --no-link .#checks.x86_64-linux.integration-managed-file-displacement`
      → MUST fail: the guest's `home-manager-test.service` aborts on
      `Existing file '…/settings.conf' would be clobbered` (no displacement
      command declared). Paste.
- [ ] GREEN: pass the declared value again (`self.nixosConfigurations.thiniel…`);
      with Task 1's helper in place this is the displacement script. Re-run the
      build → the guest boots, the activation completes, the rendered file is in
      place, `settings.conf.1` still holds the earlier rewrite and
      `settings.conf.2` holds the newer one. Paste.
- [ ] REFACTOR: `nix fmt` on the touched Nix files; re-run the build.
- [ ] COMMIT: record the hash.

---

## Operator step (applies the setting to the device)

This is the same step that failed twice on 2026-10-13; it now applies cleanly and
each earlier failure's file is already parked.

- [ ] `sudo nixos-rebuild switch --flake .#thiniel` on the laptop (Firefox may
      stay open this time: nothing needs to be freed, the activation moves any
      conflicting file aside).
- [ ] Confirm the activation completes and `home-manager-dan.service` shows the
      new activation timestamp.
- [ ] Record the date and what was observed.

---

## Final verification

- [ ] `./scripts/givn-verify.sh` → `[givn-verify] OK`, no new warning in its output.
- [ ] `./scripts/givn-verify-e2e.sh` → `[givn-verify-e2e] OK` (includes the new check).
- [ ] `python3 scripts/givn-spec-trace.py` → 0 findings; `givn lint --change managed-file-displacement` → clean.
