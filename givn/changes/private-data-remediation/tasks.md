# Tasks: private-data-remediation

RED→GREEN→REFACTOR→COMMIT per scenario. Non-@e2e first, then @e2e. Every phase
runs the scenario's bound target (its `@check:`/`@host:`/`@deploy:` tag) with the
targeted command from `docs/GIVN-VERIFICATION.md` — never the whole suite.

Legend: an unticked box is pending; a ticked box counts as done only when evidence and the commit hash are filled in. Check each scenario's box immediately after completing it — tasks.md must always reflect true state.

---

## Domain Constraints

Owning use case: `publish-infrastructure-configuration` (introduced by this
change; `specs/publish-infrastructure-configuration/usecase.md`). Capability:
`operational-data-separation`. Ideation topic: none. Personas: `owner--operator`
(confirmed, relevant — the operator publishes the repository and deploys the
hosts); `family--application-user` (confirmed, unaffected — no hosted
application, access path or shared resource changes).

| Scenario / capability | Use-case guarantee or rule | Persona impact |
|---|---|---|
| Scenario 1 (`@host:adlerkopf`) | Rule: "The host network defaults are documentation-range placeholders or empty values." Extension 1: a missing private value fails loudly. | `owner--operator` |
| Scenarios 2–4 (`@check:private-data-hygiene`) | Rule: "Operational values never live in the public repository"; rule: "A revision that would record an operational value, a per-host private-value file, or an unencrypted secret is refused"; rule: "A secret is encrypted before it is recorded." | `owner--operator` |
| Scenario 5 (`@e2e @check:integration-private-data-separation`) | Success guarantee: every host builds and deploys with the values held outside the repository. | `owner--operator` |
| Carried open inputs | The history rewrite (D2, operator-executed); the pre-commit/CI wiring (operator-owned process control); `cupix001`'s out-of-band console path before its first deploy. | — |

---

## Prerequisites (not scenarios — ordering safety)

The private-input migration MUST land before the untracking, or every host build
breaks (the `git+file://` source rule; `design.md` "Overview").

- [ ] **P1 — Private repository.** Create `~/dev/PRIVATE/nix-private` as its own
      git repository with `nixosModules.adlerkopf` and `nixosModules.cupix001`
      holding the real values (read from the current `hosts/*/private.nix`
      contents in git history / `stash@{0}`, written only outside this
      repository). `git init`, commit. No remote.
- [ ] **P2 — Public stub.** Create `private-stub/flake.nix` exporting
      `nixosModules.adlerkopf` and `nixosModules.cupix001`, each asserting the
      host's declared network values are documentation-range placeholders or
      empty (`design.md` "Technology Decisions").
- [ ] **P3 — Flake wiring.** `flake.nix`: add `inputs.private.url =
      "path:./private-stub"`; add `inputs.private.nixosModules.adlerkopf` /
      `.cupix001` to the matching `nixosConfigurations` `modules` lists.
- [ ] **P4 — Remove the local imports.** `hosts/adlerkopf/default.nix` and
      `hosts/cupix001/default.nix`: remove `./private.nix` from `imports`.
- [ ] **P5 — Prove the tree still evaluates.** `nix flake check` with the stub
      (no override) MUST pass, and for each host
      `nixos-rebuild build --flake .#<host> --override-input private git+file:///home/dan/dev/PRIVATE/nix-private`
      MUST produce the same store path as before the migration.
      Evidence:
      ```
      $ nix flake check
      <paste>
      $ nixos-rebuild build --flake .#adlerkopf --override-input private git+file:///home/dan/dev/PRIVATE/nix-private
      <paste>
      ```

---

## Proof the targeted RED run fails (do first)

- [ ] **Wire the new targets before any RED.** `flake.nix`: add
      `checks.private-data-defaults` and `checks.private-data-hygiene` (all
      systems). `tests/integration/default.nix` and `flake.nix`: add
      `integration-private-data-separation`. Register nothing new in
      `tests/unit/default.nix` (no unit target in this change) and no new
      assertion module (the placeholder rule lives in the stub).
- [ ] **Proof the targeted RED run fails.** The three
      `@check:private-data-hygiene` scenarios share one target, so their RED is
      one run; `design.md` records the aggregation as an accepted limitation.
      Record each scenario's RED evidence inside its own section below as it is
      produced. `scripts/givn-spec-trace.py` exits 1 with five findings until
      the three checks resolve — that is the pre-implementation state, not the
      RED evidence. **Mask operational values in pasted evidence** (replace an
      address with `<LAN>` and the like): the tasks file is recorded content and
      the guard refuses operational values.

---

## Tasks

