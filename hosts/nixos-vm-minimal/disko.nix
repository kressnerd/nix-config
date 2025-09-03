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
              size = "512M";
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

            # Root partition
            root = {
              priority = 2;
              name = "root";
              label = "nixos";
              size = "100%"; # Use remaining space
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

  # Additional filesystem configuration for VM optimization
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_net"
  ];

  # Ensure proper disk labels are available during boot
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # Wait for disk labels to be available
    echo "Waiting for disk labels..."
    for i in $(seq 1 10); do
      if [ -e /dev/disk/by-label/nixos ] && [ -e /dev/disk/by-label/boot ]; then
        echo "Disk labels found!"
        break
      fi
      sleep 1
    done
  '';
}
