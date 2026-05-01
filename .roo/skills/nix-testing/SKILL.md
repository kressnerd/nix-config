# Skill: Nix Testing

**Applies to**: architect, code, debug  
**Trigger**: Writing tests, test infrastructure, nixosTest, lib.runTests, assertions, test-first workflow, Red-Green-Refactor, integration tests, flake checks

## Scope

This skill covers all test types in the nix-config repository: pure Nix unit tests (`lib.debug.runTests`), NixOS module assertions, QEMU-based integration tests (`pkgs.testers.runNixOSTest`), and post-deployment validation (`pytest-testinfra`). It provides production-ready patterns, not conceptual overviews.

## Prerequisites (from existing rules)

- `.roo/rules/13-test-first.md` — TEST-FIRST-001: mandatory Red-Green-Refactor cycle
- `.roo/rules-orchestrator/03-test-first.md` — ORCH-TEST-001: delegation sequence
- `.roo/rules-code/05-test-writing.md` — CODE-TEST-001: test writing patterns and return format
- `.roo/rules-code/01-validation.md` — CODE-VALID-001: validation pipeline including test step
- `.roo/rules/11-repository-conventions.md` — test directory structure under `tests/`

---

## 1. Unit Tests — `lib.debug.runTests`

### When to Use
Pure Nix logic: helper functions, IP calculations, attrset transforms, list operations. Runs on all platforms (Linux + macOS). No VM required.

### Pattern

```nix
# tests/unit/<module>-test.nix
{ lib }:
lib.debug.runTests {
  testFunctionReturnsExpected = {
    expr = myFunction "input";
    expected = "expected-output";
  };
  testEdgeCase = {
    expr = myFunction "";
    expected = null;
  };
}
```

### Aggregator Pattern

```nix
# tests/unit/default.nix
{ pkgs }:
let
  helperTests = import ./helpers-test.nix { inherit (pkgs) lib; };
in
pkgs.runCommand "unit-helpers" { } ''
  ${if helperTests == [ ] then ''
    echo "All unit tests passed"
    touch $out
  '' else ''
    echo "FAIL: ${builtins.toJSON helperTests}"
    exit 1
  ''}
''
```

### Flake Integration

```nix
# In flake.nix checks output
checks.<system>.unit-helpers = import ./tests/unit/default.nix {
  pkgs = nixpkgs.legacyPackages.${system};
};
```

### Run Commands
```bash
# All unit tests via flake check
nix flake check

# Specific unit test
nix build .#checks.aarch64-darwin.unit-helpers

# Quick eval (no derivation)
nix eval --impure --expr 'import ./tests/unit/helpers-test.nix { lib = (import <nixpkgs> {}).lib; }'
```

### Key Rules
- `lib.debug.runTests` returns `[]` on success, list of `{ name, expected, result }` on failure
- Tests are pure Nix — no side effects, no IO
- Each test has exactly `expr` and `expected` fields
- Test names must start with `test` (lowercase 't')

---

## 2. Module Assertions

### When to Use
Option constraints, type guards, dependency requirements, configuration invariants. Fires at evaluation time — `nix flake check --no-build` is sufficient.

### Pattern

```nix
# tests/assertions/<scope>-invariants.nix
{ config, lib, ... }:
{
  config.assertions = [
    {
      assertion = config.networking.hostName != "" && config.networking.hostName != "localhost";
      message = "Host invariant violated: networking.hostName must be set";
    }
    {
      assertion = config.networking.firewall.enable;
      message = "Host invariant violated: firewall must be enabled";
    }
  ];
}
```

### Wiring into Host Config
```nix
# hosts/<hostname>/default.nix
{
  imports = [
    ../../tests/assertions
    # ... other imports
  ];
}
```

### Run Commands
```bash
# Eval-only (assertions fire without building)
nix flake check --no-build

# Full check (assertions + builds)
nix flake check
```

### Key Rules
- Assertions are NixOS module attributes — they must be imported into host configs
- `assertion` is a boolean expression; `message` is a string shown on failure
- Assertions fire during evaluation, not at runtime
- Cannot test "assertion fails correctly" from within NixOS eval — use separate `nix eval` for negative tests
- Use `lib.mkIf` to make assertions conditional on feature enablement

---

## 3. Integration Tests — `testers.runNixOSTest`

### When to Use
Service behavior, firewall rules, systemd units, networking, TLS, sops secret paths, impermanence, disk layout. Requires QEMU — Linux-only.

### Pattern

```nix
# tests/integration/<feature>-test.nix
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "<descriptive-test-name>";

  nodes.machine = { pkgs, ... }: {
    # Minimal NixOS config for the feature under test
    services.openssh.enable = true;
    networking.firewall.enable = true;
    networking.firewall.allowedTCPPorts = [ 22 ];
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("sshd.service")
    machine.wait_for_open_port(22)
    machine.succeed("systemctl is-active sshd.service")
    machine.fail("curl -sf http://localhost:80")
  '';
}
```

### Multi-Node Pattern

```nix
pkgs.testers.runNixOSTest {
  name = "multi-node-networking";

  nodes = {
    server = { ... }: {
      services.nginx.enable = true;
      networking.firewall.allowedTCPPorts = [ 80 ];
    };
    client = { ... }: { };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("nginx.service")
    client.succeed("curl -sf http://server:80")
  '';
}
```

### Python Test Script API

