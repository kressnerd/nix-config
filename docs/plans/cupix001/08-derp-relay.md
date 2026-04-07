← [Back to Index](00-index.md)

## Epic 8: DERP Relay

**Goal**: Standalone derper service proxied through Caddy.

**Depends on**: Epic 5 (WireGuard), Epic 7 (Caddy for TLS termination)

### Story 8.1: Derper Service

#### Step 8.1.1: Red — Assert derper service is configured

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.systemd.services ? "derper"` (or check for a custom derper systemd unit)
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 8.1.2: Green — Create derper service module

- **File**: `hosts/cupix001/derper.nix`
- **What to implement**: Custom systemd service for `derper` binary (from `pkgs.tailscale` or dedicated package). Configure `--hostname=derp.example.de`, `--certmode=manual`, `--stun`, `--a=:3478`, `--http-port=<localhost-port>`. Set `DynamicUser=true`. Import in `default.nix`.
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 8.2: Derper Integration Test

#### Step 8.2.1: Red — Integration test: derper running

- **Test type**: integration
- **File**: `tests/integration/cupix001-derper-test.nix`
- **What to test**: `derper.service` running, STUN port 3478/udp listening, HTTP port listening on localhost
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-derper`
- **Expected**: FAIL

#### Step 8.2.2: Green — Implement derper integration test

- **File**: `tests/integration/cupix001-derper-test.nix`
- **What to implement**: `pkgs.testers.runNixOSTest` verifying derper systemd unit and port bindings
- **File**: `tests/integration/default.nix`
- **What to implement**: Register `integration-cupix001-derper`
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-derper`
- **Expected**: PASS
