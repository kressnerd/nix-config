# Tasks: {{CHANGE_ID}}

RED→GREEN→REFACTOR→COMMIT per scenario. Non-@e2e first, then @e2e. Every phase
runs the scenario's bound target (its `@check:`/`@host:`/`@deploy:` tag) with
the targeted command from `docs/GIVN-VERIFICATION.md` — never the whole suite.

Legend: `[ ]` pending · `[x]` done only when evidence + commit hash are filled in. Check boxes immediately after each scenario — tasks.md must always reflect true state.

---

## Proof the targeted RED run fails (do first)

An already-passing target makes GREEN meaningless: it never demonstrated the
scenario was ever failing. Wire the target, then prove the targeted RED run
exits non-zero for the expected reason before any scenario work.

- [ ] **Wire the new target** (only when the change adds one): unit →
      `tests/unit/default.nix` + `flake.nix`; assertion →
      `tests/assertions/default.nix`; VM test → `tests/integration/default.nix`.
- [ ] **Proof the targeted RED run fails**: run the targeted command for the
      first scenario's binding. Confirm non-zero exit for the expected reason.
      ```
      <!-- paste the targeted command + non-zero output -->
      ```
      If it exits 0, the target already passes — strengthen it before proceeding.

---

## Tasks

## Domain Constraints

> Copy the owning use-case guarantees, rules, capability ownership, and
> relevant ideation decisions here before listing scenario tasks. Personas are
> recorded only when the use-case context confirms one (an infra change usually
> records `none` with a reason).

| Scenario / capability | Use-case guarantee or rule | Persona impact |
|---|---|---|
| | | |

- [ ] Scenario: `{{FIRST_SCENARIO_TITLE}}`
  - [ ] RED: add or extend the bound target so it asserts what this scenario
        describes; run the targeted command for this scenario's binding
        (`docs/GIVN-VERIFICATION.md`). Must fail for the expected reason.
        ```
        <!-- paste the targeted command + non-zero output -->
        ```
  - [ ] GREEN: implement the configuration change (module option, service,
        firewall rule, secret wiring, host definition).
        Files created/modified: <!-- list them -->
        Re-run the targeted command. Must pass.
        ```
        <!-- paste GREEN evidence -->
        ```
  - [ ] REFACTOR: restructure the module/option layout, no behaviour change.
        Re-run the targeted command. Must still pass.
        ```
        <!-- paste REFACTOR evidence -->
        ```
  - [ ] COMMIT: `<hash>` — `<message>` (one `givn commit` for RED+GREEN+REFACTOR)

<!-- One section per non-@e2e scenario. -->

---

## E2E Scenarios

- [ ] Confirm `verify.e2e_command` (`scripts/givn-verify-e2e.sh`) is set and is
      not identical to `verify.command` (`scripts/givn-verify.sh`); it builds the
      `integration-*` scope only. Paste the trace summary with the `@e2e`
      scenario count vs the total (e2e must be the strict subset).
      ```
      <!-- paste both scope counts from scripts/givn-spec-trace.py -->
      ```
- [ ] Wire the new `integration-*` target in `tests/integration/default.nix` and
      `flake.nix`, and confirm the Linux/KVM builder boots a trivial
      `runNixOSTest` smoke target.
      ```
      <!-- paste builder boot confirmation -->
      ```
- [ ] @e2e Scenario: `{{SCENARIO_TITLE}}`
  - [ ] RED: point the bound `integration-*`/host/deploy target at the described
        state; run `verify.e2e_command` for this scenario's target. Must fail for
        the expected reason.
        ```
        <!-- paste the targeted command + non-zero output -->
        ```
  - [ ] GREEN: implement the configuration so the booted system reaches the
        described observable state.
        Files: <!-- list them -->
        Re-run the targeted e2e command. Must pass.
        ```
        <!-- paste GREEN evidence -->
        ```
  - [ ] REFACTOR: restructure, no behaviour change. Re-run. Must still pass.
        ```
        <!-- paste REFACTOR evidence -->
        ```
  - [ ] COMMIT: `<hash>` — `test(e2e): <message>` (one `givn commit`)

<!-- One section per @e2e scenario. -->

---

**Done when:** every box checked with targeted-command evidence and a commit
hash, the RED evidence shows a non-zero exit for every scenario, and both
`{{VERIFY_COMMAND}}` and `verify.e2e_command` exit 0 (the latter on a Linux/KVM
builder).
