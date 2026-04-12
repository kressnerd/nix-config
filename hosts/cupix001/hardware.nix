# Hardware configuration for cupix001 — netcup KVM VPS
# Boot mode determined in prerequisites step 2; update to systemd-boot if UEFI
# fileSystems and boot.loader.grub.devices will be replaced by disko in Step 2
_: {
  boot = {
    loader.grub = {
      enable = true;
      # Placeholder device — replaced by disko in disk-layout step
      devices = [ "/dev/vda" ];
    };
    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_scsi"
      "virtio_blk"
      "virtio_net"
    ];
  };

  # Placeholder root filesystem — replaced by disko in disk-layout step
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  swapDevices = [ ];
}
