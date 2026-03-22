# VM Testing Configurations

This directory contains VM test configurations for validating server setups before production deployment.

## Available VM Configurations

### [`pronix-vm/`](pronix-vm/default.nix:1)
Simplified test version of [`pronix`](pronix/default.nix:1) server configuration.

**Key Features:**
- Single virtio disk with btrfs
- Impermanence (ephemeral root)
- No RAID/LUKS/LVM (simplified for VM testing)
- Password auth enabled (user: `dan`, password: `test`)
- AMD/Intel KVM optimized

**Use Case:** Test the impermanence setup, btrfs layout, and basic server functionality before deploying on real hardware with RAID.

### [`cupix001-vm/`](cupix001-vm/default.nix:1)
Simplified test version of [`cupix001`](cupix001/default.nix:1) VPS configuration.

**Key Features:**
- Headscale coordination server
- Nginx reverse proxy (HTTP only, no ACME)
- Impermanence (ephemeral root)
- No security hardening (for easier testing)
- Password auth enabled (user: `dan`, password: `test`)

**Use Case:** Test Headscale setup, nginx configuration, and impermanence before deploying to production VPS.

## Quick Start

### 1. Build and Validate

```bash
# Check configurations
nix flake check

# Build specific VM
./scripts/build-vm-test.sh pronix-vm
./scripts/build-vm-test.sh cupix001-vm

# Or build both
./scripts/build-vm-test.sh both
```

### 2. Create VM

**macOS (UTM):**
- New VM → Emulate → Linux
- 2-4 CPU cores, 4GB RAM, 20GB disk
- Attach NixOS minimal ISO

**Linux (KVM):**
```bash
virt-install \
  --name pronix-vm \
  --memory 4096 \
  --vcpus 2 \
  --disk size=20 \
  --cdrom nixos-minimal.iso \
  --os-variant nixos-unknown \
  --network bridge=virbr0
```

### 3. Install

Boot into live environment, then:

```bash
# Clone your config
git clone <your-repo> /tmp/config
cd /tmp/config

# Partition with disko
sudo nix run github:nix-community/disko -- \
  --mode disko \
  /tmp/config/hosts/pronix-vm/disko.nix

# Install NixOS
sudo nixos-install --flake /tmp/config#pronix-vm

# Reboot
sudo reboot
```

### 4. Test

```bash
# SSH into VM
ssh dan@VM_IP  # password: test

# Test impermanence
sudo touch /root/test-file.txt
sudo reboot
# After reboot, file should be gone but /persist remains

# For cupix001-vm, test Headscale
systemctl status headscale
sudo headscale users create testuser
```

## Differences from Production

| Feature | Production | VM Test |
|---------|-----------|---------|
| **Authentication** | SSH keys only | Password enabled (`test`) |
| **Encryption** | LUKS/OPAL (pronix) | None |
| **Storage** | RAID1 (pronix), Single disk (cupix001) | Single virtio disk |
| **ACME/TLS** | Cloudflare DNS-01 | Disabled (HTTP only) |
| **Hardening** | AppArmor, auditd, fail2ban | Disabled |
| **SOPS** | Encrypted secrets | Placeholder files |
| **Sudo** | Password required | No password |

## Documentation

Full testing guide: [`docs/VM-TESTING-GUIDE.md`](../docs/VM-TESTING-GUIDE.md:1)

## File Structure

```
hosts/
├── pronix/                 # Production config
│   ├── default.nix
│   ├── disko.nix          # RAID1 + LUKS + LVM + btrfs
│   └── hardware.nix       # Bare metal hardware
│
├── pronix-vm/             # VM test config
│   ├── default.nix        # Simplified, password auth
│   ├── disko.nix          # Single disk, btrfs only
│   └── hardware.nix       # KVM/QEMU guest
│
├── cupix001/              # Production VPS
│   ├── default.nix
│   ├── disko.nix          # Unencrypted btrfs
│   ├── headscale.nix      # With secrets
│   ├── nginx.nix          # ACME enabled
│   └── hardening.nix      # Full security
│
└── cupix001-vm/           # VM test VPS
    ├── default.nix        # Simplified, no hardening
    ├── disko.nix          # Same layout as production
    ├── headscale.nix      # No secrets required
    └── nginx.nix          # HTTP only
```

## Validation Steps

### Both VMs
- [ ] Boots successfully
- [ ] User `dan` can login with password `test`
- [ ] Impermanence wipes root on reboot
- [ ] `/persist` data survives reboot
- [ ] NetworkManager configured
- [ ] SSH accessible
- [ ] Sudo works

### cupix001-vm Specific
- [ ] Headscale service running
- [ ] Nginx reverse proxy working
- [ ] Can create Headscale users
- [ ] STUN port 3478 open
- [ ] Fish shell configured

## Rollback to Production

After VM testing confirms the setup works:

1. **pronix**: Deploy with full RAID/LUKS/LVM as specified in [`pronix/disko.nix`](pronix/disko.nix:1)
2. **cupix001**: Add SOPS secrets, enable ACME, deploy to VPS using [`docs/CUPIX001-DEPLOYMENT.md`](../docs/CUPIX001-DEPLOYMENT.md:1)

## Tips

- Use snapshots before testing destructive changes
- Test impermanence thoroughly (multiple reboots)
- Verify all services start on boot
- Check logs: `journalctl -b`
- Monitor resource usage: `htop`

For detailed instructions, see the [VM Testing Guide](../docs/VM-TESTING-GUIDE.md:1).
