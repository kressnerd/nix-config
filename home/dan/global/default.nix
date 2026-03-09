{
  config,
  pkgs,
  lib,
  ...
}: {
  home.stateVersion = "25.11";

  # Suppress options.json generation to avoid nixpkgs store path context warning
  # (upstream nixosOptionsDoc issue with flakes-based setups)
  manual.manpages.enable = false;

  home.packages = with pkgs; [
    htop
    ripgrep
  ];

  programs.home-manager.enable = true;
}
