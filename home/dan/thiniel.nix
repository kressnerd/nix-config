{ ... }:
{
  imports = [
    ./global/default.nix
    ./features/cli/deploy-tools.nix
    ./features/cli/fish.nix
    ./features/cli/git.nix
    ./features/cli/kitty.nix
    ./features/cli/shell-utils.nix
    ./features/cli/ssh.nix
    ./features/cli/starship.nix
    ./features/cli/vim.nix
    ./features/development/claude-code.nix
    ./features/development/formatters.nix
    ./features/development/go.nix
    ./features/development/python-tools.nix
    ./features/linux/fonts.nix
    ./features/linux/gnome-keyring.nix
    ./features/linux/fuzzel.nix
    ./features/linux/hypridle.nix
    ./features/linux/hyprland.nix
    ./features/linux/hyprlock.nix
    ./features/linux/gtk-qt.nix
    ./features/linux/mako.nix
    ./features/linux/waybar.nix
    ./features/linux/impermanence.nix
    ./features/productivity/browser.nix
    ./features/productivity/firefox-personal.nix
    ./features/productivity/keepassxc.nix
    ./features/productivity/owncloud.nix
    ./features/productivity/sweethome3d.nix
    ./features/productivity/vscode-fhs.nix
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
    # Colmena fleet deployment
    cs = "colmena apply --on";
    ct = "colmena apply --goal test --on";
    cb = "colmena apply --goal boot --on";
    cda = "colmena apply --goal dry-activate --on";
    call = "colmena apply";
  };
}
