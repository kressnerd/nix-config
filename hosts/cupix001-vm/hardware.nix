{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Boot loader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Kernel modules for VM (KVM/UTM)
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_net"
  ];

  boot.kernelModules = ["kvm-intel"]; # or kvm-amd

  # Kernel parameters for VM testing (less strict)
  boot.kernel.sysctl = {
    # IP forwarding for Headscale
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # Basic security
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.tcp_syncookies" = 1;
  };

  # Networking hardware (virtio)
  networking.useDHCP = lib.mkDefault true;

  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # VM optimization
  services.qemuGuest.enable = true;
}
