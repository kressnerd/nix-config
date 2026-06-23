{ pkgs, ... }:
{
  home.packages = with pkgs; [
    age
    sops
    age-plugin-yubikey
  ];
}
