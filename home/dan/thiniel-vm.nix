{
  config,
  inputs,
  outputs,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./global/linux.nix
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
    secrets = {
      # "git/personal/name" = {};
      # "git/personal/email" = {};
      # "git/personal/folder" = {};
      # Add more secrets as needed for testing
    };
  };

  # VM-specific shell aliases and configuration
  programs.zsh.shellAliases = {
    # VM-specific rebuild commands
    nrs = "sudo nixos-rebuild switch --flake ~/nix-config";
    nrt = "sudo nixos-rebuild test --flake ~/nix-config";
    nrb = "sudo nixos-rebuild boot --flake ~/nix-config";

    # VM management aliases
    vm-info = "uname -a && free -h && df -h";
    vm-rebuild = "sudo nixos-rebuild switch --flake ~/nix-config#thiniel-vm";
    vm-update = "nix flake update ~/nix-config && sudo nixos-rebuild switch --flake ~/nix-config#thiniel-vm";

    # Useful VM development aliases
    flake-check = "nix flake check ~/nix-config";
    flake-show = "nix flake show ~/nix-config";
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
    echo "🚀 Thiniel VM Environment Ready!"
    echo "💻 Configuration: ${config.home.homeDirectory}/nix-config"
    echo "🔧 Use 'vm-rebuild' to apply changes"

    # Auto-change to nix-config directory
    if [[ -d "$HOME/nix-config" ]]; then
      cd "$HOME/nix-config"
    fi
  '';
}
