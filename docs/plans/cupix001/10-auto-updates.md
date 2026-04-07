← [Back to Index](00-index.md)

## Epic 10: Auto Updates

**Goal**: Enable automatic security updates with reboot window.

**Depends on**: Epic 1

### Story 10.1: AutoUpgrade Configuration

#### Step 10.1.1: Red — Assert autoUpgrade is enabled

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.system.autoUpgrade.enable == true`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 10.1.2: Green — Enable autoUpgrade

- **File**: `hosts/cupix001/default.nix`
- **What to implement**: `system.autoUpgrade.enable = true; system.autoUpgrade.allowReboot = true; system.autoUpgrade.rebootWindow = { lower = "03:00"; upper = "05:00"; }; system.autoUpgrade.flake = "github:user/nix-config#cupix001";` (placeholder flake URL)
- **Verify**: `nix flake check`
- **Expected**: PASS
