{ config, pkgs, lib, inputs, ... }:

{
  home = {
    stateVersion = "25.05";

    # Common packages for all hosts
    packages = with pkgs; [
      htop
      ripgrep
    ];
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # SOPS configuration
  sops = {
    defaultSopsFile = ../../../hosts/J6G6Y9JK7L/secrets.yaml;
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
    };
  };
}
