#!/usr/bin/env bash
set -euo pipefail

# NixOS VM Deployment Script using nixos-anywhere
# This script automates the deployment of NixOS to VMs using nixos-anywhere and disko

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DEFAULT_VM_NAME="nixos-vm-minimal"
DEFAULT_VM_IP="192.168.64.2"  # Common UTM default IP

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
NixOS VM Deployment Script using nixos-anywhere

Usage: $0 [COMMAND] [VM_NAME] [VM_IP] [OPTIONS]

Commands:
    prepare         - Setup SSH keys and prepare for deployment
    check-ssh       - Test SSH connectivity to target VM
    deploy          - Deploy NixOS configuration using nixos-anywhere
    deploy-local    - Deploy to local VM (assumes VM is accessible)
    generate-iso    - Generate a nixos-anywhere compatible ISO
    help           - Show this help message

Arguments:
    VM_NAME        - Name of VM configuration (default: nixos-vm-minimal)
    VM_IP          - IP address of target VM (default: 192.168.64.2)

Options:
    --user USER    - SSH user for deployment (default: nixos)
    --key PATH     - Path to SSH private key (default: ~/.ssh/id_ed25519)
    --dry-run      - Show what would be deployed without executing
    -h, --help     - Show help message

Examples:
    $0 prepare                                    # Setup SSH keys
    $0 check-ssh nixos-vm-minimal 192.168.64.2  # Test connectivity
    $0 deploy nixos-vm-minimal 192.168.64.2     # Deploy configuration
    $0 deploy-local                              # Deploy to default local VM

Prerequisites:
    1. VM booted from NixOS installer ISO
    2. VM accessible via SSH (usually after enabling SSH in installer)
    3. SSH keys configured (use 'prepare' command)

Notes:
    - The VM must be booted from a NixOS installer ISO
    - SSH must be enabled in the installer (systemctl start sshd)
    - The deployment will partition disks according to disko configuration
    - Existing data on target disk will be DESTROYED

For UTM setup:
    1. Create VM with generated UTM config
    2. Boot from NixOS installer ISO
    3. Enable SSH: sudo systemctl start sshd
    4. Set password: sudo passwd nixos
    5. Find VM IP: ip addr show
    6. Run: $0 deploy nixos-vm-minimal <VM_IP>
EOF
}

prepare_ssh() {
    log_info "Preparing SSH keys for nixos-anywhere deployment..."
    
    local ssh_key_path="$HOME/.ssh/id_ed25519"
    
    if [[ ! -f "$ssh_key_path" ]]; then
        log_warning "SSH key not found at $ssh_key_path"
        read -p "Generate new SSH key? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-keygen -t rsa -b 4096 -f "$ssh_key_path" -N ""
            log_success "SSH key generated at $ssh_key_path"
        else
            log_error "SSH key required for deployment"
            return 1
        fi
    else
        log_success "SSH key found at $ssh_key_path"
    fi
    
    log_info "SSH public key content (copy this to target VM if needed):"
    echo "----------------------------------------"
    cat "$ssh_key_path.pub"
    echo "----------------------------------------"
    
    log_info "To enable SSH access on NixOS installer:"
    echo "  sudo systemctl start sshd"
    echo "  sudo passwd nixos"
    echo "  # Then optionally add your public key to ~/.ssh/authorized_keys"
}

check_ssh_connectivity() {
    local vm_ip="${1:-$DEFAULT_VM_IP}"
    local ssh_user="${2:-nixos}"
    local ssh_key="${3:-$HOME/.ssh/id_ed25519}"
    
    log_info "Testing SSH connectivity to $ssh_user@$vm_ip..."
    
    if ssh -i "$ssh_key" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ssh_user@$vm_ip" "echo 'SSH connection successful'"; then
        log_success "SSH connectivity confirmed!"
        return 0
    else
        log_error "SSH connectivity failed. Ensure:"
        log_error "  1. VM is running and accessible at $vm_ip"
        log_error "  2. SSH is enabled on target: sudo systemctl start sshd"
        log_error "  3. User password is set: sudo passwd $ssh_user"
        log_error "  4. SSH key is correct: $ssh_key"
        return 1
    fi
}

