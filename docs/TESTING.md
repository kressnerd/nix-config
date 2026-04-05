# Testing

Test-first workflow: every configuration change starts with a failing test (Red), then implementation makes it pass (Green), then refactor while tests stay green.

## Quick Reference

| Command | What It Does |
|---------|-------------|
| `nix flake check` | Evaluates all configs, runs all checks (unit + integration) |
| `nix flake check --no-build` | Evaluation only (assertions fire, no VM tests) |
| `nix build .#checks.<system>.<name>` | Build and run a specific test |
| `nix build .#checks.<system>.<name>.driverInteractive` | Interactive VM test debugging |
| `nix flake show` | Verify test appears in checks output |

## Test Types

### Unit Tests (`tests/unit/`)

Pure Nix logic tests using `lib.debug.runTests`. Cross-platform (macOS + Linux).

```bash
# Run unit tests
nix build .#checks.aarch64-darwin.unit-helpers

# Quick eval without building
nix eval --impure --expr 'import ./tests/unit/helpers-test.nix { lib = (import <nixpkgs> {}).lib; }'
```

**Add a new unit test:**
1. Create `tests/unit/<name>-test.nix` with `lib.debug.runTests { ... }` pattern
2. Add aggregator entry in `tests/unit/default.nix`
3. Add check attribute in `flake.nix` under `checks`

### Module Assertions (`tests/assertions/`)

NixOS evaluation-time guards. Fire during `nix flake check --no-build`.

```bash
# Verify assertions pass
nix flake check --no-build
```

**Add a new assertion:**
1. Create `tests/assertions/<scope>-invariants.nix` as a NixOS module with `config.assertions`
2. Import in `tests/assertions/default.nix`
3. Assertions fire automatically via host config imports

### Integration Tests (`tests/integration/`)

QEMU VM tests using `pkgs.testers.runNixOSTest`. Linux-only.

```bash
# Run specific integration test
nix build .#checks.x86_64-linux.integration-vm-minimal-ssh

# Interactive debugging
nix build .#checks.x86_64-linux.integration-vm-minimal-ssh.driverInteractive
result/bin/nixos-test-driver

# Inside driver:
# >>> machine.start()
# >>> machine.shell_interact()
```

**Add a new integration test:**
1. Create `tests/integration/<feature>-test.nix` with `pkgs.testers.runNixOSTest { ... }` pattern
2. Add entry in `tests/integration/default.nix`
3. Tests are automatically wired into `checks` via the aggregator

### Post-Deployment Validation (`tests/deploy/`)

SSH-based validation using `pytest-testinfra` on real hosts. Run after `nixos-rebuild switch`.

```bash
pytest --hosts=ssh://dan@thiniel tests/deploy/test_thiniel.py
```

## Current Checks

| Check Attribute | Platform | Tests |
|----------------|----------|-------|
| `unit-helpers` | All (x86_64-linux, aarch64-linux, aarch64-darwin) | `lib/helpers.nix` functions |
| `integration-vm-minimal-ssh` | Linux only | SSH + firewall behavior |

## Workflow

```
1. Write test          → nix flake check → FAIL (Red)
2. Implement change    → nix flake check → PASS (Green)
3. Refactor            → nix flake check → PASS (Refactor)
4. Deploy              → pytest           → Validate
```

## Exceptions

Tests are NOT required for: `.md` files, `nix flake update`, SOPS secret values, formatting-only changes.
