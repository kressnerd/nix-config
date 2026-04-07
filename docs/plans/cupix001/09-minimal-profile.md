← [Back to Index](00-index.md)

## Epic 9: Minimal System Profile

**Goal**: Strip unnecessary packages, disable build tools.

**Depends on**: Epic 1

### Story 9.1: Remove Default Packages

#### Step 9.1.1: Red — Assert environment.defaultPackages is empty

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**:
  ```nix
  { assertion = config.environment.defaultPackages == [];
    message = "cupix001: environment.defaultPackages must be [] — NixOS default packages (perl, rsync, strace) must not be present on a hardened edge host"; }
  ```
- **Verify**: `nix flake check`
- **Expected**: FAIL (NixOS default packages present)

#### Step 9.1.1b: Red — Assert no build tools in system packages

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: None of `["gcc" "make" "cmake" "git" "curl" "wget"]` appear in `config.environment.systemPackages` pnames (does not catch `defaultPackages` — the assertion above covers that)
- **Verify**: `nix flake check`
- **Expected**: FAIL (common/global or default packages may include some)

#### Step 9.1.2: Green — Set minimal system packages

- **File**: `hosts/cupix001/hardening.nix`
- **What to implement**: `environment.defaultPackages = [];`, `environment.systemPackages` limited to `[pkgs.htop pkgs.tcpdump]` (diagnostics only). Set `nix.settings.trusted-users = ["root"];`
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 9.2: Minimal Profile Integration Test

#### Step 9.2.1: Red — Integration test: no gcc/git/make in PATH

- **Test type**: integration
- **File**: `tests/integration/cupix001-minimal-test.nix`
- **What to test**: `which gcc` fails, `which git` fails, `which make` fails
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-minimal`
- **Expected**: FAIL

#### Step 9.2.2: Green — Implement minimal profile integration test

- **File**: `tests/integration/cupix001-minimal-test.nix`
- **What to implement**: `pkgs.testers.runNixOSTest` with minimal packages config, verifying build tools are absent
- **File**: `tests/integration/default.nix`
- **What to implement**: Register `integration-cupix001-minimal`
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-minimal`
- **Expected**: PASS
