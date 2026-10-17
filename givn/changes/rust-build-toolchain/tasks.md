# Tasks: rust-build-toolchain

RED→GREEN→REFACTOR→COMMIT per scenario. Non-`@e2e` first, then `@e2e`. Every
phase runs the scenario's bound target (its `@check:`/`@host:`/`@deploy:` tag)
with the targeted command from `docs/GIVN-VERIFICATION.md` — never the whole
suite. Check each box as its evidence is filled in.

---

## Domain Constraints

Owning use case: `reproduce-working-environment` (permanent contract, carried
with the new capability and rule). Capability: `rust-build-toolchain`.

| Scenario / capability | Use-case guarantee or rule | Persona impact |
|---|---|---|
| `rust-build-toolchain` (all scenarios) | Rule (new): a device that builds Rust projects provides one default toolchain — compiler, Cargo, a C linker and pkg-config — declares the Cargo home persistent, and exercises a lint driver. Rule: the toolchain is the device's, not a project-specific pin. | `owner--operator` — the operator builds Rust projects on their own laptop. `family--application-user` unaffected: no hosted application, shared resource, or access path changes. |
| Task 1 (packages) | Rule: the device provides the compiler, package manager, C linker and pkg-config. | `owner--operator` |
| Task 2 (persistence) | Rule: the device declares the Cargo home persistent, so it survives boots. Dangerous area: impermanence. | `owner--operator` |
| Task 3 (booted build) | Flow step 4: the owner attempts the defined usual work and the system checks usable work context rather than installation alone. | `owner--operator` |

---

## Setup task (do first)

- [ ] **Wire the new target and prove RED.** Create
      `tests/integration/rust-toolchain-test.nix`, register it in
      `tests/integration/default.nix`, create `home/dan/features/development/rust.nix`
      with no packages, and import it from `home/dan/thiniel.nix`. Run the
      scenario's targeted command; it must fail because the guest has no `cargo`
      (not because the check is missing or the module does not evaluate).
- [ ] **Confirm the runners differ**: `verify.command` = `./scripts/givn-verify.sh`
      vs `verify.e2e_command` = `./scripts/givn-verify-e2e.sh` (`givn/commands.yaml`).

---

## Task 1 — Scenario: `The personal laptop provides the Rust compiler and Cargo` (`@host:thiniel`)

- [ ] RED: remove `@wip` from this scenario only. Add the package assertion to
      `tests/assertions/thiniel-hm-invariants.nix`. Targeted run:
      `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
      — must fail naming the missing `rustc`/`cargo`/`gcc`/`pkg-config` packages.
- [ ] GREEN: add `rustc`, `cargo`, `gcc`, `pkg-config` to
      `home/dan/features/development/rust.nix` (host package set). Re-run the
      targeted command; must exit 0.
- [ ] REFACTOR: `nix fmt` the touched files; re-run; still exit 0.
- [ ] COMMIT: `givn commit` with the release note as subject and the scenario
      title in the body; record the hash.

---

## Task 2 — Scenario: `The personal laptop keeps the Cargo home across boots` (`@host:thiniel`)

Dangerous area: impermanence. The entry generates a system-level mount unit and
an activation entry for `/home/dan/.cargo`; the apply order is `switch` before
`boot`, and the rollback is the previous generation
(`sudo nixos-rebuild switch --rollback`).

- [ ] RED: remove `@wip`. Add the persistence assertion to
      `tests/assertions/thiniel-hm-invariants.nix`. Targeted run must fail naming
      the missing `.cargo` entry.
- [ ] GREEN: add `.cargo` to the module's persistence list behind
      `lib.optionalAttrs config.myHome.persistence.enable`. Re-run; must exit 0.
- [ ] REFACTOR: `nix fmt`; re-run; still exit 0.
- [ ] COMMIT: `givn commit`; record the hash.

---

## Task 3 — Scenario: `A booted device builds and runs a Rust project` (`@e2e @check:integration-rust-toolchain`)

- [ ] RED: remove `@wip`. The check is already wired from the setup task. Make
      the guest build, run and lint a project; the lint assertion must fail
      because `clippy` is not yet installed. Targeted run
      `nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).integration-rust-toolchain`
      — must exit non-zero with the unknown `clippy` subcommand / missing
      `cargo-clippy`.
- [ ] GREEN: add `clippy` to the module. Re-run the targeted command; must exit 0.
- [ ] REFACTOR: `nix fmt`; re-run; still exit 0.
- [ ] COMMIT: `givn commit` with `test(e2e):` subject per the skill; record the hash.

---

## Final verification

- [ ] `./scripts/givn-verify.sh` exits 0.
- [ ] `./scripts/givn-verify-e2e.sh` exits 0.
- [ ] `python3 scripts/givn-spec-trace.py` exits 0.
- [ ] No tautologies in the added targets; commit count matches the task count.
