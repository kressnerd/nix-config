← [Back to Index](00-index.md)

## Epic 6: SSH Hardening

**Goal**: Key-only SSH with bootstrap flag for initial WireGuard setup.

**Depends on**: Epic 3 (impermanence for host key persistence), Epic 4 (firewall for SSH port)

### Story 6.1: SSH Service Configuration

#### Step 6.1.1: Red — Assert SSH is enabled

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.services.openssh.enable == true`
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 6.1.1b: Red — Assert SSH AllowUsers restricts access

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.services.openssh.settings.AllowUsers` is non-empty and contains "dan" (or equivalent group restriction via `AllowGroups`)
- **Verify**: `nix flake check`
- **Expected**: FAIL (AllowUsers not yet configured)

#### Step 6.1.2: Green — Enable and harden SSH

- **File**: `hosts/cupix001/hardening.nix`
- **What to implement**: Create hardening module with:
  - `services.openssh.enable = true`
  - `services.openssh.settings.PasswordAuthentication = false`
  - `services.openssh.settings.KbdInteractiveAuthentication = false`
  - `services.openssh.settings.MaxAuthTries = 3`
  - `services.openssh.settings.PermitRootLogin = "prohibit-password"`
  - `services.openssh.settings.X11Forwarding = false`
  - `services.openssh.settings.AllowUsers = ["dan"]` — restrict SSH access to the `dan` user only
  - Import in `default.nix`.
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 6.2: SSH Listen Addresses

#### Step 6.2.1: Red — Assert SSH listens on WireGuard IP

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: SSH `listenAddresses` is configured (non-empty)
- **Verify**: `nix flake check`
- **Expected**: FAIL

#### Step 6.2.2: Green — Configure SSH listen addresses

- **File**: `hosts/cupix001/hardening.nix`
- **What to implement**: `services.openssh.listenAddresses` set to WireGuard tunnel IP (extracted from `config.networking.cupix001.wgTunnelIPv4` — needs IP without CIDR prefix). Conditionally add bootstrap listener on public IP + `sshBootstrapPort` when `enablePublicSSH` is true. Use `lib.mkMerge` with `lib.mkIf`.
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 6.3: SSH Host Key Persistence — Regression Checkpoint

**Note**: `/etc/ssh` persistence is already asserted and implemented in Epic 3 Story 3.2. This story is a cross-reference checkpoint only. Write the assertion (Step 6.3.1) BEFORE Story 3.2 is implemented to get a genuine Red; after 3.2 it will be Green. Do not write a separate assertion here — the one in 3.2.1 covers this.

**Reordering note for implementer**: If implementing in strict epic order, the Red for `/etc/ssh` persistence must be written as part of Story 3.2.1 (Red), not retroactively here. Epic 6 depends on Epic 3 being complete.

### Story 6.4: SSH Integration Test

#### Step 6.4.1: Red — Integration test: SSH hardening

- **Test type**: integration
- **File**: `tests/integration/cupix001-ssh-test.nix`
- **What to test**: Password auth disabled, MaxAuthTries 3, port 22 not on public interface, bootstrap port conditionally open, `AllowUsers` only "dan"
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-ssh`
- **Expected**: FAIL

#### Step 6.4.2: Green — Implement SSH integration test

- **File**: `tests/integration/cupix001-ssh-test.nix`
- **What to implement**: `pkgs.testers.runNixOSTest` testing:
  - `sshd -T | grep passwordauthentication` → "no"
  - `sshd -T | grep maxauthtries` → "3"
  - `sshd -T | grep allowusers` → "dan"
  - port 22 not listening on public-equivalent interface
- **File**: `tests/integration/default.nix`
- **What to implement**: Register `integration-cupix001-ssh`
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-ssh`
- **Expected**: PASS

### Story 6.5: SSH Host Key Stability Integration Test

#### Step 6.5.1: Red — Integration test: SSH host key survives reboot

- **Test type**: integration
- **File**: `tests/integration/cupix001-ssh-test.nix` (extend existing test)
- **What to test**: SSH host key fingerprint is identical before and after a reboot cycle — verifying that `/persist/etc/ssh` is correctly mounted and SSH keys are not regenerated on boot
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-ssh`
- **Expected**: FAIL (test not yet in the test script)

#### Step 6.5.2: Green — Add host key stability test to SSH integration test

- **File**: `tests/integration/cupix001-ssh-test.nix`
- **What to implement**: Add to the NixOS test script:
  ```python
  fp_before = machine.succeed("ssh-keygen -lf /persist/etc/ssh/ssh_host_ed25519_key.pub").strip()
  machine.shutdown()
  machine.start()
  machine.wait_for_unit("multi-user.target")
  fp_after = machine.succeed("ssh-keygen -lf /persist/etc/ssh/ssh_host_ed25519_key.pub").strip()
  assert fp_before == fp_after, f"SSH host key changed after reboot: {fp_before} != {fp_after}"
  ```
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-ssh`
- **Expected**: PASS

### Story 6.6: Bootstrap SSH Flag Integration Test

#### Step 6.6.1: Red — Integration test: enablePublicSSH flag controls port availability

- **Test type**: integration
- **File**: `tests/integration/cupix001-ssh-test.nix` (extend or add second test node)
- **What to test**:
  - Node A (`enablePublicSSH = true`): `ss -tlnp | grep ':55809'` succeeds
  - Node B (`enablePublicSSH = false`): `ss -tlnp | grep ':55809'` fails
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-ssh`
- **Expected**: FAIL (flag-flip test not yet in test script)

#### Step 6.6.2: Green — Add flag-flip test to SSH integration test

- **File**: `tests/integration/cupix001-ssh-test.nix`
- **What to implement**: Two NixOS test nodes in the same `runNixOSTest`:
  - `machine_public` with `networking.cupix001.enablePublicSSH = true`
  - `machine_wg_only` with `networking.cupix001.enablePublicSSH = false`
  - Test: `machine_public.succeed("ss -tlnp | grep ':55809'")`, `machine_wg_only.fail("ss -tlnp | grep ':55809'")`
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-ssh`
- **Expected**: PASS
