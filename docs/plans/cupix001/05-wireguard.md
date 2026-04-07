← [Back to Index](00-index.md)

## Epic 5: WireGuard Tunnel

**Goal**: Point-to-point WireGuard tunnel to homelab, private key via sops-nix.

**Depends on**: Epic 3 (impermanence for key persistence), Epic 4 (firewall for WG port)

### Story 5.1: WireGuard Interface

#### Step 5.1.1: Red — Assert WireGuard interface wg0 is configured

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.networking.wireguard.interfaces ? wg0`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 5.1.2: Green — Configure WireGuard wg0

- **File**: `hosts/cupix001/networking.nix`
- **What to implement**: `networking.wireguard.interfaces.wg0` with `listenPort = priv.wgListenPort`, `privateKeyFile = config.sops.secrets."wireguard/private-key".path`, `ips = [priv.wgTunnelIPv4]`, peer with:
  - `publicKey = "HOMELAB_WG_PUBKEY_HERE"` (not sensitive, public repo)
  - `allowedIPs = ["10.100.0.0/30"]`
  - **Do NOT set `persistentKeepalive`** on this side — cupix001 is the passive endpoint (listens); the homelab side initiates. Setting `persistentKeepalive` on the passive endpoint is harmless but misleading. The spec states "homelab initiates (PersistentKeepalive = 25)" — configure that on the homelab IPFire config, not here. Add a comment: `# persistentKeepalive is set on the homelab side (IPFire), not here — cupix001 is the passive listener`
- **Also**: Add `sops.secrets."wireguard/private-key"` definition in `default.nix` or a dedicated secrets section
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 5.2: WireGuard Sops Secret — Regression Guard

**Note**: This story documents a regression sentinel assertion, not a new Red-Green cycle. The `sops.secrets."wireguard/private-key"` declaration is implemented as part of Story 5.1.2 (Green). This assertion is written BEFORE Story 5.1.2 as a Red step to confirm the test fails, then passes after 5.1.2.

#### Step 5.2.1: Red — Assert WireGuard private key is declared in sops secrets

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.sops.secrets ? "wireguard/private-key"` — write this assertion BEFORE implementing Story 5.1.2 to get a genuine Red confirmation
- **Verify**: `nix flake check`
- **Expected**: FAIL (sops secret not yet declared — write assertion first, then implement 5.1.2)

### Story 5.3: WireGuard Integration Test

#### Step 5.3.1: Red — Integration test: WireGuard service running

- **Test type**: integration
- **File**: `tests/integration/cupix001-wireguard-test.nix`
- **What to test**: WireGuard interface `wg0` exists, listening on configured port, interface has IP
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-wireguard`
- **Expected**: FAIL

#### Step 5.3.2: Green — Implement WireGuard integration test

- **File**: `tests/integration/cupix001-wireguard-test.nix`
- **What to implement**: `pkgs.testers.runNixOSTest` with node that has WireGuard configured with dummy keys (generated in test). Verify: `ip link show wg0` succeeds, `ss -ulnp | grep <port>` succeeds
- **File**: `tests/integration/default.nix`
- **What to implement**: Register `integration-cupix001-wireguard`
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-wireguard`
- **Expected**: PASS
