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
    for i in $(seq 1 10); do
      if [ -e /dev/disk/by-partlabel/crypted ] && [ -e /dev/disk/by-label/boot ]; then
        echo "Disk labels found!"
        break
      fi
      sleep 1
    done
  '';
}
