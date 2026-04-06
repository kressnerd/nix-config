{ pkgs, ... }:
{
  home.packages = with pkgs; [
    colmena # NixOS fleet deployment tool
  ];
}
