{
  config,
  pkgs,
  lib,
  pkgs-unstable,
  ...
}: {
  home.stateVersion = "25.11";

  # Basic user information
  home.username = "dan";
  home.homeDirectory = "/home/dan";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Import compatible features from existing modules
  # imports = [
  #   # Start with basic CLI tools that should work cross-platform
  #   ./features/cli/git.nix
  #   ./features/cli/vim.nix
  #   ./features/cli/zsh.nix
  #   ./features/cli/starship.nix
  #   # Add more features incrementally after testing
  # ];

  # VM-specific shell configuration
  programs.zsh = {
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

  # Essential user packages for VM environment
  home.packages = with pkgs; [
    # Basic utilities only to avoid conflicts
    htop
    tree
    curl
    wget
    unzip
  ];

  # Basic git configuration (will be overridden by git.nix feature)
  programs.git = {
    enable = true;
    settings.user = {
      name = "Dan";
      email = "dan@nixos-vm";
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    PAGER = "less";
  };
}
