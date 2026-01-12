{pkgs, ...}: {
  home.packages = with pkgs; [
    # Modern replacements for common commands
    eza # Better ls
    bat # Better cat
    fd # Better find
    ripgrep # Better grep
    fzf # Fuzzy finder
    zoxide # Better cd
    delta # Better git diff
    sd # Better sed
    duf # Better df
    dust # Better du
    procs # Better ps
    bottom # Better top
    #    coreutils
    #    findutils
    #    gnugrep
    #    gnused
    #    gawk

    # Useful utilities
    jq # JSON processor
    yq # YAML processor
    httpie # Better curl
    tldr # Simplified man pages
    tree # Directory tree
    ncdu # Disk usage analyzer

    # Development tools
    direnv # Per-directory environments
    lazygit # Terminal UI for git
    #git
    #gh
    #delta # Better git diff
    #neovim
    #tmux
    #curl
    #wget
    #watch

    # Build tools
    #gnumake
    #cmake
    #pkg-config

    # Container tools
    #colima        # Docker Desktop alternative

    # Language tools
    #nodejs_20
    #python312
    go
    #rustup

    # Cloud tools (moved to cloud-tools.nix module)
    # See features/cli/cloud-tools.nix for cloud CLI tools
  ];

  # Configure some of these tools
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "catppuccin-latte";
    };

    # Add Catppuccin themes
    themes = {
      catppuccin-latte = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-latte.tmTheme";
      };
      catppuccin-frappe = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-frappe.tmTheme";
      };
      catppuccin-macchiato = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-macchiato.tmTheme";
      };
      catppuccin-mocha = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-mocha.tmTheme";
      };
    };
  };

  programs.fzf = {
    enable = true;
  };

  programs.zoxide = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Add aliases for the new tools
  # programs.fish.shellAliases = {
  #   ls = "eza";
  #   cat = "bat";
  #   ps = "procs";
  #   top = "btm";
  #   du = "dust";
  #   df = "duf";
  #   cd = "z"; # From zoxide
  # };
}