| Method | Description |
|--------|-------------|
| `machine.start()` | Start the VM |
| `start_all()` | Start all VMs in multi-node tests |
| `machine.wait_for_unit("name.service")` | Wait for systemd unit to be active |
| `machine.wait_for_open_port(N)` | Wait for TCP port to be open |
| `machine.succeed("cmd")` | Assert command exits 0; returns stdout |
| `machine.fail("cmd")` | Assert command exits non-0 |
| `machine.execute("cmd")` | Run command; returns `(exit_code, stdout)` |
| `machine.wait_until_succeeds("cmd")` | Retry command until it succeeds (with timeout) |
| `machine.shutdown()` | Graceful shutdown |
| `machine.crash()` | Hard kill (test reboot scenarios) |
| `machine.wait_for_unit("multi-user.target")` | Wait for full boot |
| `machine.shell_interact()` | Interactive shell (debug only) |

### Aggregator Pattern

```nix
# tests/integration/default.nix
{ pkgs, ... }:
{
  integration-vm-minimal-ssh = import ./nixos-vm-minimal-test.nix { inherit pkgs; };
  integration-nginx = import ./nginx-test.nix { inherit pkgs; };
}
```

### Run Commands
```bash
# Build and run specific integration test
nix build .#checks.x86_64-linux.integration-vm-minimal-ssh

# Interactive debugging
nix build .#checks.x86_64-linux.integration-vm-minimal-ssh.driverInteractive
result/bin/nixos-test-driver

# Inside interactive driver:
# >>> machine.start()
# >>> machine.shell_interact()
# >>> machine.succeed("systemctl status sshd")
```

### Testable Scenarios

| Scenario | Test Approach |
|----------|---------------|
| Firewall rules | `nft list ruleset`, port scans between nodes |
| Service dependencies | `wait_for_unit`, `systemctl is-active` |
| Network connectivity | Multi-node: ping, curl between VMs |
| Impermanence | Reboot VM, verify `/` is clean and `/persist` intact |
| TLS termination | `curl -k https://...`, certificate checks |
| sops-nix secrets | File existence checks, permission verification |
| Package absence | `machine.fail("which gcc")` |
| systemd hardening | Parse `systemd-analyze security` output |
| Disk layout (disko) | `lsblk`, `btrfs subvolume list /` |

### Key Rules
- Use `pkgs.testers.runNixOSTest` (NOT `pkgs.nixosTest`) outside nixpkgs
- Tests must be self-contained — do NOT import actual host configs (avoids sops/hardware deps)
- Mirror the desired behavior in a minimal NixOS config
- Linux-only — add to `checks` only for `x86_64-linux` and `aarch64-linux`

---

## 4. Post-Deployment Validation — `pytest-testinfra`

### When to Use
After `nixos-rebuild switch` on real hosts. Validates actual system state via SSH.

### Pattern

```python
# tests/deploy/test_<host>.py
def test_sshd_running(host):
    sshd = host.service("sshd")
    assert sshd.is_running
    assert sshd.is_enabled

def test_firewall_active(host):
    fw = host.service("firewall")
    assert fw.is_running

def test_user_exists(host):
    user = host.user("dan")
    assert user.exists
    assert "wheel" in user.groups
```

### Run Commands
```bash
# Against a live host
pytest --hosts=ssh://dan@thiniel tests/deploy/test_thiniel.py

# From nix develop shell (testinfra available)
nix develop
pytest --hosts=ssh://dan@thiniel tests/deploy/
```

### Key Rules
- Testinfra runs OUTSIDE Nix build — it's a Python tool via SSH
- NOT a replacement for integration tests — it complements them
- Validates the actual deployed state, not the Nix configuration
- Requires SSH access to the target host

---

## 5. Platform Constraint Matrix

| Test Type | macOS (darwin) | Linux (NixOS) | Verify Command |
|-----------|---------------|---------------|----------------|
| `lib.debug.runTests` | ✅ | ✅ | `nix flake check` |
| NixOS `assertions` | ⚠️ NixOS hosts eval only | ✅ | `nix flake check --no-build` |
| NixOS `assertions` (darwin host) | ✅ via HM profile import | — | `nix build .#darwinConfigurations.<host>.config.system` |
| `testers.runNixOSTest` | ❌ (needs linux-builder) | ✅ | `nix build .#checks.<linux-system>.<name>` |
| `flake-checker` | ✅ | ✅ | `nix run github:DeterminateSystems/flake-checker` |
| `pytest-testinfra` | ✅ (SSH from devShell) | ✅ | `pytest --hosts=ssh://...` |

#### Darwin Host Assertions

The `tests/assertions/default.nix` NixOS aggregator cannot be imported by `darwinConfigurations` hosts. For darwin hosts, import assertion modules **directly** from the HM profile (`home/dan/<host>.nix`). They fire at eval-time:

```nix
# home/dan/J6G6Y9JK7L.nix
{ imports = [ ../../tests/assertions/J6G6Y9JK7L-invariants.nix ]; }
```

Verify with:
```bash
nix build .#darwinConfigurations.<host>.config.system
```

---

## 6. Red-Green-Refactor Quick Reference

```
1. Red:   Write test → nix flake check → FAIL ✗
2. Green: Implement  → nix flake check → PASS ✓
3. Refactor:         → nix flake check → PASS ✓
4. Deploy:           → pytest           → PASS ✓
```

### Choosing the Right Test

| Change Type | Test Layer | File Pattern |
|-------------|-----------|--------------|
| Pure Nix function | Unit | `tests/unit/<name>-test.nix` |
| Module option/constraint | Assertion | `tests/assertions/<name>-invariants.nix` |
| Service/firewall/network | Integration | `tests/integration/<name>-test.nix` |
| Post-deploy verification | Deploy | `tests/deploy/test_<host>.py` |
