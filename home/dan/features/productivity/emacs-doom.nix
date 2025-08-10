{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable Doom Emacs with declarative configuration via nix-doom-emacs-unstraightened
  programs.doom-emacs = {
    enable = true;
    doomDir = ./../../doom.d; # Point to our Doom configuration (home/dan/doom.d)
    provideEmacs = true; # Provides both doom-emacs and emacs binaries
  };

  # Enable Emacs daemon service for faster startup
  # Note: nix-doom-emacs-unstraightened automatically sets services.emacs.package
  services.emacs = {
    enable = true;
    defaultEditor = true; # Set emacsclient as default editor
    client.enable = true; # Generate emacsclient desktop file
    startWithUserSession = "graphical"; # Start with graphical session

    # Additional daemon options for macOS optimization
    extraOptions = [
      "--with-ns"
      "--with-native-compilation"
    ];
  };

  # Add essential development tools and LSP servers
  # These packages are used by Doom modules for various language support
  home.packages = with pkgs; [
    # LSP servers for various languages (from original config)
    nixd # Nix LSP server
    nodePackages.typescript-language-server
    pyright # Python LSP
    rust-analyzer # Rust LSP

    # Additional tools for development (many already in shell-utils.nix)
    silver-searcher # Another grep alternative (ag) - used by Doom search

    # Git tools (git already in git.nix)
    git-crypt

    # Fonts for better Doom Emacs experience (from original config)
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono

    # Additional tools that Doom Emacs modules may use
    (ripgrep.override {withPCRE2 = true;}) # Enhanced ripgrep for better search
    fd # Fast find alternative (used by Doom's file search)

    # Language-specific tools
    nodePackages.js-beautify # For web-mode formatting

    # Markdown and document processing
    pandoc # Universal document converter

    # Additional productivity tools
    sqlite # Used by org-roam
    graphviz # For org-mode diagrams

    # macOS specific tools
    (lib.mkIf pkgs.stdenv.isDarwin terminal-notifier) # For notifications
  ];

  # Configure shell environment for better Emacs integration
  # These aliases work with both vanilla Emacs and Doom Emacs
  programs.zsh = {
    shellAliases = {
      e = "emacsclient -n"; # Quick edit
      ec = "emacsclient -c"; # New frame
      et = "emacsclient -t"; # Terminal mode
      emacs-restart = "pkill -f emacs; emacs --daemon"; # Restart daemon

      # Doom-specific aliases
      doom = "doom"; # Doom CLI (available through nix-doom-emacs-unstraightened)
      doom-sync = "echo 'Doom sync not needed with Nix - rebuild instead'"; # Reminder
      doom-doctor = "doom doctor"; # Health check
    };

    sessionVariables = {
      EDITOR = "emacsclient -t";
      VISUAL = "emacsclient -c";

      # Doom-specific environment variables
      DOOMDIR = "${config.home.homeDirectory}/.config/nix-config/home/dan/doom.d";

      # Improve Doom performance
      LSP_USE_PLISTS = "true"; # Better LSP performance
    };
  };

  # macOS-specific configuration for better app integration
  targets.darwin.defaults = lib.mkIf pkgs.stdenv.isDarwin {
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
        # Additional file type associations for development
        {
          LSHandlerContentType = "public.source-code";
          LSHandlerRoleAll = "org.gnu.Emacs";
        }
        {
          LSHandlerContentType = "com.apple.property-list";
          LSHandlerRoleAll = "org.gnu.Emacs";
        }
      ];
    };
  };

  # Create necessary directories for Doom Emacs
  home.file = {
    # Create org directory if it doesn't exist
    "org/.keep".text = "";

    # Create org-roam directory
    "org/roam/.keep".text = "";

    # Create local config file placeholder for machine-specific settings
    ".config/doom/local.el".text = ''
      ;;; local.el --- Machine-specific Doom Emacs configuration

      ;; This file is loaded by config.el and can contain machine-specific
      ;; configuration that shouldn't be committed to version control.
      ;;
      ;; Examples:
      ;; - API keys or tokens
      ;; - Machine-specific paths
      ;; - Local network configurations
      ;; - Personal preferences that vary by machine

      ;; Example machine-specific configuration:
      ;; (setq user-mail-address "your-specific-email@example.com")
      ;; (setq org-directory "~/specific/path/to/org/")

      ;;; local.el ends here
    '';
  };

  # XDG configuration for proper Doom directory structure
  xdg.configHome = "${config.home.homeDirectory}/.config";

  # Additional services for enhanced Doom Emacs experience
  services = {
    # Enable GPG agent for signing commits (used by Magit)
    gpg-agent = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry_mac;
    };
  };

  # Development environment integration
  home.sessionPath = [
    # Add doom binary to PATH (provided by nix-doom-emacs-unstraightened)
    "${config.home.homeDirectory}/.nix-profile/bin"
  ];

  # Integration with other tools
  programs = {
    # Enhanced Git integration for Magit
    git = {
      extraConfig = {
        # Better Magit integration
        magit = {
          hideCursor = false;
        };

        # Improved diff display in Magit
        diff = {
          algorithm = "histogram";
          compactionHeuristic = true;
        };
      };
    };
  };
}
