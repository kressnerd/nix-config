{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../tests/assertions/J6G6Y9JK7L-invariants.nix
    ./global/default.nix
    ./features/cli/ansible.nix
    ./features/cli/cloud-tools.nix
    ./features/cli/deploy-tools.nix
    ./features/cli/git.nix
    ./features/cli/kitty.nix
    ./features/cli/shell-utils.nix
    ./features/cli/sops.nix
    ./features/cli/ssh.nix
    ./features/cli/starship.nix
    ./features/cli/vim.nix
    ./features/cli/yazi.nix
    ./features/cli/fish.nix
    ./features/development/containers.nix
    ./features/development/formatters.nix
    ./features/development/go.nix
    ./features/development/python-tools.nix
    ./features/development/nodejs.nix
    ./features/development/fnm.nix
    ./features/development/omp.nix
    ./features/development/opencode.nix
    ./features/development/givn.nix
    ./features/macos/defaults.nix
    ./features/macos/aerospace.nix
    ./features/productivity/browser.nix
    ./features/productivity/firefox-company.nix
    # ./features/productivity/keepassxc.nix # installed via Homebrew cask to have signed version for quick unlock
    # ./features/productivity/vscode.nix
    ./features/productivity/mac-tools.nix
    ./features/productivity/emacs-doom.nix
  ];

  sops = {
    defaultSopsFile = ../../hosts/J6G6Y9JK7L/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
    secrets = {
      "git/personal/name" = { };
      "git/personal/email" = { };
      "git/personal/folder" = { };
      "git/company/name" = { };
      "git/company/email" = { };
      "git/company/folder" = { };
      "git/client001/name" = { };
      "git/client001/email" = { };
      "git/client001/folder" = { };
      "git/client002/name" = { };
      "git/client002/email" = { };
      "git/client002/folder" = { };
      "context7/api-key" = { };
      "kagi/api-key" = { };
      "github/access-token" = { };
    };

    # The rendered fragment is what this machine's nix clients read the
    # credential from; the include keeps the value out of every file the
    # configuration generates, so the owner and root read it by privilege.
    templates."nix-github-access-tokens" = {
      content = "access-tokens = github.com=${config.sops.placeholder."github/access-token"}\n";
      mode = "0400";
    };
  };

  # nix reads the owner's user configuration in every client; root's own
  # user configuration is written by the host module's activation script.
  xdg.configFile."nix/nix.conf".text = "!include ${
    config.sops.templates."nix-github-access-tokens".path
  }\n";

  # Identity material this device holds: its per-purpose personal key and the
  # manually maintained work-laptop ssh_config files it keeps.
  myHome.ssh = {
    personalIdentityFile = "~/.ssh/id_ed25519_personal_2026-10-04";
    includedConfigs = [
      "config.d/company"
      "config.d/client002"
      "config.d/nix-builder"
    ];
  };

  # Host-specific overrides
  # Disable App Management TCC check — JAMF MDM resets this permission on every check-in
  targets.darwin.copyApps.enableChecks = false;

  # Use Homebrew Cask kitty for GUI app
  # programs.kitty.enable remains true — HM still generates ~/.config/kitty/kitty.conf
  programs.kitty.package = pkgs.emptyDirectory;

  home = {
    username = "daniel.kressner";
    homeDirectory = "/Users/daniel.kressner";
    sessionPath = [ "$HOME/.cargo/bin" ];
    # The Rust formatter is no longer in the shared formatter module: the
    # laptop takes it from its declared Rust toolchain, and this host has no
    # such toolchain, so it declares the standalone package. See the change
    # `rust-coverage-toolchain`.
    packages = [ pkgs.rustfmt ];
  };

  # Host-specific shell aliases
  programs.fish.shellAliases = {
    drs = "sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config --override-input givn github:kressnerd/givn";
    # Colmena fleet deployment
    cs = "colmena apply --on";
    ct = "colmena apply --goal test --on";
    cb = "colmena apply --goal boot --on";
    cda = "colmena apply --goal dry-activate --on";
    call = "colmena apply";
  };

  # Fix for sops-nix on macOS: ensure /usr/bin is in PATH for getconf
  launchd.agents.sops-nix = {
    enable = true;
    config = {
      EnvironmentVariables = {
        PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin:${config.home.path}/bin";
      };
    };
  };
}
