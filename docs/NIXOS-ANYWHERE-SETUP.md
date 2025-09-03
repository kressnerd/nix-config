# NixOS Anywhere + Disko Setup Guide

This guide covers using nixos-anywhere with disko for automated, declarative NixOS deployments to VMs and bare metal systems.

## Overview

**nixos-anywhere** automates NixOS installation on remote machines by:

- Booting a minimal NixOS installer
- Partitioning and formatting disks according to your disko specification
- Installing your full NixOS configuration
- Rebooting into your configured system

**disko** provides declarative disk management by:

- Defining partitioning schemes in Nix
- Creating filesystems and mount points
- Handling encryption, LVM, ZFS, etc.
- Ensuring reproducible disk layouts

## What's Changed

### New Files Added

- **[`hosts/nixos-vm-minimal/disko.nix`](../hosts/nixos-vm-minimal/disko.nix)** - Declarative disk configuration
- **[`scripts/deploy-vm.sh`](../scripts/deploy-vm.sh)** - nixos-anywhere deployment script

### Modified Files

- **[`flake.nix`](../flake.nix)** - Added disko and nixos-anywhere inputs
- **[`hosts/nixos-vm-minimal/default.nix`](../hosts/nixos-vm-minimal/default.nix)** - Imports disko configuration
- **[`hosts/nixos-vm-minimal/hardware.nix`](../hosts/nixos-vm-minimal/hardware.nix)** - Removed manual filesystem definitions
- **[`scripts/build-vm.sh`](../scripts/build-vm.sh)** - Added deploy command integration

## Quick Start

### 1. Prepare Your System

```bash
# Setup SSH keys for deployment
./scripts/deploy-vm.sh prepare

# Generate UTM VM configuration
./scripts/build-vm.sh generate-utm nixos-vm-minimal
```

### 2. Setup VM in UTM

1. Import the generated UTM configuration
2. Create a new 20GB+ disk image
3. Download and attach NixOS installer ISO
4. Boot VM from ISO

### 3. Enable SSH in Installer

```bash
# In the VM installer terminal:
sudo systemctl start sshd
sudo passwd nixos  # Set password for SSH access
ip addr show       # Note the VM's IP address
```

### 4. Deploy NixOS

```bash
# Test SSH connectivity first
./scripts/deploy-vm.sh check-ssh nixos-vm-minimal <VM_IP>

# Deploy your configuration
./scripts/deploy-vm.sh deploy nixos-vm-minimal <VM_IP>
```

The deployment will:

- Connect to your VM via SSH
- Partition the disk according to disko configuration
- Install NixOS with your complete configuration
- Reboot into your configured system

## Deployment Script Commands

### Basic Usage

```bash
./scripts/deploy-vm.sh [COMMAND] [VM_NAME] [VM_IP]
```

### Commands

#### `prepare`

Setup SSH keys for deployment:

```bash
./scripts/deploy-vm.sh prepare
```

#### `check-ssh`

Test SSH connectivity to target VM:

```bash
./scripts/deploy-vm.sh check-ssh nixos-vm-minimal 192.168.64.2
```

#### `deploy`

Deploy NixOS configuration using nixos-anywhere:

```bash
./scripts/deploy-vm.sh deploy nixos-vm-minimal 192.168.64.2
```

#### `deploy-local`

Deploy to default local VM IP:

```bash
./scripts/deploy-vm.sh deploy-local nixos-vm-minimal
```

#### `generate-iso`

Generate nixos-anywhere compatible installer ISO:

```bash
./scripts/deploy-vm.sh generate-iso nixos-vm-minimal
```

### Advanced Options

```bash
# Custom SSH user
./scripts/deploy-vm.sh deploy nixos-vm-minimal 192.168.64.2 --user root

# Custom SSH key
./scripts/deploy-vm.sh deploy nixos-vm-minimal 192.168.64.2 --key ~/.ssh/custom_key

# Dry run (show what would be deployed)
./scripts/deploy-vm.sh deploy nixos-vm-minimal 192.168.64.2 --dry-run
```

## Disko Configuration

The disko configuration ([`hosts/nixos-vm-minimal/disko.nix`](../hosts/nixos-vm-minimal/disko.nix)) defines:

### Disk Layout

- **GPT partition table** on `/dev/vda`
- **512MB EFI System Partition** (`/boot`) - FAT32
- **Remaining space** for root (`/`) - ext4

### Optimizations

- VM-specific kernel modules for virtio devices
- Proper disk label handling during boot
- Mount options optimized for VM performance

### Customization

To modify the disk layout, edit [`hosts/nixos-vm-minimal/disko.nix`](../hosts/nixos-vm-minimal/disko.nix):

