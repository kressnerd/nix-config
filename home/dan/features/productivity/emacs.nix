{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable Emacs with comprehensive configuration
  programs.emacs = {
    enable = true;
    package = pkgs.emacs; # Emacs 30 is available in stable

    # Essential Emacs packages for Nix ecosystem and productivity
    extraPackages = epkgs:
      with epkgs; [
        # Essential packages
        use-package # Package configuration management
        magit # Git integration
        company # Auto-completion framework
        ivy # Completion framework
        counsel # Ivy-enhanced commands
        swiper # Ivy-enhanced search
        projectile # Project management

        # Nix ecosystem support
        nix-mode # Nix language support
        nixos-options # NixOS options browser
        company-nixos-options # Company completion for NixOS options

        # Development tools
        lsp-mode # Language Server Protocol
        lsp-ui # LSP UI enhancements
        flycheck # Syntax checking
        yasnippet # Snippet system
        which-key # Keybinding help

        # File management and navigation
        dired-sidebar # File sidebar
        treemacs # Project tree
        neotree # File tree

        # Theme and appearance
        doom-themes # Modern themes
        doom-modeline # Modern modeline
        all-the-icons # Icon support

        # Org mode enhancements
        org-bullets # Pretty org bullets
        org-roam # Note-taking system

        # macOS specific
        exec-path-from-shell # Inherit shell PATH on macOS

        # Additional productivity
        markdown-mode # Markdown support
        yaml-mode # YAML support
        json-mode # JSON support
        web-mode # Web development
        restclient # REST API testing

        # Terminal integration
        vterm # Better terminal emulator
        multi-vterm # Multiple vterm instances
      ];

    # Basic Emacs configuration optimized for macOS and Nix
    extraConfig = ''
      ;; Basic settings
      (setq inhibit-startup-message t
            initial-scratch-message nil
            ring-bell-function 'ignore
            backup-directory-alist '((".*" . "~/.emacs.d/backups/"))
            auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t))
            custom-file (concat user-emacs-directory "custom.el"))

      ;; macOS specific settings
      (when (eq system-type 'darwin)
        ;; Fix PATH issues on macOS GUI applications
        (when (memq window-system '(mac ns x))
          (exec-path-from-shell-initialize))

        ;; macOS keybindings
        (setq mac-option-modifier 'meta
              mac-command-modifier 'super
              mac-right-option-modifier 'nil)

        ;; Better scrolling on macOS
        (setq mouse-wheel-scroll-amount '(1 ((shift) . 1))
              mouse-wheel-progressive-speed nil
              mouse-wheel-follow-mouse 't
              scroll-step 1))

      ;; UI improvements
      (menu-bar-mode -1)
      (tool-bar-mode -1)
      (scroll-bar-mode -1)
      (column-number-mode 1)
      (global-display-line-numbers-mode 1)
      (show-paren-mode 1)

      ;; Font configuration for macOS
      (when (eq system-type 'darwin)
        (set-face-attribute 'default nil
                            :family "SF Mono"
                            :height 140
                            :weight 'medium))

      ;; Enable use-package
      (require 'use-package)
      (setq use-package-always-ensure nil) ; We manage packages via Nix

      ;; Company mode configuration
      (use-package company
        :config
        (global-company-mode 1)
        (setq company-idle-delay 0.2
              company-minimum-prefix-length 2))

      ;; Ivy/Counsel/Swiper configuration
      (use-package ivy
        :config
        (ivy-mode 1)
        (setq ivy-use-virtual-buffers t
              ivy-count-format "(%d/%d) "))

      (use-package counsel
        :config
        (counsel-mode 1))

      (use-package swiper
        :bind ("C-s" . swiper))

      ;; Projectile configuration
      (use-package projectile
        :config
        (projectile-mode 1)
        (setq projectile-completion-system 'ivy)
        :bind-keymap
        ("C-c p" . projectile-command-map))

      ;; Magit configuration
      (use-package magit
        :bind ("C-x g" . magit-status))

      ;; Nix mode configuration
      (use-package nix-mode
        :mode "\\.nix\\'")

      ;; Company nixos-options
      (use-package company-nixos-options
        :config
        (add-to-list 'company-backends 'company-nixos-options))

      ;; LSP configuration
      (use-package lsp-mode
        :init
        (setq lsp-keymap-prefix "C-c l")
        :hook ((nix-mode . lsp)
               (lsp-mode . lsp-enable-which-key-integration))
        :commands lsp)

      (use-package lsp-ui
        :commands lsp-ui-mode)

      ;; Flycheck
      (use-package flycheck
        :config
        (global-flycheck-mode))

      ;; YASnippet
      (use-package yasnippet
        :config
        (yas-global-mode 1))

      ;; Which-key
      (use-package which-key
        :config
        (which-key-mode))

      ;; Theme configuration
      (use-package doom-themes
        :config
        (setq doom-themes-enable-bold t
              doom-themes-enable-italic t)
        (load-theme 'doom-one t)
        (doom-themes-visual-bell-config)
        (doom-themes-org-config))

      ;; Doom modeline
      (use-package doom-modeline
        :config
        (doom-modeline-mode 1))

      ;; All-the-icons (run M-x all-the-icons-install-fonts after first setup)
      (use-package all-the-icons)

      ;; Org mode enhancements
      (use-package org-bullets
        :hook (org-mode . org-bullets-mode))

      ;; File modes
      (use-package markdown-mode
        :mode (("README\\.md\\'" . gfm-mode)
               ("\\.md\\'" . markdown-mode)
               ("\\.markdown\\'" . markdown-mode)))

      (use-package yaml-mode
        :mode "\\.ya?ml\\'")

      (use-package json-mode
        :mode "\\.json\\'")

      ;; Custom keybindings
      (global-set-key (kbd "C-x C-b") 'ibuffer)
      (global-set-key (kbd "C-c r") 'revert-buffer)

      ;; macOS specific keybindings
      (when (eq system-type 'darwin)
        (global-set-key (kbd "s-=") 'text-scale-increase)
        (global-set-key (kbd "s--") 'text-scale-decrease)
        (global-set-key (kbd "s-0") 'text-scale-adjust))

      ;; Load custom file if it exists
      (when (file-exists-p custom-file)
        (load custom-file))
    '';
  };

  # Enable Emacs daemon service for faster startup
  services.emacs = {
    enable = true;
    package = pkgs.emacs;
    defaultEditor = true; # Set emacsclient as default editor
    client.enable = true; # Generate emacsclient desktop file
    startWithUserSession = "graphical"; # Start with graphical session

    # Additional daemon options for macOS optimization
    extraOptions = [
      "--with-ns"
      "--with-native-compilation"
    ];
  };

  # Add Emacs-related packages to user environment
  home.packages = with pkgs; [
    # LSP servers for various languages
    nixd # Nix LSP server
    nodePackages.typescript-language-server
    pyright # Python LSP (fixed package name)
    rust-analyzer # Rust LSP

    # Additional tools (many already in shell-utils.nix)
    # ripgrep, fd, git already installed in other modules
    silver-searcher # Another grep alternative (ag)

    # Git tools (git already in git.nix)
    git-crypt

    # Font for better Emacs experience
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  # Configure shell environment for better Emacs integration
  programs.zsh = {
    shellAliases = {
      e = "emacsclient -n"; # Quick edit
      ec = "emacsclient -c"; # New frame
      et = "emacsclient -t"; # Terminal mode
      emacs-restart = "pkill -f emacs; emacs --daemon"; # Restart daemon
    };

    sessionVariables = {
      EDITOR = "emacsclient -t";
      VISUAL = "emacsclient -c";
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
      ];
    };
  };
}
