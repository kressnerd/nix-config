# VM Testing Guide for pronix-vm and cupix001-vm

This guide explains how to test the [`pronix`](../hosts/pronix/default.nix:1) and [`cupix001`](../hosts/cupix001/default.nix:1) server configurations in a VM environment using UTM (macOS) or KVM (Linux).

## Overview

Two VM test configurations have been created:

- **[`pronix-vm`](../hosts/pronix-vm/default.nix:1)** - Simplified version of pronix (RAID/LUKS/LVM removed, single disk with btrfs + impermanence)
- **[`cupix001-vm`](../hosts/cupix001-vm/default.nix:1)** - Simplified version of cupix001 (Headscale + nginx + impermanence, no ACME/secrets)

## Key Simplifications for VM Testing

### Both VMs
- ✅ Password authentication enabled (password: `test`)
- ✅ Sudo without password
- ✅ Single virtio disk (`/dev/vda`)
- ✅ No SOPS encryption required
- ✅ Simplified firewall rules
- ✅ QEMU guest optimizations

### pronix-vm Specific
- ❌ No RAID (mdadm removed)
- ❌ No LUKS encryption
- ❌ No LVM
- ✅ Direct btrfs on partition with impermanence
- ✅ Reduced swap to 4GB

### cupix001-vm Specific
- ❌ No ACME/Let's Encrypt
- ❌ No fail2ban
- ❌ No security hardening (AppArmor, auditd)
- ❌ No auto-updates
- ✅ Headscale with HTTP-only nginx
- ✅ Impermanence testing enabled

## Prerequisites

### macOS (UTM)
```bash
# Install UTM
brew install --cask utm
```

### Linux (KVM)
```bash
# Fedora/RHEL
sudo dnf install @virtualization

# Ubuntu/Debian
sudo apt install qemu-kvm libvirt-daemon-system virtinst virt-manager

# Arch
sudo pacman -S qemu-full libvirt virt-manager
```

## Building the VM Images

### Option 1: Build Installation ISO

```bash
# Build pronix-vm installer
nix build .#nixosConfigurations.pronix-vm.config.system.build.isoImage

# Build cupix001-vm installer
nix build .#nixosConfigurations.cupix001-vm.config.system.build.isoImage
```

### Option 2: Build VM Disk Image Directly

```bash
# Build pronix-vm VM image
nix build .#nixosConfigurations.pronix-vm.config.system.build.vm

# Build cupix001-vm VM image
nix build .#nixosConfigurations.cupix001-vm.config.system.build.vm
```

### Option 3: Use nixos-anywhere (Recommended)

The easiest approach is to use disko + nixos-anywhere to install directly:

```bash
# This will partition and install in one step
# (Requires a temporary VM with any Linux running)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#pronix-vm \
  --vm-test
```

## Manual VM Setup

### Step 1: Create VM in UTM (macOS)

1. **Open UTM** → New VM → Emulate
2. **Operating System**: Linux
3. **Boot ISO**: Use NixOS minimal ISO or any Linux installer
4. **Hardware**:
   - CPU: 2-4 cores
   - RAM: 4GB minimum (pronix-vm), 2GB (cupix001-vm)
   - Storage: 20GB virtio disk
5. **Network**: Shared Network (NAT) or Bridged

### Step 2: Create VM in virt-manager (Linux)

```bash
# Download NixOS minimal ISO
curl -LO https://channels.nixos.org/nixos-25.11/latest-nixos-minimal-x86_64-linux.iso

# Create VM
virt-install \
  --name pronix-vm \
  --memory 4096 \
  --vcpus 2 \
  --disk size=20 \
  --cdrom latest-nixos-minimal-x86_64-linux.iso \
  --os-variant nixos-unknown \
  --network bridge=virbr0
```

### Step 3: Install Using Disko

Once booted into the live environment:

```bash
# Get your flake onto the VM
# Option A: Clone from git
nix-shell -p git
git clone https://github.com/yourusername/nix-config /tmp/config
cd /tmp/config

# Option B: Copy via SSH (from host)
scp -r ~/dev/PRIVATE/nix-config nixos@VM_IP:/tmp/config

# Run disko to partition
sudo nix run github:nix-community/disko -- --mode disko /tmp/config/hosts/pronix-vm/disko.nix

# Install NixOS
sudo nixos-install --flake /tmp/config#pronix-vm

# Set root password (temporary)
sudo nixos-enter
passwd
exit

# Reboot
sudo reboot
```

## Testing Scenarios

### Test 1: Impermanence (Both VMs)

Verify root filesystem is wiped on reboot:

```bash
# SSH into VM
ssh dan@VM_IP  # password: test

# Create temporary file
sudo touch /root/test-file.txt
ls /root/

# Reboot
sudo reboot

# After reboot, file should be gone
ssh dan@VM_IP
ls /root/  # test-file.txt should not exist

# But persistent data remains
ls /persist/
```

