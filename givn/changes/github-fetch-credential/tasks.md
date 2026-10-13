# Tasks: github-fetch-credential

Release note (commit subject for every scenario):
**the two build machines fetch this configuration's private GitHub sources with a credential each machine declares, so nix pulls without a hand-exported token and without a world-token file every local account can read**

Domain constraints copied from the use case and the design (they hold for every
scenario below):

- The credential is recorded only **encrypted** (`github/access-token` in the
  machine's own `secrets.yaml`); never a plaintext value, a store path, a
  generated configuration literal, or a process environment variable.
- A machine presents only the credential it declares; a machine that declares
  none presents none and never borrows another machine's.
- The rendered fragment is mode `0400`, owned by the device owner; root reads it
  by privilege; no other local account can read it.
- A missing or unreadable fragment leaves that machine's fetches unauthenticated
  (reported through `!include` tolerance), never replaced by another credential.
- Only thiniel and the work MacBook are in scope; every other host declares
  nothing.
- `system.stateVersion`/`home.stateVersion` never change; `hosts/*/hardware.nix`
  is read-only; **never run `sops`** — the operator's `sops` steps are
  prerequisite to deploying a host, not to these checks.

Dangerous area: secret wiring. Rollback for both machines is recorded in
`design.md` "Deployment & Rollback" (`nixos-rebuild switch --rollback` /
`darwin-rebuild switch --rollback`; the include is additive and `@e2e`-proven).

---

## Task 0 — Setup: targets wired before the first RED

- [x] Read the owning `usecase.md` (`givn/specs/reproduce-working-environment/usecase.md`),
      its guarantees, and the delta's added rules; they are copied into the
      header above.
- [x] The bounded targets this change uses are **edits to existing assertion
      modules** (already aggregated/imported: `tests/assertions/thiniel-invariants.nix`
      and `adlerkopf-invariants.nix` through `tests/assertions/default.nix`,
      `J6G6Y9JK7L-invariants.nix` through `home/dan/J6G6Y9JK7L.nix`,
      `J6G6Y9JK7L-darwin-invariants.nix` through `hosts/J6G6Y9JK7L/default.nix`),
      so no new assertion target needs registering. The one **new** target is
      the VM check, wired in Task 4's setup before its own RED.
- [x] RED evidence for the evaluation-level scenarios. Both assertions were
      written against the current revision first and each host target fails to
      evaluate because the option surface does not exist yet (same runs as the
      RED halves of Scenario 1 and Scenario 3 below):
  - command: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
  - output:
    ```
    $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
    error: attribute 'githubFetchCredential' missing
          at /home/dan/dev/PRIVATE/nix-config/tests/assertions/thiniel-invariants.nix:176:23:
             175|         {
             176|           assertion = config.mySystem.githubFetchCredential.enable;
                |                       ^
    exit 1
    ```
  - command: `nix eval --raw .#nixosConfigurations.adlerkopf.config.system.build.toplevel.drvPath`
  - output:
    ```
    $ nix eval --raw .#nixosConfigurations.adlerkopf.config.system.build.toplevel.drvPath
    error: attribute 'mySystem' missing
          at /home/dan/dev/PRIVATE/nix-config/tests/assertions/adlerkopf-invariants.nix:110:21:
             110|         assertion = config.mySystem.githubFetchCredential.enable == false;
                |                     ^
    exit 1
    ```

Also confirmed: `nix.extraOptions` exists in this pin —
`nix eval --raw '.#nixosConfigurations.thiniel.options.nix.extraOptions.type.description'`
→ `strings concatenated with "\n"` ("Additional text appended to `nix.conf`").

---

## Scenario 1 — The laptop declares the credential it presents to the GitHub host

`@host:thiniel` — bound target: `tests/assertions/thiniel-invariants.nix`
(NixOS-level assertion, fired by host evaluation).

- [x] **RED** — added the assertion to `tests/assertions/thiniel-invariants.nix`:
      `mySystem.githubFetchCredential.enable == true`, the declared
      `sops.secrets."github/access-token"`, the template
      `nix-github-access-tokens` with `mode = "0400"` and `owner = "dan"` and the
      rendered path `/run/secrets/rendered/nix-github-access-tokens`, and
      `nix.extraOptions` containing `!include <that path>`. Removed `@wip` from
      this scenario. Targeted run:
  - command: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
  - output:
    ```
    $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
    error: attribute 'githubFetchCredential' missing
          at /home/dan/dev/PRIVATE/nix-config/tests/assertions/thiniel-invariants.nix:176:23:
             176|           assertion = config.mySystem.githubFetchCredential.enable;
                |                       ^
    exit 1
    ```

- [x] **GREEN** — implemented `modules/nixos/github-fetch-credential/options.nix`
      (`mySystem.githubFetchCredential.{enable,user}`), its `default.nix`
      (secret + template + `nix.extraOptions`), the import in
      `hosts/common/global/default.nix`, and
      `mySystem.githubFetchCredential.enable = true` in `hosts/thiniel/default.nix`.
      Files added/modified: `modules/nixos/github-fetch-credential/options.nix`,
      `modules/nixos/github-fetch-credential/default.nix`,
      `hosts/common/global/default.nix`, `hosts/thiniel/default.nix`.
      Re-run:
    ```
    $ git add modules/nixos/github-fetch-credential   # flake only sees tracked files
    $ nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath
    /nix/store/ybv6pd5bp4aw0i8pcyplwjhyky9d0hzr-nixos-system-thiniel-26.11.20261008.8edc0c7.drv
    exit 0
    ```
    (first attempt failed with `Path 'modules/nixos/github-fetch-credential' in
    the repository … is not tracked by Git`; `git add` fixed it before the run above.)

- [x] **REFACTOR** — `nix fmt` on the new module and edited files; re-run:
  - command: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
  - output: the drvPath above, `exit 0` (post-format).

- [x] **COMMIT** — `givn commit -m "feat(github-fetch-credential): <release note>"`
      with the scenario title in the body. Record the hash:
  - hash: `7e4e302`

Evidence: RED: `attribute 'githubFetchCredential' missing` (exit 1). GREEN:
`/nix/store/ybv6pd5bp4aw0i8pcyplwjhyky9d0hzr-nixos-system-thiniel-26.11.20261008.8edc0c7.drv`
(exit 0). REFACTOR: same drvPath after `nix fmt` (exit 0). Files:
`modules/nixos/github-fetch-credential/{options,default}.nix`,
`hosts/common/global/default.nix`, `hosts/thiniel/default.nix`.

---

## Scenario 2 — The work MacBook declares the credential it presents to the GitHub host

`@host:J6G6Y9JK7L` — bound targets: `tests/assertions/J6G6Y9JK7L-invariants.nix`
(home-manager level: declared secret, template owner/mode/path, and the owner's
`nix/nix.conf` include) and `tests/assertions/J6G6Y9JK7L-darwin-invariants.nix`
(darwin level: the activation script that writes root's user configuration
exists).

- [x] **RED** — added both assertions (the declarations did not exist, so they
      failed by name): the home-manager-level file asserts the declared secret,
      the template's `mode`/`path`, and the owner's `nix/nix.conf` include; the
      darwin-level file asserts an activation script (`nixGithubAccessTokens`)
      writes root's user configuration with the same include. Removed `@wip`.
      Run:
  - command: `nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath`
  - output:
    ```
    $ nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath
    error: attribute '"nix/nix.conf"' missing
          at /home/dan/dev/PRIVATE/nix-config/tests/assertions/J6G6Y9JK7L-invariants.nix:339:131:
             339|       assertion = lib.hasInfix "!include ${config.home.homeDirectory}/.config/sops-nix/secrets/rendered/nix-github-access-tokens" config.xdg.configFile."nix/nix.conf".text;
                |                                                                                                                                   ^
    exit 1
    ```

- [x] **GREEN** — implemented in `home/dan/J6G6Y9JK7L.nix`: the
      `sops.secrets."github/access-token"` declaration, the
      `sops.templates."nix-github-access-tokens"` (mode `0400`), and the owner's
      `xdg.configFile."nix/nix.conf"` include; in
      `hosts/J6G6Y9JK7L/default.nix`: `system.activationScripts.nixGithubAccessTokens`
      writing `/var/root/.config/nix/nix.conf` with the same include (no secret
      material). Files modified: `home/dan/J6G6Y9JK7L.nix`,
      `hosts/J6G6Y9JK7L/default.nix`. Re-run:
    ```
    $ nix eval --raw .#darwinConfigurations.J6G6Y9JK7L.config.system.build.toplevel.drvPath
    /nix/store/363r2acpblx7x4dc04j71qvpyr2gqxid-darwin-system-26.11.4cff07d.drv
    exit 0

    $ nix eval --impure --raw --expr '…sops.templates."nix-github-access-tokens".path'
    /Users/daniel.kressner/.config/sops-nix/secrets/rendered/nix-github-access-tokens
    ```

- [x] **REFACTOR** — `nix fmt` on the four touched files; re-run the targeted
      command → the drvPath above, `exit 0` (post-format).

- [x] **COMMIT** — `givn commit -m "feat(github-fetch-credential): <release note>"`
      with the scenario title in the body.
  - hash: `9922830`

Evidence: RED: `attribute '"nix/nix.conf"' missing` (exit 1). GREEN/REFACTOR:
`/nix/store/363r2acpblx7x4dc04j71qvpyr2gqxid-darwin-system-26.11.4cff07d.drv`
(exit 0). Files: `home/dan/J6G6Y9JK7L.nix`, `hosts/J6G6Y9JK7L/default.nix`,
`tests/assertions/J6G6Y9JK7L-invariants.nix`,
`tests/assertions/J6G6Y9JK7L-darwin-invariants.nix`.

---

## Scenario 3 — A host that does not build this configuration declares no credential

`@host:adlerkopf` — bound target: `tests/assertions/adlerkopf-invariants.nix`.

- [x] **RED** — added the assertion (`config.mySystem.githubFetchCredential.enable == false`
      and no `!include` of the rendered path in `nix.extraOptions`) and removed
      `@wip`. The RED run was captured **before** the module import landed (it is
      the same run recorded in Task 0), because the option is what the assertion
      reads:
  - command: `nix eval --raw .#nixosConfigurations.adlerkopf.config.system.build.toplevel.drvPath`
  - output:
    ```
    $ nix eval --raw .#nixosConfigurations.adlerkopf.config.system.build.toplevel.drvPath
    error: attribute 'mySystem' missing
          at /home/dan/dev/PRIVATE/nix-config/tests/assertions/adlerkopf-invariants.nix:110:21:
             110|         assertion = config.mySystem.githubFetchCredential.enable == false;
                |                     ^
    exit 1
    ```

- [x] **GREEN** — the implementation from Scenario 1 is present (option module
      imported through `hosts/common/global/default.nix`, default `false`); no
      adlerkopf change is needed. Re-run:
    ```
    $ nix eval --raw .#nixosConfigurations.adlerkopf.config.system.build.toplevel.drvPath
    /nix/store/x7ipy8zza4p1i3h5xyjwaflynd8x15b6-nixos-system-adlerkopf-26.05.20261010.6fcc160.drv
    exit 0
    ```

- [x] **REFACTOR** — `nix fmt` on `tests/assertions/adlerkopf-invariants.nix`;
      re-run the targeted command → the drvPath above, `exit 0` (post-format).

- [x] **COMMIT** — `givn commit -m "feat(github-fetch-credential): <release note>"`
      with the scenario title in the body.
  - hash: `2ffa755`

Evidence: RED: `attribute 'mySystem' missing` (exit 1, captured before the
option module was imported). GREEN/REFACTOR:
`/nix/store/x7ipy8zza4p1i3h5xyjwaflynd8x15b6-nixos-system-adlerkopf-26.05.20261010.6fcc160.drv`
(exit 0). File: `tests/assertions/adlerkopf-invariants.nix`.

---

## Task 4 — E2E setup (before the first `@e2e` scenario)

- [x] `verify.e2e_command` (`./scripts/givn-verify-e2e.sh`) is set and differs
      from `verify.command` (`./scripts/givn-verify.sh`) — confirmed in
      `givn/commands.yaml`.
- [x] Scope is real. The delta carries **4** scenarios (not the 5 this task
      presumed): 3 non-`@e2e` and 1 `@e2e` (strictly smaller). Whole-corpus
      counts from `python3 scripts/givn-spec-trace.py`:
      `givn-spec-trace: 29 scenario(s) across 6 feature file(s), 0 finding(s)`
      (exit 0); `scripts/givn-scenario-count.py` → regular `21`, e2e `8`.
- [x] Wire the new target: `tests/integration/github-fetch-credential-test.nix`
      registered in `tests/integration/default.nix`, which the flake's linux
      checks block merges directly, exposing
      `checks.integration-github-fetch-credential` (confirmed: `nix flake check`
      evaluates it, and `nix build …integration-github-fetch-credential` reaches
      the VM derivation).
- [x] The Linux/KVM builder boots a VM: the new check boots and passes
      (`nix build .#checks.x86_64-linux.integration-github-fetch-credential`
      → exit 0; full run recorded in Scenario 4 below).

Evidence: `givn/commands.yaml` (`verify.command` vs `verify.e2e_command`);
spec-trace `29 scenario(s) … 0 finding(s)`; the check builds and boots (Scenario
4). Scope note: the delta's real scenario count is 4, recorded above rather than
the task's presumed 5.

---

## Scenario 4 — A booted device materialises the declared credential and presents it to the GitHub host

`@e2e @check:integration-github-fetch-credential` — bound target:
`tests/integration/github-fetch-credential-test.nix`.

- [x] **RED** — wrote the test (build-time fixture derivation; guest declares the
      credential through the module; `sops.defaultSopsFile` = the fixture;
      `sops.age.keyFile` = a runtime path; an initrd tmpfiles copy of the key;
      `virtualisation.additionalPaths`) with its assertions: fragment exists at
      the declared path with mode `0400` and the declared owner; `nix config show`
      reports `github.com=<fixture value>` for that account and for root; a
      second, unprivileged account cannot read it; the value appears in no
      configuration file. Removed `@wip`. Targeted run:
  - command: `nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).integration-github-fetch-credential`
  - output:
    ```
    $ nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).integration-github-fetch-credential
    error: flake 'git+file:///home/dan/dev/PRIVATE/nix-config' does not provide attribute 'packages.x86_64-linux.checks.x86_64-linux.integration-github-fetch-credential', 'legacyPackages.x86_64-linux.checks.x86_64-linux.integration-github-fetch-credential' or 'checks.x86_64-linux.integration-github-fetch-credential'
    exit 1
    ```

- [x] **GREEN** — wiring the check uncovered two factual errors in `design.md`
      (both corrected in place before this task was completed, and re-review
      requested from Main):
      1. the fixture's YAML must nest `github:` → `access-token:`
         (`module` validation: `the key 'github' cannot be found`);
      2. the design's `sops.age.keyFile` + `systemd.tmpfiles.rules` mechanism
         cannot work: this pin runs system activation **from the initrd**
         (`initrd-nixos-activation-start[…] … sops-install-secrets: cannot read
         keyfile '/run/github-fetch-credential-test/age-key.txt'`), so the real
         system's `systemd-tmpfiles-setup.service` is too late, and sops-nix
         rejects a store-path key (`pathNotInStore`). Replaced with
         `boot.initrd.systemd.tmpfiles.settings` (initrd tmpfiles run before
         `initrd-switch-root.target`) plus
         `boot.initrd.systemd.storePaths = [ fixture ]`; the guest also needed
         `nix.settings.experimental-features = [ "nix-command" "flakes" ]` for
         `nix config show`.
      Re-run:
    ```
    $ nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).integration-github-fetch-credential
    building '/nix/store/23jlsa80xb5i5h4kvfa9hfjjb1kyhzc6-vm-test-run-github-fetch-credential.drv'...
    exit 0
    ```

- [x] **REFACTOR** — `nix fmt` on the test and the module; `nix build
      .#checks.x86_64-linux.lint-nixfmt` → exit 0; the targeted VM check above is
      post-format (exit 0).

- [ ] **COMMIT** — `givn commit -m "test(e2e): <release note>"` with the scenario
      title in the body (also carries the corrected `design.md`, the module's
      option-presence guard and this evidence).
  - hash: `PENDING_HASH_4`

Evidence: RED: attribute not provided (exit 1). GREEN/REFACTOR: the VM boots and
the check passes (exit 0). Files: `tests/integration/github-fetch-credential-test.nix`,
`tests/integration/default.nix`, `flake.nix` (linux checks block, unchanged),
`modules/nixos/github-fetch-credential/default.nix`,
`givn/changes/github-fetch-credential/design.md`.

---

## Task 5 — Verification (both gates)

- [x] `./scripts/givn-verify.sh` exits 0 (spec traceability now resolves
      `@check:integration-github-fetch-credential`).
- [x] `./scripts/givn-verify-e2e.sh` exits 0 on the Linux/KVM builder.

Evidence:
```
$ python3 scripts/givn-spec-trace.py
givn-spec-trace: 29 scenario(s) across 6 feature file(s), 0 finding(s)   # exit 0

$ ./scripts/givn-verify.sh
[givn-verify] 1/5 … nix flake check --no-build → all checks passed!
[givn-verify] 3/5 build non-VM checks (unit + lint)
[givn-verify] 4/5 host configuration assertions (tests/assertions)
[givn-verify]   nixosConfiguration.{adlerkopf,cupix001,nixos-vm-minimal,thiniel}
[givn-verify]   darwinConfiguration.J6G6Y9JK7L
[givn-verify] 5/5 python test suite (scripts/)
256 passed in 7.23s
[givn-verify] OK                                                         # exit 0

$ ./scripts/givn-verify-e2e.sh
[givn-verify-e2e] system=x86_64-linux
[givn-verify-e2e] building: integration-adlerkopf integration-agent-tooling
  integration-github-fetch-credential integration-managed-file-displacement
  integration-private-data-separation integration-ssh-identity-selection
  integration-vm-minimal-ssh
[givn-verify-e2e] OK                                                     # exit 0
```
