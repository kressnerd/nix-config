# tests/assertions/thiniel-invariants.nix
# Thiniel-specific NixOS module assertions — enforced at evaluation time via nix flake check
# Guarded by hostname to avoid failures on other hosts that import tests/assertions
{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = config.programs.fish.enable;
        message = "thiniel: programs.fish.enable must be true (required for fish as login shell)";
      }
      {
        assertion = config.users.users.dan.shell == pkgs.fish;
        message = "thiniel: users.users.dan.shell must be set to pkgs.fish";
      }
      {
        assertion =
          let
            sysPkgNames = builtins.map (p: p.pname or p.name or "") config.environment.systemPackages;
            hmManagedTools = [
              "eza"
              "bat"
              "fd"
              "ripgrep"
              "fzf"
              "zoxide"
              "delta"
              "duf"
              "dust"
              "procs"
              "bottom"
            ];
          in
          !builtins.any (tool: builtins.elem tool sysPkgNames) hmManagedTools;
        message = "thiniel: CLI tools managed by Home Manager (shell-utils.nix) must not be duplicated in environment.systemPackages";
      }
      {
        assertion = !(config.services.greetd.settings ? initial_session);
        message = "thiniel: greetd must not use initial_session (auto-login). Use tuigreet with password for PAM keyring unlock.";
      }
      {
        assertion = config.services.gnome.gnome-keyring.enable;
        message = "thiniel: gnome-keyring must be enabled for D-Bus Secret Service (VS Code credential storage).";
      }
      {
        assertion = config.security.pam.services.greetd.enableGnomeKeyring;
        message = "thiniel: security.pam.services.greetd.enableGnomeKeyring must be true for PAM keyring auto-unlock on login.";
      }
      {
        assertion = config.services.greetd.useTextGreeter;
        message = "thiniel: greetd must use useTextGreeter to clear boot messages from the login TTY";
      }
      {
        assertion =
          let
            hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
          in
          builtins.elem "nodejs" hmPkgNames;
        message = "thiniel: Node.js must be installed for development";
      }
      {
        assertion =
          let
            hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
          in
          builtins.elem "python3" hmPkgNames;
        message = "thiniel: Python 3 must be installed for development";
      }
      {
        assertion =
          let
            hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
          in
          builtins.elem "podman" hmPkgNames;
        message = "thiniel: Podman must be installed via Home Manager for container development";
      }
    ];
  };
}
