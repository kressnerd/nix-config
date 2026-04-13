# Test-First Workflow — Red-Green-Refactor

## Rule ID: TEST-FIRST-001

**Priority**: MANDATORY  
**Applies to**: All modes, all configuration changes

## Core Principle

Every configuration change MUST start with a failing test (Red), then implement the change to make the test pass (Green), then refactor while tests stay green (Refactor).

## Small Steps — One Change Per Cycle

Each Red-Green-Refactor cycle covers exactly **one minimal, verifiable change**. Do not batch multiple changes into a single cycle.

### What Constitutes One Step

- **One assertion** per cycle (not 5 assertions at once)
- **One module option** per cycle (not an entire service config)
- **One test case** per cycle (write test → fail → implement → pass → next test)
- **One firewall rule** per cycle (not all ports at once)

### Iterative Progression Example

```
Cycle 1: Red   → assertion: hostname must not be empty
         Green → set networking.hostName = "myhost"

Cycle 2: Red   → assertion: firewall must be enabled
         Green → networking.firewall.enable = true

Cycle 3: Red   → nixosTest: SSH must be running
         Green → services.openssh.enable = true

Cycle 4: Red   → nixosTest: root login must be disabled
         Green → services.openssh.settings.PermitRootLogin = "no"

Cycle 5: Refactor → extract SSH config into reusable module
         Verify  → all tests still pass
```

### Anti-Patterns

- ❌ Writing 10 assertions, then implementing everything at once
- ❌ Creating an entire service module, then writing tests after
- ❌ Skipping Red phase because "the test is obvious"
- ❌ Combining unrelated changes in one cycle
- ❌ Writing assertions that check **exact counts** of list members (e.g., "package list must have exactly 5 entries") — these break whenever an unrelated item is added or removed. Assert presence or absence of **specific named items** instead

### Granularity Guide

| Change Scope | Cycles Expected |
|--------------|----------------|
| Add one package | 1 (assertion or unit test) |
| Enable a service | 2–3 (enable → port → security) |
| Configure firewall | 1 per rule/port |
| New feature module | 3–5 (option → enable → config → verify → refactor) |
| New host config | 5–10 (hostname → network → firewall → ssh → users → services) |

## Test Layers

| Layer | Tool | Runs Without VM? | Trigger |
|-------|------|-------------------|---------|
| Unit tests | `lib.debug.runTests` via `tests/unit/` | Yes | Pure Nix logic (helpers, IP calculations, attrset transforms) |
| Module assertions | NixOS `assertions` via `tests/assertions/` | Yes (eval-time) | Option constraints, type guards, dependency requirements |
| Integration tests | `pkgs.testers.runNixOSTest` via `tests/integration/` | No (QEMU) | Service behavior, firewall rules, networking, systemd units |
| Deploy validation | `pytest-testinfra` via `tests/deploy/` | No (SSH to real host) | Post-deployment verification on live systems |

## Red-Green-Refactor Cycle

### For Module/Option Changes
1. **Red**: Write assertion or `lib.debug.runTests` test → `nix flake check` → FAIL
2. **Green**: Implement module/option → `nix flake check` → PASS
3. **Refactor**: Restructure → `nix flake check` → PASS

### For Service/Infrastructure Changes
1. **Red**: Write `testers.runNixOSTest` → `nix build .#checks.<system>.<test>` → FAIL
2. **Green**: Implement service config → `nix build .#checks.<system>.<test>` → PASS
3. **Refactor**: Clean up → all tests → PASS
4. **Deploy**: `nixos-rebuild switch` → `pytest` validates real system

## Obligations

All modes MUST:

- Write the test BEFORE the implementation
- Verify the test FAILS before implementing (Red confirmation)
- Verify the test PASSES after implementing (Green confirmation)
- Run ALL existing tests after refactoring to prevent regressions
- Add new tests to `flake.nix` `checks` output so `nix flake check` runs them

## Prohibitions

- Writing implementation code without a corresponding test = rule violation
- Deploying to a real host when integration tests for that host's services fail = rule violation
- Deleting or weakening existing tests to make implementation "pass" = rule violation
- Skipping the Red phase (writing test + implementation simultaneously) = rule violation

## Exceptions

Test-first is NOT required for:

- Documentation-only changes (`.md` files)
- `nix flake update` (dependency updates)
- SOPS secret value changes (encrypted content)
- Formatting-only changes (`nixfmt`)
- `.gitignore`, `.editorconfig`, and similar tooling config

## Test File Locations

| Test Type | Directory | Naming Convention |
|-----------|-----------|-------------------|
| Unit tests | `tests/unit/` | `<module>-test.nix` |
| Assertions | `tests/assertions/` | `<scope>-invariants.nix` |
| Integration | `tests/integration/` | `<host-or-feature>-test.nix` |
| Deploy | `tests/deploy/` | `test_<host>.py` |

## Verification Commands

| Command | What It Tests |
|---------|---------------|
| `nix flake check` | Evaluates all configs + runs all `checks.*` derivations |
| `nix flake check --no-build` | Evaluates only (assertions fire, no VM tests) |
| `nix build .#checks.<system>.<name>` | Build a specific test |
| `nix build .#checks.<system>.<name>.driverInteractive` | Interactive VM test debugging |
| `nix flake show` | Verify test appears in checks output |

## Enforcement

- Any configuration change without a preceding failing test is a rule violation
- Code Mode MUST report test results in its DONE response
- Orchestrator MUST delegate Red and Green as separate subtasks
- Reviewer MUST verify test coverage exists for reviewed changes
