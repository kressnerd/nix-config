← [Back to Index](00-index.md)

## Epic 12: VM Testing Setup

**Goal**: vmVariant with mocked values for local testing.

**Depends on**: Epic 3 (impermanence), Epic 5 (WireGuard), Epic 7 (Caddy)

### Story 12.1: vmVariant Configuration

#### Step 12.1.1: Red — Assert VM variant builds

- **Test type**: unit (build check)
- **File**: N/A — command-line validation
- **What to test**: `nix build .#nixosConfigurations.cupix001.config.system.build.vm` succeeds
- **Verify**: `nix build .#nixosConfigurations.cupix001.config.system.build.vm`
- **Expected**: FAIL (vmVariant not configured, sops secrets missing in VM context)

#### Step 12.1.2: Green — Add vmVariant overrides

- **File**: `hosts/cupix001/default.nix`
- **What to implement**: `virtualisation.vmVariant` block with: `virtualisation.memorySize = 2048`, `virtualisation.forwardPorts` (host 8443 → guest 443, host 8080 → guest 80), mock WireGuard (disable or dummy), self-signed TLS for Caddy, disable autoUpgrade, mock sops secret paths (use `pkgs.writeText` for dummy keys)
- **Verify**: `nix build .#nixosConfigurations.cupix001.config.system.build.vm`
- **Expected**: PASS
