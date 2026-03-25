_: {
  # Extensions and theme managed via VS Code UI
  # Install "Catppuccin for VSCode" from marketplace, set theme to "Catppuccin Latte"
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;

    # Extensions and settings now managed by VSCode itself
    # Configure through VSCode UI: Preferences > Settings
    # Extensions: Cmd/Ctrl+Shift+X
  };
}
