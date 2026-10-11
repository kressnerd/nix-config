# Instruction: tasks

Write the implementation task breakdown as a strict scenario-by-scenario
RED→GREEN→REFACTOR→COMMIT loop. Every phase runs the scenario's **bound
target** — the native verification target named by its tag. The canonical
verification model is `docs/GIVN-VERIFICATION.md`; read it first. This
instruction does not restate it.

## Setup task (first task, always)

Before writing scenario tasks, read the owning `usecase.md`, its guarantees and
rules, the use-case context, and any ideation seed. Copy the relevant domain
constraints into every scenario task so implementation cannot lose use-case
context between artifacts.

A scenario's executable specification is its bound target
(`@check:`/`@host:`/`@deploy:` — see `docs/GIVN-VERIFICATION.md`). When a change
introduces a new target, wire it in before any RED:

- unit test → register it in `tests/unit/default.nix` and expose the check in
  `flake.nix`;
- assertion → add it to `tests/assertions/default.nix` (imported by the host
  config, fired on host evaluation);
- VM integration test → register it in `tests/integration/default.nix`.

Then prove the targeted RED run fails: run the scenario's bound target with the
targeted command from `docs/GIVN-VERIFICATION.md` ("Single-scenario (targeted)
run") and confirm it exits non-zero for the expected reason. Paste the command
and the non-zero output into the setup task. Do not proceed until it fails — a
target that already passes is not RED.

## Rule: prove the targeted RED run fails, with evidence

An already-passing target makes GREEN meaningless: it never demonstrated the
scenario was ever failing. Prove RED explicitly before relying on it:

1. Add or extend the bound target with the assertion the scenario describes
   (a `lib.debug.runTests` case, an assertion in the relevant
   `tests/assertions/*.nix`, a `runNixOSTest`, or a deploy test).
2. Run the targeted command (`docs/GIVN-VERIFICATION.md`, "Single-scenario
   (targeted) run") — never the whole suite, never inferred from whole-suite
   output.
3. Confirm the command exits non-zero for the expected reason.
4. Paste the command and the non-zero-exit output.

A target that exits 0 on its RED run is a hard stop: strengthen the assertion
until the scenario genuinely fails before continuing.

## TDD loop — non-@e2e scenarios (in .feature order)

```
For each scenario:
  RED:      Remove @wip from THIS scenario only. Add or extend the bound
              target so it asserts what the scenario describes. Run the
              targeted command for THIS scenario's binding (never the whole
              suite). PASTE the output. MUST exit non-zero for the expected
              reason. Exit 0 = the target already passed — hard stop, fix the
              target before continuing.
  GREEN:    Implement the configuration change — module option, service,
              firewall rule, secret wiring, host definition. Re-run the
              targeted command for THIS scenario. PASTE the output. MUST exit
              zero.
  REFACTOR: Restructure the module/option layout, no behaviour change.
              Re-run the targeted command. PASTE the output. MUST still exit
              zero.
  COMMIT:   One commit for RED+GREEN+REFACTOR, e.g.
              "feat(<capability>): <release note>". The message carries the
              release note as its message subject, and the scenario title goes
              in the message body. Run `givn commit` and record the hash. No
              commit, or a commit touching only the spec/target skeleton with
              no configuration change = task not done.
```

## Rule: dangerous areas need a warning and a rollback

A scenario that touches `boot.loader`, `networking`, `fileSystems`/disko,
`environment.persistence`/impermanence, or the kernel carries an explicit
operator warning and a rollback path in its task. Never change
`system.stateVersion`/`home.stateVersion`; `hardware.nix` is read-only. No
plaintext secrets — use sops-nix and never run `sops`.

## Rule: @e2e tags are immutable — never remove them

Once `@e2e` is placed on a delta scenario, it MUST NOT be removed. The
`verify-e2e` hook at review time and `givn lint --change <id>` both
independently detect tag removal by cross-referencing against tasks.md content.
If e2e is blocked by the builder, configure `verify.e2e_command` — never delete
the tag. Removing `@e2e` tags to bypass a gate is a procedure violation.

## TDD loop — @e2e scenarios (after all non-@e2e are GREEN)

Same loop, but the targeted command is `verify.e2e_command`
(`scripts/givn-verify-e2e.sh`), which builds the `integration-*` checks for the
current system. It requires a Linux builder with KVM; on a non-Linux host it
fails loudly rather than reporting a false pass — provision the builder instead
of weakening the target. Before writing or reviewing `@e2e` targets, read the
canonical policy in `docs/GIVN-VERIFICATION.md`. Commit message:
`test(e2e): <release note>` — the message carries the release note as its
message subject, and the scenario title goes in the message body.

## E2e setup task

Before the first `@e2e` scenario:

- Confirm `verify.e2e_command` (`scripts/givn-verify-e2e.sh`) is set and is not
  identical to `verify.command` (`scripts/givn-verify.sh`). If both are
  byte-identical, the "e2e run" is silently re-running the whole suite, not
  isolating `@e2e` scenarios — hard stop, fix before continuing. Prove the scope
  is real: from the `scripts/givn-spec-trace.py` summary, record the number of
  `@e2e` scenarios and the total scenario count; the e2e scope MUST be strictly
  smaller (unless literally every in-scope scenario is tagged `@e2e`, which must
  be stated explicitly). Paste both counts into this task.
- Wire the new `integration-*` target in `tests/integration/default.nix` and
  `flake.nix`, and confirm the Linux/KVM builder can actually boot a trivial
  `runNixOSTest` smoke target before writing any `@e2e` scenario.

## Rule: never silently deviate from design.md

Tasks execute what design.md decided — they do not re-decide it. If, while
implementing, the exact target, file layout, or command design.md names turns
out to be wrong, impractical, or an easier alternative appears (e.g. reusing one
check instead of the two design.md named, or pointing `verify.e2e_command` at
the same command as `verify.command` because configuring a real scope is
inconvenient), that is a design gap or a design.md error — not something tasks
may work around unilaterally:

1. STOP. Do not implement the deviation.
2. Update `design.md` to reflect the corrected decision, with the same rigor as
   the original section (name the exact target/command/file, not "TBD" or
   "similar to below").
3. Because `design.md` changed, `design-review` un-gates and must be re-run
   (and, if the change plausibly affects any arc42 chapter — most commonly
   ch.05/06/07/08 for a structural or infrastructure decision — the arc42
   addon's chapter table must be reassessed against the new design.md, not left
   stale).
4. Only after design-review re-passes does the task resume, now implementing
   what the corrected design.md says.

A tasks-phase shortcut that never touches design.md is not a faster path — it is
an unreviewed, unrecorded design decision made by the wrong artifact.
Reviewers (see review.md fabrication audit) diff actual implementation against
design.md's stated targets/files/commands specifically to catch this.

## Distinctions

- `givn lint`: static check, no tests.
- `verify.command`: confirms GREEN for non-@e2e — the spec traceability check
  plus the unit/lint check builds and every host configuration evaluation.
- `verify.e2e_command`: confirms GREEN for @e2e, scoped to the `integration-*`
  VM checks — never the same string as `verify.command`. See "Rule" above.

Never conflate the three.

## Tasks file format

- `[ ]`/`[x]` checkboxes. One section per scenario: RED/GREEN/REFACTOR/COMMIT.
- Each RED/GREEN/REFACTOR line has a field for pasted targeted-command output.
- Each scenario has a field for the commit hash.
- Non-@e2e scenarios first, @e2e last.
- Check `[x]` only when evidence and commit hash are filled in. Empty fields =
  incomplete.
- **tasks.md must always be up-to-date.** Check each scenario's box immediately
  after completing it — before starting the next scenario. An unchecked box
  means that scenario is not done. Never leave all boxes unchecked and
  batch-check them at the end. Using `sed` or any text-replacement tool to
  mass-check boxes without filling in evidence and commit hashes is prohibited.
- Done when: all boxes checked, every scenario has a commit, the targeted RED
  evidence shows a non-zero exit for every scenario, and both `verify.command`
  and `verify.e2e_command` exit 0 (the latter on a Linux/KVM builder).
