# initrd Network Troubleshooting Guide

## Current Issue: Network Not Working in initrd

The VM shows the LUKS prompt but SSH on port 2222 is not accessible because network isn't initializing in initrd.

## Diagnostic Steps

### 1. Check VM Console for Network Messages

When the VM boots and shows the LUKS prompt, look for these messages in the console:

```
[    X.XXXXXX] virtio_net virtio0: registered device ethX
[    X.XXXXXX] IPv6: ADDRCONF(NETDEV_UP): ethX: link is not ready
[    X.XXXXXX] IPv6: ADDRCONF(NETDEV_CHANGE): ethX: link became ready
```

### 2. Add Network Debugging to Configuration

Add this to hardware.nix initrd.network section:

```nix
network = {
  enable = true;

  # Force DHCP client
  udhcpc.enable = true;

  # Debug network initialization
  postCommands = ''
    # Show available network interfaces
    echo "=== Network Interfaces ==="
    ip link show

    # Show loaded network modules
    echo "=== Network Modules ==="
    lsmod | grep -E "(virtio|net)"

    # Try to bring up interface manually
    echo "=== Manual Network Setup ==="
    for iface in eth0 ens3 enp0s1; do
      if ip link show $iface 2>/dev/null; then
        echo "Found interface: $iface"
        ip link set $iface up
        udhcpc -i $iface -n -q
        ip addr show $iface
        break
      fi
    done

    # Show routing table
    echo "=== Routing Table ==="
    ip route show

    # Test SSH daemon
    echo "=== SSH Status ==="
    ps aux | grep ssh || echo "SSH not running"
    netstat -ln | grep :2222 || echo "Port 2222 not listening"
  '';

  ssh = {
    enable = true;
    # ... rest of SSH config
  };
};
```

### 3. Alternative Network Driver Configuration

If virtio_net isn't working, try adding these modules:

```nix
boot.initrd.availableKernelModules = [
  # ... existing modules ...

  # Alternative network drivers
  "e1000"      # Intel Gigabit Ethernet
  "e1000e"     # Intel PRO/1000
  "virtio_net" # Virtio networking (paravirtualized)
  "8139too"    # Realtek RTL8139
  "ne2k_pci"   # NE2000 PCI
];
```

### 4. VM Network Configuration Check

Ensure your VM network settings are correct:

**UTM/QEMU Settings:**

- Network Mode: Shared (NAT) or Bridged
- Interface Type: virtio-net-pci (recommended)
- Alternative: e1000 or rtl8139

### 5. Force Network Interface Name

Add kernel parameter to force interface naming:

```nix
boot.kernelParams = [
  "console=ttyS0,115200n8"
  "console=tty0"
  "net.ifnames=0"  # Use old-style eth0 naming
];
```

### 6. Static IP Configuration (if DHCP fails)

```nix
network = {
  enable = true;
  postCommands = ''
    # Static IP configuration
    ip addr add 192.168.64.10/24 dev eth0
    ip route add default via 192.168.64.1
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
  '';
};
```

## Quick Test Commands

After applying network debugging config and rebooting:

1. Watch console output during boot
2. Look for network interface detection
3. Check if SSH daemon starts
4. Try connecting from host:

```bash
# Test basic connectivity
ping <VM_IP>

# Check SSH ports
nmap -p 22,2222 <VM_IP>

# Try SSH with verbose output
ssh -vvv -p 2222 root@<VM_IP>
```

## Common Issues and Solutions

### Issue: No Network Interface Detected

**Solution**: Check VM network adapter type, use virtio-net-pci

### Issue: Interface Detected but No IP

**Solution**: Add `udhcpc.enable = true` and manual DHCP commands

### Issue: Network Works but SSH Doesn't Start

**Solution**: Check SSH host keys exist: `ls /etc/secrets/initrd/`

### Issue: SSH Starts but Can't Connect

**Solution**: Verify authorized keys and check firewall/network routing

## Next Steps

1. Apply the debugging configuration
2. Rebuild and reboot the VM
3. Check console output for network messages
4. Report back what you see in the network setup section
