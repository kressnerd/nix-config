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

- [x] **Wire the new target and prove RED.** Created
      `tests/integration/rust-toolchain-test.nix`, registered it in
      `tests/integration/default.nix`, created `home/dan/features/development/rust.nix`
      with no packages, and imported it from `home/dan/thiniel.nix`. The new
      files were staged so the flake sees them. Evidence:
      ```
      $ python3 scripts/givn-spec-trace.py
      givn-spec-trace: 32 scenario(s) across 7 feature file(s), 0 finding(s)
      exit 0

      $ nix build --no-link '.#checks.x86_64-linux.integration-rust-toolchain'
      machine: must succeed: sudo -u test env HOME=/home/test PATH=/etc/profiles/per-user/test/bin rustc --version
      machine # env: ‘rustc’: No such file or directory
      !!! RequestedAssertionFailed: command `... rustc --version` failed (exit code 127)
      exit 1
      ```
      The check was wired first; the RED is the guest's missing toolchain, not a
      wiring error.
- [x] **Confirm the runners differ**: `verify.command` = `./scripts/givn-verify.sh`
      vs `verify.e2e_command` = `./scripts/givn-verify-e2e.sh` (`givn/commands.yaml`) — confirmed.

---

## Task 1 — Scenario: `The personal laptop provides the Rust compiler and Cargo` (`@host:thiniel`)

- [x] RED: removed `@wip` from this scenario only. Added the package assertions
      to `tests/assertions/thiniel-hm-invariants.nix`. Targeted run:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      error:
      Failed assertions:
      - dan profile: thiniel: the Rust compiler (rustc) must be installed for the Rust build toolchain
      - dan profile: thiniel: Cargo must be installed for the Rust build toolchain
      - dan profile: thiniel: a C linker (gcc) must be installed so a Rust build can link its program
      - dan profile: thiniel: pkg-config must be installed so Rust crates can discover system libraries
      exit 1
      ```
      (A first attempt read `config.home-manager.users.dan.home.packages` inside
      the Home Manager module, which has no such option; corrected to
      `config.home.packages` before the run above.)
- [x] GREEN: added `rustc`, `cargo`, `gcc`, `pkg-config` to
      `home/dan/features/development/rust.nix` from the host package set.
      Files modified: `home/dan/features/development/rust.nix`,
      `home/dan/thiniel.nix`,
      `tests/assertions/thiniel-hm-invariants.nix`. Evidence:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      /nix/store/223nsvvqqp3a1qrjxb1r4h5zcx1kl29a-nixos-system-thiniel-26.11.20261016.f20cd90.drv
      exit 0
      ```
- [x] REFACTOR: `nix fmt` on the touched Nix files; the host evaluation above
      is post-format (exit 0).
- [x] COMMIT: `0989915` — release note as subject, scenario title in the body.

---

## Task 2 — Scenario: `The personal laptop keeps the Cargo home across boots` (`@host:thiniel`)

Dangerous area: impermanence. The entry generates a system-level mount unit and
an activation entry for `/home/dan/.cargo`; the apply order is `switch` before
`boot`, and the rollback is the previous generation
(`sudo nixos-rebuild switch --rollback`).

- [x] RED: removed `@wip`. Added the persistence assertion to
      `tests/assertions/thiniel-hm-invariants.nix`. Targeted run:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      error:
      Failed assertions:
      - dan profile: thiniel: .cargo must be persisted so the Cargo home survives the root wipe
      exit 1
      ```
- [x] GREEN: added `.cargo` to the module's persistence list behind
      `lib.optionalAttrs config.myHome.persistence.enable`. Evidence:
      ```
      $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
      /nix/store/jgj9p46d92makbhcppxrwdfc7hl7ikbs-nixos-system-thiniel-26.11.20261016.f20cd90.drv
      exit 0
      ```
- [x] REFACTOR: `nix fmt`; the host evaluation above is post-format (exit 0).
- [x] COMMIT: `b41693d` — release note as subject, scenario title in the body.

---

## Task 3 — Scenario: `A booted device builds and runs a Rust project` (`@e2e @check:integration-rust-toolchain`)

- [x] RED: removed `@wip`. The check was already wired from the setup task. The
      guest built and ran the project, then failed on the lint assertion
      because `clippy` was not yet installed:
      ```
      $ nix build --no-link '.#checks.x86_64-linux.integration-rust-toolchain'
      machine: must succeed: sudo -u test env HOME=/home/test PATH=/etc/profiles/per-user/test/bin cargo clippy --offline --manifest-path /home/test/hello/Cargo.toml
      machine # error: no such command: `clippy`
      !!! RequestedAssertionFailed: command `... cargo clippy ...` failed (exit code 101)
      exit 1
      ```
- [x] GREEN: added `clippy` to the module. Evidence:
      ```
      $ nix build --no-link '.#checks.x86_64-linux.integration-rust-toolchain'
      building '/nix/store/8qlsc6w5021izzkh7h3jn501zj7laybi-vm-test-run-rust-toolchain.drv'...
      exit 0
      ```
- [x] REFACTOR: `nix fmt home/dan/features/development/rust.nix`; the booted
      check above is the post-format run, and the host evaluation stayed green
      (`/nix/store/dynnivxs6yhs88a93sq890v31gzqb6wi-nixos-system-thiniel-...drv`).
- [x] COMMIT: `7265e32` — release note as subject, scenario title in the body.

---

## Final verification

- [x] `./scripts/givn-verify.sh` exits 0.
      ```
      [givn-verify] 5/5 python test suite (scripts/)
      256 passed in 7.27s
      [givn-verify] OK
      ```
- [x] `./scripts/givn-verify-e2e.sh` exits 0.
      ```
      [givn-verify-e2e] building: integration-adlerkopf integration-agent-tooling integration-github-fetch-credential integration-managed-file-displacement integration-private-data-separation integration-rust-toolchain integration-ssh-identity-selection integration-vm-minimal-ssh
      [givn-verify-e2e] OK
      ```
- [x] `python3 scripts/givn-spec-trace.py` exits 0.
      ```
      givn-spec-trace: 32 scenario(s) across 7 feature file(s), 0 finding(s)
      ```
- [x] No tautologies in the added targets; commit count matches the task count.
      The host assertions compare concrete package names and the `.cargo`
      persistence entry; the VM check runs real commands and asserts the
      program's output. Three scenario commits: `0989915`, `b41693d`, `7265e32`.
