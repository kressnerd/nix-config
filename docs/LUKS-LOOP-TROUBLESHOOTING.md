# LUKS Loop Issue Troubleshooting

## Problem Description

SSH connection to initrd works correctly, but `cryptsetup-askpass` gets stuck in an infinite loop:

```
Passphrase for /dev/disk/by-partlabel/crypted:
Waiting 10 seconds for LUKS to request a passphrase.... - success
[repeats indefinitely]
```

## Root Causes and Solutions

### 1. Device Path Issues

**Problem**: The LUKS device path `/dev/disk/by-partlabel/crypted` may not exist or point to wrong device.

**Diagnostic**: After rebuild and reboot, check console output for debug messages showing available devices.

**Solutions**:

- Verify disko configuration matches actual disk layout
- Check if VM disk is `/dev/vda` vs `/dev/sda`
- Ensure partition labels are correctly set

### 2. Multiple LUKS Configurations

**Problem**: Conflicting LUKS device configurations cause askpass to loop.

**Check**: Look for duplicate LUKS device definitions in:

- `disko.nix` (line 77: `boot.initrd.luks.devices."crypted"`)
- `hardware.nix` (should not have additional LUKS config)

**Solution**: Ensure only one LUKS device configuration exists.

### 3. Device Already Unlocked

**Problem**: LUKS device is already unlocked, but askpass keeps trying.

**Diagnostic**: Check if `/dev/mapper/crypted` already exists before unlock attempt.

**Solution**: Modify LUKS configuration to detect already-unlocked devices.

### 4. Timing Issues

**Problem**: Device not ready when askpass starts.

**Solution**: The enhanced `postDeviceCommands` now waits up to 30 seconds for device availability.

## Testing the Fix

### 1. Rebuild and Test

```bash
# On the VM
sudo nixos-rebuild switch

# Reboot and test
sudo reboot
```

### 2. Check Debug Output

During boot, look for these debug messages in console:

```
=== initrd Network Setup Debug ===
Available LUKS devices:
[should show /dev/disk/by-partlabel/crypted]

Waiting for disk labels...
LUKS device found: /dev/disk/by-partlabel/crypted
[should show device details]
```

### 3. Connect and Test

```bash
ssh -p 2222 root@<VM_IP>
```

**Expected behavior**: Single password prompt that unlocks and continues boot.

## Manual Debugging in initrd

If you can get an interactive shell in initrd (modify SSH shell temporarily):

```bash
# Check available devices
ls -la /dev/disk/by-partlabel/

# Check if already unlocked
ls -la /dev/mapper/

# Manual unlock test
cryptsetup luksOpen /dev/disk/by-partlabel/crypted crypted

# Check unlock success
ls -la /dev/mapper/crypted
```

## Alternative Approaches

### Option 1: Use Device Path Instead of Label

If by-partlabel doesn't work, modify disko.nix:

```nix
boot.initrd.luks.devices."crypted" = {
  device = "/dev/vda2";  # Direct device path
  allowDiscards = true;
  bypassWorkqueues = true;
};
```

### Option 2: Add Fallback Device Detection

```nix
boot.initrd.luks.devices."crypted" = {
  device = "/dev/disk/by-partlabel/crypted";
  fallbackToPassword = true;
  allowDiscards = true;
  bypassWorkqueues = true;
};
```

## Next Steps

1. **Rebuild** with debugging configuration
2. **Boot** and check console for debug output
3. **Connect** via SSH and test unlock
4. **Report** what debug messages appear
5. **Adjust** configuration based on findings

The debug output will show exactly what devices are available and help identify why the loop occurs.
