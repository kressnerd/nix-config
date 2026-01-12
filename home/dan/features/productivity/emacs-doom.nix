{
  config,
  pkgs,
  lib,
  ...
}: {
  # Install Emacs declaratively via Nix (Henrik Lissner's approach)
  # Doom Emacs will manage its own packages via straight.el

  programs.emacs = {
    enable = true;
    package = pkgs.emacs; # Emacs 30.2 from nixpkgs
  };

  # Enable font configuration for macOS
  fonts.fontconfig.enable = true;

  # System-level dependencies and tools for Doom Emacs
  # These are NOT Emacs packages - they're external binaries
  home.packages = with pkgs;
    [
      # Core Doom dependencies
      git
      (ripgrep.override {withPCRE2 = true;})
      fd
      fontconfig # Required for nerd-icons font detection

      # Optional but recommended tools
      imagemagick # For image-dired
      zstd # For undo-tree compression

      # Spell checking - Hunspell with English and German dictionaries
      (hunspell.withDicts (dicts: [dicts.en_US dicts.de_DE]))

      # LSP servers (managed by Nix, used by Doom)
      nixd # Nix LSP
      nodePackages.typescript-language-server
      pyright # Python LSP
      rust-analyzer # Rust LSP
      nodePackages.bash-language-server
      nodePackages.yaml-language-server

      # Language formatters
      nixpkgs-fmt # Nix formatter
      nixfmt-rfc-style # Nix formatter (official)
      nodePackages.prettier
      black # Python formatter
      shfmt # Shell formatter
      stylelint # CSS linter
      nodePackages.js-beautify # JS beautifier

      # Build tools
      cmake
      gnumake

      # Python tools
      python3Packages.pyflakes
      python3Packages.isort
      python3Packages.nose2 # nose is deprecated/removed in newer python versions
      python3Packages.pytest
      pipenv

      # Rust tools
      cargo
      rustc

      # Shell tools
      shellcheck

      # Search tools (used by Doom's search features)
      silver-searcher # ag command

      # Document processing
      pandoc # Universal document converter

      # Org-mode tools
      sqlite # For org-roam
      graphviz # For org diagrams

      # Git tools (for Magit)
      git-crypt

      # Fonts for better Doom experience
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only # Required for nerd-icons in Doom Emacs

      # macOS specific
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      coreutils # Provides gls
      terminal-notifier # macOS notifications
      pinentry_mac # GPG pinentry for macOS
    ];

  # Doom Emacs installation and management
  # Following Henrik Lissner's dotfiles pattern
  home.activation = {
    # Remove old doom.d symlink if it exists (cleanup from previous setup)
    cleanupOldDoomConfig = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      DOOM_PRIVATE_DIR="${config.home.homeDirectory}/.config/doom"
      if [ -L "$DOOM_PRIVATE_DIR" ] || [ -e "$DOOM_PRIVATE_DIR" ]; then
        $VERBOSE_ECHO "Removing old doom.d configuration"
        $DRY_RUN_CMD rm -rf "$DOOM_PRIVATE_DIR"
      fi
    '';

    # Clone Doom Emacs if it doesn't exist
    installDoomEmacs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      DOOM_DIR="${config.home.homeDirectory}/.config/emacs"

      # Clone Doom Emacs if not present
      if [ ! -d "$DOOM_DIR" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs "$DOOM_DIR"
        $VERBOSE_ECHO "Cloned Doom Emacs to $DOOM_DIR"
      fi
    '';

    # Run doom sync after Home Manager activation
    # This keeps Doom packages in sync with doom.d configuration
    doomSync = lib.hm.dag.entryAfter ["installDoomEmacs" "linkGeneration"] ''
      DOOM_DIR="${config.home.homeDirectory}/.config/emacs"
      DOOM_BIN="$DOOM_DIR/bin/doom"

      if [ -x "$DOOM_BIN" ]; then
        $VERBOSE_ECHO "Running doom sync..."
        # Use the newly installed Emacs from Nix
        PATH="${pkgs.emacs}/bin:${pkgs.git}/bin:$PATH" $DRY_RUN_CMD "$DOOM_BIN" sync -e
      else
        $VERBOSE_ECHO "Doom binary not found at $DOOM_BIN, skipping sync"
        $VERBOSE_ECHO "Run 'doom install' manually after activation completes"
      fi
    '';
  };

  # Shell integration for Doom Emacs
  programs.fish = {
    shellAliases = {
      # Emacs aliases
      emacs = "emacsclient -c -a 'emacs'"; # Open in GUI, start daemon if needed
      e = "emacsclient -t -a 'emacs'"; # Open in terminal
      ec = "emacsclient -c -a 'emacs'"; # Open in GUI client

      # Doom CLI
      doom = "~/.config/emacs/bin/doom";

      # Restart Emacs daemon
      emacs-restart = "systemctl --user restart emacs";
    };

    shellInit = ''
      # Add Doom bin to PATH
      set -gx PATH $HOME/.config/emacs/bin $PATH

      # Environment variables
      set -gx EDITOR "emacsclient -t -a 'emacs'"
      set -gx VISUAL "emacsclient -c -a 'emacs'"
      set -gx DOOMDIR "${config.home.homeDirectory}/.config/doom"
      set -gx LSP_USE_PLISTS "true"
    '';
  };

  # Emacs daemon service
  services.emacs = {
    enable = true;
    client.enable = true;
    defaultEditor = true;
    startWithUserSession = "graphical";

    # Socket activation for faster startup
    socketActivation.enable = lib.mkIf (!pkgs.stdenv.isDarwin) true;

    # Add Nix packages to Emacs PATH (macOS GUI fix)
    extraOptions = lib.optionals pkgs.stdenv.isDarwin [
      "--eval"
      ''(setenv "PATH" (concat "${config.home.profileDirectory}/bin:" (getenv "PATH")))''
    ];
  };

  # Declaratively manage doom.d configuration
  # Home Manager will symlink this to ~/.config/doom
  xdg.configFile."doom" = {
    source = ./../../doom.d;
    recursive = true;
  };

  # Create necessary directories
  home.file = {
    # Org directory
    "org/.keep".text = "";
    "org/roam/.keep".text = "";
  };

  # macOS-specific configuration
  targets.darwin = lib.mkIf pkgs.stdenv.isDarwin {
    defaults = {
      # Register Emacs with macOS Launch Services
      "com.apple.LaunchServices" = {
        LSHandlers = [
          {
            LSHandlerContentType = "public.plain-text";
            LSHandlerRoleAll = "org.gnu.Emacs";
          }
          {
            LSHandlerContentType = "public.unix-executable";
            LSHandlerRoleAll = "org.gnu.Emacs";
          }
          {
            LSHandlerContentType = "public.data";
            LSHandlerRoleAll = "org.gnu.Emacs";
          }
          {
            LSHandlerContentType = "public.source-code";
            LSHandlerRoleAll = "org.gnu.Emacs";
          }
        ];
      };
    };
  };

  # Git configuration for better Magit integration
  programs.git.settings = {
    magit = {
      hideCursor = false;
    };
    diff = {
      algorithm = "histogram";
      compactionHeuristic = true;
    };
  };

  # GPG agent for commit signing (Magit)
  services.gpg-agent = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry_mac;
  };
}
