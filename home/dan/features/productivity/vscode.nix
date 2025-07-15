{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = with pkgs.vscode-extensions;
        [
          catppuccin.catppuccin-vsc
          catppuccin.catppuccin-vsc-icons

          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
          github.copilot
          kamadorueda.alejandra
        ]
        ++ (with pkgs-unstable.vscode-extensions; [
          github.copilot-chat
          jnoortheen.nix-ide
          rooveterinaryinc.roo-cline
        ]);

      userSettings = {
        "catppuccin.accentColor" = "blue";
        "editor.fontFamily" = "JetBrainsMono Nerd Font";
        "editor.fontSize" = 12;
        "editor.formatOnSave" = true;
        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = false;
        "npm.fetchOnlinePackageInfo" = false;
        "telemetry.telemetryLevel" = "off";
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "update.mode" = "none";
        "vim.handleKeys" = {
          "<C-d>" = true;
          "<C-s>" = false;
          "<C-z>" = false;
        };
        "workbench.colorTheme" = "Catppuccin Latte";
        "workbench.enableExperiments" = false;
        "workbench.iconTheme" = "catppuccin-latte";
        "workbench.settings.enableNaturalLanguageSearch" = false;
        "roo-cline.allowedCommands" = [
          "npm test"
          "npm install"
          "tsc"
          "git log"
          "git diff"
          "git show"
        ];
      };
    };
  };
}
