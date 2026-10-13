# Design Review: managed-file-displacement

## Process

- **Phase 1 grilling**: fresh-context subagent `GrillDisplacement` (task tool,
  agent `reviewer`, read-only, 8m02s) walked ten branches against the plan and the
  tree, reading Home Manager's own linking machinery in the store
  (`modules/files/check-link-targets.sh`, `modules/files.nix`,
  `nixos/default.nix`).
- **Question handling**: the grilling raised one question that needed the
  operator — which displacement mechanism to use — plus procedural ones that the
  codebase settled. The mechanism question was put to the operator (two rounds:
  the first asked extension vs manual; the review then found the extension covers
  only the first conflict per path, so a second round asked extension-only vs
  extension+overwrite vs a numbered rename). The operator chose the numbered
  rename; recorded as proposal D1 with both rejected alternatives.
- **Deferrals**: none. Both runners are configured and distinct.
- **Phase 2 hardening**: below.

## Branch walk

| # | Branch | Outcome |
|---|---|---|
| 1 | Option exists where the plan puts it | Clean: `home-manager.backupCommand`/`backupFileExtension` resolve on all five Home Manager configurations (`null or string`, default `null`); all four NixOS hosts import the shared module and the HM NixOS module, the darwin host imports the HM darwin module. |
| 2 | Fixture mechanism | Mechanism sound (`system.activationScripts` runs before systemd, so before the HM unit) but two defects: a false self-checking rationale (F4) and a missing `deps`/ownership (F5). |
| 3 | Passing the declared value from the flake | Clean: the checks block already reads `self.nixosConfigurations…config…` (`private-data-defaults`) and passes several arguments through the aggregator. |
| 4 | Testability / RED | One high finding (F1: the extension covers only the first conflict per path), one medium (F3: the planned handling of a `null` declaration could turn RED into an evaluation error), one low (F6: the new guest lacks the release-pairing assertion). |
| 5 | Scope | Clean: three scenarios, each with exactly one binding; the proposal's outcomes map onto them. |
| 6 | Verification bindings | Clean apart from the expected pre-implementation finding (the new check does not exist yet). |
| 7 | Use case and Persona | Clean on ownership and the base-hash stamp; one low wording defect (F7: the interaction row named the Persona instead of the role). |
| 8 | Risk | F1 is the top risk: the mechanism as designed would not survive the device's real, repeated rewrites. |
| 9 | ADR qualification | Clean: enabling a Home Manager option fails the gate (durable consequence, lower-level artifact) → change design + chapter 2; R-025 is free. |
| 10 | arc42 | One medium finding (F2: chapters 01, 03?, 06, 09 missing from the design's list; 05/12 need the new check named). |

## Grilling findings and dispositions

| # | Severity | Finding | Disposition |
|---|---|---|---|
| F1 | high | `home-manager.backupFileExtension` alone displaces a conflicting file **once per path**; on the second conflict the activation aborts with `Existing file '<file>.<suffix>' would be clobbered by backing up '<file>'`, which is the normal case for the browser that triggered the change. | **Fixed by the operator's decision (proposal D1).** The mechanism is now `home-manager.backupCommand` running a script that renames to the first free `<name>.<n>`: every rewrite is displaced and nothing is deleted. The design records the rejected alternatives with the source evidence. |
| F2 | medium | The design's arc42 chapter list was incomplete (01, 06, 09 missing; 05/12 need the new check named). | **Fixed**: the list is 01, 02, 05, 06, 07, 08, 09, 10, 11, 12, and the chapters themselves are updated with the change. |
| F3 | medium | The plan did not say how a `null` declaration is handled; interpolating it into the expected path would fail at evaluation, and any "fallback" value fed into the option would break RED. | **Fixed**: the fixture passes the declared value through untouched and builds the expected names (`.1`, `.2`) independently — no interpolation of the option, no fallback. Recorded in the design's Assertion mechanics. |
| F4 | medium | The design claimed the seed's ordering is self-checking via `wait_for_unit`; a late seed would produce a false GREEN, not a loud failure. | **Fixed**: the rationale now rests on stage-2 activation running before systemd, and the assertion side checks the displaced contents as well as the service state. |
| F5 | low | The seed needs `deps = [ "users" ]` and file ownership, or it can run before `/home/test` exists and fail for the wrong reason. | **Fixed**: the design's fixture shape carries `deps` and `install -o test -g users`. |
| F6 | low | The new Home-Manager-based guest lacked the release-pairing assertion the two sibling checks carry. | **Fixed**: the fixture carries the same node assertion (keeps R-023's mitigation and QS-015 intact). |
| F7 | low | The new interaction row named the Persona where its siblings name the interaction role. | **Fixed**: the row now reads `a device applies its configuration`. |
| F8 | low | The proposal's Capability Routing evidence did not reproduce. | **Fixed**: the proposal records the current `givn spec route` output (`no signal — the top candidates tie at 15.00`) and marks the earlier `EXTEND … 13.00` figure as historical; the decision to deviate stands on the contracts. |
| F9–F13 | info | Clean branches (option availability, fixture mechanism soundness in principle, flake wiring, binding rules, use-case ownership/base hash, ADR routing, R-025 being free). | No action. |

## Hardening applied

| Finding | Change | Where |
|---|---|---|
| F1 | Mechanism replaced by `home-manager.backupCommand` + `mkManagedFileDisplacement` (`lib/helpers.nix`); promise, rule, interaction row and scenario wording aligned; D1 rewritten with the rejected mechanisms | `proposal.md`, `specs/…/usecase.md`, `design.md`, `tasks.md` |
| F2 | Chapter list corrected; chapters updated | `design.md`, `docs/arc42/*` |
| F3–F6 | Fixture contract fixed (declared value passed through, expected names independent, seed `deps`/ownership, pairing assertion) | `design.md`, `tasks.md` |
| F7 | Interaction row reworded | `specs/…/usecase.md` |
| F8 | Route evidence corrected | `proposal.md` |

Post-hardening checks: `givn lint --change managed-file-displacement` → the three
expected `@wip` findings plus one shape advisory on the two host scenarios
(merging them would drop a binding, so the advisory is benign);
`python3 scripts/givn-spec-trace.py` → one finding, the not-yet-existing
`@check:integration-managed-file-displacement` that the implementation creates.

DESIGN-REVIEW: PASS
