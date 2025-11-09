{
  config,
  inputs,
  outputs,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./global/default.nix
    ./features/cli/git.nix
    ./features/cli/shell-utils.nix
    ./features/cli/vim.nix
    ./features/cli/zsh.nix
    ./features/cli/starship.nix
    ./features/linux/hyprland.nix
    ./features/linux/fonts.nix
    ./features/productivity/firefox-linux.nix
    # Note: No impermanence module for VM simplicity
    # Note: Can add more features incrementally for testing
  ];

  # Host-specific overrides
  home = {
    username = "dan";
    homeDirectory = "/home/dan";
    stateVersion = "25.05";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # SOPS configuration for thiniel-vm (simplified)
  sops = {
    defaultSopsFile = ../../hosts/thiniel-vm/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    secrets = {
      # "git/personal/name" = {};
      # "git/personal/email" = {};
      # "git/personal/folder" = {};
      # Add more secrets as needed for testing
    };
  };

  # VM-specific shell aliases and configuration
  programs.zsh.shellAliases = {
    # VM management aliases
    vm-info = "uname -a && free -h && df -h";
  };

  # VM-specific environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    BROWSER = "firefox";
    TERMINAL = "kitty";
    # VM identification
    VM_HOST = "thiniel-vm";
  };

  # Additional VM-specific packages for testing
  home.packages = with pkgs; [
    # Development tools for testing configurations
    nil # Nix LSP

    # VM utilities
    htop
    neofetch
    tree
    curl
    wget

    # Testing tools
    stress
    iperf3
  ];

  # Git configuration override for VM
  programs.git = {
    extraConfig = {
      # VM-specific git settings
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      # Safe directory for VM testing
      safe.directory = [
        "/home/dan/nix-config"
        "/home/dan/Projects/*"
      ];
    };
  };

  # VM-specific service configurations
  services = {
    # Enable clipboard manager for better VM integration
    clipmenu.enable = true;
  };

  # Additional shell initialization for VM
  programs.zsh.initContent = ''
    # VM Environment setup
    echo "Thiniel VM Environment Ready!"
    echo "Configuration: ${config.home.homeDirectory}/nix-config"
    echo "Use 'vm-rebuild' to apply changes"

    # Auto-change to nix-config directory
    if [[ -d "$HOME/nix-config" ]]; then
      cd "$HOME/nix-config"
    fi
  '';
}
