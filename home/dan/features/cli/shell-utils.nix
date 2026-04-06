{ pkgs, ... }:
{
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
    glab # GitLab CLI
    nil # Nix language server (LSP)
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

    # Cloud tools (moved to cloud-tools.nix module)
    # See features/cli/cloud-tools.nix for cloud CLI tools
  ];

  # Configure some of these tools
  programs = {
    eza = {
      enable = true;
      enableFishIntegration = true;
      git = true;
      icons = "auto";
    };

    bat = {
      enable = true;
      config.theme = "catppuccin-latte";
      # Catppuccin Latte theme for bat
      themes.catppuccin-latte = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-latte.tmTheme";
      };
    };

    fzf = {
      enable = true;
      # Catppuccin Latte colors
      defaultOptions = [
        "--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39"
        "--color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78"
        "--color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39"
        "--color=selected-bg:#bcc0cc,border:#ccd0da,label:#4c4f69"
      ];
    };

    lazygit = {
      enable = true;
      settings = {
        gui.theme = {
          activeBorderColor = [
            "#7287fd"
            "bold"
          ];
          inactiveBorderColor = [ "#4c4f69" ];
          optionsTextColor = [ "#1e66f5" ];
          selectedLineBgColor = [ "#ccd0da" ];
          cherryPickedCommitFgColor = [ "#1e66f5" ];
          cherryPickedCommitBgColor = [ "#7287fd" ];
          markedBaseCommitFgColor = [ "#fe640b" ];
          markedBaseCommitBgColor = [ "#df8e1d" ];
          unstagedChangesColor = [ "#d20f39" ];
          defaultFgColor = [ "#4c4f69" ];
        };
      };
    };

    zoxide.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
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
