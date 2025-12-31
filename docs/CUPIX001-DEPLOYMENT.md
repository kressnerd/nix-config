# Cupix001 Bastion Host Deployment Guide

## Overview

Cupix001 is a hardened bastion host running on a Netcup VPS 1000. It provides:
- **Nginx** reverse proxy with HTTPS termination (Let's Encrypt)
- **Headscale** VPN coordination server with built-in DERP relay
- **Impermanence** for ephemeral root filesystem
- **Fail2ban** for brute-force protection
- **Hardened** security configuration

## Architecture

```
Internet
    ↓
  Nginx (443/80)
    ├── cupix001.kressner.cloud → 444 (connection close)
    └── headscale.kressner.cloud → Headscale (localhost:8080)
         ├── API/Web UI
         ├── DERP relay (UDP 3478)
         └── Metrics (localhost:9090, restricted)

SSH → Port 22 (fail2ban protected)
```

### Filesystem Layout (Btrfs + Impermanence)

```
/dev/sda
├── /boot (512MB, FAT32, unencrypted)
└── / (Btrfs, unencrypted for unattended reboots)
    ├── / (ephemeral, wiped on boot)
    ├── /nix (persistent)
    ├── /persist (persistent config/data)
    └── /var/log (persistent)
```

## Prerequisites

1. **Netcup VPS** with NixOS installer ISO booted
2. **DNS records** configured:
   - `cupix001.kressner.cloud` → VPS IP
   - `headscale.kressner.cloud` → VPS IP
3. **Cloudflare API token** for DNS-01 ACME challenges
4. **SSH keys** for authentication

## Deployment Steps

### 1. Prepare Secrets

On your local machine:

```bash
# Generate age key from SSH key
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > age-key.txt

# Note the public key for .sops.yaml
ssh-to-age < ~/.ssh/id_ed25519.pub
```

Update [`.sops.yaml`](../.sops.yaml:1) to include cupix001's age public key.

Generate required secrets:

```bash
# User password hash
mkpasswd -m sha-512
# Output: $6$rounds=656000$...

# Headscale noise private key (generate after first boot)
# Will be generated on server
```

Edit [`hosts/cupix001/secrets.yaml`](../hosts/cupix001/secrets.yaml:1):

```bash
# Add your secrets (unencrypted first)
vim hosts/cupix001/secrets.yaml

# Encrypt
sops -e -i hosts/cupix001/secrets.yaml
```

### 2. Initial System Installation

Boot the NixOS installer and connect via SSH.

#### Create Disk Layout

```bash
# On the VPS installer
# First, verify disk device
lsblk

# Clone your config repo
nix-shell -p git
git clone https://github.com/yourusername/nix-config.git /tmp/config
cd /tmp/config

# Run disko to partition and format
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko /tmp/config/hosts/cupix001/disko.nix
```

#### Manual Installation (Alternative to nixos-anywhere)

```bash
# Mount filesystems (disko should have done this)
mount | grep /mnt

# Generate hardware config (optional, we have hardware.nix)
nixos-generate-config --root /mnt

# Copy your config
mkdir -p /mnt/etc/nixos
cp -r /tmp/config/* /mnt/etc/nixos/

# Install
nixos-install --flake /mnt/etc/nixos#cupix001 --no-root-password

# Create persist structure before first boot
mkdir -p /mnt/persist/var/lib/sops-nix
mkdir -p /mnt/persist/home/dan/.ssh

# Copy age key
cat > /mnt/persist/var/lib/sops-nix/key.txt << 'EOF'
# Paste your age private key here
EOF
chmod 600 /mnt/persist/var/lib/sops-nix/key.txt

# Reboot
reboot
```

#### Using nixos-anywhere (Recommended)

From your local machine:

```bash
# Ensure nixos-anywhere is available
nix run github:nix-community/nixos-anywhere -- \
  --flake .#cupix001 \
  --build-on-remote \
  root@<VPS_IP>
```

### 3. Post-Installation Setup

SSH into the server:

```bash
ssh dan@cupix001.kressner.cloud
```

#### Initialize Headscale

```bash
# Generate noise private key
sudo headscale generate private-key > /tmp/noise-key

# Add to secrets
sudo sops /persist/etc/nixos/hosts/cupix001/secrets.yaml
# Add the noise key value

# Rebuild to apply
sudo nixos-rebuild switch --flake /etc/nixos#cupix001
```

#### Create Headscale User and Pre-Auth Key

```bash
# Create a user/namespace
sudo headscale users create homelab

# Generate pre-auth key for clients
sudo headscale preauthkeys create --user homelab --expiration 24h --reusable

# Example output:
# 1a2b3c4d5e...
```

#### Verify Services

```bash
# Check service status
systemctl status nginx headscale fail2ban

# Check firewall
sudo nftables list ruleset
# or
sudo iptables -L -n -v

# Test HTTPS
curl -I https://headscale.kressner.cloud

# Check Headscale
sudo headscale nodes list
```

### 4. Configure Tailscale Clients

On client machines:

```bash
# Linux/macOS
sudo tailscale up --login-server https://headscale.kressner.cloud --authkey <PREAUTH_KEY>

# Verify
tailscale status
```

## Management

### Update System

```bash
# Update flake inputs
cd /etc/nixos
sudo nix flake update

# Test build
sudo nixos-rebuild test --flake .#cupix001

# Apply
sudo nixos-rebuild switch --flake .#cupix001
```

### Rollback

```bash
# Boot menu shows generations
# Or manually:
sudo nixos-rebuild switch --rollback
```

### Headscale Management

```bash
# List users
sudo headscale users list

# List nodes
sudo headscale nodes list

# Create route
sudo headscale routes enable -r <ROUTE_ID>

# Expire node
sudo headscale nodes expire -i <NODE_ID>
```

### View Logs

```bash
# All logs are in /var/log (persistent)
journalctl -u nginx
journalctl -u headscale
journalctl -u fail2ban

# Nginx access/error logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Manage Secrets

```bash
# Edit encrypted secrets
sudo sops /persist/etc/nixos/hosts/cupix001/secrets.yaml

# After editing, rebuild
sudo nixos-rebuild switch --flake /etc/nixos#cupix001
```

## Monitoring

### Check Certificate Renewal

```bash
# ACME certificates
sudo systemctl list-timers acme-*

# Manual renewal test
sudo systemctl start acme-headscale.kressner.cloud.service
```

### Firewall Activity

```bash
# Check blocked IPs (fail2ban)
sudo fail2ban-client status sshd

# Unban an IP
sudo fail2ban-client set sshd unbanip <IP>
```

### Disk Usage (Impermanence)

```bash
# Check old roots
sudo btrfs subvolume list /

# Check space
df -h

# Manual cleanup (old roots auto-delete after 7 days)
sudo btrfs subvolume delete /old_roots/<timestamp>
```

## Troubleshooting

### SSH Access Issues

- Check fail2ban: `sudo fail2ban-client status sshd`
- Verify firewall: `sudo iptables -L -n -v | grep 22`
- Check SSH logs: `journalctl -u sshd`

### Headscale Connection Issues

1. Verify DNS resolves: `dig headscale.kressner.cloud`
2. Check nginx proxy: `journalctl -u nginx`
3. Test backend: `curl http://localhost:8080/health`
4. Verify DERP: `sudo ss -ulnp | grep 3478`

### Certificate Issues

```bash
# Check ACME logs
journalctl -u acme-headscale.kressner.cloud.service

# Verify DNS challenge
# Check Cloudflare API token has Zone:DNS:Edit permission
```

### Impermanence Issues

If critical files are missing after reboot:

```bash
# Add to hosts/cupix001/impermanence.nix persistence directories
# Then rebuild
```

## Security Notes

1. **No disk encryption** - Provider may reboot without notice
2. **Secrets encrypted** with sops-nix (age)
3. **Fail2ban active** - 3 SSH attempts = 1h ban
4. **Firewall restrictive** - Only 22, 80, 443 TCP; 3478 UDP
5. **AppArmor enabled** - Additional process confinement
6. **Audit logging** - Track privileged operations
7. **Auto-updates disabled** - Manual control preferred

## Files Reference

- [`hosts/cupix001/default.nix`](../hosts/cupix001/default.nix:1) - Main configuration
- [`hosts/cupix001/hardware.nix`](../hosts/cupix001/hardware.nix:1) - Hardware & kernel settings
- [`hosts/cupix001/disko.nix`](../hosts/cupix001/disko.nix:1) - Disk partitioning
- [`hosts/cupix001/impermanence.nix`](../hosts/cupix001/impermanence.nix:1) - Persistence configuration
- [`hosts/cupix001/hardening.nix`](../hosts/cupix001/hardening.nix:1) - Security hardening
- [`hosts/cupix001/firewall.nix`](../hosts/cupix001/firewall.nix:1) - Firewall rules
- [`hosts/cupix001/nginx.nix`](../hosts/cupix001/nginx.nix:1) - Reverse proxy & ACME
- [`hosts/cupix001/headscale.nix`](../hosts/cupix001/headscale.nix:1) - Headscale VPN server
- [`hosts/cupix001/home.nix`](../hosts/cupix001/home.nix:1) - Home Manager config
- [`hosts/cupix001/secrets.yaml`](../hosts/cupix001/secrets.yaml:1) - Encrypted secrets

## Next Steps

1. Configure Headscale ACLs in `/var/lib/headscale/acl.json`
2. Add internal services behind nginx proxy
3. Set up monitoring (Prometheus/Grafana)
4. Configure backup strategy for `/persist`
5. Document internal network topology
