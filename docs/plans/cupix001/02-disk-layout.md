← [Back to Index](00-index.md)

## Epic 2: Disk Layout

**Goal**: Define disko configuration with btrfs subvolumes for impermanence.

**Depends on**: Epic 1

### Story 2.1: Disko Configuration

#### Step 2.1.1: Red — Assert disko device is configured

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.disko.devices.disk.vda.device == "/dev/vda"` (or verify `disko.devices` is non-empty)
- **Verify**: `nix flake check`
- **Expected**: FAIL (no disko config yet)

#### Step 2.1.1b: Red — Assert /persist and /var/log neededForBoot

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**:
  ```nix
  { assertion = config.fileSystems."/persist".neededForBoot;
    message = "cupix001: /persist must have neededForBoot = true — sops-nix requires /persist before secrets decryption"; }
  { assertion = config.fileSystems."/var/log".neededForBoot;
    message = "cupix001: /var/log must have neededForBoot = true — persistent logs require early mount"; }
  ```
- **Verify**: `nix flake check`
- **Expected**: FAIL (no disko config yet, fileSystems entries absent)

#### Step 2.1.2: Green — Create disko.nix with btrfs subvolumes

- **File**: `hosts/cupix001/disko.nix`
- **What to implement**: GPT partition table on `/dev/vda`, ESP partition (512M, fat32, `/boot`), root partition (remaining space, btrfs) with subvolumes: `@root` → `/`, `@persist` → `/persist`, `@nix` → `/nix`, `@log` → `/var/log`, `@swap` → `/swap` (2G swapfile). Set `fileSystems."/persist".neededForBoot = true` and `fileSystems."/var/log".neededForBoot = true`. Label root btrfs as `nixos`.
- **Also**: Import `./disko.nix` in `hosts/cupix001/default.nix`
- **Verify**: `nix flake check`
- **Expected**: PASS

#### Step 2.1.3: Refactor — Extract boot mode conditional

- **File**: `hosts/cupix001/disko.nix`, `hosts/cupix001/hardware.nix`
- **What to implement**: If user confirms BIOS: set `boot.loader.grub.device = "/dev/vda"`, no ESP partition. If UEFI: keep ESP + `boot.loader.systemd-boot.enable = true`. Add comment documenting which mode was detected.
- **Verify**: `nix flake check`
- **Expected**: PASS
