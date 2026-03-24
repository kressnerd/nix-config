{pkgs, ...}: {
  home = {
    stateVersion = "25.11";

    # Basic user information
    username = "dan";
    homeDirectory = "/home/dan";

    # Essential user packages for VM environment
    packages = with pkgs; [
      # Basic utilities only to avoid conflicts
      htop
      tree
      curl
      wget
      unzip
    ];

    # Environment variables
    sessionVariables = {
      EDITOR = "vim";
      PAGER = "less";
    };
  };

  # Suppress options.json generation to avoid nixpkgs store path context warning
  manual.manpages.enable = false;

  # Let Home Manager manage itself
  programs = {
    home-manager.enable = true;

    # VM-specific shell configuration
    zsh = {
      shellAliases = {
        # VM-specific aliases (no conflicts with existing feature)
        vm-info = "uname -a && free -h && df -h";
      };
      initContent = ''
        # VM-specific shell configuration
        export EDITOR=vim
        echo "NixOS VM Environment Ready!"
      '';
    };

    # Basic git configuration (will be overridden by git.nix feature)
    git = {
      enable = true;
      settings.user = {
        name = "Dan";
        email = "dan@nixos-vm";
      };
    };
  };
}