- [ ] Scenario: `A host declares placeholders when no private source supplies its values` (`@check:private-data-defaults`)
  - [ ] RED: `hosts/adlerkopf/options.nix` still carried the real LAN values, so
        the stub assertion failed the host evaluation. The bound target was
        subsequently rebound to the check (the canonical `@host:adlerkopf`
        command cannot exit 0 — R-017), so the observed RED is the assertion:
        ```
        $ nix eval --raw .#nixosConfigurations.adlerkopf.config.system.build.toplevel.drvPath
        error:
               Failed assertions:
               - private-stub: networking.adlerkopf.lanIPv4 must be a documentation-range placeholder (192.0.2.0/24) or empty when no private source supplies values, got '<LAN>'
               - private-stub: networking.adlerkopf.gateway4 must be a documentation-range placeholder (192.0.2.0/24) or empty when no private source supplies values, got '<GW>'
               - private-stub: networking.adlerkopf.wgSubnet must be the generic placeholder 10.0.0.0/24 or empty when no private source supplies values, got '<WG>'
               - private-stub: networking.adlerkopf.wgServerIPv4 must be the generic placeholder 10.0.0.1 or empty when no private source supplies values, got '<WG1>'
        exit 1
        ```
        After the rebinding, the check's own RED run reports the same four
        option names (values masked).
  - [ ] REFACTOR: the module layout was not restructured.
  - [ ] GREEN: replaced the `networking.adlerkopf.*` defaults in
        `hosts/adlerkopf/options.nix` with RFC 5737 / generic RFC 1918
        placeholders; the stub assertion no longer fires and the check passes.
        Re-run:
        ```
        $ nix build --no-link .#checks.x86_64-linux.private-data-defaults
        building '/nix/store/0x0b2apnpg369vrzfijk6p9d0dg5d2p9-private-data-defaults.drv'...
        exit 0
        $ nix flake check --no-build --no-write-lock-file
        all checks passed!
        exit 0
        ```
  - [ ] COMMIT: `givn commit -m "feat(operational-data-separation): <release note>"` with the scenario title in the body. Hash: `<paste>`

- [ ] Scenario: `The repository records no operational value` (`@check:private-data-hygiene`)
  - [ ] RED: the check runs the guard over the recorded tree; the tree still
        carries the operational literals (`design.md` "Document sanitization")
        and the two `hosts/*/private.nix` files are in the index.
        Targeted run:
        ```
        $ python3 scripts/private_data_hygiene.py <recorded-file-list>
        [private-data-hygiene] docs/ADLERKOPF-DEPLOY-RUNBOOK.md:123: home-LAN subnet is recorded
        [private-data-hygiene] docs/edge-all.md:79: WireGuard subnet is recorded
        [private-data-hygiene] hosts/adlerkopf/private.nix: per-host private-value file is recorded
        [private-data-hygiene] hosts/cupix001/private.nix: per-host private-value file is recorded
        [private-data-hygiene] hosts/cupix001/private.nix.example:41: WireGuard subnet is recorded
        ... (131 findings across 25 files; every value masked as its class label)
        [private-data-hygiene] 131 finding(s)
        exit 1
        ```
        The check itself was absent at that point, so its own RED run was the
        unresolved binding (`givn-spec-trace.py` finding).
  - [ ] GREEN: sanitize every listed document (`design.md` "Document
        sanitization"; re-run `git grep` per class until every hit is replaced or
        shown non-operational); untrack the two private-value files
        (`git rm --cached hosts/adlerkopf/private.nix hosts/cupix001/private.nix`);
        add `docs/plans/private-data-remediation-plan.md` to `.gitignore`;
        remove the obsolete `hosts/*/private.nix.example` files. Re-run the
        targeted command; MUST exit 0.
        ```
        $ python3 scripts/private_data_hygiene.py <recorded-file-list>
        [private-data-hygiene] no operational value, private-value file or plaintext secret recorded
        exit 0
        $ nix build --no-link .#checks.x86_64-linux.private-data-hygiene
        /nix/store/vz2bc57x473ldacd5fwy3xna9jv4c7fp-private-data-hygiene
        exit 0
        ```
  - [ ] REFACTOR: none expected.
  - [ ] COMMIT: `givn commit -m "chore(operational-data-separation): <release note>"`. Hash: `<paste>`

- [ ] Scenario: `The hygiene rule rejects recorded content that contains an operational value` (`@check:private-data-hygiene`)
  - [ ] RED: the check's value fixture (an in-class address that is not any
        literal currently in the tree) must be rejected; the guard's value rule
        is absent, so the fixture is accepted and the check fails. Record the
        run:
        ```
        $ python3 scripts/private_data_hygiene.py --tree /tmp/pdh/value
        [private-data-hygiene] /tmp/pdh/value/x.nix:1: home-LAN subnet is recorded
        [private-data-hygiene] 1 finding(s)
        exit 1
        ```
        (before the rule existed, the same fixture exited 0). The check was
        absent, so its own RED run was the unresolved binding.
  - [ ] GREEN: the value rule rejects the fixture (an in-class address that is
        not any literal in the tree) and the check accepts it as rejected.
        ```
        $ nix build --no-link .#checks.x86_64-linux.private-data-hygiene
        exit 0
        ```
  - [ ] REFACTOR: none expected.
  - [ ] COMMIT: `givn commit -m "feat(operational-data-separation): <release note>"`. Hash: `<paste>`

