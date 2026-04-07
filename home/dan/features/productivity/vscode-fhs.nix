{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    vscode.fhs
  ];

  # Tell VS Code to use gnome-libsecret for credential storage via D-Bus Secret Service
  home.file.".vscode/argv.json".text = builtins.toJSON {
    password-store = "gnome-libsecret";
  };
}
