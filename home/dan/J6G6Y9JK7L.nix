{
  config,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./global/default.nix
    ./features/cli/cloud-tools.nix
    ./features/cli/git.nix
    ./features/cli/kitty.nix
    ./features/cli/shell-utils.nix
    ./features/cli/ssh.nix
    ./features/cli/starship.nix
    ./features/cli/vim.nix
    ./features/cli/zsh.nix
    ./features/development/containers.nix
    ./features/development/formatters.nix
    ./features/development/jdk.nix
    ./features/development/nodejs.nix
    ./features/macos/defaults.nix
    ./features/productivity/browser.nix
    # ./features/productivity/keepassxc.nix # installed via Homebrew cask to have signed version for quick unlock
    ./features/productivity/vscode.nix
    ./features/productivity/tools.nix
    ./features/productivity/emacs-doom.nix
  ];

  sops = {
    defaultSopsFile = ../../hosts/J6G6Y9JK7L/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
    secrets = {
      "git/personal/name" = {};
      "git/personal/email" = {};
      "git/personal/folder" = {};
      "git/company/name" = {};
      "git/company/email" = {};
      "git/company/folder" = {};
      "git/client001/name" = {};
      "git/client001/email" = {};
      "git/client001/folder" = {};
    };
  };

  # Host-specific overrides
  home = {
    username = "daniel.kressner";
    homeDirectory = "/Users/daniel.kressner";
  };
}
