# Scripts

Deployment and VM management scripts. These are complex shell scripts that have not yet been migrated to Nix derivations in `pkgs/`.

## build-vm-test.sh

Builds VM test images for `pronix-vm` and `cupix001-vm` configurations.

**Usage:**
```bash
scripts/build-vm-test.sh pronix-vm
scripts/build-vm-test.sh cupix001-vm
```

Runs `nix flake check --no-build` first, then builds system closures.

## build-vm.sh

Multi-purpose VM management script supporting multiple commands.

**Usage:**
```bash
scripts/build-vm.sh check
scripts/build-vm.sh build-iso
scripts/build-vm.sh build-vm
scripts/build-vm.sh generate-utm
scripts/build-vm.sh deploy
```

Generates UTM JSON config templates. Targets `nixos-vm-minimal` and `thiniel-vm` configurations.

## deploy-vm.sh

Deploys NixOS to VMs via nixos-anywhere. Handles SSH setup, LUKS encryption password provisioning, and nixos-anywhere orchestration.

**Usage:**
```bash
scripts/deploy-vm.sh deploy <host> <ip>
```

Default target: `nixos-vm-minimal` at `192.168.64.2`.

**Requirements:** `nixos-anywhere` (available via `nix-shell` or `nix develop`)
