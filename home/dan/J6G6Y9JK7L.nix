{ config, inputs, outputs, ... }:

{
  imports = [
    ./global
    ./features/cli/git.nix
    ./features/cli/ssh.nix
    ./features/cli/vim.nix
    ./features/cli/zsh.nix
    ./features/productivity/vscode.nix
    ./features/productivity/tools.nix
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
