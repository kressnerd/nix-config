_: {
  # Extensions and theme managed via VS Code UI
  # Install 'One Light Theme' from marketplace (e.g., 'Atom One Light Theme' by akamud)
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;

    # Extensions and settings now managed by VSCode itself
    # Configure through VSCode UI: Preferences > Settings
    # Extensions: Cmd/Ctrl+Shift+X
  };
}
