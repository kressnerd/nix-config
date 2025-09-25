{
  config,
  lib,
  ...
}: {
  disko.devices = {
    disk = {
      # Primary VM disk - matches UTM's typical setup
      vda = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            # ESP/Boot partition
            ESP = {
              priority = 1;
              name = "ESP";
              label = "boot";
              size = "1G";
              type = "EF00"; # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "fmask=0022"
                  "dmask=0022"
                ];
              };
            };

            # Root partition (encrypted)
            root = {
              priority = 2;
              name = "root";
              label = "crypted";
              size = "100%"; # Use remaining space
              content = {
                type = "luks";
                name = "crypted";
                passwordFile = "/tmp/secret.key"; # Will be prompted during installation
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = [
                    "defaults"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };

  # Additional filesystem configuration for VM optimization
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_net"
    # LUKS encryption support
    "aes"
    "dm_crypt"
    "cryptd"
  ];

  # LUKS configuration
  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-partlabel/crypted";
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  # Ensure proper disk labels are available during boot
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # Wait for disk labels to be available
    echo "Waiting for disk labels..."
    for i in $(seq 1 30); do
      if [ -e /dev/disk/by-partlabel/crypted ]; then
        echo "LUKS device found: /dev/disk/by-partlabel/crypted"
        ls -la /dev/disk/by-partlabel/crypted
        break
      fi
      echo "Waiting for LUKS device... ($i/30)"
      sleep 1
    done

    # Debug: Show all available devices
    echo "=== Available devices ==="
    ls -la /dev/vd* 2>/dev/null || echo "No /dev/vd* devices"
    ls -la /dev/sd* 2>/dev/null || echo "No /dev/sd* devices"
    echo "=== Partition labels ==="
    ls -la /dev/disk/by-partlabel/ 2>/dev/null || echo "No by-partlabel directory"
  '';
}
