# Skill: Nix Testing

**Applies to**: architect, coder, debugger
**Trigger**: Writing tests, test infrastructure, nixosTest, lib.runTests, assertions, test-first workflow, Red-Green-Refactor, integration tests, flake checks, nix-unit, pytest-testinfra

## Scope

All test types in the nix-config repository: pure Nix unit tests (`lib.debug.runTests`), NixOS module assertions, QEMU-based integration tests (`pkgs.testers.runNixOSTest`), and post-deployment validation (`pytest-testinfra`). Production-ready patterns, not conceptual overviews.

## Prerequisites

See the **Test-First Workflow** and **Validation Pipeline** sections in `CLAUDE.md`.

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

# Quick eval (no derivation, for rapid iteration)
nix eval --impure --expr 'import ./tests/unit/helpers-test.nix { lib = (import <nixpkgs> {}).lib; }'
```

### Key Rules
- `lib.debug.runTests` returns `[]` on success, list of `{ name; expected; result; }` on failure
- Tests are pure Nix — no side effects, no IO
- Each test has exactly `expr` and `expected` fields
- Test names must start with `test` (lowercase 't')

### Alternative: `nix-unit`
`nix-unit` (available in nixpkgs) provides per-test failure isolation — one eval error doesn't abort all tests. Same `{ expr; expected; }` format. Add to devShell for faster local iteration:
```bash
nix-unit ./tests/unit/helpers-test.nix
```

---

## 2. Module Assertions

### When to Use
Option constraints, type guards, dependency requirements, configuration invariants. Fires at evaluation time — `nix flake check --no-build` is sufficient. No VM required.

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
    {
      assertion = !(config.services.openssh.enable && config.services.openssh.settings.PermitRootLogin == "yes");
      message = "Security invariant violated: PermitRootLogin must not be 'yes'";
    }
  ];
}
```

### Wiring into Host Config
```nix
# hosts/<hostname>/default.nix
{
  imports = [
    ../../tests/assertions   # imports tests/assertions/default.nix → host-invariants.nix
    # ... other imports
  ];
}
```

### Run Commands
```bash
# Eval-only (assertions fire without building — fast)
nix flake check --no-build

# Full check (assertions + builds)
nix flake check
```

### Key Rules
- Assertions are NixOS module attributes — they must be imported into host configs
- `assertion` is a boolean; `message` is shown on failure
- Assertions fire during evaluation, not at runtime
- Use `lib.mkIf` to make assertions conditional on feature enablement
- Cannot test "assertion fails correctly" from within NixOS eval — use separate `nix eval` for negative tests

---

## 3. Integration Tests — `testers.runNixOSTest`

### When to Use
Service behavior, firewall rules, systemd units, networking, TLS, sops secret paths, impermanence, disk layout. Requires QEMU — **Linux-only**.

### Pattern

```nix
# tests/integration/<feature>-test.nix
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "<descriptive-test-name>";

  nodes.machine = { pkgs, ... }: {
    # Minimal self-contained NixOS config for the feature under test
    # Do NOT import actual host configs (avoids sops/hardware dependencies)
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
|---|---|
| `machine.start()` | Start the VM |
| `start_all()` | Start all VMs (multi-node) |
| `machine.wait_for_unit("name.service")` | Wait for systemd unit to be active |
| `machine.wait_for_open_port(N)` | Wait for TCP port to be open |
| `machine.succeed("cmd")` | Assert command exits 0; returns stdout |
| `machine.fail("cmd")` | Assert command exits non-0 |
| `machine.execute("cmd")` | Run command; returns `(exit_code, stdout)` |
| `machine.wait_until_succeeds("cmd")` | Retry until succeeds (with timeout) |
| `machine.shutdown()` | Graceful shutdown |
| `machine.crash()` | Hard kill (test reboot/impermanence scenarios) |
| `machine.shell_interact()` | Interactive shell (debug only) |

### Aggregator Pattern

```nix
# tests/integration/default.nix
{ pkgs, ... }:
{
  integration-vm-minimal-ssh = import ./nixos-vm-minimal-test.nix { inherit pkgs; };
  # Add new tests here
}
```

### Flake Integration (Linux-only)

```nix
# In flake.nix — add to the linux-only checks block
checks."x86_64-linux".integration-new-feature =
  import ./tests/integration/new-feature-test.nix { pkgs = nixpkgs.legacyPackages."x86_64-linux"; };
```

### Run Commands
```bash
# Build and run specific integration test (Linux system required)
nix build .#checks.x86_64-linux.integration-vm-minimal-ssh

# Interactive debugging (builds the REPL driver)
nix build .#checks.x86_64-linux.integration-vm-minimal-ssh.driverInteractive
result/bin/nixos-test-driver
# Inside the driver REPL:
# >>> machine.start()
# >>> machine.shell_interact()   # drop into VM shell
# >>> machine.succeed("systemctl status sshd")
```

### Testable Scenarios

| Scenario | Test Approach |
|---|---|
| Firewall rules | `nft list ruleset`, port scans between nodes |
| Service dependencies | `wait_for_unit`, `systemctl is-active` |
| Network connectivity | Multi-node: ping, curl between VMs |
| Impermanence | `machine.crash()` then reboot, verify `/` clean and `/persist` intact |
| TLS termination | `curl -k https://...`, certificate checks |
| sops-nix secrets | File existence checks, permission verification |
| Package absence | `machine.fail("which gcc")` |
| systemd hardening | Parse `systemd-analyze security <unit>` output |
| Disk layout (disko) | `lsblk`, `btrfs subvolume list /` |

