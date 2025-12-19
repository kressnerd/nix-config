# Thiniel VM Setup Guide

This guide covers the **thiniel-vm** configuration, which brings the ThinkPad `thiniel` configuration to a virtual machine environment for testing and development.

## Overview

The **thiniel-vm** provides:

- **Full thiniel experience** in a VM environment
- **Hyprland Wayland desktop** with all visual features
- **Comprehensive development tools** from the thiniel configuration
- **VM-optimized hardware** settings for UTM/QEMU
- **Simplified architecture** without impermanence for easier testing
- **Cross-platform compatibility** (aarch64-linux default, x86_64-linux supported)

## Configuration Structure

```
nix-config/
├── hosts/thiniel-vm/                    # VM host configuration
│   ├── default.nix                     # Main system config
│   ├── hardware.nix                    # VM-optimized hardware
│   ├── home.nix                        # Home Manager integration
│   └── secrets.yaml                    # SOPS secrets template
├── home/dan/thiniel-vm.nix             # Home Manager config
├── scripts/build-vm.sh                 # Enhanced build script
└── docs/THINIEL-VM-SETUP.md           # This documentation
```

## Key Differences from Original Configurations

### vs. Original Thiniel

| Feature              | Thiniel (Hardware)     | Thiniel-VM              |
| -------------------- | ---------------------- | ----------------------- |
| **Hardware**         | ThinkPad X270 specific | VM-generic (UTM/QEMU)   |
| **Architecture**     | x86_64-linux           | aarch64-linux (default) |
| **File System**      | Btrfs + impermanence   | ext4 (simplified)       |
| **Boot Loader**      | systemd-boot           | systemd-boot            |
| **Desktop**          | Hyprland + greetd      | Hyprland + greetd       |
| **Power Management** | ThinkPad optimized     | VM optimized            |
| **Virtualization**   | Host libvirtd          | Guest optimizations     |
| **Persistence**      | Impermanence enabled   | Standard filesystem     |

### vs. nixos-vm-minimal

| Feature          | nixos-vm-minimal       | Thiniel-VM              |
| ---------------- | ---------------------- | ----------------------- |
| **Purpose**      | Basic CLI testing      | Full desktop testing    |
| **Desktop**      | None (CLI only)        | Hyprland Wayland        |
| **Home Manager** | Minimal features       | Full thiniel features   |
| **Package Set**  | Essential tools only   | Comprehensive dev tools |
| **Memory Usage** | ~4GB recommended       | ~8GB recommended        |
| **Use Case**     | Infrastructure testing | Desktop/app testing     |

## Features Included

### ✅ Desktop Environment

- **Hyprland** Wayland compositor (from unstable)
- **greetd + tuigreet** login manager
- **waybar, mako, kitty** essential Wayland tools
- **rofi** application launcher

### ✅ Development Tools

- **Comprehensive CLI tools** (rust-based: eza, fd, ripgrep, bat, etc.)
- **Git integration** with SOPS-managed credentials
- **Starship prompt** and **zsh** shell
- **Vim** as default editor
- **Firefox** browser with Linux optimizations

### ✅ VM Optimizations

- **QEMU guest agent** for VM management
- **SPICE agent** for better integration
- **Virtio drivers** for performance
- **Memory/CPU optimizations** for virtualization
- **Hardware acceleration** support for graphics

### ❌ Features Excluded (for simplicity)

- **Impermanence** (uses standard ext4 filesystem)
- **nixos-hardware modules** (VM-generic instead)
- **Power management tools** (auto-cpufreq, thermald)
- **Host virtualization** (libvirtd, virt-manager)
- **Hardware-specific** ThinkPad optimizations

## Building and Testing

### Prerequisites

- **UTM** (macOS) or **QEMU/KVM** (Linux)
- **Nix with flakes** enabled
- **Remote builder** (for aarch64-linux builds from macOS)

### Quick Start

1. **Validate configuration:**

   ```bash
   ./scripts/build-vm.sh check thiniel-vm
   ```

2. **Generate UTM configuration:**

   ```bash
   ./scripts/build-vm.sh generate-utm thiniel-vm
   ```

3. **Build VM system** (requires remote builder):

   ```bash
   ./scripts/build-vm.sh build-vm thiniel-vm
   ```

4. **Build installation ISO** (optional):
   ```bash
   ./scripts/build-vm.sh build-iso thiniel-vm
   ```

### Manual Build Commands

```bash
# Check configuration
nix build .#nixosConfigurations.thiniel-vm.config.system.build.toplevel --dry-run

# Build system closure
nix build .#nixosConfigurations.thiniel-vm.config.system.build.toplevel

# Build ISO image
nix build .#nixosConfigurations.thiniel-vm.config.system.build.isoImage
```

## VM Setup Instructions

### UTM Configuration (macOS)

1. **Import generated config:**

   ```bash
   ./scripts/build-vm.sh generate-utm thiniel-vm
   # Import vm-utm-config-thiniel-vm.json into UTM
   ```

2. **Recommended VM settings:**

   - **Memory**: 8GB+ (Hyprland needs resources)
   - **CPU**: 6+ cores for smooth experience
   - **Graphics**: Hardware acceleration enabled
   - **Display**: 1920x1080 or higher
   - **Network**: Shared network mode

