{ lib, pkgs, ... }:
{
  imports = [
    ../common/global
    ../common/users/dan.nix
    ./hardware.nix
    ./disko.nix
    ./options.nix
    ./networking.nix
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
}
