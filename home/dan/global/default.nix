{
  config,
  pkgs,
  lib,
  ...
}: {
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    htop
    ripgrep
  ];

  programs.home-manager.enable = true;
}
