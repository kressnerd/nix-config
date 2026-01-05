{
  config,
  pkgs,
  lib,
  pkgs-unstable,
  ...
}: {
  home.stateVersion = "25.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
    secrets = {
      "git/personal/name" = {};
      "git/personal/email" = {};
      "git/personal/folder" = {};
      "git/company/name" = {};
      "git/company/email" = {};
      "git/company/folder" = {};
      "git/client001/name" = {};
      "git/client001/email" = {};
      "git/client001/folder" = {};
      "git/client002/name" = {};
      "git/client002/email" = {};
      "git/client002/folder" = {};
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    htop
    ripgrep
  ];
}