### Key Rules
- Use `pkgs.testers.runNixOSTest` — NOT `pkgs.nixosTest` (deprecated outside nixpkgs)
- Tests must be self-contained — do NOT import actual host configs (avoids sops/hardware deps)
- Mirror the desired behavior in a minimal NixOS config inside `nodes`
- Wire into `checks` only for `x86_64-linux` and `aarch64-linux` (not darwin)

---

## 4. Post-Deployment Validation — `pytest-testinfra`

### When to Use
After `nixos-rebuild switch` on real hosts. Validates actual deployed system state via SSH. Complements integration tests — does not replace them.

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

def test_ssh_port_listening(host):
    assert host.socket("tcp://0.0.0.0:22").is_listening

def test_http_port_closed(host):
    assert not host.socket("tcp://0.0.0.0:80").is_listening

def test_user_exists(host):
    user = host.user("dan")
    assert user.exists
    assert "wheel" in user.groups
```

### Run Commands
```bash
# Against a live host (from devShell with testinfra available)
pytest --hosts=ssh://dan@thiniel tests/deploy/test_thiniel.py

# Multiple hosts
pytest --hosts=ssh://dan@thiniel --hosts=ssh://dan@pronix tests/deploy/
```

### Adding testinfra to devShell (shell.nix)
```nix
pkgs.mkShell {
  buildInputs = [
    (pkgs.python3.withPackages (ps: with ps; [
      pytest
      pytest-testinfra
      paramiko
    ]))
  ];
}
```

### Key Rules
- Testinfra runs OUTSIDE Nix build — Python tool via SSH
- Requires SSH access and a running host
- Validates deployed state, not Nix configuration
- Tests go in `tests/deploy/test_<hostname>.py`

---

## 5. Additional Testing Tools

### `nix eval` — Expression Spot-Checks
```bash
# Check a config attribute value without building
nix eval .#nixosConfigurations.thiniel.config.networking.firewall.enable

# Check multiple outputs exist
nix eval .#checks.aarch64-darwin --apply builtins.attrNames

# Inline expression test
nix eval --expr 'let h = import ./lib/helpers.nix; in builtins.length (h.mkFirefoxExtensions { addons = {}; }).common'
```
Use for fast spot-checks during Red phase before adding a full derivation.

### `flake-checker` — Input Health
```bash
nix run github:DeterminateSystems/flake-checker
```
Checks: nixpkgs on a supported branch, inputs updated within 30 days, inputs from NixOS org. Run periodically, not on every change.

### `nix-fast-build` — Parallel Check Execution
```bash
# Drop-in replacement for nix flake check with parallel eval+build
nix-fast-build

# Skip already-cached derivations
nix-fast-build --skip-cached
```
Add to devShell when the number of checks grows and `nix flake check` becomes slow.

### `passthru.tests` — Package Testing
For custom packages in `pkgs/`, attach tests as `passthru.tests`:
```nix
passthru.tests = {
  version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "my-tool --version";
  };
};
```
Wire into `flake.nix` checks: `checks.${system}.my-tool-version = pkgs.my-tool.passthru.tests.version;`

---

## 6. Platform Constraint Matrix

| Test Type | macOS (darwin) | Linux (NixOS) | Verify Command |
|---|---|---|---|
| `lib.debug.runTests` | Yes | Yes | `nix flake check` |
| NixOS `assertions` | Eval only (NixOS hosts) | Yes | `nix flake check --no-build` |
| `testers.runNixOSTest` | No (needs linux-builder) | Yes | `nix build .#checks.<linux-system>.<name>` |
| `flake-checker` | Yes | Yes | `nix run github:DeterminateSystems/flake-checker` |
| `pytest-testinfra` | Yes (SSH from devShell) | Yes | `pytest --hosts=ssh://...` |
| `nix eval` spot-checks | Yes | Yes | `nix eval .#...` |

---

## 7. Red-Green-Refactor Quick Reference

```
1. Red:    Write test  → nix flake check [--no-build]  → FAIL ✗
2. Green:  Implement   → nix flake check [--no-build]  → PASS ✓
3. Refactor:           → nix flake check               → PASS ✓
4. Deploy:             → pytest --hosts=ssh://...       → PASS ✓
```

### Choosing the Right Test

| Change Type | Test Layer | File Pattern |
|---|---|---|
| Pure Nix function | Unit | `tests/unit/<name>-test.nix` |
| Module option/constraint | Assertion | `tests/assertions/<name>-invariants.nix` |
| Service/firewall/network | Integration | `tests/integration/<name>-test.nix` |
| Post-deploy verification | Deploy | `tests/deploy/test_<host>.py` |
