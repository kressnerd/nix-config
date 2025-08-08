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

  # Boot configuration optimized for UTM
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "virtio_pci"
        "usbhid"
        "usb_storage"
        "sr_mod"
        "virtio_blk"
      ];
      kernelModules = [];
    };

    kernelModules = [];

    # Enable virtio modules for better VM performance
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
    ];

    extraModulePackages = [];

    # UEFI boot configuration for VM
    loader = {
      grub.enable = false; # Explicitly disable GRUB
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # File systems configuration for UTM VM
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  # No swap for VM
  swapDevices = [];

  # Network interfaces
  networking.useDHCP = lib.mkDefault true;

  # Hardware platform
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # VM-specific optimizations
  services = {
    # Enable SPICE agent for better integration
    spice-vdagentd.enable = true;

    # QEMU guest agent for VM management
    qemuGuest.enable = true;
  };

  # Video drivers for UTM
  services.xserver = {
    enable = false; # We'll start minimal without X11
    videoDrivers = ["qxl"];
  };

  # Power management for VMs
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Memory and CPU optimizations for virtualization
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
  };
}
