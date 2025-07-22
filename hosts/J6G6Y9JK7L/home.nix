{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.05";

  imports = [ ./git.nix ];

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
    };
  };

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
      drs = "sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config";
      ll = "ls -la";
    };
  };

  programs.keepassxc.enable = true;

  programs.librewolf.enable = true;

  programs.vscode = {
    enable = true;

    mutableExtensionsDir = false;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        github.copilot
        github.copilot-chat
      ];
      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none";
        "extensions.autoUpdate" = false;
        "extensions.autoCheckUpdates" = false;
        "npm.fetchOnlinePackageInfo" = false;
        "workbench.enableExperiments" = false;
        "workbench.settings.enableNaturalLanguageSearch" = false;
      };
    };
  };

  # Add some useful packages
  home.packages = with pkgs; [
    htop
    ripgrep

    # GUI
    jetbrains-toolbox
  ];
}
