{
  config,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./global
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
    ./features/productivity/vscode.nix
    ./features/productivity/tools.nix
#    ./features/productivity/emacs-doom.nix
  ];

  # Host-specific overrides
  home = {
    username = "daniel.kressner";
    homeDirectory = "/Users/daniel.kressner";
  };

  # Host-specific shell aliases
  programs.zsh.shellAliases = {
    drs = "sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config";
  };
}