- [ ] Scenario: `The hygiene rule rejects a recorded per-host private-value file or unencrypted secret` (`@check:private-data-hygiene`)
  - [ ] RED: the check's file and secret fixtures must be rejected; the file
        rule and the SOPS-metadata secret rule are absent, so both are accepted
        and the check fails. Record the run:
        ```
        $ python3 scripts/private_data_hygiene.py --tree /tmp/pdh/file
        [private-data-hygiene] /tmp/pdh/file/private.nix: per-host private-value file is recorded
        exit 1
        $ python3 scripts/private_data_hygiene.py --tree /tmp/pdh/secret
        [private-data-hygiene] /tmp/pdh/secret/secrets.yaml: secret file has no SOPS metadata block
        exit 1
        ```
        The check was absent, so its own RED run was the unresolved binding.
  - [ ] GREEN: the file rule (a recorded `hosts/*/private.nix`/`private.md`, and
        a `./private.nix` entry in a host `imports` list) and the secret rule (a
        `secrets.y[a]ml` without SOPS metadata and ciphertext values) both
        reject their fixtures and the check accepts them as rejected.
        ```
        $ nix build --no-link .#checks.x86_64-linux.private-data-hygiene
        exit 0
        ```
  - [ ] REFACTOR: none expected.
  - [ ] COMMIT: `givn commit -m "feat(operational-data-separation): <release note>"`. Hash: `<paste>`

### E2E setup task (before the first @e2e scenario)

- [ ] **E2E scope is real.** `verify.e2e_command`
      (`scripts/givn-verify-e2e.sh`) is set and is not byte-identical to
      `verify.command`. From the trace summary, the `@e2e` count is strictly
      smaller than the total scenario count. Record both counts:
      ```
      givn-spec-trace: 9 scenario(s) across 2 feature file(s), 0 finding(s)
      @e2e scenarios: 1 of 9 total (strictly smaller)
      verify.command  = ./scripts/givn-verify.sh
      verify.e2e_command = ./scripts/givn-verify-e2e.sh  (not identical)
      ```
- [ ] **KVM builder boots a trivial VM.** Confirmed: the builder boots
      `runNixOSTest` machines (the sibling `integration-*` checks and this
      change's new check both built and booted).
      ```
      $ nix build --no-link .#checks.x86_64-linux.integration-private-data-separation
      exit 0
      ```

- [ ] Scenario: `A host booted with values supplied from outside the repository uses those values` (`@e2e @check:integration-private-data-separation`)
  - [ ] RED: the VM check did not exist, so the binding did not resolve
        (`givn-spec-trace.py` finding). Recorded:
        ```
        [FAIL] ...:40: scenario 'A host booted with values supplied from outside the repository uses those values' binds @check:integration-private-data-separation, which is not a check in the flake
        ```
  - [ ] GREEN: add `tests/integration/private-data-separation-test.nix` — a
        `pkgs.testers.runNixOSTest` that imports the host's option module plus a
        test module supplying known values, boots, and asserts the interface
        carries the supplied address. Re-run; MUST exit 0.
        ```
        $ nix build --no-link .#checks.x86_64-linux.integration-private-data-separation
        building '/nix/store/8iibg23wp0q47hr9wcw1ncfihy77da6p-vm-test-run-private-data-separation.drv'...
        exit 0
        ```
        The booted machine's interface carries `198.51.100.10` (the supplied
        value) and not `192.0.2.10` (the public placeholder).
  - [ ] REFACTOR: none expected.
  - [ ] COMMIT: `givn commit -m "test(e2e): <release note>"`. Hash: `<paste>`

---

## Post-change tasks (not scenarios)

- [ ] **Prevention wiring (operator-owned process control).**
      `.pre-commit-config.yaml` (gitleaks + the guard on staged paths) and
      `.github/workflows/secret-scan.yml` (`nix flake check` + gitleaks);
      `gitleaks` added to `shell.nix`. Not verifiable by a native target
      (`design.md` "Verification Binding").
- [ ] **Rebuild aliases with the preflight.** `home/dan/adlerkopf.nix` and
      `home/dan/cupix001.nix`: a rebuild alias that runs the forgotten-override
      preflight and then deploys with `--override-input` (`design.md`
      "Deployment & Rollback").
- [ ] **Documentation.** `README.md` host-addition sequence;
      `.roo/rules/11-repository-conventions.md`; remove the `Intended` markers in
      `docs/arc42/{05,06,08,12}.md` once the targets land.
- [ ] **Remove the @wip tags** from every scenario once its target passes, and
      run `givn lint --change private-data-remediation`.
- [ ] **History rewrite (D2, operator-executed).** The operator runs the
      procedure in `docs/plans/private-data-remediation-plan.md` §9.1 from a
      fresh clone after a mirror backup, then confirms the published history
      records no operational value. This change's tasks end here.
- [ ] **Operational responses (out of scope).** New address from the provider,
      provider token rotation, host-key regeneration, SSH-port move — actions on
      live providers and hosts, tracked separately.
