← [Back to Index](00-index.md)

## Epic 4: Networking & Firewall

**Goal**: Configure static networking and nftables default-deny firewall.

**Depends on**: Epic 1

### Story 4.1: Static Networking

#### Step 4.1.1: Red — Assert NetworkManager is disabled

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.networking.networkmanager.enable == false`
- **Verify**: `nix flake check`
- **Expected**: FAIL (common/global sets `networking.networkmanager.enable = true`)

#### Step 4.1.2: Green — Disable NetworkManager, configure static IP

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: Create networking module that consumes `config.networking.cupix001` (from `private.nix`), sets static IPv4/IPv6 addresses on `priv.interfaceName`, configures `defaultGateway`, `nameservers`. Import in `default.nix`. The `networking.networkmanager.enable = lib.mkForce false` is already in `default.nix` from Step 1.1.2.
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 4.2: nftables Firewall — Base

#### Step 4.2.1: Red — Assert nftables is enabled

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.networking.nftables.enable == true`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 4.2.2: Green — Enable nftables

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: `networking.nftables.enable = true; networking.firewall.enable = true;`
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 4.3: Firewall — HTTP/HTTPS Ports

#### Step 4.3.1: Red — Assert port 443 is allowed

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `builtins.elem 443 config.networking.firewall.allowedTCPPorts`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 4.3.2: Green — Allow ports 80, 443

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: `networking.firewall.allowedTCPPorts = [80 443];` (port 80 for ACME HTTP-01 fallback; can be removed once DNS-01 is confirmed working)
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 4.4: Firewall — STUN Port

#### Step 4.4.1: Red — Assert UDP 3478 is allowed

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `builtins.elem 3478 config.networking.firewall.allowedUDPPorts`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 4.4.2: Green — Allow UDP 3478

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: `networking.firewall.allowedUDPPorts = [3478];`
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 4.5: Firewall — WireGuard Port

#### Step 4.5.1: Red — Assert WireGuard UDP port is allowed

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `builtins.elem config.networking.cupix001.wgListenPort config.networking.firewall.allowedUDPPorts`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 4.5.2: Green — Allow WireGuard port from private.nix

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: Add `config.networking.cupix001.wgListenPort` to `networking.firewall.allowedUDPPorts`
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 4.6: Firewall — Bootstrap SSH Port

#### Step 4.6.1: Red — Assert bootstrap SSH port is conditionally allowed

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: When `config.networking.cupix001.enablePublicSSH == true`, `config.networking.cupix001.sshBootstrapPort` is in `config.networking.firewall.allowedTCPPorts`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 4.6.2: Green — Conditional bootstrap SSH port

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: `networking.firewall.allowedTCPPorts = lib.mkMerge [ [80 443] (lib.mkIf config.networking.cupix001.enablePublicSSH [config.networking.cupix001.sshBootstrapPort]) ];`
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 4.7: Firewall — No Standard SSH

#### Step 4.7.1: Red — Assert port 22 is NOT in public firewall rules

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `!(builtins.elem 22 config.networking.firewall.allowedTCPPorts)` — port 22 must never be open on public interface
- **Verify**: `nix flake check`
- **Expected**: PASS (port 22 was never added — guard rail for future changes)

**Note**: This is a "stay green" assertion — it should pass immediately. Added to prevent regressions.

### Story 4.8: Firewall — Stateful Connection Tracking and ICMP

#### Step 4.8.1: Red — Assert NixOS firewall stateful tracking is enabled (implied by firewall.enable)

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.networking.firewall.enable == true` AND `config.networking.nftables.enable == true` (NixOS nftables firewall includes `ct state established,related accept` and `ct state invalid drop` implicitly; assert both are set as a combined guard)
- **Verify**: `nix flake check`
- **Expected**: PASS (covered by Stories 4.2 — this is a regression sentinel ensuring both stay enabled)

**Note**: NixOS `networking.firewall` with `networking.nftables.enable = true` automatically generates the stateful tracking rules (`ct state established,related accept; ct state invalid drop`) and rate-limited ICMP rules. No explicit custom nftables ruleset is needed for these — they are provided by the NixOS module. The integration test (Story 4.9) will verify the generated nft ruleset contains these rules.

### Story 4.9: Firewall — IPv6 Rule Mirroring

#### Step 4.9.1: Red — Assert IPv6 addresses are configured

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.networking.cupix001.publicIPv6 != ""` — when IPv6 is available (confirmed in prerequisites), this must be set. Guard: `lib.mkIf (config.networking.cupix001.publicIPv6 != "")`
- **Verify**: `nix flake check`
- **Expected**: FAIL (options.nix defaults publicIPv6 to "", private.nix doesn't set it yet)

#### Step 4.9.2: Green — Configure IPv6 interface and extend firewall rules for IPv6

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: When `priv.publicIPv6 != ""`: add `networking.interfaces.${priv.interfaceName}.ipv6.addresses` with address and prefixLength; add `networking.defaultGateway6` with address and interface; set `networking.enableIPv6 = true`. The NixOS firewall with nftables automatically applies equivalent rules for both IPv4 and IPv6. Document with comment: `# IPv6 rules mirror IPv4 rules automatically via NixOS nftables firewall module`
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 4.10: Firewall — Integration Test (comprehensive)

#### Step 4.10.1: Red — Integration test: firewall rules

- **Test type**: integration
- **File**: `tests/integration/cupix001-firewall-test.nix`
- **What to test**: Standalone NixOS test node with nftables config mirroring cupix001. Verify:
  - ports 443/tcp, 3478/udp open; port 22 NOT open on public interface; bootstrap SSH port conditionally open
  - `nft list ruleset` contains `ct state established,related accept` (stateful tracking)
  - `nft list ruleset` contains `ct state invalid drop` (invalid packet drop)
  - `nft list ruleset` contains icmp/icmpv6 rate-limiting rule
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-firewall`
- **Expected**: FAIL (test not registered)

#### Step 4.10.2: Green — Register and implement firewall integration test

- **File**: `tests/integration/cupix001-firewall-test.nix`
- **What to implement**: `pkgs.testers.runNixOSTest` with node that enables nftables + firewall rules. Test script:
  1. Checks `nft list ruleset` for stateful tracking, invalid drop, ICMP, and port rules
  2. Verifies port states with `ss -tlnp` / `ss -ulnp`
  3. Tests with `enablePublicSSH = true` node: bootstrap port open; with separate `enablePublicSSH = false` node: bootstrap port not open
- **File**: `tests/integration/default.nix`
- **What to implement**: Register `integration-cupix001-firewall`
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-firewall`
- **Expected**: PASS

### Story 4.11: Firewall — WireGuard Trusted Interface

#### Step 4.11.1: Red — Assert wg0 is in trustedInterfaces

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `builtins.elem "wg0" config.networking.firewall.trustedInterfaces` — without this, all homelab traffic through the WireGuard tunnel is blocked by NixOS firewall default deny
- **Verify**: `nix flake check`
- **Expected**: FAIL (wg0 not in trustedInterfaces)

#### Step 4.11.2: Green — Add wg0 to trustedInterfaces

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: `networking.firewall.trustedInterfaces = ["wg0"];` — allows all traffic on the WireGuard interface (spec §2: "WireGuard interface (wg0): allow all (trusted)")
- **Verify**: `nix flake check`
- **Expected**: PASS
