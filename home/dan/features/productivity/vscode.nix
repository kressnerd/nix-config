{ config, pkgs, pkgs-unstable, ... }:

{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = [
        pkgs.vscode-extensions.github.copilot
        pkgs-unstable.vscode-extensions.github.copilot-chat
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
}
