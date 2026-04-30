# Plan: Add Homebrew Cask `marta` to Host `J6G6Y9JK7L`

**Status**: COMPLETED
**Target Host**: `J6G6Y9JK7L` (aarch64-darwin)
**Author**: Architect Mode
**Related Files**:
- [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:94)
- [`flake.nix`](../../flake.nix:319)
- [`tests/unit/default.nix`](../../tests/unit/default.nix:1)
- [`tests/unit/hm-modules-test.nix`](../../tests/unit/hm-modules-test.nix:1)

---

## 1. Business Context / Goal

Add the macOS file manager [`marta`](https://formulae.brew.sh/cask/marta) to the declarative `homebrew.casks` list of the nix-darwin host `J6G6Y9JK7L`, so it is installed and managed by `nix-homebrew` on the next `darwin-rebuild switch`.

## 2. Acceptance Criteria

- [ ] A pure Nix unit test asserts `"marta"` is a member of the casks list declared in [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:94).
- [ ] The new test is wired into `flake.nix` `checks.<system>.unit-helpers` via the [`tests/unit/default.nix`](../../tests/unit/default.nix:1) aggregator.
- [ ] `nix flake check` passes on `aarch64-darwin` (and remains green on Linux systems — the test is host-config-only and platform-agnostic in evaluation).
- [ ] The casks list remains alphabetically sorted.

## 3. Technical Analysis

### 3.1 Decision: Where Does the Test Live?

Two evaluated alternatives:

| Option | Approach | Trade-offs |
|---|---|---|
| **(a)** Add a `lib.debug.runTests` unit test under [`tests/unit/`](../../tests/unit/) that **imports the host module file directly** as a raw attrset (lazy eval) and asserts `"marta" ∈ result.homebrew.casks` | Tiny, ~30 LOC, follows the established pattern from [`tests/unit/hm-modules-test.nix`](../../tests/unit/hm-modules-test.nix:53) (which imports HM profiles directly with mocked args). System-agnostic — runs on every system in `allSystems`. | Bypasses the NixOS/darwin module system; relies on `homebrew.casks` being a literal list expression in the host file (it is — see [lines 94–100](../../hosts/J6G6Y9JK7L/default.nix:94)). |
| **(b)** Create a brand-new darwin-host **assertion-test scaffold** under [`tests/assertions/`](../../tests/assertions/) that evaluates `self.darwinConfigurations.J6G6Y9JK7L.config.homebrew.casks` through the full module system | Closer to "production-truth" — exercises `nix-homebrew` module merging. | Requires new infrastructure: darwin assertion runner, `aarch64-darwin`-only system gating in `checks`, plumbing `inputs`/`outputs` into the test. Cross-system evaluation of a darwin config from a Linux runner is brittle/impossible. Massive over-engineering for a single-line addition. |

**Recommendation: (a)**.

Justification (KISS / YAGNI):
- A single membership assertion does not justify a new test category.
- The existing pattern of importing host/HM modules as raw attrsets is already proven in this repo (see [`tests/unit/hm-modules-test.nix:53`](../../tests/unit/hm-modules-test.nix:53), where `J6G6Y9JK7L.nix` is imported with mocked `config`/`pkgs`/`lib`).
- Lazy evaluation: only `result.homebrew.casks` is forced; the host module's reference to `config.nix-homebrew.taps` at [`default.nix:87`](../../hosts/J6G6Y9JK7L/default.nix:87) is never evaluated, so a minimal stub `config = {}` suffices.
- Platform independence: the casks list is a literal `[ "..." ]` expression with no `pkgs.stdenv` or platform predicates.

### 3.2 Test File Path

`tests/unit/J6G6Y9JK7L-homebrew-test.nix`

### 3.3 Wiring Into `flake.nix` Checks

The flake check `checks.<system>.unit-helpers` is defined at [`flake.nix:346`](../../flake.nix:346) as:

```nix
unit-helpers = import ./tests/unit/default.nix { inherit pkgs; };
```

It is registered for **all systems** (`x86_64-linux`, `aarch64-linux`, `aarch64-darwin`) via `forSystems allSystems` at [`flake.nix:340`](../../flake.nix:340). Therefore **no edit to `flake.nix` itself is required** — the test is auto-discovered once added to the aggregator.

The aggregator file [`tests/unit/default.nix`](../../tests/unit/default.nix:1) must be edited to:
1. `import ./J6G6Y9JK7L-homebrew-test.nix { inherit (pkgs) lib; };` (binding name e.g. `j6HomebrewTests`)
2. Concatenate it into `allFailures` with `++ j6HomebrewTests`.

### 3.4 System Guarding

Not needed. The test imports a `.nix` file as a raw attrset — no darwin-specific evaluation. It runs identically on every system in `allSystems`.

(Compare: option (b) would have required `aarch64-darwin`-only gating because evaluating `darwinConfigurations.J6G6Y9JK7L.config.*` on Linux would fail.)

### 3.5 Test Skeleton (illustrative — not for direct copy)

```nix
{ lib }:
let
  hostModule = import ../../hosts/J6G6Y9JK7L/default.nix {
    config = { };
    pkgs = { };
    lib = { };
    inputs = { };
  };
  casks = hostModule.homebrew.casks;
in
lib.debug.runTests {
  testMartaCaskPresent = {
    expr = builtins.elem "marta" casks;
    expected = true;
  };
}
```

Note: this test file pattern matches the convention in [`tests/unit/hm-modules-test.nix`](../../tests/unit/hm-modules-test.nix:1) — `lib.debug.runTests` returns `[]` on success and a list of failures otherwise; the aggregator concatenates them.

### 3.6 Alphabetical Insertion Position

Current list ([`default.nix:94–100`](../../hosts/J6G6Y9JK7L/default.nix:94)):
```
cameracontroller
claude
claude-code
crossover
kitty
```

`marta` sorts after `kitty` — append as the **last entry** before the closing `];`.

## 4. Implementation Phases

### Phase 0 — Validation Strategy (Pre-Implementation)

| Concern | Detail |
|---|---|
| Sole gate | `nix flake check` |
| Affected hosts | `J6G6Y9JK7L` (no rebuild in this plan) |
| Dangerous-change category | None — Homebrew cask addition is reversible at any time by editing the list and re-running `darwin-rebuild switch` |
| Rollback | Remove `"marta"` from the list; `darwin-rebuild switch` will uninstall it on next apply (because `homebrew.onActivation.cleanup = "zap"` is set at [`default.nix:89`](../../hosts/J6G6Y9JK7L/default.nix:89)) |

### Phase 1 — RED (Write Failing Test)

**Atomic step 1.1**: Create the test file.
- File: `tests/unit/J6G6Y9JK7L-homebrew-test.nix`
- Content: as in §3.5 above.

**Atomic step 1.2**: Wire into the aggregator.
- File: [`tests/unit/default.nix`](../../tests/unit/default.nix:1)
- Add binding after the existing `hmMacosTests` line:
  ```nix
  j6HomebrewTests = import ./J6G6Y9JK7L-homebrew-test.nix { inherit (pkgs) lib; };
  ```
- Append `++ j6HomebrewTests` to the `allFailures` concatenation.

**Verification**: `nix flake check` MUST FAIL with a `testMartaCaskPresent` failure (expr=`false`, expected=`true`).

### Phase 2 — GREEN (Make Test Pass)

**Atomic step 2.1**: Append `"marta"` to the casks list.
- File: [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:94)
- Change at line 99–100:
  ```nix
      "kitty"
    ];
  ```
  becomes:
  ```nix
      "kitty"
      "marta"
    ];
  ```

**Verification**: `nix flake check` MUST PASS.

### Phase 3 — REFACTOR

Not applicable. Two single-line additions; no refactoring opportunity.

## 5. Validation Strategy

| Check | Command | When |
|---|---|---|
| Syntax + tests | `nix flake check` | After Phase 1 (expect FAIL) and after Phase 2 (expect PASS) |
| Format | `nix fmt` on changed files | After each phase |
| Lint | `statix check` and `deadnix` on changed files | After Phase 2 |

No `darwin-rebuild build` step is part of this plan — `nix flake check` is sufficient because the casks list is a literal that is fully resolved at evaluation time.

## 6. Out of Scope

- Deployment via `darwin-rebuild switch` (manual user step after merge).
- Documentation updates — adding a single cask does not warrant doc changes per repo policy.
- Verifying Marta launches or is properly installed at runtime (not a Nix-level concern).
- Refactoring the casks list into a separate module.

## 7. Current Status

| Phase | Status |
|---|---|
| Phase 0 — Validation Strategy | DEFINED |
| Phase 1 — RED | DONE |
| Phase 2 — GREEN | DONE |
| Phase 3 — REFACTOR | N/A |

## 8. Completion Log

(To be filled by the orchestrator/code mode as phases complete.)
- 2026-04-30 — Phases 1 (RED) and 2 (GREEN) complete. nix flake check PASS.
