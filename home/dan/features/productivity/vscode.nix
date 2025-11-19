{
  config,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;

    # Extensions and settings now managed by VSCode itself
    # Configure through VSCode UI: Preferences > Settings
    # Extensions: Cmd/Ctrl+Shift+X
  };
}
