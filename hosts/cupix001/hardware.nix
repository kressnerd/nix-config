# Hardware configuration for cupix001 — netcup KVM VPS (UEFI boot)
# Disk layout managed by disko (see ./disko.nix)
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
}
