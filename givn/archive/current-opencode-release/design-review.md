# Design Review — current-opencode-release

- Date: 2026-10-13
- Reviewed artifacts: `proposal.md`, `specs/reproduce-working-environment/*`,
  `design.md`, `arc42.md` and the twelve `docs/arc42/` chapters
- Method: one grilling subagent in a fresh context (`reviewer`, no access to the
  session that wrote the design) read the planning artifacts and the relevant
  source and returned ranked findings. Its findings are recorded below with
  their dispositions; each was re-checked against the tree before being accepted
  or rejected.

## Phase 1 — grilling findings and dispositions

| # | Finding | Severity | Disposition |
|---|---|---|---|
| F1 | Wiring `((import ./overlays/opencode) pkgs pkgs).opencode` into the whole `linuxSystems` block makes `checks.aarch64-linux.integration-agent-tooling` un-evaluable: the overlay ships prebuilt binaries for `x86_64-linux` and `aarch64-darwin` only, so on `aarch64-linux` the platform lookup yields `null` and forcing the package fails — which `nix flake check --all-systems` surfaces. | BLOCKER | **Fixed.** The design now passes `opencodePackage` only where `builtins.elem system opencodePkgs.opencode.meta.platforms` holds, and `tests/integration/default.nix` forwards it to the check, which treats it as optional. Verified after implementation: `nix eval --raw .#checks.aarch64-linux.integration-agent-tooling.drvPath` exits 0. |
| F2 | The booted check's floor is `2.0.28`, but the existing omp driver compares only `(major, minor)`; a faithful copy would compare `(2, 0) >= (2, 0)` and pass the pre-refresh `2.0.22` binary, so the scenario could never go RED. | MAJOR | **Fixed.** The design states the three-component comparison explicitly, and the check asserts the parsed triple is at least `(2, 0, 28)`. The RED was observed with the pre-refresh package. |
| F3 | Proposal D2 (an out-of-band OpenCode on the Mac) is carried to `design.md`, but the design had no `## Decisions` ledger and never mentioned it. | MAJOR | **Fixed.** The design gained a `## Decisions` ledger resolving D1 and D2; the operator answered D2 on 2026-10-13 (no out-of-band OpenCode exists), and the proposal records the same status. |
| F4 | `design.md` cites the use-case contract at the change path, but the change shipped no delta `usecase.md`, unlike every archived change. | MAJOR | **Fixed.** The change-side `specs/reproduce-working-environment/usecase.md` now exists, carrying the two amended rules, the added OpenCode interaction row and the added out-of-scope bullet. |
| F5 | The glossary's "Agent version floor" entry still said the floor is `18.10` on both devices, which is stale once OpenCode's `2.0.28` floor exists. | MINOR | **Fixed.** The entry names both floors and both refresh mechanisms. |
| F6 | The proposal binds verification points 1 and 3 to `@check:unit-helpers`, but neither the delta spec nor the design adds a unit case; the deviation was implicit. | MINOR | **Fixed.** The proposal's binding table now records that the host assertions prove the package content and that no unit case is added. |
| F7 | The design said `tests/assertions/thiniel-invariants.nix` is "imported by `home/dan/thiniel.nix`". It is not: the module is a NixOS assertion aggregated by `tests/assertions/default.nix`, imported by `hosts/thiniel/default.nix`. | MINOR | **Fixed.** Both wiring columns are corrected (the Mac's file *is* a home-manager module imported by `home/dan/J6G6Y9JK7L.nix`). |
| F8 | The design's affected-file list omitted `tests/integration/default.nix`, which must accept and forward `opencodePackage`. | MINOR | **Fixed.** Added to the Architecture Impact and Test Targets tables. |
| F9 | The glossary's "Model server (MCP server)" entry defines the declaration site as `~/.omp/agent/mcp.json` only, which is incomplete once OpenCode is a coding agent. | MINOR | **Fixed.** The entry records both declaration sites. |
| F10 | The change reinterprets the contract rule "a device that carries the coding agent also carries its guardrails" to exclude OpenCode, without amending the contract text. | INFO | **Fixed.** The change-side `usecase.md` scopes the rule to the agent with a user-level guard and adds the boundary to its out-of-scope list. |

No finding was rejected.

## Phase 1 — operator question, closed

### Q1 — An OpenCode installed on the work MacBook outside this configuration

- Status: closed 2026-10-13 (operator).
- Blocks: whether the change touches a file outside the configuration on the
  Mac, and whether the asserted floor describes the binary actually run.
- Context: the repository installs OpenCode for `J6G6Y9JK7L` only through the
  shared feature module; a hand-installed copy (npm global, Homebrew) could
  shadow it, and the session cannot reach that machine.
- Options considered: (1) no out-of-band install exists; (2) it exists and is
  removed; (3) it exists and is left in place.
- Resolution: **option 1** — the operator confirmed no OpenCode exists on that
  machine outside this configuration. Rejected: option 2, nothing to remove and
  the deletion would be destructive outside this change's scope; option 3, the
  PATH-shadowing risk it priced does not exist here. One re-check stays on the
  Mac after activation (`command -v opencode` under the Nix store), because the
  repository cannot observe that machine.

## Branch coverage

| Branch | Verdict | Evidence |
|---|---|---|
| Scope | Passes | The three delta scenarios cover proposal points 1–5 with nothing extra: two host floors and one booted launch. The Mac's launch is a disclosed limit (no deploy layer), not a silent gap. |
| Tech choices | Fixed | The overlay/package plumbing is sound but was over-applied (F1). The package argument is **required**, not defaulted — the post-implementation correction recorded in Phase 3 below. Each host passes its own `pkgs.opencode`; the booted guest, whose package set has no overlay, receives the overlay's package. |
| Missing scenarios | Passes | No observable behaviour in the proposal lacks a scenario; the "refuses an older OpenCode" property is the floor assertion itself, which scenarios 1 and 2 carry. |
| Testability | Fixed | Both host scenarios fail today for a named reason (`2.0.22` below the `2.0.28` floor). The booted scenario's RED was at risk of being degenerate (F2) and is now a three-component comparison. |
| Verification-binding completeness | Passes | Exactly one binding tag per scenario; `@e2e` binds to `@check:integration-agent-tooling`; `verify.command` (`./scripts/givn-verify.sh`) differs from `verify.e2e_command` (`./scripts/givn-verify-e2e.sh`). `scripts/givn-spec-trace.py` resolves all three bindings against existing targets. |
| Deployment & rollback | Passes | The change touches no dangerous area — no `boot.loader`, `networking`, `fileSystems`/disko, impermanence, kernel or secret change; only a package version and two assertions. Apply and rollback are recorded anyway. |
| Risk | Recorded | Most likely failure: the booted check's package never reaches the guest (F1/F8) — fixed and verified by evaluating the check for both Linux systems. Second: a wrong checksum fails the derivation build, caught before activation. |
| Decision ledger | Passes | D1 answered in the proposal; D2 answered by the operator above; the one HOW question decided in the design's `## Decisions`. No unrecorded item. |
| Use-case and Persona context | Passes | Use case `reproduce-working-environment`; capability `current-agent-tooling` extended (route: EXTEND, score 12.60). The change-side `usecase.md` differs from the permanent one by two rules, one interaction row, one example and one out-of-scope bullet. Personas: `owner--operator` relevant; `family--application-user` unaffected. No Persona invented or promoted. |
| Ubiquitous language | Fixed | "Coding agent" names both agents; "Agent version floor" names both floors; "Model server (MCP server)" records both declaration sites (F5, F9). The spec's "the OpenCode coding agent" is consistent with the glossary entry. |
| Architecture documentation | Passes after fixes | The twelve-row assessment in `arc42.md` was re-derived; the three stale sentences it found inside chapters marked Yes (F5, F9 and the "Agent version floor" wording) are fixed. No ADR is created and chapter 9 routes the non-qualifying candidate to the design. |
| Anything else | Passes | `tests/integration/default.nix` is the only wiring file the design initially missed (F8). The delta feature's title matches the permanent feature's title, so the archive merge appends to the same capability. |

## Phase 2 — hardening log

- Re-checked F1 against the tree after the fix: the integration block computes
  the package only for a supported system, and the check is evaluable for both
  `x86_64-linux` and `aarch64-linux`.
- Re-checked F2: the check's comparison is a parsed `(major, minor, patch)`
  triple, so `2.0.22` fails and `2.0.28` passes.
- Re-checked F7 by reading the importers: `hosts/thiniel/default.nix` imports
  `../../tests/assertions`; `home/dan/J6G6Y9JK7L.nix` imports its own invariants
  file.
- The proposal's binding table and the design's Test Targets table now agree.

## Phase 3 — post-implementation correction (design-review re-run)

- **What changed and why.** `design.md` as reviewed specified a defaulted module
  argument (`opencodePackage ? pkgs.opencode`) with only the booted check
  overriding it. Implementation disproved it: the Home Manager module system
  resolves every formal through `_module.args` and fails with "attribute
  `opencodePackage` missing" when a formal is absent — reproduced for both
  `? pkgs.opencode` and `? null`. The argument is therefore **required**: each
  host passes its own `pkgs.opencode` (through its `{ pkgs, ... }` module
  arguments), and the booted check passes the overlay's package.
- **Re-run.** A second fresh-context reviewer re-checked the corrected decision
  against the tree and independently reproduced the premise with
  `lib.evalModules` against the pinned nixpkgs
  (`github:NixOS/nixpkgs/8edc0c72e3a38faf5434e40d1f19431125fe4b30`,
  `lib/modules.nix:738-749`). It confirmed the code wiring is consistent:
  `home/dan/features/development/opencode.nix` declares the argument required and
  installs it with no fallback; both hosts that import the module pass it; the
  module has no other importer; the unit instantiation passes it; the integration
  check treats it as optional and the flake gates it by supported platform.
- **Findings from the re-run, both fixed.** (1) This file's Tech-choices row and
  this addendum: the row still described the defaulted shape — corrected above.
  (2) `arc42.md`'s chapter-5 row said "package argument with its default" —
  corrected to "required package argument"; the durable chapter
  (`docs/arc42/05-building-block-view.md`) was already corrected.
- **Arc42 reassessment.** The correction is not structural — no chapter's
  affected/not-affected verdict changes — so the twelve-row assessment stands
  with the chapter-5 wording fix above.
- **Design conformance after the re-run:** CLEAN.

DESIGN-REVIEW: PASS