```nix
# Example: Add swap partition
swap = {
  priority = 3;
  size = "2G";
  content = {
    type = "swap";
  };
};
```

## UTM Integration

### Generated UTM Configuration

The [`scripts/build-vm.sh generate-utm`](../scripts/build-vm.sh) command creates VM configurations optimized for different use cases:

- **nixos-vm-minimal**: 4GB RAM, 4 cores, standard graphics
- **thiniel-vm**: 8GB RAM, 6 cores, enhanced graphics for Wayland

### VM Setup Process

1. **Create VM** - Import generated UTM configuration
2. **Attach Disk** - Create 20GB+ disk image
3. **Boot Installer** - Use NixOS installer ISO
4. **Enable SSH** - In installer: `sudo systemctl start sshd`
5. **Deploy** - Run deployment script from host

## Comparison: Traditional vs nixos-anywhere

### Traditional Manual Installation

```bash
# 1. Boot installer ISO
# 2. Manual partitioning
sudo fdisk /dev/vda
sudo mkfs.ext4 /dev/vda2
sudo mkfs.fat -F 32 /dev/vda1

# 3. Mount filesystems
sudo mount /dev/vda2 /mnt
sudo mkdir /mnt/boot
sudo mount /dev/vda1 /mnt/boot

# 4. Generate config
sudo nixos-generate-config --root /mnt

# 5. Edit configuration files manually
sudo nano /mnt/etc/nixos/configuration.nix

# 6. Install
sudo nixos-install

# 7. Reboot and configure system
```

### nixos-anywhere + disko

```bash
# 1. Boot installer ISO
# 2. Enable SSH
sudo systemctl start sshd
sudo passwd nixos

# 3. Deploy from host machine
./scripts/deploy-vm.sh deploy nixos-vm-minimal <VM_IP>
# Done! Fully configured system ready
```

## Benefits

### Reproducible Deployments

- **Declarative disk layout** - Same partitioning every time
- **Complete system configuration** - No manual post-install steps
- **Version controlled** - All changes tracked in git

### Automation

- **One-command deployment** - From installer to configured system
- **SSH-based** - Deploy from any machine with network access
- **Error handling** - Built-in validation and safety checks

### Flexibility

- **Multiple targets** - VMs, bare metal, cloud instances
- **Custom configurations** - Easy to modify for different use cases
- **Integration** - Works with existing Nix flake workflows

## Troubleshooting

### SSH Connection Issues

```bash
# Check VM IP address
# In VM: ip addr show

# Test basic connectivity
ping <VM_IP>

# Test SSH service
nc -zv <VM_IP> 22

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
```

### Deployment Failures

```bash
# Run with verbose output
nix run github:nix-community/nixos-anywhere -- --flake .#nixos-vm-minimal --verbose nixos@<VM_IP>

# Check disk space
# In VM: df -h

# Verify disko configuration
nix build .#nixosConfigurations.nixos-vm-minimal.config.system.build.diskoScript
```

### UTM Specific Issues

- **Network connectivity** - Ensure VM network mode is "Shared"
- **Boot order** - ISO should boot first, then disk after deployment
- **Disk size** - Minimum 10GB, recommended 20GB+
- **Memory** - Minimum 2GB, recommended 4GB+

## Security Considerations

### SSH Keys

- Use strong SSH keys (RSA 4096-bit or Ed25519)
- Keep private keys secure and encrypted
- Use different keys for different environments

### Network Security

- Deploy over trusted networks only
- Consider VPN for remote deployments
- Disable SSH password authentication after key setup

### Disk Encryption

To add disk encryption, modify the disko configuration:

```nix
# In disko.nix
content = {
  type = "luks";
  name = "crypted";
  content = {
    type = "filesystem";
    format = "ext4";
    mountpoint = "/";
  };
};
```

## Next Steps

1. **Test the deployment** - Try deploying to a VM
2. **Customize disko config** - Adapt disk layout for your needs
3. **Add more configurations** - Create variations for different use cases
4. **Automate with CI/CD** - Integrate with your deployment pipeline
5. **Scale to bare metal** - Use same workflow for physical machines

## Related Documentation

- **[VM-SETUP.md](VM-SETUP.md)** - Traditional VM setup guide
- **[THINIEL-VM-SETUP.md](THINIEL-VM-SETUP.md)** - Full desktop VM configuration
- **[nixos-anywhere documentation](https://github.com/nix-community/nixos-anywhere)**
- **[disko documentation](https://github.com/nix-community/disko)**

## Support

For issues and questions:

- Check this documentation thoroughly
- Test configurations with `--dry-run` first
- Use `--verbose` flags for detailed error information
- Review disko and nixos-anywhere documentation for advanced use cases
