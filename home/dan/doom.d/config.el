;;; config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;;; Personal Information
(setq user-full-name "Daniel Kressner"
      user-mail-address "daniel.kressner@example.com") ; Update with actual email

;;; UI Configuration
;; Font configuration for macOS - using available Nix fonts
;; Using JetBrains Mono as primary font (installed via nix packages)
(setq doom-font (font-spec :family "JetBrains Mono" :size 14 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "Helvetica" :size 16)
      doom-unicode-font (font-spec :family "Menlo" :size 14)
      doom-big-font (font-spec :family "JetBrains Mono" :size 20 :weight 'medium))

;; Fallback font configuration if JetBrains Mono is not available
(when (not (find-font doom-font))
  (setq doom-font (font-spec :family "Monaco" :size 14 :weight 'medium)
        doom-variable-pitch-font (font-spec :family "Arial" :size 16)
        doom-unicode-font (font-spec :family "Monaco" :size 14)
        doom-big-font (font-spec :family "Monaco" :size 20 :weight 'medium)))

;; Theme configuration - keeping doom-one from original
(setq doom-theme 'doom-one)

;; Modeline configuration
(setq doom-modeline-height 32
      doom-modeline-bar-width 3
      doom-modeline-icon t
      doom-modeline-major-mode-icon t
      doom-modeline-buffer-file-name-style 'truncate-upto-project)

;; Dashboard configuration
(setq doom-dashboard-name "Welcome to Doom Emacs"
      +doom-dashboard-menu-sections
      '(("Recently opened files" :icon (all-the-icons-octicon "file-text" :face 'doom-dashboard-menu-title) :action recentf-open-files)
        ("Open project" :icon (all-the-icons-octicon "briefcase" :face 'doom-dashboard-menu-title) :action projectile-switch-project)
        ("Jump to bookmark" :icon (all-the-icons-octicon "bookmark" :face 'doom-dashboard-menu-title) :action bookmark-jump)
        ("Open private configuration" :icon (all-the-icons-octicon "tools" :face 'doom-dashboard-menu-title) :action doom/open-private-config)
        ("Open documentation" :icon (all-the-icons-octicon "book" :face 'doom-dashboard-menu-title) :action doom/help)))

;;; macOS specific configuration
(when IS-MAC
  ;; macOS modifier keys - matching original configuration
  (setq mac-option-modifier 'meta
        mac-command-modifier 'super
        mac-right-option-modifier 'nil
        ns-use-native-fullscreen nil
        ns-use-fullscreen-animation nil)

  ;; Better scrolling on macOS - from original config
  (setq mouse-wheel-scroll-amount '(1 ((shift) . 1))
        mouse-wheel-progressive-speed nil
        mouse-wheel-follow-mouse t
        scroll-step 1
        scroll-conservatively 10000)

  ;; macOS specific keybindings - from original config
  (global-set-key (kbd "s-=") 'text-scale-increase)
  (global-set-key (kbd "s--") 'text-scale-decrease)
  (global-set-key (kbd "s-0") 'text-scale-adjust)

  ;; PATH integration - Doom handles this better than exec-path-from-shell
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;;; Editor Configuration
;; Line numbers - Doom enables this by default, but ensure it's configured properly
(setq display-line-numbers-type 'relative) ; Use relative line numbers for vim-style navigation

;; Disable line numbers in certain modes where they're not useful
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                treemacs-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Better defaults matching original configuration
(setq-default
 delete-by-moving-to-trash t                      ; Delete files to trash
 window-combination-resize t                      ; Take new window space from all other windows
 x-stretch-cursor t)                             ; Stretch cursor to the glyph width

(setq undo-limit 80000000                         ; Raise undo-limit to 80Mb
      evil-want-fine-undo t                       ; By default while in insert all changes are one big blob
      auto-save-default t                         ; Nobody likes to lose work
      truncate-string-ellipsis "…"                ; Unicode ellipses are nicer
      scroll-margin 2)                            ; It's nice to maintain a little margin

;;; Org Mode Configuration
(after! org
  ;; Better org defaults
  (setq org-directory "~/org/"
        org-agenda-files (list org-directory)
        org-ellipsis " ▾ "
        org-hide-emphasis-markers t
        org-log-done 'time
        org-startup-folded 'overview
        org-startup-with-inline-images t)

  ;; Org-roam configuration (using roam2 as per init.el)
  (setq org-roam-directory (file-truename "~/org/roam/")
        org-roam-dailies-directory "daily/"
        org-roam-completion-everywhere t))

;;; Development Configuration
;; LSP configuration - enhanced from original
(after! lsp-mode
  (setq lsp-keymap-prefix "C-c l"
        lsp-enable-symbol-highlighting t
        lsp-ui-doc-enable t
        lsp-ui-doc-show-with-cursor nil
        lsp-ui-doc-show-with-mouse t
        lsp-signature-render-documentation t
        lsp-completion-provider :company-capf)

  ;; Nix LSP configuration
  (add-hook 'nix-mode-hook #'lsp)
  
  ;; Performance optimizations
  (setq lsp-log-io nil
        lsp-idle-delay 0.500
        lsp-completion-provider :capf
        lsp-prefer-flymake nil))

;; Company configuration - enhanced from original
(after! company
  (setq company-idle-delay 0.2
        company-minimum-prefix-length 2
        company-tooltip-limit 20
        company-tooltip-align-annotations t
        company-require-match 'never
        company-global-modes '(not erc-mode message-mode help-mode gud-mode eshell-mode shell-mode)
        company-backends '(company-capf company-files company-keywords)
        company-auto-complete nil
        company-auto-complete-chars nil
        company-dabbrev-downcase nil
        company-dabbrev-ignore-case nil))

;; Projectile configuration - matching original
(after! projectile
  (setq projectile-completion-system 'ivy
        projectile-enable-caching t
        projectile-indexing-method 'hybrid))

;;; Nix Integration
;; Enhanced Nix support building on original configuration
(after! nix-mode
  (add-to-list 'company-backends 'company-nixos-options)
  
  ;; Better Nix indentation
  (setq nix-indent-function 'nix-indent-line)
  
  ;; Nix-specific keybindings
  (map! :localleader
        :map nix-mode-map
        "f" #'nix-format-buffer
        "r" #'nix-repl-show
        "s" #'nix-shell
        "b" #'nix-build
        "u" #'nix-unpack))

;; Company nixos-options integration
(after! company-nixos-options
  (add-to-list 'company-backends 'company-nixos-options))

;;; Git Integration
;; Magit configuration - enhanced from original
(after! magit
  (setq magit-repository-directories '(("~/dev" . 2))
        magit-save-repository-buffers nil
        magit-inhibit-save-previous-winconf 'user)
  
  ;; Better magit performance
  (setq magit-diff-refine-hunk t
        magit-revision-show-gravatars '("^Author:     " . "^Commit:     ")))

;;; Terminal Integration
;; VTerm configuration - enhanced from original
(after! vterm
  (setq vterm-max-scrollback 10000
        vterm-buffer-name-string "vterm %s"
        vterm-kill-buffer-on-exit t)
  
  ;; Better vterm keybindings
  (map! :map vterm-mode-map
        "C-c C-t" #'multi-vterm
        "C-c C-n" #'multi-vterm-next
        "C-c C-p" #'multi-vterm-prev))

;;; File Management
;; Dired configuration
(after! dired
  (setq dired-dwim-target t
        dired-recursive-copies 'always
        dired-recursive-deletes 'top
        delete-by-moving-to-trash t)
  
  ;; macOS specific dired configuration
  (when IS-MAC
    (setq dired-use-ls-dired nil
          insert-directory-program "/usr/bin/ls")))

;;; Custom Keybindings
;; Global keybindings from original configuration
(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-set-key (kbd "C-c r") 'revert-buffer)

;; Additional Doom-specific keybindings
(map! :leader
      ;; File operations
      "f r" #'recentf-open-files
      "f R" #'rename-file-and-buffer
      
      ;; Buffer operations
      "b r" #'revert-buffer
      "b R" #'rename-buffer
      
      ;; Project operations
      "p t" #'multi-vterm-project
      
      ;; Window operations
      "w =" #'balance-windows
      
      ;; Git operations
      "g s" #'magit-status
      "g b" #'magit-branch-checkout
      "g l" #'magit-log-oneline
      
      ;; Search operations
      "s p" #'projectile-ag
      "s d" #'ag-dired)

;;; Package-specific configurations
;; REST client configuration
(after! restclient
  (add-to-list 'auto-mode-alist '("\\.http\\'" . restclient-mode)))

;; Treemacs configuration
(after! treemacs
  (setq treemacs-width 32
        treemacs-follow-mode t
        treemacs-filewatch-mode t
        treemacs-fringe-indicator-mode 'always
        treemacs-git-mode 'extended))

;; Ivy configuration enhancements
(after! ivy
  (setq ivy-use-virtual-buffers t
        ivy-count-format "(%d/%d) "
        ivy-display-style 'fancy
        ivy-initial-inputs-alist nil)) ; Don't start searches with ^

;; Which-key configuration
(after! which-key
  (setq which-key-idle-delay 0.5
        which-key-popup-type 'side-window
        which-key-side-window-location 'bottom
        which-key-side-window-max-width 0.33
        which-key-side-window-max-height 0.25))

;;; Performance optimizations
;; Large file handling
(after! vlf-setup
  (setq vlf-application 'dont-ask))

;; Garbage collection optimization
(setq gc-cons-threshold 100000000
      read-process-output-max (* 1024 1024))

;;; Load local configuration if it exists
;; This allows for machine-specific configuration without modifying this file
(when (file-exists-p (concat doom-user-dir "local.el"))
  (load! "local"))

;; Load custom file if it exists (for customize interface)
(setq custom-file (expand-file-name "custom.el" doom-user-dir))
(when (file-exists-p custom-file)
  (load custom-file))