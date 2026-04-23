{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libreoffice.unwrapped
  ];
}
