#!/usr/bin/env bash
# Build VM test images for pronix-vm and cupix001-vm
# Usage: ./scripts/build-vm-test.sh [pronix-vm|cupix001-vm|both]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTION]

Build NixOS VM test images for testing server configurations.

Options:
    pronix-vm      Build only pronix-vm
    cupix001-vm    Build only cupix001-vm
    both           Build both VMs (default)
    -h, --help     Show this help message

Examples:
    $(basename "$0")                # Build both VMs
    $(basename "$0") pronix-vm      # Build only pronix-vm
    $(basename "$0") cupix001-vm    # Build only cupix001-vm

After building, see docs/VM-TESTING-GUIDE.md for setup instructions.
EOF
}

build_vm() {
    local vm_name="$1"
    log_info "Building ${vm_name}..."
    
    if nix build "$REPO_ROOT#nixosConfigurations.${vm_name}.config.system.build.toplevel" --print-build-logs; then
        log_info "✓ ${vm_name} built successfully"
        
        # Show system closure size
        local closure_size
        closure_size=$(nix path-info -Sh "$REPO_ROOT#nixosConfigurations.${vm_name}.config.system.build.toplevel" 2>/dev/null | awk '{print $2}' || echo "unknown")
        log_info "  Closure size: ${closure_size}"
        
        return 0
    else
        log_error "✗ ${vm_name} build failed"
        return 1
    fi
}

main() {
    local target="${1:-both}"
    
    if [[ "$target" == "-h" ]] || [[ "$target" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    cd "$REPO_ROOT"
    
    log_info "Checking flake..."
    if ! nix flake check --no-build; then
        log_error "Flake check failed. Fix errors before building."
        exit 1
    fi
    
    local exit_code=0
    
    case "$target" in
        pronix-vm)
            build_vm "pronix-vm" || exit_code=1
            ;;
        cupix001-vm)
            build_vm "cupix001-vm" || exit_code=1
            ;;
        both)
            build_vm "pronix-vm" || exit_code=1
            build_vm "cupix001-vm" || exit_code=1
            ;;
        *)
            log_error "Unknown target: $target"
            show_usage
            exit 1
            ;;
    esac
    
    if [[ $exit_code -eq 0 ]]; then
        log_info "All builds completed successfully!"
        log_info "Next steps:"
        log_info "  1. Read: docs/VM-TESTING-GUIDE.md"
        log_info "  2. Create a VM in UTM or virt-manager"
        log_info "  3. Install using: nix run github:nix-community/nixos-anywhere -- --flake .#${target} root@VM_IP"
    else
        log_error "Some builds failed. Check logs above."
    fi
    
    exit $exit_code
}

main "$@"
