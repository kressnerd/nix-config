{
  config,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./global/linux.nix
    ./features/cli/git.nix
    ./features/cli/shell-utils.nix
    ./features/cli/vim.nix
    ./features/linux/hyprland.nix
    ./features/linux/impermanence.nix
    ./features/productivity/firefox-linux.nix
    ./features/linux/fonts.nix
  ];

  # Host-specific overrides
  home = {
    username = "dan";
    homeDirectory = "/home/dan";
  };

  # SOPS configuration for thiniel
  sops = {
    defaultSopsFile = ../../hosts/thiniel/secrets.yaml;
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

  # Host-specific shell aliases
  programs.zsh.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake ~/Projects/nix-config";
    nrt = "sudo nixos-rebuild test --flake ~/Projects/nix-config";
  };
}
