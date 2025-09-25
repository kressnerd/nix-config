# Remote LUKS Unlocking: Technical Reference

This document provides technical details for the remote LUKS unlocking implementation in the nixos-vm-minimal VM configuration.

## Architecture Overview

The remote unlocking system operates in the initrd (initial ramdisk) environment before the main NixOS system boots:

```
Boot Flow:
1. UEFI/BIOS loads bootloader
2. Bootloader loads kernel + initrd
3. initrd starts with network + SSH server (port 2222)
4. User connects via SSH → cryptsetup-askpass
5. LUKS unlock → initrd exits → main system boots
6. Main system SSH available (port 22)
```

## Technical Implementation

### initrd Network Configuration

Located in [`hardware.nix`](../hosts/nixos-vm-minimal/hardware.nix):

```nix
boot.initrd = {
  availableKernelModules = [
    # ... other modules ...
    "virtio_net"  # Network support for VMs
  ];

  network = {
    enable = true;

    ssh = {
      enable = true;
      port = 2222;
      shell = "/bin/cryptsetup-askpass";  # Direct LUKS unlock

      # Auto-generated during NixOS build
      hostKeys = [
        "/etc/secrets/initrd/ssh_host_rsa_key"
        "/etc/secrets/initrd/ssh_host_ed25519_key"
      ];

      # Your SSH public key for access
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWvGgnlCq6l+ObGMVLLs34CP0vEX+Edf7sx6/3BvDpQ dan"
      ];
    };
  };
};
```

### LUKS Device Configuration

Located in [`disko.nix`](../hosts/nixos-vm-minimal/disko.nix):

```nix
# Partition with LUKS encryption
root = {
  content = {
    type = "luks";
    name = "crypted";
    passwordFile = "/tmp/secret.key";  # For initial setup
    settings = {
      allowDiscards = true;      # SSD optimization
      bypassWorkqueues = true;   # Performance optimization
    };
  };
};

# Additional LUKS configuration in hardware.nix
boot.initrd.luks.devices."crypted" = {
  device = "/dev/disk/by-partlabel/crypted";
  allowDiscards = true;
  bypassWorkqueues = true;
};
```

## SSH Key Management

### Automatic Key Generation

SSH host keys for initrd are **automatically generated** during the NixOS build process:

- Keys are created in `/etc/secrets/initrd/` by the build system
- No manual generation required before deployment
- Keys are stored in the Nix store (not secret)

### Key Security Model

```
Security Boundary:
┌─────────────────────┐
│ LUKS Passphrase     │ ← Primary security (secret)
└─────────────────────┘
┌─────────────────────┐
│ SSH Public Key      │ ← Access control (your key)
└─────────────────────┘
┌─────────────────────┐
│ SSH Host Keys       │ ← Authentication only (not secret)
└─────────────────────┘
```

**Important**: SSH host keys are **not secret** - they're stored in the Nix store and provide only host authentication, not security.

### Correct Deployment Sequence

