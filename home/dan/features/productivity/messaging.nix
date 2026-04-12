{ pkgs, ... }:
{
  home.packages = with pkgs; [
    signal-desktop
    threema-desktop
  ];
}
