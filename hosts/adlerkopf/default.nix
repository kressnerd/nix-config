{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../common/global
    ../common/users/dan.nix
    ./hardware.nix
    ./disko.nix
    ./options.nix
    ./networking.nix
    ./caddy.nix
    ./tpm2.nix
    ./impermanence.nix
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
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

  # SOPS secrets configuration
  # Age key derived from SSH host key persisted under /persist/system
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/persist/system/etc/ssh/ssh_host_ed25519_key" ];
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
      # Disable TPM2/LUKS and impermanence rollback in VM — no encrypted disk
      initrd = {
        systemd = {
          enable = lib.mkForce false;
          services.rollback = lib.mkForce { };
        };
        luks.devices = lib.mkForce { };
        availableKernelModules = lib.mkForce [
          "virtio_pci"
          "virtio_blk"
          "virtio_net"
          "xhci_pci"
        ];
      };
      kernelModules = lib.mkForce [ ];
    };

    # Disable SOPS secret decryption in VM — no age key available
    sops.age = {
      sshKeyPaths = lib.mkForce [ ];
      keyFiles = lib.mkForce [ ];
    };
  };
}
