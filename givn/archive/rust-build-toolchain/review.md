# Review — rust-build-toolchain

## Fabrication audit

0. **@e2e tag integrity.** One delta `.feature` file. Its single `@e2e`
   scenario still carries `@e2e` and binds to
   `@check:integration-rust-toolchain`; no tag was removed. The other two
   scenarios are `@host:thiniel`.
1. **Traceability.**
   ```
   $ python3 scripts/givn-spec-trace.py
   givn-spec-trace: 32 scenario(s) across 7 feature file(s), 0 finding(s)
   exit 0
   ```
   Each new scenario carries exactly one resolving binding; the `@e2e`
   scenario binds to an `integration-*` check. The run's only warnings are the
   pre-existing unreferenced `integration-adlerkopf` and
   `integration-vm-minimal-ssh` checks, unrelated to this change.
2. **Commit cross-check.** Three scenario commits, each touching real
   configuration or tests:
   | Task | Commit | Real files in the diff |
   |---|---|---|
   | 1 — packages | `0989915` | `home/dan/features/development/rust.nix`, `home/dan/thiniel.nix`, `tests/assertions/thiniel-hm-invariants.nix`, `tests/integration/rust-toolchain-test.nix`, `tests/integration/default.nix` |
   | 2 — persistence | `b41693d` | `home/dan/features/development/rust.nix`, `tests/assertions/thiniel-hm-invariants.nix` |
   | 3 — booted build and lint | `7265e32` | `home/dan/features/development/rust.nix` |
   The setup and final-verification checkboxes are evidence-only and fold into
   the three scenario commits; no task's diff is spec-only.
3. **Promised-target existence.** `home/dan/features/development/rust.nix`
   exists and is imported by `home/dan/thiniel.nix`;
   `tests/assertions/thiniel-hm-invariants.nix` exists and is imported by the
   same profile; `tests/integration/rust-toolchain-test.nix` exists and is
   registered in `tests/integration/default.nix`, which flake.nix aggregates
   into `checks.<linux-system>.integration-rust-toolchain` (the check
   evaluated and built in the targeted runs).
4. **RED evidence.** Every scenario has a pasted non-zero targeted run in
   `tasks.md`:
   - packages: the host evaluation failed with the four package assertion
     messages;
   - persistence: the host evaluation failed with the `.cargo` assertion;
   - booted build: the VM run failed with `error: no such command: clippy`
     (exit 101) after the build and run had passed.
   `verify.command` (`./scripts/givn-verify.sh`) and `verify.e2e_command`
   (`./scripts/givn-verify-e2e.sh`) are different strings.
5. **E2E reality.** The `@e2e` check boots a QEMU NixOS machine, runs the
   per-user Home Manager profile's `rustc`, `cargo`, `gcc` and `pkg-config`,
   creates a project, builds it, runs the produced binary and runs
   `cargo clippy`. It observes real command behaviour, not an evaluation.
6. **E2E isolation.** Trace reports 32 scenarios; the e2e scope counts 9, the
   regular scope 23 (strictly smaller). The e2e runner builds the
   `integration-*` checks only.
7. **Safety.** No secret or decryption command is added. `git diff` shows no
   change to `system.stateVersion`, `home.stateVersion`, or
   `hosts/*/hardware.nix`.
8. **Dangerous areas.** The change touches the user persistence list;
   `design.md` carries a Deployment & Rollback section with
   `sudo nixos-rebuild switch --rollback`, the corrected
   `/persist/home/dan/.cargo` path, and the apply-order note.
9. **Design conformance.** File layout, package set (host `pkgs`), persistence
   guard (`lib.optionalAttrs`), check name, and VM command match `design.md`
   as reviewed after the design-review fixes.
10. **Result:** 0 fabricated scenarios/targets found across 3 scenarios.

## Arc42 implementation conformance

| Arc42 chapter or fact | Durable-doc source | `arc42.md` claim | `design.md` | `tasks.md` | Implementation evidence | Match? |
|---|---|---|---|---|---|---|
| thiniel import count | 02:42 | Affected | N/A (count) | Task 1 | `home/dan/thiniel.nix` imports `rust.nix`; count 42 | Yes |
| feature-module count and Rust Level-3 entry | 05:19, 05:49, 05:160-169 | Affected | Architecture Impact | Task 1 | 60 feature modules; `rust.nix` exists with the described elements | Yes |
| integration-test inventory | 05:178 | Affected | Test Targets | Task 3 | `integration-rust-toolchain` registered and built | Yes |
| thiniel Rust property row | 07:116 | Affected | Technology Decisions | Tasks 1–3 | packages and `.cargo` in the module | Yes |
| persisted Cargo bin risk | 11 R-030 | Affected | Blast Radius | Tasks 1–2 | `$HOME/.cargo/bin` on `sessionPath`; `.cargo` persisted | Yes |
| Rust toolchain glossary term and check inventory | 12:12, 12:47 | Affected | arc42 chapter impact | Tasks 1–3 | module and check names match | Yes |

Chapters marked "No" in `arc42.md` were re-derived from the implementation and
remain non-affected: no goal, constraint, context, solution strategy, runtime
flow, cross-cutting concept, ADR, quality goal or technical-debt change beyond
R-030.

`ARC42 CONFORMANCE: CLEAN`

## Coverage

No instrumented coverage (`addons.coverage` is disabled). The traceability run
above resolves every scenario to an existing target. The two trace warnings
(`integration-adlerkopf`, `integration-vm-minimal-ssh`) are pre-existing and
unrelated to this change.

## Classification

- Dead config: none — every file, assertion and check added by this change is
  reachable from the host profile or the flake check.
- Missing test coverage: none — each scenario has a bound target that failed
  before implementation and passes after.
- Legitimately hard to test: none. The persistence claim is verified as a
  declaration, matching the repository's existing persistence assertions; the
  booted behaviour the scenario promises (build, run, lint) is verified by the
  VM check.

## Deferrals

None. Neither mandatory runner is deferred.

## Use-case and Persona conformance

Owning contract: `reproduce-working-environment`, carried with the new
capability `rust-build-toolchain`, its toolchain rule, its interaction row (a
device builds a Rust project) and an out-of-scope bullet for project-specific
pins and other devices. The use-case delta's base hash matches the permanent
file (`2ffa4aa…`). Goal, guarantees, actors and typed relationships are
preserved.

`owner--operator` (confirmed 2026-10-11) is the operator who builds Rust
projects on the laptop. `family--application-user` is unaffected: no hosted
application, shared resource or access path changes. No Persona was invented or
promoted.

## Overlap dispositions

None — the change adds no overlapping scenario pair.

## Split-or-keep

None — no added scenario exceeds the gate threshold; the three scenarios each
state one observable outcome.

## Sign-off

- [x] Fabrication audit clean.
- [x] Traceability exits 0; one binding per scenario; `@e2e` bound to an integration check.
- [x] Every checked task has a verified commit touching real configuration.
- [x] Every promised module/assertion/check exists and is wired.
- [x] Targeted RED evidence present for every scenario.
- [x] `@e2e` scenario boots a real VM and asserts real command behaviour; no tag removed.
- [x] `verify.e2e_command` differs from `verify.command`; e2e scope 9 of 32.
- [x] No secret, no `stateVersion` change, no `hardware.nix` change.
- [x] Dangerous-area Deployment & Rollback section present.
- [x] Implementation matches the reviewed design.

README-IMPACT: none. The `readme` addon is disabled (`readme: false`), and the
change adds no command, flag or configuration key a README reader would use; the
behaviour is documented in the arc42 set and the glossary.

REVIEW: PASS
