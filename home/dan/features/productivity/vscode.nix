{ config, pkgs, pkgs-unstable, ... }:

{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        catppuccin.catppuccin-vsc

        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        github.copilot
        kamadorueda.alejandra
        vscodevim.vim
      ]
      ++ (with pkgs-unstable.vscode-extensions; [
        github.copilot-chat
        jnoortheen.nix-ide
        rooveterinaryinc.roo-cline
      ]);

      userSettings = {
        "editor.formatOnSave" = true;
        "editor.fontSize" = 12;
        "editor.fontFamily" = "JetBrainsMono Nerd Font";
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "extensions.autoUpdate" = false;
        "extensions.autoCheckUpdates" = false;
        "npm.fetchOnlinePackageInfo" = false;
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none";
        "workbench.enableExperiments" = false;
        "workbench.settings.enableNaturalLanguageSearch" = false;
        "workbench.colorTheme" = "Catppuccin Latte";
        "workbench.iconTheme" = "catppuccin-latte";

        "vim.handleKeys" = {
          "<C-d>" = true;
          "<C-s>" = false;
          "<C-z>" = false;
        };

        "catppuccin.accentColor" = "blue";
      };
    };
  };
}