1. **Initial deployment**: NixOS builds without initrd SSH (keys don't exist)
2. **Generate keys**: Run `generate-initrd-keys.sh` on deployed system
3. **Rebuild**: `nixos-rebuild` copies keys into initrd
4. **Reboot**: initrd SSH now works with generated keys

## Network and Firewall

### initrd vs Main System

```
Boot Phase         │ SSH Port │ Firewall      │ Purpose
─────────────────────────────────────────────────────────
initrd (early boot) │ 2222     │ None          │ LUKS unlock
Main system        │ 22       │ iptables/nft  │ Normal admin
```

**Key Point**: No firewall configuration needed for port 2222 because:

- initrd runs before the main system firewall loads
- Port 2222 is only active during the brief initrd phase
- Once boot completes, nothing listens on port 2222

### Network Configuration

- **DHCP**: Automatic IP assignment in initrd
- **Virtio**: Optimized networking for virtualization
- **Interface**: Usually `eth0` or similar in VMs

## Usage Patterns

### Standard Unlock Session

```bash
$ ssh -p 2222 root@vm-ip
Please unlock disk crypted:
Password: ████████████
Connection closed.
```

### Connection Lifecycle

1. **TCP Connect**: SSH client connects to port 2222
2. **Key Exchange**: SSH host key verification
3. **Authentication**: Your SSH key verified against authorized_keys
4. **Shell Exec**: `/bin/cryptsetup-askpass` executed immediately
5. **LUKS Prompt**: Password prompt appears
6. **Unlock**: Passphrase sent to cryptsetup
7. **Success**: Connection terminates, boot continues

### Error Scenarios

```bash
# Wrong passphrase
Please unlock disk crypted:
Password: ████████████
cryptsetup: invalid passphrase
Connection closed.

# LUKS device not found
Please unlock disk crypted:
cryptsetup: device not found
Connection closed.
```

## Advanced Configurations

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

### Static IP Configuration

Override DHCP with static configuration:

```nix
boot.initrd.network.postCommands = ''
  ip addr add 192.168.1.100/24 dev eth0
  ip route add default via 192.168.1.1
  echo "nameserver 8.8.8.8" > /etc/resolv.conf
'';
```

### Key File Automation

For unattended unlocking with key files:

```nix
boot.initrd.luks.devices."crypted" = {
  device = "/dev/disk/by-partlabel/crypted";
  keyFile = "/crypto_keyfile.bin";  # Must be available in initrd
  allowDiscards = true;
};
```

### Custom Shell Scripts

Replace `cryptsetup-askpass` with custom logic:

```nix
boot.initrd.network.ssh.shell = "/bin/custom-unlock";

boot.initrd.network.postCommands = ''
  cat > /bin/custom-unlock <<'EOF'
  #!/bin/sh
  echo "Custom LUKS unlock system"
  echo "Enter passphrase for root:"
  read -s pass
  echo "$pass" | cryptsetup luksOpen /dev/disk/by-partlabel/crypted crypted
  echo "Unlock completed"
  EOF
  chmod +x /bin/custom-unlock
'';
```

## Debugging and Troubleshooting

### initrd Environment Inspection

Connect to the initrd SSH and explore:

```bash
ssh -p 2222 root@vm-ip
# This normally runs cryptsetup-askpass immediately
# To get a shell instead, temporarily change the shell config
```

### Common Issues

**SSH Connection Refused**

- Check VM network connectivity
- Verify VM has reached initrd phase
- Check for network firewall blocking port 2222

**SSH Key Rejected**

- Verify your public key is in the authorized_keys list
- Check key format and encoding
- Ensure private key matches public key

**LUKS Unlock Fails**

- Verify correct passphrase
- Check LUKS device exists: `/dev/disk/by-partlabel/crypted`
- Review VM console for cryptsetup error messages

**Boot Hangs After Unlock**

- Check for filesystem errors on unlocked device
- Verify kernel modules for storage are loaded
- Review systemd logs after boot

### Logging and Monitoring

```bash
# Check SSH connections to initrd (from another system)
journalctl -f | grep "port 2222"

# Monitor unlock attempts
dmesg | grep -i luks

# Check network configuration in initrd
ip addr show
ip route show
```

## Security Considerations

### Threat Model

**Protected Against**:

- Unauthorized disk access (LUKS encryption)
- Unauthorized network access (SSH key authentication)
- MITM attacks (SSH host key verification)

**Not Protected Against**:

- SSH host key stored in Nix store (by design)
- Network sniffing of SSH traffic (use strong SSH)
- Physical access to running system (RAM contents)

### Hardening Options

```nix
# Restrict SSH access
boot.initrd.network.ssh = {
  authorizedKeys = [ "your-key-only" ];  # Specific key only
  extraConfig = ''
    AllowUsers root
    PermitRootLogin forced-commands-only
  '';
};

# Network restrictions (if possible)
boot.initrd.network.postCommands = ''
  # Add iptables rules to restrict source IPs
  iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 2222 -j ACCEPT
  iptables -A INPUT -p tcp --dport 2222 -j DROP
'';
```

### Operational Security

- **Monitor access**: Log all SSH connections to port 2222
- **Rotate keys**: Rebuild configuration periodically to rotate SSH keys
- **Strong passphrases**: Use high-entropy LUKS passphrases
- **Network isolation**: Restrict network access to port 2222 if possible
- **Physical security**: Protect console access to VMs

## Integration

### Deployment Scripts

The [`deploy-vm.sh`](../scripts/deploy-vm.sh) script includes:

- `check-initrd`: Test initrd SSH connectivity
- Automatic detection of LUKS-enabled configurations
- Enhanced error handling for remote unlock scenarios

### Monitoring Integration

```bash
# Check initrd SSH availability
function check_initrd_ssh() {
  local vm_ip="$1"
  timeout 5 ssh -p 2222 -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no root@"$vm_ip" echo "ready" 2>/dev/null
}
```

This technical reference provides the foundation for understanding and extending the remote LUKS unlocking system.
