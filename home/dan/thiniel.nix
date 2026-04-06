{ ... }:
{
  imports = [
    ./global/default.nix
    ./features/cli/fish.nix
    ./features/cli/git.nix
    ./features/cli/kitty.nix
    ./features/cli/shell-utils.nix
    ./features/cli/ssh.nix
    ./features/cli/starship.nix
    ./features/cli/vim.nix
    ./features/development/formatters.nix
    ./features/linux/hyprland.nix
    ./features/linux/impermanence.nix
    ./features/productivity/browser.nix
    ./features/productivity/firefox-personal.nix
    ./features/productivity/keepassxc.nix
    ./features/productivity/owncloud.nix
    ./features/productivity/sweethome3d.nix
    ./features/linux/fonts.nix
  ];

  # Host-specific overrides
  home = {
    username = "dan";
    homeDirectory = "/home/dan";
  };

  # SOPS configuration for thiniel - only personal secrets for security
  sops = {
    defaultSopsFile = ../../hosts/thiniel/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      "git/personal/name" = { };
      "git/personal/email" = { };
      "git/personal/folder" = { };
    };
  };

  # Host-specific shell aliases
  programs.fish.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake ~/Projects/nix-config";
    nrt = "sudo nixos-rebuild test --flake ~/Projects/nix-config";
    nrb = "sudo nixos-rebuild boot --flake ~/Projects/nix-config";
    # Remote deploy aliases — use --use-remote-sudo so target user does not need root SSH
    nrs-remote = "nixos-rebuild switch --flake ~/Projects/nix-config --use-remote-sudo --target-host";
    nrt-remote = "nixos-rebuild test --flake ~/Projects/nix-config --use-remote-sudo --target-host";
    nrb-remote = "nixos-rebuild boot --flake ~/Projects/nix-config --use-remote-sudo --target-host";
  };
}
