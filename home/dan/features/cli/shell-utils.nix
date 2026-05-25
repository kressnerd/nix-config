{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      # Modern replacements for common commands
      eza # ls alternative — better listing with icons and git status
      bat # cat alternative — syntax highlighting and git integration
      fd # find alternative — fast file search
      ripgrep # grep alternative — fast text search
      fzf # fuzzy finder — interactive filtering for files, history, etc.
      zoxide # cd alternative — smart directory jumping
      delta # diff alternative — syntax-highlighted git diffs
      sd # sed alternative — text substitution with simpler syntax
      duf # df alternative — disk usage overview with better formatting
      dust # du alternative — intuitive disk usage by directory
      procs # ps alternative — process list with colours and sorting
      bottom # top alternative — terminal resource monitor

      # Useful utilities
      jq # JSON processor — query and transform JSON data
      yq # YAML processor — query and transform YAML/JSON/TOML
      httpie # curl alternative — human-friendly HTTP client
      tldr # man alternative — simplified community-maintained docs
      tree # directory tree — recursive directory listing
      ncdu # disk usage analyzer — interactive ncurses du

      # TUI apps
      lazydocker # TUI for Docker and docker-compose management
      fastfetch # system information display — fast neofetch alternative

      # Development tools
      lazygit # TUI for git — interactive staging, rebasing, log
      glab # GitLab CLI — manage issues, MRs, pipelines from terminal
      nil # Nix language server — LSP for editor integration
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      bluetuith # TUI Bluetooth manager — Linux-only, requires bluez
      pulsemixer # TUI PulseAudio mixer — Linux-only volume control
      iotop # per-process I/O monitoring
      iw # wireless diagnostics — signal strength, channel
      acpi # battery and thermal status
      dig # DNS tools — dig, nslookup, host
    ];

  # Configure tools
  programs = {
    eza = {
      enable = true;
      enableFishIntegration = true;
      git = true;
      icons = "auto";
    };

    bat = {
      enable = true;
      # Theme injected by Stylix — no hardcoded theme needed
    };

    fzf = {
      enable = true;
      # Colors injected by Stylix — no hardcoded defaultOptions needed
    };

    lazygit = {
      enable = true;
      # Theme injected by Stylix — no hardcoded gui.theme needed
    };

    btop = {
      enable = true;
      settings = {
        vim_keys = true; # hjkl navigation in btop
      };
    };

    zoxide.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  # Stylix targets — explicit opt-in required because autoEnable = false
  stylix.targets = {
    bat.enable = true;
    fzf.enable = true;
    lazygit.enable = true;
    btop.enable = true;
  };

  # fastfetch: minimal module list; inherits terminal colours (no Stylix target needed)
  xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
    modules = [
      "title"
      "separator"
      "os"
      "kernel"
      "shell"
      "wm"
      "terminal"
      "cpu"
      "memory"
    ];
  };
}
