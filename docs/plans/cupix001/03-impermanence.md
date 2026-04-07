← [Back to Index](00-index.md)

## Epic 3: Impermanence

**Goal**: Configure root-wipe mechanism and persistent path declarations.

**Depends on**: Epic 2

### Story 3.1: Root Wipe Mechanism

#### Step 3.1.1: Red — Assert initrd root-wipe command is configured

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.boot.initrd.postResumeCommands` contains "btrfs subvolume" (string match)
- **Verify**: `nix flake check`
- **Expected**: FAIL (no initrd commands configured)

#### Step 3.1.2: Green — Add root-wipe initrd commands

- **File**: `hosts/cupix001/impermanence.nix`
- **What to implement**: `boot.initrd.postResumeCommands = lib.mkAfter ''...''` with btrfs snapshot rollback of `@root` from `@root-blank`. Import in `default.nix`.
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 3.2: Persistent Paths

#### Step 3.2.1: Red — Assert /etc/ssh is persisted

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `"/etc/ssh"` appears in `config.environment.persistence."/persist/system".directories` (or equivalent impermanence path attribute)
- **Verify**: `nix flake check`
- **Expected**: FAIL (no persistence paths declared)

#### Step 3.2.1b: Red — Assert /var/lib/nixos is persisted (CRITICAL)

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**:
  ```nix
  { assertion = builtins.elem { directory = "/var/lib/nixos"; } config.environment.persistence."/persist/system".directories
      || builtins.any (d: (d.directory or d) == "/var/lib/nixos") config.environment.persistence."/persist/system".directories;
    message = "cupix001: /var/lib/nixos MUST be persisted — it holds the UID/GID map; missing it causes permission drift after every reboot"; }
  ```
- **Verify**: `nix flake check`
- **Expected**: FAIL (no persistence paths declared yet)

#### Step 3.2.2: Green — Declare persistent paths

- **File**: `hosts/cupix001/impermanence.nix`
- **What to implement**: `environment.persistence."/persist/system"` with directories:
  - `/etc/ssh` (SSH host keys — required for key stability across reboots)
  - `/var/lib/caddy` (ACME certs and Caddy state)
  - `/var/lib/nixos` (**CRITICAL**: UID/GID map — prevents permission drift after every reboot)
  - `/var/lib/systemd` (persistent timers, random-seed)
  - and files: `/etc/machine-id`, `/var/lib/sops-nix/key.txt` (only if using `sops.age.keyFile`; skip if using `sops.age.sshKeyPaths`)
  - Reserve path `/var/lib/crowdsec` with `# TODO Phase 2: CrowdSec LAPI` comment
  - **Note**: Do NOT include `/etc/nixos` — on a flake-managed host deployed via colmena/nixos-anywhere, this directory is empty and irrelevant; persisting it wastes space and causes confusion
- **Verify**: `nix flake check`
- **Expected**: PASS

#### Step 3.2.3: Red — Integration test: impermanence reboot

- **Test type**: integration
- **File**: `tests/integration/cupix001-impermanence-test.nix`
- **What to test**: Write file to `/root/test.txt` → reboot → file gone; write to `/persist/test.txt` → reboot → file survives; also verify btrfs subvolumes are correct: `btrfs subvolume list /` must contain `@root`, `@persist`, `@nix`, `@log`, `@swap` (spec §15 Layer 2: "btrfs subvolumes correct")
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-impermanence`
- **Expected**: FAIL (test not registered, VM config not complete enough)

**Note**: This integration test may need to be deferred until Epic 12 (VM Testing Setup) provides the full vmVariant. Register the test file but create a standalone NixOS test node that mimics the impermanence setup without requiring the full cupix001 config.

#### Step 3.2.4: Green — Register integration test, implement minimal VM node

- **File**: `tests/integration/cupix001-impermanence-test.nix`
- **What to implement**: Standalone `pkgs.testers.runNixOSTest` with a minimal btrfs + impermanence node (not the full cupix001 config), testing file persistence across reboot. Also add: `machine.succeed("btrfs subvolume list / | grep -q '@root'")`, `machine.succeed("btrfs subvolume list / | grep -q '@persist'")`, etc. for all 5 expected subvolumes
- **File**: `tests/integration/default.nix`
- **What to implement**: Register `integration-cupix001-impermanence`
- **Verify**: `nix build .#checks.x86_64-linux.integration-cupix001-impermanence`
- **Expected**: PASS
