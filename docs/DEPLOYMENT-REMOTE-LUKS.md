# Remote LUKS Unlocking: Setup Guide

This guide shows how to deploy and configure the nixos-vm-minimal VM with remote LUKS unlocking capabilities.

## Overview

The nixos-vm-minimal configuration supports remote LUKS unlocking through SSH during boot. This allows you to unlock encrypted disks remotely, making it suitable for headless server deployments.

## How It Works

When the VM boots:

1. **initrd loads** with network support and SSH server on port 2222
2. **You connect via SSH** and are immediately prompted for the LUKS passphrase
3. **Boot continues automatically** after successful unlock

The configuration uses:

- `boot.initrd.network.ssh.shell = "/bin/cryptsetup-askpass"` for direct LUKS prompting
- Dedicated SSH host keys (auto-generated during NixOS build)
- Your SSH public key for authorized access

## Deployment Workflow

### 1. Initial Deployment

Deploy the VM configuration (initrd SSH won't work yet):

```bash
# Deploy to your VM
./scripts/deploy-vm.sh deploy nixos-vm-minimal <VM_IP>

# Or for local VM with default IP
./scripts/deploy-vm.sh deploy-local
```

**Note**: The first deployment will complete but initrd SSH won't work yet because SSH host keys don't exist.

### 2. Generate SSH Host Keys

After the initial deployment, generate SSH keys for initrd:

```bash
# SSH into the deployed system
ssh dan@<VM_IP>

# Generate initrd SSH host keys
sudo /path/to/nix-config/scripts/generate-initrd-keys.sh

# Rebuild to include the generated keys in initrd
sudo nixos-rebuild switch --flake /path/to/nix-config#nixos-vm-minimal
```

### 3. Test Remote Unlocking

After rebuild and reboot, test the remote unlocking:

```bash
# Connect during boot (immediate LUKS passphrase prompt)
ssh -p 2222 root@<VM_IP>

# Enter LUKS passphrase when prompted
# Connection closes automatically, boot continues
```

### 4. Verify Normal Boot

After successful unlock, verify normal SSH access:

```bash
# Test normal SSH after full boot
./scripts/deploy-vm.sh check-ssh <VM_IP>
```

## Configuration Details

### SSH Configuration

```nix
boot.initrd.network.ssh = {
  enable = true;
  port = 2222;
  shell = "/bin/cryptsetup-askpass";  # Direct LUKS prompting
  hostKeys = [
    "/etc/secrets/initrd/ssh_host_rsa_key"      # Auto-generated
    "/etc/secrets/initrd/ssh_host_ed25519_key"  # Auto-generated
  ];
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWvGgnlCq6l+ObGMVLLs34CP0vEX+Edf7sx6/3BvDpQ dan"
  ];
};
```

### Network Features

- **DHCP**: Automatic IP configuration in initrd
- **Virtio networking**: Optimized for VM environments
- **No firewall**: initrd operates before main system firewall

### Security Features

- **Separate SSH keys**: Auto-generated keys specific to initrd (stored in Nix store)
- **Key-based auth**: Only your SSH public key can access initrd environment
- **Limited shell**: Direct connection to `cryptsetup-askpass`, no shell access
- **Automatic cleanup**: SSH session terminates after unlock

## Testing Commands

```bash
# Check if initrd SSH is responding during boot
./scripts/deploy-vm.sh check-initrd <VM_IP>

# Check normal SSH after boot
./scripts/deploy-vm.sh check-ssh <VM_IP>

# Test complete deployment workflow
./scripts/deploy-vm.sh deploy nixos-vm-minimal <VM_IP>
```

## Troubleshooting

### SSH Connection Issues

- Verify VM network connectivity: `ping <VM_IP>`
- Check VM console for boot errors
- Ensure port 2222 isn't blocked by network firewalls

### LUKS Unlock Issues

- Verify correct LUKS passphrase
- Check VM console for cryptsetup errors
- Ensure LUKS device exists: `/dev/disk/by-partlabel/crypted`

### Boot Hanging

- Check VM console output for errors
- Verify network interface configuration
- Ensure all required kernel modules loaded

## Advanced Configuration

### Static IP Configuration

For static IP instead of DHCP in initrd:

```nix
boot.initrd.network.postCommands = ''
  ip addr add 192.168.1.100/24 dev eth0
  ip route add default via 192.168.1.1
'';
```

### Multiple LUKS Devices

For systems with multiple encrypted volumes:

```nix
boot.initrd.luks.devices = {
  "crypted-root" = {
    device = "/dev/disk/by-partlabel/crypted";
    allowDiscards = true;
  };
  "crypted-home" = {
    device = "/dev/disk/by-partlabel/home";
    allowDiscards = true;
  };
};
```

### Key File Automation

For automated unlocking with key files:

```nix
boot.initrd.luks.devices."crypted" = {
  device = "/dev/disk/by-partlabel/crypted";
  keyFile = "/crypto_keyfile.bin";
  allowDiscards = true;
};
```

## Security Considerations

- **SSH keys are not secret**: initrd SSH keys are stored in the Nix store
- **Use strong passphrases**: LUKS passphrase is your primary security
- **Network access control**: Consider restricting network access to port 2222
- **Key rotation**: Periodically rebuild configuration to rotate SSH keys
- **Monitor access**: Log and monitor SSH connections to initrd environment

## Files Modified

This configuration modifies:

- [`hardware.nix`](../hosts/nixos-vm-minimal/hardware.nix) - initrd network and SSH setup
- [`default.nix`](../hosts/nixos-vm-minimal/default.nix) - main system configuration
- [`deploy-vm.sh`](../scripts/deploy-vm.sh) - deployment script enhancements

## Example Session

```bash
$ ssh -p 2222 root@192.168.64.2
Warning: Permanently added '[192.168.64.2]:2222' (ED25519) to the list of known hosts.

Please unlock disk crypted:
Password: [enter LUKS passphrase]

Connection to 192.168.64.2 closed.
# Boot continues automatically
```

The system is now ready for remote LUKS unlocking!