### Test 2: Btrfs + Compression (Both VMs)

```bash
# Check btrfs subvolumes
sudo btrfs subvolume list /

# Check compression
sudo btrfs filesystem df /
sudo compsize /

# Verify mount options
mount | grep btrfs
```

### Test 3: Headscale (cupix001-vm only)

```bash
# Check Headscale service
systemctl status headscale

# Create test user
sudo headscale users create testuser

# Generate auth key
sudo headscale preauthkeys create --user testuser

# Check nginx proxy
curl http://localhost/
curl http://headscale.local/  # Add to /etc/hosts first

# View logs
journalctl -u headscale -f
journalctl -u nginx -f
```

### Test 4: Nginx (cupix001-vm only)

```bash
# Check nginx status
systemctl status nginx

# Test endpoints
curl http://localhost/
curl http://localhost/metrics  # Should be denied

# View access logs
sudo tail -f /var/log/nginx/access.log
```

### Test 5: Network Configuration (Both VMs)

```bash
# Check NetworkManager
nmcli device status
nmcli connection show

# Check firewall
sudo iptables -L -n -v

# Check open ports
sudo ss -tlnp
```

## Validation Checklist

### pronix-vm
- [ ] VM boots successfully
- [ ] Can login as `dan` with password `test`
- [ ] Btrfs subvolumes mounted correctly
- [ ] Impermanence working (root wiped on reboot)
- [ ] `/persist` data survives reboot
- [ ] SSH access works
- [ ] Sudo works without password
- [ ] Networking configured via NetworkManager

### cupix001-vm
- [ ] All pronix-vm checks pass
- [ ] Headscale service running
- [ ] Nginx reverse proxy working
- [ ] Can create Headscale users
- [ ] Firewall allows ports 22, 80, 443, 3478
- [ ] Fish shell configured
- [ ] Home Manager applied correctly
- [ ] Impermanence preserves /var/lib/headscale

## Building for Production

Once VM testing is successful:

### pronix
Compare [`pronix-vm/disko.nix`](../hosts/pronix-vm/disko.nix:1) with [`pronix/disko.nix`](../hosts/pronix/disko.nix:1) to ensure RAID/LUKS/LVM logic is correct.

### cupix001
1. Set up SOPS secrets:
   ```bash
   # Generate age key
   ssh-to-age -private-key -i ~/.ssh/id_ed25519 > /persist/var/lib/sops-nix/key.txt
   sudo chmod 600 /persist/var/lib/sops-nix/key.txt
   
   # Edit secrets
   sops hosts/cupix001/secrets.yaml
   ```

2. Configure DNS for ACME:
   - Add A/AAAA records for domains
   - Get Cloudflare API token
   - Add to secrets.yaml

3. Update [`cupix001/default.nix`](../hosts/cupix001/default.nix:178):
   ```nix
   system.autoUpgrade.flake = "github:yourusername/nix-config#cupix001";
   ```

4. Deploy using nixos-anywhere:
   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#cupix001 \
     root@VPS_IP
   ```

## Troubleshooting

### VM won't boot
- Check UEFI is enabled in VM settings
- Verify virtio drivers are available
- Check disko partitioning: `lsblk`

### Disko fails
```bash
# Check available disks
lsblk

# If using different disk (e.g., /dev/sda), edit disko.nix:
sed -i 's|/dev/vda|/dev/sda|g' hosts/*/disko.nix
```

### Impermanence not working
```bash
# Check boot script ran
journalctl -b | grep -i btrfs

# Check subvolumes
sudo btrfs subvolume list /

# Verify old_roots cleanup
ls /old_roots/  # Should show timestamped snapshots
```

### Headscale not starting
```bash
# Check service status
systemctl status headscale

# Check logs
journalctl -u headscale -n 50

# Verify database
sudo ls -la /var/lib/headscale/

# Check ACL file
sudo cat /var/lib/headscale/acl.json
```

### Network issues
```bash
# Check DHCP
sudo dhclient -v

# Check DNS
cat /etc/resolv.conf

# Test connectivity
ping 1.1.1.1
ping google.com
```

## Cleanup

### Remove VM (UTM)
1. Shut down VM
2. Right-click → Delete
3. Confirm deletion

### Remove VM (KVM)
```bash
# Stop and delete VM
virsh destroy pronix-vm
virsh undefine pronix-vm --remove-all-storage

# Or use virt-manager GUI
```

## Next Steps

After successful VM testing:

1. Review [`docs/CUPIX001-DEPLOYMENT.md`](./CUPIX001-DEPLOYMENT.md:1) for production deployment
2. Set up monitoring and backups
3. Configure automatic updates
4. Harden security settings
5. Document any customizations

## References

- [Disko documentation](https://github.com/nix-community/disko)
- [nixos-anywhere guide](https://github.com/nix-community/nixos-anywhere)
- [Impermanence module](https://github.com/nix-community/impermanence)
- [Headscale documentation](https://headscale.net/)
