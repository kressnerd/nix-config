{ config, pkgs, ... }:

{
  home.stateVersion = "25.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Basic git configuration
  programs.git = {
    enable = true;
    userName = "User Name";
    userEmail = "me@example.com";
  };

  # Configure zsh
  programs.zsh = {
    enable = true;
    shellAliases = {
      drs = "sudo darwin-rebuild switch --flake ~/Projects/PRIVATE/nix-config";
      ll = "ls -la";
    };
  };

  # Add some useful packages
  home.packages = with pkgs; [
    htop
    ripgrep
    keepassxc
  ];
}
