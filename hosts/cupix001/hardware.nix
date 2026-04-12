# Hardware configuration for cupix001 — netcup KVM VPS (UEFI boot)
# fileSystems and boot.loader will be replaced by disko in Epic 2
_: {
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_scsi"
      "virtio_blk"
      "virtio_net"
    ];
  };

  # Placeholder root filesystem — replaced by disko in Epic 2
  fileSystems."/" = {
    device = "/dev/vda2";
    fsType = "ext4";
  };

  # Placeholder EFI system partition — replaced by disko in Epic 2
  fileSystems."/boot" = {
    device = "/dev/vda1";
    fsType = "vfat";
  };

  swapDevices = [ ];
}
