{
  config,
  pkgs,
  lib,
  ...
}: {
  home.stateVersion = "25.11";

  # Basic user information
  home.username = "dan";
  home.homeDirectory = "/home/dan";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Essential user packages
  home.packages = with pkgs; [
    # System packages are sufficient for now
  ];

  # Basic git configuration
  programs.git = {
    enable = true;
    settings.user = {
      name = "Dan";
      email = "git@pronix.local";
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    PAGER = "less";
  };
}
