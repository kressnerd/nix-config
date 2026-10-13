# Design Review: quiet-configuration-evaluation

## Process

- **Phase 1 grilling**: fresh-context subagent `GrillPlan` (task tool, agent
  `reviewer`, read-only, 17m24s), briefed with the proposal, spec delta, design
  and arc42 assessment, and instructed to walk every required branch against the
  real tree and to verify the three riskiest mechanisms empirically. Its full
  report is the task result for `GrillPlan`.
- **Phase 1 evidence added by the presenting agent**: the throwaway evaluation
  probes V1–V4 below (written, evaluated, reverted; tree clean at `a355e92`), and
  the runner/trace runs V5–V6.
- **Question handling**: the grilling report raised six questions. Each was
  answerable from the repository, the approved proposal or the design's own
  carried decision, so none was put to the operator — the record below states
  the answer and its source for each (the dialog policy's rule "if a question
  can be answered by exploring the existing codebase, explore it and record the
  finding — do not burden the user with it").
- **Deferrals**: none. `verify.command` (`./scripts/givn-verify.sh`) and
  `verify.e2e_command` (`./scripts/givn-verify-e2e.sh`) are configured and
  distinct; no mandatory check is deferred; no `@e2e` tag was removed.
- **Phase 2 hardening**: applied to `design.md`, `arc42.md` and the arc42
  chapters; recorded below.

## Branch walk

| # | Branch | Outcome |
|---|---|---|
| 1 | Scope (spec vs proposal) | Clean except one promised outcome with no target (G8). No scenario beyond the promise; the end state is observable and names the host. |
| 2 | Tech choices | Option paths and enum values confirmed real; one wiring defect (G1); one unrecorded alternative (G9). |
| 3 | Missing scenarios | G8; the "no diagnostic" claims are observed through cause-assertions rather than stderr capture, which the repository's binding model allows and which V1/V5 prove do fire. |
| 4 | Testability / RED | Mechanisms verified (V1–V4); one trap (G2). |
| 5 | Verification-binding completeness | No issue: one binding tag per scenario; the only unresolved binding is the check the implementation adds; `@e2e` scenarios bind to `integration-*`; the two runners differ. |
| 6 | Deployment & rollback | Present, but the rollback wording was inaccurate (G10). |
| 7 | Risk | The most likely failure was G1 (an uncaught Mac regression); G1 and G2 also threatened the RED/GREEN loop. Both are fixed. |
| 8 | Decision ledger | No issue: D1–D4 resolved; the rejected alternatives are restated in the design (D4's in the proposal). |
| 9 | Use-case & Persona | No issue: `publish-infrastructure-configuration` owns the new capability; only `owner--operator` (confirmed 2026-10-11) is recorded; no invented Persona, no biography as actor. |
| 10 | arc42 | The 12-row chapter set matched the reviewer's independent derivation, but two rows marked "No" carried stale text (G3, G4) plus two minor stalenesses (G6, G7). All 12 chapter files exist with real content; no ASCII-art diagrams. Chapter 09 holds the NOT_QUALIFIED verdict; chapter 11 holds R-023/R-024/TD-015/TD-010. |
| 11 | Ubiquitous language | Consistent; `Superseded default` recorded in the glossary (G6 covers the stale `Check` enumeration). |
| 12 | ADR qualification | No issue: the candidate is NOT_QUALIFIED with a credible route to chapter 2 + the design; D3 also fails the gate and stays in the design. |

## Grilling findings and dispositions

| # | Severity | Finding | Disposition |
|---|---|---|---|
| G1 | P1 | The browser profile path was set in the shared browser feature, which the work MacBook imports; unguarded it would have moved the Mac's Firefox profile, contradicting the proposal's Out-of-Scope promise and going uncaught. | **Fixed by design change.** The setting is guarded to `pkgs.stdenv.hostPlatform.isLinux` (Technology Decisions, Architecture Impact, Blast Radius), and the MacBook's platform-default path is pinned by a new assertion in `tests/assertions/J6G6Y9JK7L-invariants.nix`. |
| G2 | P2 | The planned persistence assertion (string membership in `home.persistence."<root>".directories`) can never turn GREEN: the list elements are attribute sets, and deepening the read throws the impermanence module's removed-`method` error. | **Fixed by a stronger observable.** The assertion reads the persistence layer's *effect*: `config.systemd.mounts` targets — `/home/dan/.config/mozilla` present, `/home/dan/.mozilla` absent (V2, V3). The agent's suggested `.directory` variant works only shallowly and couples the assertion to the persistence module's internals; rejected for that reason. |
| G3 | P2 | `arc42.md` marked chapter 6 "No", but chapter 6 still described the hive as a live, node-less alternative. | **Fixed.** Chapter 6's note updated; row 6 is now "Yes" with the reason. |
| G4 | P2 | `arc42.md` marked chapter 3 "No", but chapter 3 enumerated the `colmena` input and described the fleet path. | **Fixed.** Chapter 3's input list, diagram and fleet row updated; row 3 is now "Yes" with the reason. |
| G5 | P3 | The design claimed the assertion predicate "is the release's own condition" for both settings; for the compositor the release uses the direct (non-deferred) form. | **Fixed.** The mechanics text now states the compositor predicate is the equivalent `optionUsesDefaultPriority` condition computed by the same helper in deferred mode, sealed by the V1 probe. |
| G6 | P3 | The glossary's `Check` enumeration omitted the new `flake-output-contract`. | **Fixed.** The enumeration names it and attributes it to this change. |
| G7 | P3 | Chapter 5's assertion-module count and description predate the new Home-Manager-level module. | **Fixed.** Chapter 5 now records 18 modules, distinguishing the 17 aggregated NixOS-level modules from the home-profile-level one. |
| G8 | P3 | The promised survival of the fleet CLI and the operator's aliases had no target. | **Fixed as guards.** `thiniel-hm-invariants.nix` also asserts the Colmena package is installed and the five aliases exist. These are guards, not scenario targets: they hold before and after the change, and a scenario whose bound target already passes cannot be RED under this repository's verification model, so they are recorded as guards in the design instead of inflating the spec. |
| G9 | P3 | D3's option space omitted "load the release `home-manager` in the two fixtures". | **Fixed.** Recorded as a considered-and-rejected alternative with the mirroring reason. |
| G10 | P3 | The rollback section listed a separate Home-Manager generation step (none exists on this host) and did not gate the destructive delete on a rollback test. | **Fixed.** Rollback now states that the system-generation rollback covers the home profile, and the `/persist/.mozilla` delete is gated on a confirmed relocation *and* a exercised rollback. |

## Questions and how each was answered

| Question | Answer and source |
|---|---|
| Q1 — guard the shared browser path, or move it to a Linux-only module? | Answered from the plan: the approved proposal's Out-of-Scope section says the MacBook's paths stay untouched, so an unguarded setting is out of scope by definition. The mechanism follows the repository's own convention (`lib.mkIf pkgs.stdenv.hostPlatform.isLinux`, used in `features/cli/kitty.nix`, `features/cli/ssh.nix`, `features/productivity/browser.nix`), so no operator preference was needed. |
| Q2 — how should the persistence assertion read the directory list? | Answered from evidence and rejected as posed: the deep read throws (V2) and the elements are attribute sets. The persistence layer's produced mount targets are the better observable (V3). |
| Q3 — update arc42 chapters 3 and 6, or re-mark the rows? | Answered by the chapter-documentation rule: a "No" row must be truthful, so the chapters were corrected rather than the rows re-labelled. |
| Q4 — adopt the release Home-Manager input in the fixtures? | Carried to design by the proposal (D3 was explicitly carried to `design.md`); decided as option 1 with the alternative now recorded (G9). |
| Q5 — cover the "CLI and aliases stay" promise? | Decided as a cheap guard inside the assertion module the change creates (G8); no operator trade-off is involved and no scenario can go RED for an unchanged fact. |
| Q6 — correct the rollback section? | Answered from the configuration: Home Manager is wired as a NixOS module on `thiniel`, so there is no separate home generation to select (G10). |

## Verified by the orchestrator

Commands run against the current tree, not read from the plan.

| # | Finding | Evidence |
|---|---|---|
| V1 | The Home-Manager-level superseded-default predicate works and both settings fail it today, so the two `@host:thiniel` scenarios have real RED evidence. | A throwaway HM module imported into `home/dan/thiniel.nix`, calling `lib.hm.deprecations.mkStateVersionOptionDefault { … deferWarningToConfig = true; inherit config options; }` and asserting `shouldWarn == false` for both paths: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath` → `Failed assertions: dan profile: probe: hyprland configType is resolved from a superseded default`, `dan profile: probe: firefox configPath is resolved from a superseded default`. Probe reverted; host evaluates again to the same derivation. |
| V2 | `home.persistence."<root>".directories` cannot be deep-read. | `nix eval --json '.#nixosConfigurations.thiniel.config.home-manager.users.dan.home.persistence."/persist".directories'` → `error: The option 'method' can no longer be used since it's been removed`; the equivalent read of `.files` returns entries. |
| V3 | The persistence layer's observable exists and carries the declared directories today. | `nix eval --json .#nixosConfigurations.thiniel.config.systemd.mounts --apply 'x: builtins.filter (w: builtins.match ".*mozilla.*" w != null) (map (m: m.where or "") x)'` → `["/home/dan/.cache/mozilla","/home/dan/.mozilla"]`. |
| V4 | The rendered-artifact observables are as the design assumes. | `…dan.xdg.configFile` filtered on `hypr` → `["hypr/hypridle.conf","hypr/hyprland.conf","hypr/hyprlock.conf", …]` (no `.lua`); `…dan.home.file` filtered on `mozilla` → `[".mozilla/firefox/profiles.ini", ".mozilla/firefox/user/user.js", …]`. |
| V5 | Binding completeness. | `python3 scripts/givn-spec-trace.py` → exactly one finding, the not-yet-existing `@check:flake-output-contract`; every `@e2e` scenario binds to `@check:integration-*`; `verify.e2e_command` is a strict subset of `verify.command`. |
| V6 | The runner is green on the plan's baseline and prints the four reported warnings. | `./scripts/givn-verify.sh` → `[givn-verify] OK` (256 python tests, all non-VM checks built, every host evaluated). |

Mechanisms the grilling subagent could not execute (the `flake-output-contract`
derivation's non-recursion, and the two fixtures' node assertions firing) are
not gaps in the plan: each is proven by its own RED step during implementation,
where the check and the assertions first exist. The `self`-reference worry was
dismissed against the existing checks, which already reference `self`.

## Hardening applied

| Finding | Change | Where |
|---|---|---|
| G1 | Linux guard on the browser profile location; Mac platform-default path pinned by a guard assertion | `design.md` (Technology Decisions, Architecture Impact, Blast Radius, Test Targets) |
| G2 | Persistence assertion moved to `config.systemd.mounts` (NixOS level, `thiniel-impermanence-invariants.nix`); the Home-Manager-level module keeps only the two superseded-default predicates | `design.md` (Verification Binding, Test Targets, Assertion mechanics), `specs/…/quiet-configuration-evaluation.feature` (the scenario's third `Then`) |
| G3, G4 | Chapters 3 and 6 corrected; rows 3 and 6 marked Yes with reasons; files-touched table extended | `docs/arc42/03-context-and-scope.md`, `docs/arc42/06-runtime-view.md`, `arc42.md` |
| G5 | Predicate wording corrected | `design.md` (Assertion mechanics) |
| G6 | `flake-output-contract` added to the glossary's check enumeration | `docs/arc42/12-glossary.md` |
| G7 | Assertion-module count and description corrected; integration checks' guest pin recorded | `docs/arc42/05-building-block-view.md` |
| G8 | Fleet CLI and alias guards added to the design's test targets | `design.md` (Test Targets, Architecture Impact) |
| G9 | Rejected alternative recorded | `design.md` (Decisions, D3) |
| G10 | Rollback corrected and the delete gated on a confirmed rollback test | `design.md` (Deployment & Rollback) |

Post-hardening checks: `givn lint --change quiet-configuration-evaluation` exits
0 with the five expected `@wip` findings (the scenarios are not implemented yet);
`python3 scripts/givn-spec-trace.py` exits 1 with exactly one finding — the
not-yet-existing `@check:flake-output-contract` check that the implementation
adds (its own RED step creates it). That is the finding recorded as V5, not an
unresolved binding: every scenario has a row in the design's Verification
Binding table with a target that the change creates and wires.

## Post-review corrections (recorded during implementation)

| Mechanism | Review disposition | Correction and evidence |
|---|---|---|
| The persistence assertion | G2 replaced the option-list membership test with the NixOS-level mount targets, on the finding that the option list cannot be read. | While implementing, the repository's own helper in `tests/assertions/thiniel-impermanence-invariants.nix` was found to read the same list safely (`hmHasDir`, `d.directory or ""` per element): the throw comes from *deep-forcing* an element, not from a lazy attribute read. The assertion therefore uses that existing helper — one convention, not two — and the design was updated (Verification Binding, Assertion mechanics). G2's finding stands (the naive `builtins.elem` form and the deep read are both wrong); only the chosen mechanism moved, and the mount-target form stays recorded as the alternative fact. `design.md` was corrected before the scenario was implemented, per the tasks rule. |

DESIGN-REVIEW: PASS
