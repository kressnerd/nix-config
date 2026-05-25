{ lib, pkgs, ... }:
{
  imports = [
    ../common/global
    ../common/users/dan.nix
    ./hardware.nix
    ./disko.nix
    ./options.nix
    ./networking.nix
    ./caddy.nix
    ../../tests/assertions
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "adlerkopf";

  programs.fish.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.dan = {
    extraGroups = [ "sudo" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnzrOhWy7kCWs/MhcYTEID/TQ78jhRAFfy8NWC1Cgh9 thiniel"
    ];
  };

  system.stateVersion = "25.11";

  virtualisation.vmVariant = {
    adlerkopf.vmMode = true;

    virtualisation = {
      diskSize = 8192;
      memorySize = 2048;
      cores = 2;
    };

    # Simple root filesystem — no LUKS, no btrfs subvolumes
    fileSystems = lib.mkForce {
      "/" = {
        device = "/dev/vda";
        fsType = "ext4";
        autoResize = true;
      };
    };

    swapDevices = lib.mkForce [ ];

    # Override Caddy to use plain pkgs.caddy (avoids the FOD hash)
    services.caddy.package = lib.mkForce pkgs.caddy;

    # Allow password login in VM for easy testing
    users.users.dan.password = lib.mkForce "test";

    hardware.cpu.intel.updateMicrocode = lib.mkForce false;

    boot = {
      initrd.availableKernelModules = lib.mkForce [
        "virtio_pci"
        "virtio_blk"
        "virtio_net"
        "xhci_pci"
      ];
      kernelModules = lib.mkForce [ ];
    };
  };
}
