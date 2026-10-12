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
| `permitted-identity-selection` (all five scenarios) | Success guarantee: the owner resumes the specified usual work with its required context available and usable — here the identity condition. Rules: identity access is re-established through permitted means, not by cloning credentials; device/platform differences may be intentional; owner-authorized scope only, no employer/client-data authority follows from a profile reference. Extension 2b: a selected identity is re-established rather than exported. | `owner--operator` — the owner is the only actor who evaluates private-repository access on their own device. `family--application-user` unaffected: no hosted application, shared resource or access grant changes. |
| Scenario 3 (work laptop preserved) | Rule: device differences are intentional; the owner's usual work on the MacBook is not degraded by making thiniel usable. | `owner--operator` |
| Open prerequisite | `(open: Q16)` of the owning use case stays open for the remaining state/source inventory; this change closes it for thiniel's personal identity only (proposal D2). | — |

---

## Proof the targeted RED run fails (do first)

- [ ] **Wire the new target**: VM test registered in `tests/integration/default.nix` (and the flake passes the `home-manager-unstable` / `sops-nix` inputs to it); no new unit check and no new assertion module is introduced — the assertions go into the two existing `tests/assertions/*.nix` files already wired into their hosts.
- [ ] **Proof the targeted RED run fails**: see the per-scenario RED evidence below (the first is scenario 1's host evaluation).

---

## Tasks

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
  - [ ] COMMIT: `<hash>` — `<message>` (one `givn commit` for RED+GREEN+REFACTOR)

- [ ] Scenario: `The work laptop keeps its per-purpose identity selection` (`@host:J6G6Y9JK7L`)
  - [ ] RED: extend `tests/assertions/J6G6Y9JK7L-invariants.nix` so the MacBook must declare its personal identity file, its workspace identity configuration, its three work connection entries and its three includes; run the targeted command. Must fail for the expected reason.
        ```
        <!-- paste the targeted command + non-zero output -->
        ```
  - [ ] GREEN: declare the MacBook's identity file and include files in its host user module.
        Files created/modified: <!-- list them -->
        Re-run the targeted command. Must pass.
        ```
        <!-- paste GREEN evidence -->
        ```
  - [ ] REFACTOR: no behaviour change; re-run. Must still pass.
        ```
        <!-- paste REFACTOR evidence -->
        ```
  - [ ] COMMIT: `<hash>` — `<message>` (one `givn commit` for RED+GREEN+REFACTOR)

- [ ] Scenario: `The declared device identity reaches both connection and workspace configuration` (`@check:unit-helpers`)
  - [ ] RED: extend `tests/unit/hm-cli-modules-test.nix` (mocks declare the per-host identity) so the Linux mock must render the declared path in both the SSH connection and the workspace identity configuration; run the targeted command. Must fail for the expected reason.
        ```
        <!-- paste the targeted command + non-zero output -->
        ```
  - [ ] GREEN: render the workspace identity configuration's SSH command from the declared personal identity file.
        Files created/modified: <!-- list them -->
        Re-run the targeted command. Must pass.
        ```
        <!-- paste GREEN evidence -->
        ```
  - [ ] REFACTOR: no behaviour change; re-run. Must still pass.
        ```
        <!-- paste REFACTOR evidence -->
        ```
  - [ ] COMMIT: `<hash>` — `<message>` (one `givn commit` for RED+GREEN+REFACTOR)

---

## E2E Scenarios

- [ ] Confirm `verify.e2e_command` (`scripts/givn-verify-e2e.sh`) is set and is not identical to `verify.command` (`scripts/givn-verify.sh`); paste the trace summary with the `@e2e` scenario count vs the total (e2e must be the strict subset).
      ```
      <!-- paste both scope counts from scripts/givn-spec-trace.py -->
      ```
- [ ] Wire the new `integration-*` target and confirm the Linux/KVM builder boots a `runNixOSTest` target.
      ```
      <!-- paste builder boot confirmation -->
      ```

- [ ] @e2e Scenario: `The personal device reaches private repositories with the identity it holds` (`@e2e @host:thiniel`)
  - [ ] RED: extend `tests/assertions/thiniel-invariants.nix` so thiniel's private-repository connection and its workspace identity configuration must name `~/.ssh/id_ed25519`; run the targeted command. Must fail for the expected reason.
        ```
        <!-- paste the targeted command + non-zero output -->
        ```
  - [ ] GREEN: declare thiniel's personal identity file and take both surfaces from that declaration.
        Files created/modified: <!-- list them -->
        Re-run the targeted command. Must pass.
        ```
        <!-- paste GREEN evidence -->
        ```
  - [ ] REFACTOR: no behaviour change; re-run. Must still pass.
        ```
        <!-- paste REFACTOR evidence -->
        ```
  - [ ] COMMIT: `<hash>` — `<message>` (one `givn commit` for RED+GREEN+REFACTOR)

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
  - [ ] COMMIT: `<hash>` — `test(e2e): <message>` (one `givn commit`)

---

**Done when:** every box checked with targeted-command evidence and a commit
hash, the RED evidence shows a non-zero exit for every scenario, and both
`./scripts/givn-verify.sh` and `./scripts/givn-verify-e2e.sh` exit 0 (the latter
on this Linux/KVM host).
