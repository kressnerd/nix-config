{
  config,
  lib,
  ...
}: {
  disko.devices = {
    disk = {
      # VM disk
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
                mountOptions = ["defaults" "fmask=0022" "dmask=0022"];
              };
            };

            # Root partition (unencrypted for VM testing)
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
                  # Nix store (persistent)
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  # Persistent data
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  # Logs (persistent)
                  "/var-log" = {
                    mountpoint = "/var/log";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Impermanence: clean root on boot
  boot.initrd.postDeviceCommands = lib.mkBefore ''
    mkdir -p /mnt
    mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos /mnt
    if [ -e /mnt/root ]; then
        mkdir -p /mnt/old_roots
        timestamp=$(date --date="@$(stat -c %Y /mnt/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /mnt/root "/mnt/old_roots/$timestamp"
    fi
    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/mnt/$i"
        done
        btrfs subvolume delete "$1"
    }
    for i in $(find /mnt/old_roots/ -maxdepth 1 -mtime +7); do
        delete_subvolume_recursively "$i"
    done
    btrfs subvolume create /mnt/root
    umount /mnt
  '';

  # Required directories
  fileSystems."/persist".neededForBoot = true;

  # Additional filesystem configuration for VM optimization
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_net"
  ];
}
