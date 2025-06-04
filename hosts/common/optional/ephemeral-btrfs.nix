# This file contains an ephemeral btrfs root configuration
{
  lib,
  config,
  ...
}: let
  hostname = config.networking.hostName;
  wipeScript = ''
    mkdir /btrfs_tmp
    mount /dev/root_vg/root /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';
  phase1Systemd = config.boot.initrd.systemd.enable;
in {
  boot.initrd = {
    supportedFilesystems = ["btrfs"];
    postDeviceCommands = lib.mkAfter wipeScript;
  };

  fileSystems = {
    "/" = lib.mkDefault {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=root" "noatime" "compress=zstd" ];
    };

    "/nix" = lib.mkDefault {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "compress=zstd" ];
    };

    "/persist" = lib.mkDefault {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=persist" "noatime" "compress=zstd" ];
      neededForBoot = true;
    };

    "/swap" = lib.mkDefault {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [
        "subvol=swap"
        "noatime"
      ];
    };
  };
}
