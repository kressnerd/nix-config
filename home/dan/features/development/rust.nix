{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo
    gcc
    pkg-config
    rustc
  ];
}
