# Test-First Workflow — Red-Green-Refactor

## Rule ID: TEST-FIRST-001

**Priority**: MANDATORY  
**Applies to**: All modes, all configuration changes

## Core Principle

Every configuration change MUST start with a failing test (Red), then implement the change to make the test pass (Green), then refactor while tests stay green (Refactor).

## Test Layers

| Layer | Tool | Runs Without VM? | Trigger |
|-------|------|-------------------|---------|
| Unit tests | `lib.debug.runTests` via `tests/unit/` | Yes | Pure Nix logic (helpers, IP calculations, attrset transforms) |
| Module assertions | NixOS `assertions` via `tests/assertions/` | Yes (eval-time) | Option constraints, type guards, dependency requirements |
| Integration tests | `pkgs.testers.runNixOSTest` via `tests/integration/` | No (QEMU) | Service behavior, firewall rules, networking, systemd units |
| Deploy validation | `pytest-testinfra` via `tests/deploy/` | No (SSH to real host) | Post-deployment verification on live systems |

## Red-Green-Refactor Cycle

### For Module/Option Changes
1. **Red**: Write assertion or `lib.runTests` test → `nix flake check` → FAIL
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
- Formatting-only changes (`nixfmt`, `alejandra`)
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
