{
  config,
  lib,
  ...
}: {
  disko.devices = {
    disk = {
      # Single VM disk (simplified from RAID setup)
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
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["defaults" "umask=0077"];
              };
            };

            # Root partition with btrfs (no RAID, no LUKS for VM simplicity)
            root = {
              priority = 2;
              name = "root";
              label = "nixos";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  # Root subvolume (ephemeral)
                  "/" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  # Nix store
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  # Persistent data
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  # Logs
                  "/var-log" = {
                    mountpoint = "/var/log";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  # Swap file (16G)
                  "/.swapvol" = {
                    mountpoint = "/.swapvol";
                    swap = {
                      swapfile.size = "4G"; # Reduced for VM
                    };
                  };
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
  ];

  # Ensure proper disk labels are available during boot
  boot.initrd.postDeviceCommands = lib.mkBefore ''
    # Wait for disk labels to be available
    echo "Waiting for disk labels..."
    for i in $(seq 1 10); do
      if [ -e /dev/disk/by-label/nixos ]; then
        echo "Disk labels found!"
        break
      fi
      sleep 1
    done
  '';
}
