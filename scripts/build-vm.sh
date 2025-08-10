#!/usr/bin/env bash
set -euo pipefail

# NixOS VM Build Script for UTM on macOS
# This script helps build and deploy NixOS VMs for UTM virtualization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DEFAULT_VM_NAME="nixos-vm-minimal"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
NixOS VM Build Script for UTM

Usage: $0 [COMMAND] [VM_NAME] [OPTIONS]

Commands:
    check           - Check flake configuration (can be run on macOS)
    build-iso       - Build NixOS installation ISO (requires remote builder)
    build-vm        - Build VM system configuration (requires remote builder)
    generate-utm    - Generate UTM VM configuration template
    help           - Show this help message

VM Names (optional, defaults to nixos-vm-minimal):
    nixos-vm-minimal  - Minimal CLI-only VM
    thiniel-vm        - Thiniel configuration optimized for VM testing

Options:
    -h, --help     - Show help message

Examples:
    $0 check                           # Validate all configurations
    $0 check thiniel-vm               # Validate thiniel-vm configuration
    $0 build-iso thiniel-vm           # Build thiniel-vm installation ISO
    $0 build-vm thiniel-vm            # Build thiniel-vm system
    $0 generate-utm thiniel-vm        # Create UTM config for thiniel-vm

Available configurations:
    nixos-vm-minimal  - Basic VM with essential CLI tools
    thiniel-vm        - Full thiniel experience in VM (Hyprland, dev tools)

Note: Building actual NixOS systems requires either:
  1. A remote aarch64-linux builder
  2. Running this script from within a Linux environment
  3. Using GitHub Actions or other CI for builds
EOF
}

check_config() {
    local vm_name="${1:-}"
    
    if [[ -n "$vm_name" ]]; then
        log_info "Checking $vm_name configuration..."
        cd "$REPO_ROOT"
        
        if nix build ".#nixosConfigurations.$vm_name.config.system.build.toplevel" --dry-run; then
            log_success "$vm_name configuration is valid!"
        else
            log_error "$vm_name configuration has issues. Please fix them first."
            return 1
        fi
    else
        log_info "Checking all NixOS VM configurations..."
        cd "$REPO_ROOT"
        
        if nix flake check; then
            log_success "All flake configurations are valid!"
        else
            log_error "Flake configuration has issues. Please fix them first."
            return 1
        fi
    fi
}

build_iso() {
    local vm_name="${1:-$DEFAULT_VM_NAME}"
    log_info "Building NixOS installation ISO for $vm_name..."
    log_warning "This requires a remote aarch64-linux builder or Linux environment"
    
    cd "$REPO_ROOT"
    
    if nix build ".#nixosConfigurations.$vm_name.config.system.build.isoImage" 2>/dev/null; then
        log_success "ISO built successfully for $vm_name!"
        log_info "ISO location: $(readlink -f result)"
    else
        log_error "Failed to build ISO for $vm_name. You may need:"
        log_error "  1. A remote aarch64-linux builder configured"
        log_error "  2. To run this in a Linux environment"
        log_error "  3. To use nixos-generators for cross-platform ISO creation"
        return 1
    fi
}

build_vm_system() {
    local vm_name="${1:-$DEFAULT_VM_NAME}"
    log_info "Building NixOS VM system for $vm_name..."
    log_warning "This requires a remote aarch64-linux builder or Linux environment"
    
    cd "$REPO_ROOT"
    
    if nix build ".#nixosConfigurations.$vm_name.config.system.build.toplevel" 2>/dev/null; then
        log_success "VM system built successfully for $vm_name!"
        log_info "System closure: $(readlink -f result)"
    else
        log_error "Failed to build VM system for $vm_name. You may need:"
        log_error "  1. A remote aarch64-linux builder configured"
        log_error "  2. To run this in a Linux environment"
        return 1
    fi
}

generate_utm_config() {
    local vm_name="${1:-$DEFAULT_VM_NAME}"
    local config_file="$REPO_ROOT/vm-utm-config-$vm_name.json"
    
    log_info "Generating UTM VM configuration template for $vm_name..."
    
    # Set VM-specific configurations
    local display_name memory cpucount display_hardware
    case "$vm_name" in
        "thiniel-vm")
            display_name="Thiniel VM (NixOS)"
            memory=8192  # 8GB for full desktop experience
            cpucount=6   # More cores for Hyprland
            display_hardware="virtio-gpu-gl-pci"  # Better graphics for Wayland
            ;;
        "nixos-vm-minimal")
            display_name="NixOS VM Minimal"
            memory=4096  # 4GB for minimal setup
            cpucount=4   # 4 cores sufficient
            display_hardware="virtio-ramfb-gl"  # Standard graphics
            ;;
        *)
            display_name="NixOS VM ($vm_name)"
            memory=4096
            cpucount=4
            display_hardware="virtio-ramfb-gl"
            ;;
    esac
    
    cat > "$config_file" << EOF
{
  "name": "$display_name",
  "notes": "Generated NixOS VM configuration for $vm_name",
  "architecture": "aarch64",
  "machine": "virt-4.2",
  "memory": $memory,
  "cpuCount": $cpucount,
  "drives": [
    {
      "id": "drive0",
      "imageURL": "./nixos-$vm_name-disk.qcow2",
      "interface": "virtio",
      "bootable": true
    }
  ],
  "networkCards": [
    {
      "hardware": "virtio-net-pci",
      "mode": "shared"
    }
  ],
  "displays": [
    {
      "hardware": "$display_hardware",
      "width": 1920,
      "height": 1080
    }
  ],
  "sound": {
    "hardware": "intel-hda"
  },
  "input": {
    "keyboard": "usb",
    "pointing": "usb"
  }
}
EOF
    
    log_success "UTM configuration template created: $(basename "$config_file")"
    log_info "Import this into UTM and attach a NixOS installation ISO or disk image"
    
    if [[ "$vm_name" == "thiniel-vm" ]]; then
        log_info "Note: thiniel-vm includes Hyprland desktop environment"
        log_info "      Recommended: 8GB+ RAM, hardware acceleration enabled"
    fi
}

main() {
    local command="${1:-help}"
    local vm_name="${2:-}"
    
    case "$command" in
        check)
            check_config "$vm_name"
            ;;
        build-iso)
            check_config "$vm_name" && build_iso "$vm_name"
            ;;
        build-vm)
            check_config "$vm_name" && build_vm_system "$vm_name"
            ;;
        generate-utm)
            generate_utm_config "$vm_name"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"