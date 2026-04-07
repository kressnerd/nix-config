← [Back to Index](00-index.md)

## Epic 11: Systemd Hardening

**Goal**: Restart policies and watchdog for all custom services.

**Depends on**: Epic 7 (Caddy), Epic 8 (DERP)

### Story 11.1: Service Restart Policies

#### Step 11.1.1: Red — Assert Caddy has restart policy

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.systemd.services.caddy.serviceConfig.Restart == "on-failure"` (or verify RestartSec is set)
- **Verify**: `nix flake check`
- **Expected**: FAIL (if NixOS default doesn't set this)

#### Step 11.1.1b: Red — Assert WatchdogSec is set on Caddy and derper

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**:
  ```nix
  { assertion = config.systemd.services.caddy.serviceConfig.WatchdogSec or "" != "";
    message = "cupix001: caddy.service must have WatchdogSec set (spec section 8: systemd hardening)"; }
  { assertion = config.systemd.services.derper.serviceConfig.WatchdogSec or "" != "";
    message = "cupix001: derper.service must have WatchdogSec set (spec section 8: systemd hardening)"; }
  ```
- **Verify**: `nix flake check`
- **Expected**: FAIL (WatchdogSec not yet set)

#### Step 11.1.1c: Red — Assert WireGuard service has restart policy

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.systemd.services."wireguard-wg0".serviceConfig.Restart or "always" != ""` — NixOS WireGuard module may set this by default; assertion ensures it stays configured regardless of upstream changes
- **Verify**: `nix flake check`
- **Expected**: PASS (if NixOS module already sets Restart) or FAIL (if not — then implement in Step 11.1.2)

**Note**: NixOS `networking.wireguard.interfaces` module already configures `Restart=always` for WireGuard services. This assertion is a regression sentinel — if it passes immediately, no Green step needed. If it fails, add `systemd.services."wireguard-wg0".serviceConfig.Restart = "always";` to `hosts/cupix001/networking.nix`.

#### Step 11.1.2: Green — Set restart policies and WatchdogSec

- **File**: `hosts/cupix001/caddy.nix`
- **What to implement**:
  ```nix
  systemd.services.caddy.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
    WatchdogSec = "30s";
  };
  ```
- **File**: `hosts/cupix001/derper.nix`
- **What to implement**: Same for derper service: `Restart = "on-failure"; RestartSec = "5s"; WatchdogSec = "30s";`
- **File**: `hosts/cupix001/networking.nix` (if WireGuard assertion failed)
- **What to implement**: `systemd.services."wireguard-wg0".serviceConfig = { Restart = "always"; RestartSec = "5s"; };` — only if NixOS module doesn't set restart by default
- **Verify**: `nix flake check`
- **Expected**: PASS
