← [Back to Index](00-index.md)

## Epic 7: Caddy Reverse Proxy

**Goal**: Custom Caddy build with DNS-01 plugin, forward_auth to Authentik, security headers.

**Depends on**: Epic 5 (WireGuard for backend routing), Epic 6 (SSH for management)

### Story 7.1: Caddy Service — Basic

#### Step 7.1.1: Red — Assert Caddy is enabled

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.services.caddy.enable == true`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 7.1.2: Green — Enable Caddy service

- **File**: `hosts/cupix001/caddy.nix`
- **What to implement**: Create Caddy module with `services.caddy.enable = true`. Import in `default.nix`.
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 7.2: Custom Caddy Build with DNS Plugin

#### Step 7.2.1: Red — Assert Caddy package includes netcup DNS plugin AND version >= 2.9.2

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**:
  ```nix
  { assertion = config.services.caddy.package.pname != "caddy" ||
        builtins.compareVersions config.services.caddy.package.version "2.9.2" >= 0;
    message = "cupix001: services.caddy.package must be a custom build (not default caddy) AND version >= 2.9.2 (CVE GHSA-7r4p-vjf4-gxv4 — forward_auth header injection)"; }
  ```
  Also assert the custom package is detected:
  ```nix
  { assertion = config.services.caddy.package != pkgs.caddy;
    message = "cupix001: services.caddy.package must be a custom build with caddy-dns/netcup plugin"; }
  ```
- **Verify**: `nix flake check`
- **Expected**: FAIL (using default caddy, no version check yet)

#### Step 7.2.2: Green — Build custom Caddy with caddy-dns/netcup, verify version >= 2.9.2

- **File**: `hosts/cupix001/caddy.nix`
- **What to implement**: Override Caddy package using `pkgs.caddy.withPlugins` (or `pkgs.buildGoModule` overlay) to include `github.com/caddy-dns/netcup`. Set `services.caddy.package` to the custom build.
- **Note**: If `pkgs.caddy.withPlugins` is not available in the pinned nixpkgs, use an overlay in `overlays/caddy-netcup/default.nix`. In either case, verify the resulting package version is >= 2.9.2 before committing: `nix eval .#nixosConfigurations.cupix001.config.services.caddy.package.version`
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 7.3: ACME Configuration

