{
  config,
  lib,
  pkgs-unstable,
  ...
}:
{
  home = {
    packages = with pkgs-unstable; [
      vscode.fhs
    ];

    # Tell VS Code to use gnome-libsecret for credential storage via D-Bus Secret Service
    file.".vscode/argv.json".text = builtins.toJSON {
      password-store = "gnome-libsecret";
      enable-crash-reporter = false;
    };

    persistence.${config.myHome.persistence.root}.directories =
      lib.mkIf config.myHome.persistence.enable
        [
          ".config/Code"
          ".vscode/extensions"
          ".roo"
        ];
  };
}
