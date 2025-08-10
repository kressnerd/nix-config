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

  # Boot configuration optimized for UTM/QEMU
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "virtio_pci"
        "usbhid"
        "usb_storage"
        "sr_mod"
        "virtio_blk"
        "virtio_net"
        "virtio_balloon"
        "virtio_console"
      ];
      kernelModules = [];
    };

    kernelModules = [];

    # Enable virtio modules for better VM performance and reduce boot time
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];

    extraModulePackages = [];

    # UEFI boot configuration for VM
    loader = {
      grub.enable = false;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # File systems configuration - using ext4 for simplicity (no btrfs/impermanence)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = ["noatime"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  # No swap for VM (can be added if needed)
  swapDevices = [];

  # Network interfaces
  networking.useDHCP = lib.mkDefault true;

  # Platform-agnostic - can be aarch64-linux or x86_64-linux
  # Will be overridden in flake.nix based on the system
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # VM-specific services and optimizations
  services = {
    # Enable SPICE agent for better integration with UTM/QEMU
    spice-vdagentd.enable = true;

    # QEMU guest agent for VM management
    qemuGuest.enable = true;
  };

  # Graphics configuration for Hyprland in VM
  services.xserver = {
    enable = lib.mkDefault false; # Disabled by default, Hyprland doesn't need it
    videoDrivers = ["qxl" "virtio"];
  };

  # Power management optimized for VMs
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Memory and CPU optimizations for virtualization
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
    # Additional VM optimizations
    "vm.vfs_cache_pressure" = 50;
    "kernel.sched_migration_cost_ns" = 5000000;
  };

  # Hardware enablement for VM graphics
  hardware = {
    graphics.enable = true;
    # Enable firmware if needed
    enableRedistributableFirmware = lib.mkDefault true;
  };
}
