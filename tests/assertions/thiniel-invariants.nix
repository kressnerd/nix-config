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
    assertions =
      let
        sysPkgNames = builtins.map (p: p.pname or p.name or "") config.environment.systemPackages;
        hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
        hmHasPkg = name: builtins.elem name hmPkgNames;
      in
      [
        {
          assertion = builtins.any (
            p: lib.getName p == "opencode" && lib.versionAtLeast (lib.getVersion p) "2"
          ) config.home-manager.users.dan.home.packages;
          message = "thiniel: OpenCode 2.x (>= 2) must be installed";
        }
        {
          assertion = hmHasPkg "omp";
          message = "thiniel: Oh My Pi (omp) must be installed via Home Manager";
        }
        {
          assertion = config.networking.networkmanager.enable;
          message = "thiniel: networking.networkmanager must be enabled (desktop host)";
        }
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
          assertion = config.programs.seahorse.enable;
          message = "thiniel: Seahorse (GNOME keyring GUI) must be enabled";
        }
        {
          assertion = config.services.greetd.useTextGreeter;
          message = "thiniel: greetd must use useTextGreeter to clear boot messages from the login TTY";
        }
        {
          assertion = hmHasPkg "nodejs";
          message = "thiniel: Node.js must be installed for development";
        }
        {
          assertion = hmHasPkg "python3";
          message = "thiniel: Python 3 must be installed for development";
        }
        {
          assertion = hmHasPkg "podman";
          message = "thiniel: Podman must be installed via Home Manager for container development";
        }
        {
          assertion = hmHasPkg "maestral";
          message = "thiniel: Maestral must be installed via Home Manager for Dropbox sync";
        }
        {
          assertion = hmHasPkg "iotop";
          message = "thiniel: iotop must be installed via Home Manager for per-process I/O monitoring";
        }
        {
          assertion = hmHasPkg "iw";
          message = "thiniel: iw must be installed via Home Manager for wireless diagnostics";
        }
        {
          assertion = hmHasPkg "acpi";
          message = "thiniel: acpi must be installed via Home Manager for battery and thermal status";
        }
        {
          assertion = hmHasPkg "bind";
          message = "thiniel: bind (dig/nslookup) must be installed via Home Manager for DNS diagnostics";
        }
        {
          assertion = builtins.elem "lsof" sysPkgNames;
          message = "thiniel: lsof must be installed as a system package for listing open files and sockets";
        }
        {
          assertion = builtins.elem "strace" sysPkgNames;
          message = "thiniel: strace must be installed as a system package for system call tracing";
        }
        {
          assertion = config.programs.mtr.enable;
          message = "thiniel: programs.mtr must be enabled for network path diagnostics (traceroute with SUID wrapper)";
        }
        {
          assertion = hmHasPkg "givn";
          message = "thiniel: givn must be installed via Home Manager";
        }
        {
          assertion = builtins.elem "$HOME/.cargo/bin" config.home-manager.users.dan.home.sessionPath;
          message = "thiniel: ~/.cargo/bin must be in home-manager.users.dan.home.sessionPath";
        }
        # --- cli/ssh: identity selection ---
        # Scenario: The personal device reaches private repositories with the
        # identity it holds.
        {
          assertion =
            config.home-manager.users.dan.programs.ssh.settings."github-personal".data.IdentityFile
            == "~/.ssh/id_ed25519";
          message = "thiniel: the private-repository connection must resolve to the identity file thiniel holds (~/.ssh/id_ed25519), got ${
            config.home-manager.users.dan.programs.ssh.settings."github-personal".data.IdentityFile
          }";
        }
        {
          assertion =
            lib.hasInfix "ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes"
              config.home-manager.users.dan.sops.templates."git-personal".content;
          message = "thiniel: the workspace identity configuration must name the identity file thiniel holds";
        }
        # Scenario: A device declares no connection for an identity whose
        # material it does not hold.
        {
          assertion =
            !(config.home-manager.users.dan.programs.ssh.settings ? "github-company")
            && !(config.home-manager.users.dan.programs.ssh.settings ? "github-client001")
            && !(config.home-manager.users.dan.programs.ssh.settings ? "bitbucket-client002");
          message = "thiniel: no work identity connection entry may be declared without that identity's secret material, got ${builtins.toJSON (builtins.attrNames config.home-manager.users.dan.programs.ssh.settings)}";
        }
        {
          assertion = config.home-manager.users.dan.programs.ssh.includes == [ ];
          message = "thiniel: no manually maintained work-laptop ssh configuration file may be included, got ${builtins.toJSON config.home-manager.users.dan.programs.ssh.includes}";
        }
      ];
  };
}
