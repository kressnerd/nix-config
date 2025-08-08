# NixOS VM Setup Guide for UTM on macOS

This guide covers setting up and using the NixOS virtual machine configuration within your existing nix-config repository.

## Overview

The VM configuration provides:

- **Minimal NixOS system** optimized for UTM virtualization
- **Home Manager integration** with cross-platform feature modules
- **SSH access** for development and management
- **Incremental enhancement** capabilities
- **Clean integration** with existing Darwin configuration

## Prerequisites

### Required Software

- **UTM** - Download from [getutm.app](https://getutm.app) or Mac App Store
- **NixOS Installation ISO** - ARM64 version for Apple Silicon
- **SSH client** - Built into macOS Terminal

### Optional: Remote Builder Setup

For building NixOS systems on macOS, you'll need either:

- A remote Linux builder configured in Nix
- GitHub Actions for automated builds
- Access to a Linux environment

## Quick Start

### 1. Validate Configuration

First, ensure your VM configuration is valid:

```bash
# Check flake configuration
./scripts/build-vm.sh check

# Alternative: direct flake check
nix flake check
```

### 2. Create UTM VM Configuration

Generate a UTM configuration template:

```bash
./scripts/build-vm.sh generate-utm
```

This creates `vm-utm-config.json` with optimized settings for NixOS on Apple Silicon.

### 3. Download NixOS ISO

Download the ARM64 NixOS installation ISO:

```bash
# Visit https://nixos.org/download.html
# Download: nixos-minimal-XX.XX-aarch64-linux.iso
```

### 4. Create VM in UTM

1. Open UTM
2. Click "Create a New Virtual Machine"
3. Select "Virtualize" (not Emulate)
4. Choose "Linux"
5. Configure VM:
   - **RAM**: 4GB (minimum), 8GB recommended
   - **CPU**: 4 cores
   - **Storage**: 32GB minimum, 64GB recommended
   - **Network**: Shared Network
6. Attach the NixOS ISO to the CD/DVD drive
7. Boot the VM

## Installation Process

### 1. Boot NixOS Installer

1. Start the VM in UTM
2. Boot from the ISO (should happen automatically)
3. Wait for the installer to load
4. Choose terminal-based installation

### 2. Partition Disk

```bash
# Create partition table (in VM terminal)
sudo fdisk /dev/vda

# Create partitions:
# - /dev/vda1: Root partition (ext4)
# - /dev/vda2: Swap partition (optional)

# Format partitions
sudo mkfs.ext4 /dev/vda1
sudo mkswap /dev/vda2  # if using swap

# Mount root
sudo mount /dev/vda1 /mnt
sudo swapon /dev/vda2  # if using swap
```

### 3. Generate Hardware Configuration

```bash
# Generate hardware config
sudo nixos-generate-config --root /mnt

# This creates /mnt/etc/nixos/configuration.nix and hardware-configuration.nix
```

### 4. Replace with Your Configuration

```bash
# Remove generated config
sudo rm -rf /mnt/etc/nixos/*

# Clone your nix-config (requires internet)
cd /mnt/etc
sudo git clone https://github.com/yourusername/nix-config.git nixos

# Or copy files manually if git not available
```

### 5. Install NixOS

```bash
# Install using your flake configuration
sudo nixos-install --flake '/mnt/etc/nixos#nixos-vm-minimal'

# Set root password when prompted
sudo nixos-enter --root /mnt -c 'passwd root'

# Create your user password
sudo nixos-enter --root /mnt -c 'passwd dan'
```

### 6. Reboot and Configure SSH

```bash
# Reboot VM
sudo reboot

# After reboot, get VM IP address
ip addr show

# From macOS, add your SSH key to the VM
ssh-copy-id dan@<VM_IP_ADDRESS>
```

## Repository Structure

The VM integration adds these files to your existing repository:

```
nix-config/
├── flake.nix                     # Updated with nixosConfigurations
├── hosts/
│   ├── J6G6Y9JK7L/              # Existing macOS host
│   └── nixos-vm-minimal/         # New VM host
│       ├── default.nix           # System configuration
│       ├── hardware.nix          # UTM hardware config
│       └── home.nix              # User setup
├── home/dan/
│   ├── features/                 # Cross-platform features
│   ├── J6G6Y9JK7L.nix           # macOS Home Manager
│   └── nixos-vm-minimal.nix      # VM Home Manager
├── scripts/
│   └── build-vm.sh               # VM build utilities
└── docs/
    └── VM-SETUP.md               # This guide
```

## Available Build Commands

### Flake Outputs

```bash
# Build Darwin system (macOS)
nix build .#darwinConfigurations.J6G6Y9JK7L.system

# Build NixOS VM system (requires remote builder)
nix build .#nixosConfigurations.nixos-vm-minimal.config.system.build.toplevel

# Build VM ISO (requires remote builder)
nix build .#nixosConfigurations.nixos-vm-minimal.config.system.build.isoImage
```

### Script Commands

```bash
# Validate configuration
./scripts/build-vm.sh check

# Generate UTM config template
./scripts/build-vm.sh generate-utm

# Build VM system (requires remote builder)
./scripts/build-vm.sh build-vm

# Build installation ISO (requires remote builder)
./scripts/build-vm.sh build-iso
```

## VM Management

### Rebuilding the System

From within the VM:

```bash
# Quick rebuild
rebuild

# Update and rebuild
update

# Manual rebuild
sudo nixos-rebuild switch --flake ~/nix-config
```

### SSH Access from macOS

```bash
# SSH into VM (replace with actual IP)
ssh dan@192.168.64.X

# Use VM aliases
ssh nixos-vm  # if added to ~/.ssh/config
```

### Sharing Files

Mount a shared folder in UTM:

1. VM Settings → Sharing
2. Add a directory from macOS
3. Mount in VM: `sudo mount -t 9p -o trans=virtio share /mnt/shared`

## Feature Module Compatibility

### Working Features

These feature modules work in both Darwin and NixOS:

- ✅ [`features/cli/git.nix`](../home/dan/features/cli/git.nix) - Git configuration
- ✅ [`features/cli/vim.nix`](../home/dan/features/cli/vim.nix) - Vim setup
- ✅ [`features/cli/zsh.nix`](../home/dan/features/cli/zsh.nix) - Shell configuration
- ✅ [`features/cli/starship.nix`](../home/dan/features/cli/starship.nix) - Prompt

### Platform-Specific Features

These features are Darwin-only and excluded from VM:

- ❌ [`features/macos/defaults.nix`](../home/dan/features/macos/defaults.nix) - macOS system preferences
- ❌ Homebrew integrations
- ❌ macOS-specific applications

## Troubleshooting

### Common Issues

**VM won't boot:**

- Ensure ARM64 ISO is used on Apple Silicon
- Check UTM virtualization settings (not emulation)
- Verify sufficient RAM allocation (4GB minimum)

**Network connectivity issues:**

- Use "Shared Network" mode in UTM
- Check if NetworkManager is running: `systemctl status NetworkManager`
- Restart networking: `sudo systemctl restart NetworkManager`

**SSH connection refused:**

- Verify SSH service: `systemctl status sshd`
- Check firewall: `sudo iptables -L`
- Confirm VM IP: `ip addr show`

**Home Manager activation fails:**

- Check for conflicting configurations
- Review feature module compatibility
- Use `home-manager switch --show-trace` for debugging

**Build failures on macOS:**

- Configuration is valid if `nix flake check` passes
- Actual building requires remote Linux builder
- Consider using GitHub Actions for automated builds

### Performance Optimization

**VM Performance:**

- Allocate 8GB+ RAM for better performance
- Use 4+ CPU cores
- Enable hardware acceleration in UTM
- Use SSD storage on host system

**Network Performance:**

- Use virtio network interface
- Consider bridged networking for better performance
- Enable jumbo frames if needed

## Advanced Configuration

### Adding Custom Features

Create new feature modules in [`home/dan/features/`](../home/dan/features/):

```bash
# Example: new development feature
mkdir -p home/dan/features/development
```

Add conditional imports to platform-specific configs:

```nix
# In nixos-vm-minimal.nix
imports = [
  ./features/cli/git.nix
  ./features/development/new-feature.nix  # Add new features
  # Platform-specific features only
];
```

### Remote Builder Setup

Configure remote builders in `/etc/nix/nix.conf` on macOS:

```
builders = ssh-ng://user@linux-host aarch64-linux
```

### GitHub Actions Integration

Set up automated builds with `.github/workflows/build-vm.yml`:

```yaml
name: Build NixOS VM
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v22
      - name: Build VM
        run: nix build .#nixosConfigurations.nixos-vm-minimal.config.system.build.toplevel
```

## Next Steps

1. **Enhance VM Configuration**: Add more system packages and services
2. **Integrate Development Tools**: Add language servers, compilers, etc.
3. **Set Up Shared Development**: Configure shared folders and networking
4. **Automate Deployment**: Create scripts for VM provisioning
5. **Extend Feature Modules**: Add more cross-platform functionality

## Support

For issues and questions:

- Review this documentation thoroughly
- Check existing feature modules for examples
- Test configurations with `nix flake check`
- Use `--show-trace` flags for detailed error information

The VM configuration is designed to grow incrementally - start minimal and add features as needed while maintaining compatibility with your existing Darwin setup.
