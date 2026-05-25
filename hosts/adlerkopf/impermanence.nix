_: {
  boot.initrd.systemd.services.rollback = {
    description = "Rollback btrfs @root to blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@cryptroot.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir /btrfs_tmp
      mount -t btrfs /dev/mapper/cryptroot /btrfs_tmp
      btrfs subvolume list -o /btrfs_tmp/@root | cut -f9 -d' ' |
        while read sub; do btrfs subvolume delete "/btrfs_tmp/$sub"; done || true
      btrfs subvolume delete /btrfs_tmp/@root
      btrfs subvolume snapshot /btrfs_tmp/@root-blank /btrfs_tmp/@root
      umount /btrfs_tmp
    '';
  };

  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/caddy"
      "/var/lib/private/acme"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
