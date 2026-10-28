{ pkgs, ... }:
{
  home.stateVersion = "26.05";

  # Suppress options.json generation to avoid nixpkgs store path context warning
  # (upstream nixosOptionsDoc issue with flakes-based setups)
  manual.manpages.enable = false;

  home.packages = with pkgs; [
    htop
  ];

  programs.home-manager.enable = true;
}