deploy_nixos() {
    local vm_name="${1:-$DEFAULT_VM_NAME}"
    local vm_ip="${2:-$DEFAULT_VM_IP}"
    local ssh_user="${3:-nixos}"
    local ssh_key="${4:-$HOME/.ssh/id_ed25519}"
    local dry_run="${5:-false}"
    
    log_info "Deploying $vm_name to $vm_ip using nixos-anywhere..."
    
    # Verify flake configuration exists
    if ! nix flake show "$REPO_ROOT" | rg "$vm_name"; then
        log_error "Configuration $vm_name not found in flake"
        return 1
    fi
    
    # Check SSH connectivity first
    if ! check_ssh_connectivity "$vm_ip" "$ssh_user" "$ssh_key"; then
        return 1
    fi
    
    # Prepare nixos-anywhere command
    local nixos_anywhere_cmd=(
        "nix" "run" "github:nix-community/nixos-anywhere" "--"
        "--flake" "$REPO_ROOT#$vm_name"
        "--ssh-option" "StrictHostKeyChecking=no"
        "--ssh-option" "UserKnownHostsFile=/dev/null"  
    )
    
    if [[ "$ssh_key" != "$HOME/.ssh/id_ed25519" ]]; then
        nixos_anywhere_cmd+=("--ssh-option" "IdentityFile=$ssh_key")
    fi
    
    nixos_anywhere_cmd+=("$ssh_user@$vm_ip")
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Dry run - would execute:"
        echo "${nixos_anywhere_cmd[*]}"
        return 0
    fi
    
    log_warning "This will DESTROY all data on the target disk!"
    log_info "Target: $ssh_user@$vm_ip"
    log_info "Configuration: $vm_name"
    echo
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled"
        return 0
    fi
    
    log_info "Starting nixos-anywhere deployment..."
    echo "Command: ${nixos_anywhere_cmd[*]}"
    echo
    
    if "${nixos_anywhere_cmd[@]}"; then
        log_success "Deployment completed successfully!"
        log_info "VM should reboot into your NixOS configuration"
        log_info "You can now SSH directly: ssh $ssh_user@$vm_ip"
    else
        log_error "Deployment failed!"
        return 1
    fi
}

generate_installer_iso() {
    local vm_name="${1:-$DEFAULT_VM_NAME}"
    
    log_info "Generating nixos-anywhere compatible installer ISO for $vm_name..."
    
    cd "$REPO_ROOT"
    
    # Create a temporary installer configuration
    local temp_iso_config="/tmp/nixos-anywhere-installer-$vm_name.nix"
    
    cat > "$temp_iso_config" << 'EOF'
{ config, pkgs, lib, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Enable SSH in installer
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Set a default password for nixos user
  users.users.nixos.password = "nixos";
  users.users.root.password = "nixos";

  # Include useful tools for debugging
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
EOF
    
    log_info "Building installer ISO with SSH enabled..."
    if nix build -f "$temp_iso_config" config.system.build.isoImage; then
        log_success "Installer ISO built successfully!"
        log_info "ISO location: $(readlink -f result)/iso/*.iso"
        log_info "Default credentials: nixos/nixos and root/nixos"
    else
        log_error "Failed to build installer ISO"
        return 1
    fi
    
    rm -f "$temp_iso_config"
}

main() {
    local command="${1:-help}"
    local vm_name="${2:-$DEFAULT_VM_NAME}"
    local vm_ip="${3:-$DEFAULT_VM_IP}"
    local ssh_user="nixos"
    local ssh_key="$HOME/.ssh/id_ed25519"
    local dry_run="false"
    
    # Parse additional options
    shift $# > /dev/null 2>&1 || true
    while [[ $# -gt 0 ]]; do
        case $1 in
            --user)
                ssh_user="$2"
                shift 2
                ;;
            --key)
                ssh_key="$2"
                shift 2
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "${vm_name:-}" ]]; then
                    vm_name="$1"
                elif [[ -z "${vm_ip:-}" ]]; then
                    vm_ip="$1"
                fi
                shift
                ;;
        esac
    done
    
    case "$command" in
        prepare)
            prepare_ssh
            ;;
        check-ssh)
            check_ssh_connectivity "$vm_ip" "$ssh_user" "$ssh_key"
            ;;
        deploy)
            deploy_nixos "$vm_name" "$vm_ip" "$ssh_user" "$ssh_key" "$dry_run"
            ;;
        deploy-local)
            deploy_nixos "$vm_name" "$DEFAULT_VM_IP" "$ssh_user" "$ssh_key" "$dry_run"
            ;;
        generate-iso)
            generate_installer_iso "$vm_name"
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