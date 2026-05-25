{ lib, ... }:
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

  system.stateVersion = "25.11";
}
