{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Modern replacements for common commands
    eza           # Better ls
    bat           # Better cat
    fd            # Better find
    ripgrep       # Better grep
    fzf           # Fuzzy finder
    zoxide        # Better cd
    delta         # Better git diff
    duf           # Better df
    dust          # Better du
    procs         # Better ps
    bottom        # Better top

    # Useful utilities
    jq            # JSON processor
    yq            # YAML processor
    httpie        # Better curl
    tldr          # Simplified man pages
    tree          # Directory tree
    ncdu          # Disk usage analyzer

    # Development tools
    direnv        # Per-directory environments
    lazygit       # Terminal UI for git
  ];

  # Configure some of these tools
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin Latte";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Add aliases for the new tools
  programs.zsh.shellAliases = {
    ls = "eza";
    cat = "bat";
    find = "fd";
    grep = "rg";
    ps = "procs";
    top = "btm";
    du = "dust";
    df = "duf";
    cd = "z";  # From zoxide
  };
}