#### Step 7.3.1: Red — Assert Caddy ACME email is configured

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.services.caddy.globalConfig` contains "email" (string match) or `config.services.caddy.acmeCA` is set
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 7.3.2: Green — Configure ACME with DNS-01

- **File**: `hosts/cupix001/caddy.nix`
- **What to implement**: Set Caddy `globalConfig` with ACME email (placeholder), configure DNS-01 challenge via netcup module. Add sops secrets for `netcup/ccp-api-key`, `netcup/ccp-api-password`, `netcup/ccp-customer-number`. Pass credentials via environment variables to Caddy systemd unit. Also set Caddy log format in globalConfig: `log { output stderr; format console; }` or `format json` as preferred (spec §4: "Global options: email for ACME, log format")
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 7.4: Caddy Sops Secrets — Regression Guard

**Note**: The `netcup/ccp-api-key`, `netcup/ccp-api-password`, and `netcup/ccp-customer-number` sops secret declarations are implemented as part of Story 7.3.2 (Green). Write Step 7.4.1 BEFORE Story 7.3.2 to get a genuine Red confirmation, then 7.3.2 makes it Green.

#### Step 7.4.1: Red — Assert netcup CCP API secrets are declared in sops

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: All three CCP secrets are declared:
  ```nix
  { assertion = config.sops.secrets ? "netcup/ccp-api-key"; message = "..."; }
  { assertion = config.sops.secrets ? "netcup/ccp-api-password"; message = "..."; }
  { assertion = config.sops.secrets ? "netcup/ccp-customer-number"; message = "..."; }
  ```
- **Verify**: `nix flake check`
- **Expected**: FAIL (write assertion before Story 7.3.2 implementation)

### Story 7.5: Security Headers

#### Step 7.5.1: Red — Assert Caddy config contains HSTS header

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: Caddy virtual host configuration or `extraConfig` contains "Strict-Transport-Security" (string match on the Caddyfile/JSON)
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 7.5.2: Green — Add security headers snippet

- **File**: `hosts/cupix001/caddy.nix`
- **What to implement**: Add `header` directives for HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, Permissions-Policy to a reusable snippet applied to all virtual hosts
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 7.6: Forward Auth to Authentik — with Header Stripping

#### Step 7.6.1: Red — Assert Caddy config contains forward_auth directive

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: Caddy virtual host configuration contains "forward_auth" string
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 7.6.1b: Red — Assert Caddy config strips client-supplied auth headers (SECURITY CRITICAL)

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: The Caddy config string contains all four `header_up` strip directives — these MUST appear before the `forward_auth` directive to prevent client header injection (CVE GHSA-7r4p-vjf4-gxv4 class):
  ```nix
  { assertion = lib.hasInfix "header_up -Remote-User" config.services.caddy.virtualHosts.<name>.extraConfig;
    message = "cupix001: Caddy MUST strip Remote-User header before forward_auth to prevent identity injection"; }
  ```
  Check for all four: `header_up -Remote-User`, `header_up -Remote-Groups`, `header_up -Remote-Email`, `header_up -Remote-Name`
- **Verify**: `nix flake check`
- **Expected**: FAIL (strip directives not yet in config)

#### Step 7.6.2: Green — Configure forward_auth with header stripping for virtual hosts

- **File**: `hosts/cupix001/caddy.nix`
- **What to implement**: For each of ~4 placeholder service virtual hosts:
  1. **Strip client-supplied headers FIRST** (before forward_auth reaches Authentik):
     ```
     header_up -Remote-User
     header_up -Remote-Groups
     header_up -Remote-Email
     header_up -Remote-Name
     ```
  2. `forward_auth` to Authentik (via WireGuard tunnel IP from private.nix, port 9443), URI `/outpost.goauthentik.io/auth/caddy`
  3. `copy_headers Remote-User Remote-Groups Remote-Email Remote-Name` (copy Authentik's response headers to backend request)
  4. `reverse_proxy` to homelab backend via WireGuard tunnel IP
  - Also configure `auth.example.de` as `reverse_proxy` to Authentik, and DERP subdomain to localhost
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 7.7: Caddy Data Persistence — with Integration Test

#### Step 7.7.1: Red — Assert Caddy data dir is persisted

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: Write this assertion BEFORE Story 3.2.2 to get a genuine Red. `/var/lib/caddy` is in impermanence persistent directories. After Story 3.2.2 implements it, this assertion will be Green.

**Reordering note**: The assertion for `/var/lib/caddy` must be written as part of Story 3.2.1 Red scope (alongside `/etc/ssh`). If implementing in strict epic order, this step is a cross-reference verification, not a new assertion.

#### Step 7.7.2: Red — Integration test: Caddy state persists across reboot

- **Test type**: integration
- **File**: `tests/integration/cupix001-caddy-test.nix` (add to existing Caddy integration test)
- **What to test**: Caddy `/persist/var/lib/caddy` directory survives reboot cycle:
  ```python
  machine.succeed("test -d /persist/var/lib/caddy")
  machine.shutdown()
  machine.start()
  machine.wait_for_unit("caddy.service")
  machine.succeed("test -d /persist/var/lib/caddy")
  ```
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-caddy`
- **Expected**: FAIL (reboot test not yet in test script)

#### Step 7.7.3: Green — Add Caddy persistence reboot test to integration test

- **File**: `tests/integration/cupix001-caddy-test.nix`
- **What to implement**: Add reboot persistence test as shown above in the NixOS test script (the test node must have btrfs + impermanence configured matching the cupix001 setup)
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-caddy`
- **Expected**: PASS

### Story 7.8: Caddy Integration Test

#### Step 7.8.1: Red — Integration test: Caddy service running

- **Test type**: integration
- **File**: `tests/integration/cupix001-caddy-test.nix`
- **What to test**: `caddy.service` is running, port 443 listening, response includes security headers, DERP route works, zero failed systemd units (`systemctl --failed` returns empty)
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-caddy`
- **Expected**: FAIL

#### Step 7.8.2: Green — Implement Caddy integration test

- **File**: `tests/integration/cupix001-caddy-test.nix`
- **What to implement**: `pkgs.testers.runNixOSTest` with Caddy configured with self-signed TLS. Verify: `systemctl is-active caddy.service`, `curl -sk https://localhost` returns headers, port 443 listening. Also verify: `machine.succeed("systemctl --failed | grep -c '0 loaded' || [ $(systemctl --failed --no-legend | wc -l) -eq 0 ]")` — no failed units
- **File**: `tests/integration/default.nix`
- **What to implement**: Register `integration-cupix001-caddy`
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-caddy`
- **Expected**: PASS
