#!/usr/bin/env bash

# Script to generate SSH host keys for initrd remote LUKS unlocking
# These keys are stored insecurely in the Nix store, so they should NOT be
# your regular SSH host keys.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root to generate system keys"
    exit 1
fi

# Directory for initrd SSH keys
KEYS_DIR="/etc/secrets/initrd"

# Create the directory if it doesn't exist
if [[ ! -d "$KEYS_DIR" ]]; then
    log_info "Creating directory $KEYS_DIR"
    mkdir -p "$KEYS_DIR"
    chmod 700 "$KEYS_DIR"
fi

# Generate RSA key if it doesn't exist
RSA_KEY="$KEYS_DIR/ssh_host_rsa_key"
if [[ ! -f "$RSA_KEY" ]]; then
    log_info "Generating RSA host key for initrd..."
    ssh-keygen -t rsa -b 4096 -N "" -f "$RSA_KEY"
    chmod 600 "$RSA_KEY"
    chmod 644 "$RSA_KEY.pub"
    log_info "RSA key generated: $RSA_KEY"
else
    log_warning "RSA key already exists: $RSA_KEY"
fi

# Generate Ed25519 key if it doesn't exist
ED25519_KEY="$KEYS_DIR/ssh_host_ed25519_key"
if [[ ! -f "$ED25519_KEY" ]]; then
    log_info "Generating Ed25519 host key for initrd..."
    ssh-keygen -t ed25519 -N "" -f "$ED25519_KEY"
    chmod 600 "$ED25519_KEY"
    chmod 644 "$ED25519_KEY.pub"
    log_info "Ed25519 key generated: $ED25519_KEY"
else
    log_warning "Ed25519 key already exists: $ED25519_KEY"
fi

log_info "SSH host keys for initrd are ready!"
log_warning "IMPORTANT: These keys are stored in the Nix store and are not secret!"
log_warning "Do NOT use your regular SSH host keys for initrd unlocking!"

echo ""
log_info "Key fingerprints:"
echo "RSA:"
ssh-keygen -lf "$RSA_KEY.pub"
echo "Ed25519:"
ssh-keygen -lf "$ED25519_KEY.pub"

echo ""
log_info "You can now rebuild your NixOS configuration."
log_info "After reboot, connect to the initrd SSH server with:"
log_info "  ssh -p 2222 root@<vm-ip>"
log_info "Then run 'unlock-luks' to unlock the encrypted disk."