{ ... }:
{
  imports = [
    ../../hosts/common/global
    ../../hosts/common/users/dan.nix
    ./hardware.nix
  ];

  networking.hostName = "CHANGEME";
  system.stateVersion = "25.11";
}