3. **Installation methods:**
   - **Option A**: Use NixOS installation ISO + flake
   - **Option B**: Pre-built system image (if available)
   - **Option C**: Manual installation with generated config

### QEMU/KVM Setup (Linux)

```bash
# Example QEMU command for testing
qemu-system-aarch64 \
  -machine virt \
  -cpu cortex-a72 \
  -smp 6 \
  -m 8G \
  -device virtio-gpu-pci \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0 \
  -drive file=thiniel-vm.qcow2,if=virtio \
  -cdrom nixos-thiniel-vm.iso
```

## Usage and Testing

### VM-specific Aliases (available in shell)

```bash
# System management
vm-rebuild          # Quick rebuild with flake
vm-update          # Update flake + rebuild
nrs                # sudo nixos-rebuild switch --flake ~/nix-config
nrt                # sudo nixos-rebuild test --flake ~/nix-config

# Information and diagnostics
vm-info            # System information (RAM, disk, CPU)
flake-check        # Validate flake configuration
flake-show         # Show available outputs
```

### Testing Workflow

1. **Boot into Hyprland:**

   - Login automatically as `dan` user
   - Hyprland desktop should start
   - Waybar, background, and basic apps available

2. **Test core functionality:**

   ```bash
   # Test shell and tools
   eza -la            # Modern ls
   fd pattern         # Modern find
   rg "search"        # Modern grep

   # Test git integration (SOPS-managed)
   git config --list  # Should show decrypted credentials

   # Test development environment
   vim                # Default editor
   kitty              # Terminal emulator
   firefox            # Browser
   ```

3. **Test configuration changes:**

   ```bash
   # Edit configuration
   vim ~/nix-config/home/dan/thiniel-vm.nix

   # Apply changes
   vm-rebuild

   # Test in new shell session
   ```

## Development and Customization

### Adding Features

To incrementally add features from the full thiniel configuration:

```nix
# In home/dan/thiniel-vm.nix
imports = [
  # ... existing imports ...
  ./features/development/containers.nix    # Add container tools
  ./features/productivity/emacs-doom.nix   # Add Doom Emacs
  ./features/development/nodejs.nix        # Add Node.js development
];
```

### Architecture Override

To test on x86_64-linux instead of aarch64-linux:

```nix
# In hosts/thiniel-vm/hardware.nix
nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
```

### Adding Impermanence (Advanced)

To add impermanence back to the VM:

```nix
# In hosts/thiniel-vm/default.nix
imports = [
  # ... existing imports ...
  inputs.impermanence.nixosModules.impermanence
];

# Add btrfs configuration similar to original thiniel
```

## Troubleshooting

### Common Issues

1. **Build failures:**

   ```bash
   # Check if remote builder is configured
   nix show-config | grep builders

   # Try building with more verbose output
   nix build --show-trace --verbose
   ```

2. **Graphics issues in VM:**

   - Ensure hardware acceleration is enabled in UTM
   - Try different display drivers (qxl vs virtio-gpu)
   - Check if Hyprland starts: `ps aux | grep Hyprland`

3. **Memory/performance issues:**

   - Increase VM memory to 8GB+
   - Add more CPU cores (6+ recommended)
   - Check VM resource usage: `vm-info`

4. **Network connectivity:**
   ```bash
   # Test network inside VM
   ping nixos.org
   curl -I https://cache.nixos.org
   ```

### SOPS Secrets Management

The VM uses a template secrets file. For real usage:

```bash
# Generate age key for VM
mkdir -p /var/lib/sops-nix
age-keygen -o /var/lib/sops-nix/key.txt

# Update secrets.yaml with real encrypted values
sops hosts/thiniel-vm/secrets.yaml
```

### Log Analysis

```bash
# System logs
journalctl -xeu home-manager-dan.service
journalctl -xeu display-manager.service

# Hyprland logs
journalctl --user -xeu hyprland.service
```

## Comparison with Physical Installation

| Aspect             | Physical Thiniel          | Thiniel-VM               | Notes                      |
| ------------------ | ------------------------- | ------------------------ | -------------------------- |
| **Performance**    | Native hardware           | VM overhead (~20-30%)    | CPU/GPU bound tasks slower |
| **Features**       | All hardware features     | Software features only   | No ThinkPad-specific tools |
| **Persistence**    | Impermanence + snapshots  | Standard filesystem      | Simpler but less resilient |
| **Boot Time**      | ~30-60 seconds            | ~10-30 seconds           | VM boots faster            |
| **Resource Usage** | Full system               | Configurable allocation  | Can limit resource usage   |
| **Testing Safety** | Risk of system corruption | Snapshot/rollback easily | Better for experimentation |

## Integration with Main Repository

The thiniel-vm configuration is fully integrated:

- **Flake outputs**: Available as `.#nixosConfigurations.thiniel-vm`
- **Build scripts**: Enhanced `scripts/build-vm.sh` supports both VM types
- **Documentation**: This guide and integration with existing docs
- **Home Manager**: Reuses existing feature modules where possible
- **SOPS integration**: Compatible with existing secrets management

## Next Steps

- **Test the configuration** in your VM environment
- **Add missing features** incrementally as needed
- **Contribute improvements** back to the main configuration
- **Use for development** of new features before deploying to hardware

The thiniel-vm provides a safe, full-featured environment to test the complete thiniel configuration without needing physical ThinkPad hardware.
