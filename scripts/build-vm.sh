#!/usr/bin/env bash
set -euo pipefail

# NixOS VM Build Script for UTM on macOS
# This script helps build and deploy NixOS VMs for UTM virtualization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VM_NAME="nixos-vm-minimal"

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

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    check           - Check flake configuration (can be run on macOS)
    build-iso       - Build NixOS installation ISO (requires remote builder)
    build-vm        - Build VM system configuration (requires remote builder)
    generate-utm    - Generate UTM VM configuration template
    help           - Show this help message

Options:
    -h, --help     - Show help message

Examples:
    $0 check                    # Validate configuration
    $0 build-iso               # Build installation ISO
    $0 generate-utm            # Create UTM configuration template

Note: Building actual NixOS systems requires either:
  1. A remote aarch64-linux builder
  2. Running this script from within a Linux environment
  3. Using GitHub Actions or other CI for builds
EOF
}

check_config() {
    log_info "Checking NixOS VM configuration..."
    cd "$REPO_ROOT"
    
    if nix flake check; then
        log_success "Flake configuration is valid!"
    else
        log_error "Flake configuration has issues. Please fix them first."
        return 1
    fi
}

build_iso() {
    log_info "Building NixOS installation ISO..."
    log_warning "This requires a remote aarch64-linux builder or Linux environment"
    
    cd "$REPO_ROOT"
    
    if nix build ".#nixosConfigurations.$VM_NAME.config.system.build.isoImage" 2>/dev/null; then
        log_success "ISO built successfully!"
        log_info "ISO location: $(readlink -f result)"
    else
        log_error "Failed to build ISO. You may need:"
        log_error "  1. A remote aarch64-linux builder configured"
        log_error "  2. To run this in a Linux environment"
        log_error "  3. To use nixos-generators for cross-platform ISO creation"
        return 1
    fi
}

build_vm_system() {
    log_info "Building NixOS VM system..."
    log_warning "This requires a remote aarch64-linux builder or Linux environment"
    
    cd "$REPO_ROOT"
    
    if nix build ".#nixosConfigurations.$VM_NAME.config.system.build.toplevel" 2>/dev/null; then
        log_success "VM system built successfully!"
        log_info "System closure: $(readlink -f result)"
    else
        log_error "Failed to build VM system. You may need:"
        log_error "  1. A remote aarch64-linux builder configured"
        log_error "  2. To run this in a Linux environment"
        return 1
    fi
}

generate_utm_config() {
    log_info "Generating UTM VM configuration template..."
    
    cat > "$REPO_ROOT/vm-utm-config.json" << 'EOF'
{
  "name": "NixOS VM Minimal",
  "notes": "Generated NixOS VM for development",
  "architecture": "aarch64",
  "machine": "virt-4.2",
  "memory": 4096,
  "cpuCount": 4,
  "drives": [
    {
      "id": "drive0",
      "imageURL": "./nixos-vm-disk.qcow2",
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
      "hardware": "virtio-ramfb-gl",
      "width": 1280,
      "height": 720
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
    
    log_success "UTM configuration template created: vm-utm-config.json"
    log_info "Import this into UTM and attach a NixOS installation ISO or disk image"
}

main() {
    case "${1:-help}" in
        check)
            check_config
            ;;
        build-iso)
            check_config && build_iso
            ;;
        build-vm)
            check_config && build_vm_system
            ;;
        generate-utm)
            generate_utm_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: ${1:-}"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"